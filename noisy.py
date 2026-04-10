# noisy.py - queue-based forever crawler

import argparse
import asyncio
import csv
import gzip
import json
import logging
import math
import random
import re
import socket
import ssl
import time
from collections import OrderedDict
from html.parser import HTMLParser
from typing import Dict, List, Optional, Tuple
from urllib.parse import urlsplit, urljoin
import weakref

import aiohttp

# ---- CRUX ----
CRUX_TOP_CSV = "https://raw.githubusercontent.com/zakird/crux-top-lists/main/data/global/current.csv.gz"
DEFAULT_CRUX_COUNT = 10_000
DEFAULT_CRUX_REFRESH_DAYS = 31

# ---- USER AGENT POOL ----
UA_PAGE_URL = "https://www.useragents.me"
DEFAULT_UA_COUNT = 50
DEFAULT_UA_REFRESH_DAYS = 7

# ---- CRAWLER LIMITS ----
DEFAULT_MAX_QUEUE_SIZE = 100_000
DEFAULT_MAX_DEPTH = 5
DEFAULT_THREADS = 10

# ---- VIRTUAL USERS ----
DEFAULT_NUM_USERS = 5

# ---- REQUEST TIMING ----
DEFAULT_MIN_SLEEP = 2
DEFAULT_MAX_SLEEP = 15
DEFAULT_DOMAIN_DELAY = 5.0

# ---- CONNECTION POOLING (per user) ----
DEFAULT_TOTAL_CONNECTIONS = 40
DEFAULT_CONNECTIONS_PER_HOST = 4
DEFAULT_KEEPALIVE_TIMEOUT = 30

# ---- DNS cache TTL ----
DNS_CACHE_TTL = 120

# ---- NETWORK ----
REQUEST_TIMEOUT = 15
MAX_RESPONSE_BYTES = 512 * 1024
MAX_HEADER_SIZE = 32 * 1024

# ---- RUNTIME ----
DEFAULT_RUN_TIMEOUT_SECONDS = None
SECONDS_PER_DAY = 24 * 60 * 60

# ---- VISITED URL CACHE ----
DEFAULT_VISITED_MAX = 500_000

# ---- LINK SAMPLING ----
DEFAULT_MAX_LINKS_PER_PAGE = 50

# ---- DNS-ONLY NOISE ----
DEFAULT_DNS_WORKERS = 3
DEFAULT_DNS_MIN_SLEEP = 5
DEFAULT_DNS_MAX_SLEEP = 30

_RANDOM = random.Random()

# Diurnal activity curve
def _diurnal_weight(hour: float) -> float:
    t = (hour - 4) / 24 * 2 * math.pi
    evening_t = (hour - 20) / 6 * math.pi
    daytime = 0.5 + 0.5 * math.cos(t + math.pi)
    evening_boost = max(0.0, math.cos(evening_t) * 0.4)
    return max(0.05, min(1.0, daytime + evening_boost))


def _activity_pause_seconds(rng: random.Random) -> float:
    """5% chance of an AFK pause (5-30 min)."""
    if rng.random() < 0.05:
        return rng.uniform(300, 1800)
    return 0.0


# SSL
def _build_ssl_context() -> ssl.SSLContext:
    ctx = ssl.create_default_context()
    ctx.options |= getattr(ssl, "OP_LEGACY_SERVER_CONNECT", 0)
    return ctx


SSL_CONTEXT = _build_ssl_context()

try:
    import brotli as _brotli
    _BR_SUPPORTED = True
except ImportError:
    _BR_SUPPORTED = False

_ACCEPT_ENCODING = "gzip, deflate, br" if _BR_SUPPORTED else "gzip, deflate"

