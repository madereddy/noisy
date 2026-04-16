# workers.py - Tâches fond : DNS bruit, stats, refresh UA
# IN: domains, crawlers, stop_event | OUT: none | MODIFIE: UAPool, profiles.ua
# APPELÉ PAR: noisy.py | APPELLE: fetchers, profiles, config

import asyncio
import logging
import random
import socket
import time
from typing import List, TYPE_CHECKING

from .config import DEFAULT_DNS_MAX_SLEEP, DEFAULT_DNS_MIN_SLEEP
from .fetchers import fetch_user_agents
from .profiles import _diurnal_weight

if TYPE_CHECKING:
    from .crawler import UserCrawler
    from .profiles import UAPool

log = logging.getLogger(__name__)


async def dns_noise_worker(
    domains: List[str],
    stop_event: asyncio.Event,
    min_sleep: float = DEFAULT_DNS_MIN_SLEEP,
    max_sleep: float = DEFAULT_DNS_MAX_SLEEP,
    worker_id: int = 0,
) -> None:
    """Résout des domaines aléatoires sans connexion HTTP (bruit DNS)."""
    log.info(f"[DEBUT] dns_noise_worker | id={worker_id} domains={len(domains)}")
    rng = random.Random()
    loop = asyncio.get_event_loop()
    while not stop_event.is_set():
        host = rng.choice(domains)
        try:
            await loop.getaddrinfo(host, None, proto=socket.IPPROTO_TCP)
            log.debug(f"[DNS] resolved={host}")
        except Exception as e:
            log.debug(f"[DNS] failed={host} {e}")
        hour = time.localtime().tm_hour + time.localtime().tm_min / 60
        scale = 1.0 / max(0.1, _diurnal_weight(hour))
        await asyncio.sleep(rng.uniform(min_sleep, max_sleep) * scale)


async def stats_reporter(crawlers: List["UserCrawler"], stop_event: asyncio.Event) -> None:
    """Rapporte les stats toutes les 60s : visités, échecs %, req/s."""
    prev_visited = 0
    prev_time = time.monotonic()
    while not stop_event.is_set():
        await asyncio.sleep(60)
        now = time.monotonic()
        total_v = sum(c.stats["visited"] for c in crawlers)
        total_f = sum(c.stats["failed"] for c in crawlers)
        total_q = sum(c.stats["queued"] for c in crawlers)
        rps = (total_v - prev_visited) / (now - prev_time)
        fail_pct = total_f / (total_v + total_f) * 100 if (total_v + total_f) > 0 else 0.0
        per_user = " | ".join(f"u{c.profile.user_id}:{c.stats['visited']}v" for c in crawlers)
        log.info(
            f"[STATS] visited={total_v} failed={total_f} ({fail_pct:.1f}%) "
            f"queued={total_q} rps={rps:.2f} | {per_user}"
        )
        prev_visited, prev_time = total_v, now


async def refresh_user_agents_loop(
    stop_event: asyncio.Event,
    ua_refresh_seconds: int,
    crawlers: List["UserCrawler"],
    ua_pool: "UAPool",
) -> None:
    """Rafraîchit le pool UA et tourne les agents par utilisateur."""
    import aiohttp
    log.info(f"[DEBUT] refresh_user_agents_loop | interval={ua_refresh_seconds}s")
    await asyncio.sleep(ua_refresh_seconds)
    async with aiohttp.ClientSession() as session:
        while not stop_event.is_set():
            agents = await fetch_user_agents(session)
            if agents:
                await ua_pool.replace(agents)
                for crawler, ua in zip(crawlers, ua_pool.sample(len(crawlers))):
                    crawler.profile.ua = ua
            await asyncio.sleep(ua_refresh_seconds)


async def http_noise_worker(
    domains: List[str],
    stop_event: asyncio.Event,
    worker_id: int = 0,
    min_sleep: float = 10,
    max_sleep: float = 60,
) -> None:
    """Envoie des HEAD HTTP aléatoires pour diversifier le mix de méthodes (read-only)."""
    import aiohttp as _aiohttp
    from .profiles import SSL_CONTEXT, _UA_FALLBACK
    log.info(f"[DEBUT] http_noise_worker | id={worker_id}")
    rng = random.Random()
    timeout = _aiohttp.ClientTimeout(total=10)
    async with _aiohttp.ClientSession() as session:
        while not stop_event.is_set():
            host = rng.choice(domains)
            url = f"https://{host}/"
            ua = rng.choice(_UA_FALLBACK)
            headers = {"User-Agent": ua}
            try:
                async with session.head(
                    url, headers=headers,
                    timeout=timeout, ssl=SSL_CONTEXT, allow_redirects=False,
                ) as resp:
                    log.debug(f"[HEAD] host={host} status={resp.status}")
            except Exception:
                pass
            hour = time.localtime().tm_hour + time.localtime().tm_min / 60
            scale = 1.0 / max(0.1, _diurnal_weight(hour))
            await asyncio.sleep(rng.uniform(min_sleep, max_sleep) * scale)
