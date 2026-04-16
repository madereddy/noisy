# noisy.py - Point d'entrée et orchestration principale
# IN: CLI args | OUT: none | MODIFIE: arrête le processus via stop_event
# APPELÉ PAR: __main__ | APPELLE: tous modules noisy_lib

import asyncio
import logging
import random
import sys
from typing import List, Optional
from urllib.parse import urlsplit

import aiohttp

from noisy_lib.config import DEFAULT_URL_BLACKLIST, DEFAULT_VISITED_MAX, SECONDS_PER_DAY
from noisy_lib.config_loader import build_parser, load_config_file, validate_args
from noisy_lib.crawler import SharedMetrics, UserCrawler
from noisy_lib.fetchers import fetch_crux_top_sites, fetch_user_agents
from noisy_lib.profiles import UAPool, UserProfile, _UA_FALLBACK
from noisy_lib.rate_limiter import DomainRateLimiter
from noisy_lib.structures import LRUSet
from noisy_lib.workers import dns_noise_worker, http_noise_worker, refresh_user_agents_loop, stats_reporter

log = logging.getLogger(__name__)


def setup_logging(level_str: str, logfile: Optional[str] = None):
    level = getattr(logging, level_str.upper(), logging.INFO)
    root = logging.getLogger()
    root.handlers.clear()
    root.setLevel(level)
    fmt = logging.Formatter("%(levelname)s - %(message)s")
    sh = logging.StreamHandler()
    sh.setFormatter(fmt)
    root.addHandler(sh)
    if logfile:
        fh = logging.FileHandler(logfile)
        fh.setFormatter(logging.Formatter("%(asctime)s - %(levelname)s - %(message)s"))
        root.addHandler(fh)
    logging.getLogger("aiohttp").setLevel(logging.DEBUG if level == logging.DEBUG else logging.ERROR)


async def main_async(args):
    setup_logging(args.log, args.logfile)

    errors = validate_args(args)
    if errors:
        for e in errors:
            log.error(f"[CONFIG] {e}")
        sys.exit(1)

    if args.dry_run:
        pq = max(10, args.max_queue_size // args.num_users)
        log.info(f"[DRY-RUN] threads={args.threads} users={args.num_users} depth={args.max_depth} | sleep=[{args.min_sleep},{args.max_sleep}]s delay={args.domain_delay}s")
        log.info(f"[DRY-RUN] crux={args.crux_count} dns_workers={args.dns_workers} timeout={args.timeout} | per_user_queue={pq} max_links={args.max_links_per_page}")
        return

    ua_pool = UAPool(_UA_FALLBACK)
    async with aiohttp.ClientSession() as session:
        top_sites = await fetch_crux_top_sites(session, count=args.crux_count)
        initial_uas = await fetch_user_agents(session)
        if initial_uas:
            await ua_pool.replace(initial_uas)

    if not top_sites:
        log.error("[FATAL] Aucun site CRUX chargé — arrêt.")
        return

    stop_event = asyncio.Event()
    shared_visited = LRUSet(maxsize=DEFAULT_VISITED_MAX)
    rate_limiter = DomainRateLimiter(domain_delay=args.domain_delay)
    shared_metrics = SharedMetrics()

    _rng = random.Random()
    ua_list = ua_pool.sample(args.num_users, rng=_rng)
    per_user_queue = max(10, args.max_queue_size // args.num_users)

    crawlers: List[UserCrawler] = []
    for i in range(args.num_users):
        profile = UserProfile(user_id=i, ua=ua_list[i], rng=random.Random(_rng.random()))
        sites = list(top_sites)
        profile.rng.shuffle(sites)
        crawlers.append(UserCrawler(
            profile=profile, shared_root_urls=sites[:500],
            shared_visited=shared_visited, rate_limiter=rate_limiter,
            max_depth=args.max_depth, concurrency=args.threads,
            min_sleep=args.min_sleep, max_sleep=args.max_sleep,
            max_queue_size=per_user_queue, max_links_per_page=args.max_links_per_page,
            url_blacklist=DEFAULT_URL_BLACKLIST, stop_event=stop_event,
            total_connections=args.total_connections,
            connections_per_host=args.connections_per_host,
            keepalive_timeout=args.keepalive_timeout,
            shared_metrics=shared_metrics,
        ))

    dns_hosts = [h for h in (urlsplit(s).hostname for s in top_sites) if h]
    ua_refresh_s = int(args.ua_refresh_days * SECONDS_PER_DAY)

    tasks = (
        [asyncio.create_task(c.run()) for c in crawlers]
        + [asyncio.create_task(dns_noise_worker(dns_hosts, stop_event, worker_id=i)) for i in range(args.dns_workers)]
        + [asyncio.create_task(stats_reporter(crawlers, stop_event)),
           asyncio.create_task(refresh_user_agents_loop(stop_event, ua_refresh_s, crawlers, ua_pool))]
        + [asyncio.create_task(http_noise_worker(dns_hosts, stop_event, worker_id=i))
           for i in range(args.post_noise_workers)]
    )

    if args.dashboard:
        from noisy_lib.dashboard import MetricsCollector, start_dashboard
        collector = MetricsCollector(
            crawlers, shared_visited, rate_limiter, ua_pool,
            shared_metrics, webhook_url=args.webhook_url,
        )
        tasks.append(asyncio.create_task(start_dashboard(collector, args.dashboard_port, args.dashboard_host)))

    if args.timeout:
        async def _stopper():
            await asyncio.sleep(args.timeout)
            stop_event.set()
        tasks.append(asyncio.create_task(_stopper()))
    await stop_event.wait()
    for t in tasks:
        t.cancel()
    await asyncio.gather(*tasks, return_exceptions=True)
    await asyncio.gather(*[asyncio.create_task(c.close()) for c in crawlers], return_exceptions=True)
    log.info("[FIN] main_async | arrêt propre")


def main():
    pre = __import__("argparse").ArgumentParser(add_help=False)
    pre.add_argument("--config")
    pre_args, _ = pre.parse_known_args()

    parser = build_parser()
    if pre_args.config:
        overrides = load_config_file(pre_args.config)
        if overrides:
            parser.set_defaults(**overrides)

    args = parser.parse_args()

    if args.validate_config:
        setup_logging(args.log)
        errors = validate_args(args)
        if errors:
            for e in errors:
                logging.error(f"[CONFIG] {e}")
            sys.exit(1)
        logging.info("[CONFIG] valide")
        sys.exit(0)

    try:
        asyncio.run(main_async(args))
    except KeyboardInterrupt:
        logging.info("[STOP] interruption clavier")


if __name__ == "__main__":
    main()