ACCEPT_HEADERS_POOL = [
    {
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
        "Accept-Language": "en-US,en;q=0.9",
        "Accept-Encoding": _ACCEPT_ENCODING,
        "Cache-Control": "no-cache",
        "Pragma": "no-cache",
        "Upgrade-Insecure-Requests": "1",
    },
    {
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Language": "en-GB,en;q=0.8,en-US;q=0.6",
        "Accept-Encoding": _ACCEPT_ENCODING,
        "Cache-Control": "max-age=0",
        "Upgrade-Insecure-Requests": "1",
    },
    {
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8",
        "Accept-Language": "en-US,en;q=0.7",
        "Accept-Encoding": _ACCEPT_ENCODING,
        "Upgrade-Insecure-Requests": "1",
    },
]

_UA_FALLBACK = [
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:123.0) Gecko/20100101 Firefox/123.0",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 14.3; rv:123.0) Gecko/20100101 Firefox/123.0",
    "Mozilla/5.0 (X11; Linux x86_64; rv:123.0) Gecko/20100101 Firefox/123.0",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36 Edg/122.0.0.0",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_3_1) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.3.1 Safari/605.1.15",
    "Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36",
]

# Per-user UA fingerprint
class UserProfile:
    def __init__(self, user_id: int, ua: str, rng: random.Random):
        self.user_id = user_id
        self.ua = ua
        self.rng = rng
        self.accept_headers = rng.choice(ACCEPT_HEADERS_POOL).copy()
        self.sleep_phase_offset = rng.uniform(-1.5, 1.5)

    def get_headers(self, referrer: Optional[str] = None) -> dict:
        h = self.accept_headers.copy()
        h["User-Agent"] = self.ua
        if referrer:
            h["Referer"] = referrer
        return h

    def diurnal_weight(self) -> float:
        hour = time.localtime().tm_hour + time.localtime().tm_min / 60
        return _diurnal_weight((hour + self.sleep_phase_offset) % 24)

# UA pool
class UAPool:
    def __init__(self, initial: List[str]):
        self._pool: List[str] = list(initial)
        self._lock = asyncio.Lock()

    def get_random(self) -> str:
        return _RANDOM.choice(self._pool)

    def sample(self, n: int) -> List[str]:
        pool = self._pool
        if len(pool) >= n:
            return _RANDOM.sample(pool, n)
        return [_RANDOM.choice(pool) for _ in range(n)]

    async def replace(self, agents: List[str]) -> None:
        async with self._lock:
            self._pool = list(agents)

    def __len__(self) -> int:
        return len(self._pool)


ua_pool = UAPool(_UA_FALLBACK)


async def fetch_user_agents(
    session: aiohttp.ClientSession,
    count: int = DEFAULT_UA_COUNT,
) -> List[str]:
    logging.info("Fetching user agents from useragents.me...")
    try:
        async with session.get(
            UA_PAGE_URL,
            timeout=aiohttp.ClientTimeout(total=15),
            ssl=SSL_CONTEXT,
            headers={"User-Agent": _RANDOM.choice(_UA_FALLBACK)},
        ) as resp:
            if resp.status >= 400:
                logging.warning("UA source returned %s", resp.status)
                return []
            raw = await resp.content.read(MAX_RESPONSE_BYTES)
            text = raw.decode(resp.charset or "utf-8", errors="replace")

        agents: List[str] = []
        seen: set = set()
        for block in re.findall(r"\[\s*\{[^\[\]]+\}\s*\]", text):
            try:
                for entry in json.loads(block):
                    ua_str = entry.get("ua", "").strip()
                    if ua_str and ua_str not in seen:
                        seen.add(ua_str)
                        agents.append(ua_str)
            except (json.JSONDecodeError, AttributeError):
                continue
        if not agents:
            raise ValueError("No UA strings found in useragents.me page")
        agents = agents[:count]
        logging.info("Loaded %d user agents", len(agents))
        return agents
    except (aiohttp.ClientError, asyncio.TimeoutError, ssl.SSLError) as e:
        logging.warning("UA fetch failed, keeping existing pool: %s", e)
        return []
    except Exception:
        logging.exception("Unexpected failure while fetching user agents")
        return []

# HTML link extractor
class LinkExtractor(HTMLParser):
    def __init__(self, base_url: str):
        super().__init__()
        self.base_url = base_url
        self.links: List[str] = []

    def handle_starttag(self, tag: str, attrs):
        attr_dict = dict(attrs)
        if tag == "base" and "href" in attr_dict:
            self.base_url = attr_dict["href"]
        elif tag == "a" and "href" in attr_dict:
            resolved = urljoin(self.base_url, attr_dict["href"])
            if resolved.startswith("http"):
                self.links.append(resolved)


def extract_links(html: str, base_url: str) -> List[str]:
    parser = LinkExtractor(base_url)
    try:
        parser.feed(html)
    except (ValueError, RuntimeError) as e:
        logging.debug("HTML parsing issue at %s: %s", base_url, e)
    except Exception:
        logging.exception("Unexpected parser failure at %s", base_url)
    return parser.links

# Bounded / LRU helpers
class LRUSet:
    def __init__(self, maxsize: int):
        self._data: OrderedDict = OrderedDict()
        self._maxsize = maxsize

    def __contains__(self, item) -> bool:
        return item in self._data

    def add(self, item):
        if item in self._data:
            self._data.move_to_end(item)
            return
        self._data[item] = None
        if len(self._data) > self._maxsize:
            self._data.popitem(last=False)

    def discard(self, item):
        self._data.pop(item, None)

    def __len__(self) -> int:
        return len(self._data)


class BoundedDict:
    def __init__(self, maxsize: int):
        self._data: OrderedDict = OrderedDict()
        self._maxsize = maxsize

    def get(self, key, default=None):
        return self._data.get(key, default)

    def set(self, key, value):
        if key in self._data:
            self._data.move_to_end(key)
        self._data[key] = value
        if len(self._data) > self._maxsize:
            self._data.popitem(last=False)

    def pop(self, key, default=None):
        return self._data.pop(key, default)

    def __contains__(self, key):
        return key in self._data


class TTLDict:
    def __init__(self, ttl: float, maxsize: int):
        self._data: OrderedDict = OrderedDict()
        self._times: dict = {}
        self._ttl = ttl
        self._maxsize = maxsize

    def get(self, key, default=None):
        self._maybe_evict(key)
        return self._data.get(key, default)

    def set(self, key, value):
        now = time.monotonic()
        self._data[key] = value
        self._times[key] = now
        self._data.move_to_end(key)
        while len(self._data) > self._maxsize:
            oldest = next(iter(self._data))
            del self._data[oldest]
            del self._times[oldest]

    def _maybe_evict(self, key):
        if key in self._times:
            if time.monotonic() - self._times[key] > self._ttl:
                del self._data[key]
                del self._times[key]

# DNS-only noise worker
async def dns_noise_worker(
    domains: List[str],
    stop_event: asyncio.Event,
    min_sleep: float = DEFAULT_DNS_MIN_SLEEP,
    max_sleep: float = DEFAULT_DNS_MAX_SLEEP,
    worker_id: int = 0,
) -> None:
    """Resolve random hostnames without making HTTP connections."""
    rng = random.Random()
    loop = asyncio.get_event_loop()
    logging.info("DNS noise worker %d started (%d candidate domains)", worker_id, len(domains))
    while not stop_event.is_set():
        host = rng.choice(domains)
        try:
            await loop.getaddrinfo(host, None, proto=socket.IPPROTO_TCP)
            logging.debug("DNS-only: resolved %s", host)
        except socket.gaierror:
            logging.debug("DNS-only: NXDOMAIN/timeout for %s", host)
        except Exception as exc:
            logging.debug("DNS-only: error for %s: %s", host, exc)

        hour = time.localtime().tm_hour + time.localtime().tm_min / 60
        weight = max(0.1, _diurnal_weight(hour))
        scale = 1.0 / weight
        await asyncio.sleep(rng.uniform(min_sleep, max_sleep) * scale)

# Per-user crawler
class UserCrawler:
    def __init__(
        self,
        profile: UserProfile,
        shared_root_urls: List[str],
        shared_visited: LRUSet,
        max_depth: int,
        concurrency: int,
        min_sleep: float,
        max_sleep: float,
        domain_delay: float,
        total_connections: int,
        connections_per_host: int,
        keepalive_timeout: int,
        max_queue_size: int,
        max_links_per_page: int,
        stop_event: asyncio.Event,
    ):
        self.profile = profile
        self.rng = profile.rng
        self.root_urls = set(shared_root_urls)
        self.shared_visited = shared_visited
        self.stop_event = stop_event
        self.max_depth = max_depth
        self.concurrency = concurrency
        self.min_sleep = min_sleep
        self.max_sleep = max_sleep
        self.domain_delay = domain_delay
        self.max_links_per_page = max_links_per_page

        self.queue: asyncio.Queue = asyncio.Queue(maxsize=max_queue_size)
        for url in shared_root_urls:
            try:
                self.queue.put_nowait((url, 0, None))
            except asyncio.QueueFull:
                break

        self.semaphore = asyncio.Semaphore(concurrency)
        self.domain_last_access: TTLDict = TTLDict(ttl=domain_delay * 10, maxsize=50_000)
        self._domain_locks: weakref.WeakValueDictionary = weakref.WeakValueDictionary()
        self._domain_locks_hard: dict = {}
        self._domain_lock_refcounts: dict = {}
        self.failed_counts: BoundedDict = BoundedDict(maxsize=10_000)
        self.max_failures = 3
        self.stats: Dict[str, int] = {"visited": 0, "failed": 0, "queued": 0}

        self._connector = aiohttp.TCPConnector(
            limit=total_connections,
            limit_per_host=connections_per_host,
            ttl_dns_cache=DNS_CACHE_TTL,
            keepalive_timeout=keepalive_timeout,
        )
        self._session: Optional[aiohttp.ClientSession] = None

    async def _get_session(self) -> aiohttp.ClientSession:
        if self._session is None:
            self._session = aiohttp.ClientSession(
                connector=self._connector,
                max_line_size=MAX_HEADER_SIZE,
                max_field_size=MAX_HEADER_SIZE,
            )
        return self._session

    async def close(self):
        if self._session:
            await self._session.close()
            self._session = None
        await self._connector.close()

    def _get_domain_lock(self, domain: str) -> asyncio.Lock:
        lock = self._domain_locks.get(domain)
        if lock is None:
            lock = asyncio.Lock()
            self._domain_locks[domain] = lock
        self._domain_locks_hard[domain] = lock
        self._domain_lock_refcounts[domain] = self._domain_lock_refcounts.get(domain, 0) + 1
        return lock

    def _release_domain_lock_ref(self, domain: str) -> None:
        count = self._domain_lock_refcounts.get(domain, 1) - 1
        if count <= 0:
            self._domain_locks_hard.pop(domain, None)
            self._domain_lock_refcounts.pop(domain, None)
        else:
            self._domain_lock_refcounts[domain] = count

    async def wait_for_domain(self, domain: str):
        lock = self._get_domain_lock(domain)
        try:
            async with lock:
                now = time.monotonic()
                last = self.domain_last_access.get(domain, 0)
                delta = now - last
                wait_time = max(0, self.domain_delay * self.rng.uniform(0.8, 1.2) - delta)
                if wait_time > 0:
                    await asyncio.sleep(wait_time)
                self.domain_last_access.set(domain, time.monotonic())
        finally:
            self._release_domain_lock_ref(domain)

    def _try_mark_visited(self, url: str) -> bool:
        if url in self.shared_visited:
            return False
        self.shared_visited.add(url)
        return True

    async def fetch(
        self,
        url: str,
        depth: int,
        referrer: Optional[str],
    ) -> Optional[List[Tuple[str, Optional[str]]]]:
        async with self.semaphore:
            try:
                domain = urlsplit(url).hostname
            except ValueError:
                domain = None
            if not domain:
                return None

            if not self._try_mark_visited(url):
                return None

            logging.debug("[user%d] Visiting %s (ref: %s)", self.profile.user_id, url, referrer)

            session = await self._get_session()
            try:
                await self.wait_for_domain(domain)
                headers = self.profile.get_headers(referrer=referrer)
                timeout = aiohttp.ClientTimeout(total=REQUEST_TIMEOUT)

                async with session.get(
                    url,
                    headers=headers,
                    timeout=timeout,
                    ssl=SSL_CONTEXT,
                    allow_redirects=True,
                ) as resp:
                    if resp.status >= 400:
                        self.stats["failed"] += 1
                        return None
                    raw = await resp.content.read(MAX_RESPONSE_BYTES)
                    html = raw.decode(resp.charset or "utf-8", errors="replace")
                    del raw

                self.stats["visited"] += 1

                links = extract_links(html, url)
                del html
                
                logging.debug(
                    "[user%d] %s -> extracted %d links",
                    self.profile.user_id, url, len(links),
                )

                if links:
                    if len(links) > self.max_links_per_page:
                        links = self.rng.sample(links, self.max_links_per_page)
                    else:
                        self.rng.shuffle(links)
                    logging.debug(
                        "[user%d] queuing %d child links (ref=%s)",
                        self.profile.user_id, len(links), url,
                    )

                if self.rng.random() < 0.05:
                    for root_url in self.root_urls:
                        self._safe_enqueue(root_url, 0, None)

                pause = _activity_pause_seconds(self.rng)
                if pause:
                    logging.debug("[user%d] AFK pause %.0fs", self.profile.user_id, pause)
                    await asyncio.sleep(pause)
                else:
                    weight = max(0.05, self.profile.diurnal_weight())
                    scale = 1.0 / weight
                    await asyncio.sleep(
                        self.rng.uniform(self.min_sleep, self.max_sleep)
                        * (1 + depth * 0.3)
                        * self.rng.uniform(0.8, 1.5)
                        * scale
                    )

                self.failed_counts.pop(url, None)
                return [(link, url) for link in links] if links else []

            except (aiohttp.ClientError, asyncio.TimeoutError, ssl.SSLError):
                self.shared_visited.discard(url)
                self.stats["failed"] += 1
                self._record_failure(url)
                return None
            except Exception:
                self.shared_visited.discard(url)
                logging.exception("[user%d] Unexpected error fetching %s", self.profile.user_id, url)
                self._record_failure(url)
                return None

    def _record_failure(self, url: str):
        count = (self.failed_counts.get(url, 0) or 0) + 1
        if count >= self.max_failures:
            self.failed_counts.pop(url, None)
            self.root_urls.discard(url)
        else:
            self.failed_counts.set(url, count)

    def _safe_enqueue(self, url: str, depth: int, referrer: Optional[str]):
        try:
            self.queue.put_nowait((url, depth, referrer))
            self.stats["queued"] += 1
        except asyncio.QueueFull:
            logging.debug("[user%d] Queue full, dropping %s", self.profile.user_id, url)

    async def crawl_worker(self):
        while not self.stop_event.is_set():
            try:
                url, depth, referrer = await self.queue.get()
            except asyncio.CancelledError:
                break
            if depth > self.max_depth:
                self.queue.task_done()
                continue
            result = await self.fetch(url, depth, referrer)
            self.queue.task_done()
            if result is not None and depth < self.max_depth:
                for child_url, child_ref in result:
                    self._safe_enqueue(child_url, depth + 1, child_ref)
            elif result is not None and depth >= self.max_depth:
	            logging.debug("[user%d] max_depth %d reached, not following links from %s",
	                    self.profile.user_id, self.max_depth, url)

    async def run(self):
        workers = [asyncio.create_task(self.crawl_worker()) for _ in range(self.concurrency)]
        await self.stop_event.wait()
        for w in workers:
            w.cancel()
        await asyncio.gather(*workers, return_exceptions=True)
        await self.close()

# Shared tasks
async def fetch_crux_top_sites(
    session: aiohttp.ClientSession, count: int = DEFAULT_CRUX_COUNT
) -> List[str]:
    logging.info("Fetching CRUX top sites...")
    async with session.get(CRUX_TOP_CSV) as resp:
        if resp.status >= 400:
            logging.error("CRUX fetch failed with status %s", resp.status)
            return []
        data = await resp.read()
    csv_text = gzip.decompress(data).decode()
    reader = csv.DictReader(csv_text.splitlines())
    sites, seen = [], set()
    for row in reader:
        origin = row.get("origin")
        if origin and origin not in seen:
            seen.add(origin)
            if not origin.startswith("http"):
                origin = f"https://{origin}"
            sites.append(origin)
        if len(sites) >= count:
            break
    logging.info("Loaded %d CRUX sites", len(sites))
    return sites


def setup_logging(log_level_str: str, logfile: Optional[str] = None):
    level = getattr(logging, log_level_str.upper(), logging.INFO)
    root = logging.getLogger()
    root.handlers.clear()
    root.setLevel(level)
    formatter = logging.Formatter("%(levelname)s - %(message)s")
    sh = logging.StreamHandler()
    sh.setFormatter(formatter)
    root.addHandler(sh)
    if logfile:
        fh = logging.FileHandler(logfile)
        fh.setFormatter(logging.Formatter("%(asctime)s - %(levelname)s - %(message)s"))
        root.addHandler(fh)
    logging.getLogger("aiohttp").setLevel(
        logging.DEBUG if level == logging.DEBUG else logging.ERROR
    )


async def stats_reporter(crawlers: List[UserCrawler], stop_event: asyncio.Event):
    while not stop_event.is_set():
        await asyncio.sleep(60)
        total_v = sum(c.stats["visited"] for c in crawlers)
        total_f = sum(c.stats["failed"] for c in crawlers)
        total_q = sum(c.stats["queued"] for c in crawlers)
        per_user = " | ".join(f"u{c.profile.user_id}:{c.stats['visited']}v" for c in crawlers)
        logging.info("Stats | visited=%d failed=%d queued=%d | %s", total_v, total_f, total_q, per_user)


async def refresh_user_agents_loop(
    stop_event: asyncio.Event,
    ua_refresh_seconds: int,
    crawlers: List[UserCrawler],
):
    await asyncio.sleep(ua_refresh_seconds)
    async with aiohttp.ClientSession() as session:
        while not stop_event.is_set():
            agents = await fetch_user_agents(session)
            if agents:
                await ua_pool.replace(agents)
                sampled = ua_pool.sample(len(crawlers))
                for crawler, ua in zip(crawlers, sampled):
                    crawler.profile.ua = ua
                logging.info("UA pool refreshed (%d agents)", len(agents))
            await asyncio.sleep(ua_refresh_seconds)

# Entry point
async def main_async(args):
    setup_logging(args.log, args.logfile)

    async with aiohttp.ClientSession() as session:
        top_sites = await fetch_crux_top_sites(session, count=args.crux_count)
        initial_uas = await fetch_user_agents(session)
        if initial_uas:
            await ua_pool.replace(initial_uas)

    if not top_sites:
        logging.error("No seed sites loaded; exiting.")
        return

    crux_refresh_seconds = int(args.crux_refresh_days * SECONDS_PER_DAY)
    ua_refresh_seconds = int(args.ua_refresh_days * SECONDS_PER_DAY)

    stop_event = asyncio.Event()
    shared_visited: LRUSet = LRUSet(maxsize=DEFAULT_VISITED_MAX)

    num_users = args.num_users
    ua_list = ua_pool.sample(num_users)
    profiles = [
        UserProfile(user_id=i, ua=ua_list[i], rng=random.Random(_RANDOM.random()))
        for i in range(num_users)
    ]

    crawlers: List[UserCrawler] = []
    for profile in profiles:
        user_sites = list(top_sites)
        profile.rng.shuffle(user_sites)
        crawler = UserCrawler(
            profile=profile,
            shared_root_urls=user_sites[:500],
            shared_visited=shared_visited,

            max_depth=args.max_depth,
            concurrency=args.threads,
            min_sleep=args.min_sleep,
            max_sleep=args.max_sleep,
            domain_delay=args.domain_delay,
            total_connections=args.total_connections,
            connections_per_host=args.connections_per_host,
            keepalive_timeout=args.keepalive_timeout,
            max_queue_size=args.max_queue_size // num_users,
            max_links_per_page=args.max_links_per_page,
            stop_event=stop_event,
        )
        crawlers.append(crawler)

    dns_hosts: List[str] = [
        h for h in (urlsplit(s).hostname for s in top_sites) if h
    ]

    tasks = []
    for crawler in crawlers:
        tasks.append(asyncio.create_task(crawler.run()))
    for i in range(args.dns_workers):
        tasks.append(asyncio.create_task(dns_noise_worker(dns_hosts, stop_event, worker_id=i)))
    tasks.append(asyncio.create_task(stats_reporter(crawlers, stop_event)))
    tasks.append(asyncio.create_task(refresh_user_agents_loop(stop_event, ua_refresh_seconds, crawlers)))

    if args.timeout:
        async def _stopper():
            logging.info("Will stop after %d seconds", args.timeout)
            await asyncio.sleep(args.timeout)
            logging.info("Timeout reached — stopping")
            stop_event.set()
        tasks.append(asyncio.create_task(_stopper()))

    await stop_event.wait()
    for t in tasks:
        t.cancel()
    await asyncio.gather(*tasks, return_exceptions=True)

	# Explicitly close each crawler's session and connector
    close_tasks = [asyncio.create_task(c.close()) for c in crawlers]
    await asyncio.gather(*close_tasks, return_exceptions=True)

    logging.info("All tasks shut down cleanly.")


def main():
    parser = argparse.ArgumentParser(
        description="DNS/HTTP noise generator"
    )
    parser.add_argument("--log", default="info", choices=["debug", "info", "warning", "error"])
    parser.add_argument("--logfile")
    parser.add_argument("--threads", type=int, default=DEFAULT_THREADS,
                        help="Concurrent workers per virtual user (default: %(default)s)")
    parser.add_argument("--num_users", type=int, default=DEFAULT_NUM_USERS,
                        help="Number of virtual users to simulate (default: %(default)s)")
    parser.add_argument("--max_depth", type=int, default=DEFAULT_MAX_DEPTH)
    parser.add_argument("--min_sleep", type=float, default=DEFAULT_MIN_SLEEP)
    parser.add_argument("--max_sleep", type=float, default=DEFAULT_MAX_SLEEP)
    parser.add_argument("--domain_delay", type=float, default=DEFAULT_DOMAIN_DELAY)
    parser.add_argument("--total_connections", type=int, default=DEFAULT_TOTAL_CONNECTIONS,
                        help="Max TCP connections per virtual user (default: %(default)s)")
    parser.add_argument("--connections_per_host", type=int, default=DEFAULT_CONNECTIONS_PER_HOST)
    parser.add_argument("--keepalive_timeout", type=int, default=DEFAULT_KEEPALIVE_TIMEOUT)
    parser.add_argument("--crux_count", type=int, default=DEFAULT_CRUX_COUNT)
    parser.add_argument("--crux_refresh_days", type=float, default=DEFAULT_CRUX_REFRESH_DAYS)
    parser.add_argument("--ua_refresh_days", type=float, default=DEFAULT_UA_REFRESH_DAYS)
    parser.add_argument("--max_queue_size", type=int, default=DEFAULT_MAX_QUEUE_SIZE)
    parser.add_argument("--max_links_per_page", type=int, default=DEFAULT_MAX_LINKS_PER_PAGE)
    parser.add_argument("--dns_workers", type=int, default=DEFAULT_DNS_WORKERS,
                        help="Background DNS-only noise workers (default: %(default)s)")
    parser.add_argument("--timeout", type=int, default=DEFAULT_RUN_TIMEOUT_SECONDS,
                        help="Stop after N seconds. Default: run forever")
    args = parser.parse_args()
    try:
        asyncio.run(main_async(args))
    except KeyboardInterrupt:
        logging.info("Interrupted — exiting cleanly")


if __name__ == "__main__":
    main()
