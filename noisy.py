# noisy.py - queue-based forever crawler

import argparse
import asyncio
import csv
import gzip
import json
import logging
import random
import re
import ssl
import time
from collections import OrderedDict
from typing import List, Optional, Tuple
from urllib.parse import urlsplit, urljoin

import aiohttp
from bs4 import BeautifulSoup

# ---- CRUX ----
CRUX_TOP_CSV = "https://raw.githubusercontent.com/zakird/crux-top-lists/main/data/global/current.csv.gz"
DEFAULT_CRUX_COUNT = 10_000
DEFAULT_CRUX_REFRESH_DAYS = 31  # crux list updates once a month

# ---- USER AGENT POOL ----
UA_PAGE_URL = "https://www.useragents.me"
DEFAULT_UA_COUNT = 50
DEFAULT_UA_REFRESH_DAYS = 7  # useragents.me updates weekly

# ---- CRAWLER LIMITS ----
DEFAULT_MAX_QUEUE_SIZE = 100_000
DEFAULT_MAX_DEPTH = 5
DEFAULT_THREADS = 50

# ---- REQUEST TIMING ----
DEFAULT_MIN_SLEEP = 2
DEFAULT_MAX_SLEEP = 15
DEFAULT_DOMAIN_DELAY = 5.0  # seconds per domain

# ---- CONNECTION POOLING ----
DEFAULT_TOTAL_CONNECTIONS = 200
DEFAULT_CONNECTIONS_PER_HOST = 10
DEFAULT_KEEPALIVE_TIMEOUT = 30
DNS_CACHE_TTL = 3600

# ---- NETWORK ----
REQUEST_TIMEOUT = 15
MAX_RESPONSE_BYTES = 2 * 1024 * 1024
MAX_HEADER_SIZE = 32 * 1024

# ---- RUNTIME ----
DEFAULT_RUN_TIMEOUT_SECONDS = None  # None = run forever
SECONDS_PER_DAY = 24 * 60 * 60

# ---- VISITED URL CACHE ----
DEFAULT_VISITED_MAX = 500_000

# ---- DOMAIN CACHE ----
DEFAULT_DOMAIN_CACHE_MAX = 50_000

# ---- MISC ----
SYS_RANDOM = random.SystemRandom()


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

# Fallback UA list in case
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


# Fresh UA list
class UAPool:

    def __init__(self, initial: List[str]):
        self._pool: List[str] = list(initial)
        self._lock = asyncio.Lock()

    def get_random(self) -> str:
        return SYS_RANDOM.choice(self._pool)

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
            headers={"User-Agent": SYS_RANDOM.choice(_UA_FALLBACK)},
        ) as resp:
            resp.raise_for_status()
            raw = await resp.content.read(MAX_RESPONSE_BYTES)
            html = raw.decode(resp.charset or "utf-8", errors="replace")

        soup = BeautifulSoup(html, "html.parser")
        page_text = soup.get_text()

        agents: List[str] = []
        seen: set = set()

        for block in re.findall(r"\[\s*\{[^\[\]]+\}\s*\]", page_text):
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

    except Exception as e:
        logging.warning("UA fetch failed, keeping existing pool: %s", e)
        return []


class LRUSet:
    """Size-capped set that evicts the oldest entry when full."""

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


class TTLDict:
    """Dict that lazily evicts entries older than `ttl` seconds."""

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


def setup_logging(log_level_str: str, logfile: Optional[str] = None):
    level = getattr(logging, log_level_str.upper(), logging.INFO)
    root = logging.getLogger()
    root.setLevel(level)

    handler = logging.StreamHandler()
    handler.setFormatter(logging.Formatter("%(levelname)s - %(message)s"))
    root.addHandler(handler)

    if logfile:
        fh = logging.FileHandler(logfile)
        fh.setFormatter(logging.Formatter("%(asctime)s - %(levelname)s - %(message)s"))
        root.addHandler(fh)

    logging.getLogger("aiohttp").setLevel(logging.WARNING)


async def fetch_crux_top_sites(
    session: aiohttp.ClientSession,
    count: int = DEFAULT_CRUX_COUNT,
) -> List[str]:
    logging.info("Fetching CRUX top sites...")
    async with session.get(CRUX_TOP_CSV) as resp:
        resp.raise_for_status()
        data = await resp.read()

    csv_text = gzip.decompress(data).decode()
    reader = csv.DictReader(csv_text.splitlines())

    sites = []
    seen = set()
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


def extract_links(soup: BeautifulSoup, base_url: str) -> List[str]:
    base_tag = soup.find("base", href=True)
    effective_base = base_tag["href"] if base_tag else base_url

    links = []
    for tag in soup.find_all("a", href=True):
        resolved = urljoin(effective_base, tag["href"])
        if resolved.startswith("http"):
            links.append(resolved)
    return links


class QueueCrawler:

    def __init__(
        self,
        root_urls: List[str],
        max_depth: int,
        concurrency: int,
        min_sleep: float,
        max_sleep: float,
        crux_refresh_seconds: int,
        ua_refresh_seconds: int,
        max_queue_size: int,
        domain_delay: float,
        total_connections: int,
        connections_per_host: int,
        keepalive_timeout: int,
        visited_max: int = DEFAULT_VISITED_MAX,
        domain_cache_max: int = DEFAULT_DOMAIN_CACHE_MAX,
    ):
        self.queue: asyncio.Queue[Tuple[str, int]] = asyncio.Queue(
            maxsize=max_queue_size
        )
        self.root_urls = set(root_urls)
        for url in root_urls:
            try:
                self.queue.put_nowait((url, 0))
            except asyncio.QueueFull:
                break

        self.visited_urls: LRUSet = LRUSet(maxsize=visited_max)
        self._visited_lock = asyncio.Lock()

        self.semaphore = asyncio.Semaphore(concurrency)
        self.stop_event = asyncio.Event()
        self.concurrency = concurrency

        self.max_depth = max_depth
        self.min_sleep = min_sleep
        self.max_sleep = max_sleep
        self.crux_refresh_seconds = crux_refresh_seconds
        self.ua_refresh_seconds = ua_refresh_seconds
        self.domain_delay = domain_delay

        self.total_connections = total_connections
        self.connections_per_host = connections_per_host
        self.keepalive_timeout = keepalive_timeout

        self.domain_last_access: TTLDict = TTLDict(
            ttl=domain_delay * 10,
            maxsize=domain_cache_max,
        )
        self.domain_locks: OrderedDict = OrderedDict()
        self._domain_locks_max = domain_cache_max

    def safe_enqueue(self, url: str, depth: int):

        try:
            self.queue.put_nowait((url, depth))
        except asyncio.QueueFull:
            pass

    def _get_domain_lock(self, domain: str) -> asyncio.Lock:
        if domain in self.domain_locks:
            self.domain_locks.move_to_end(domain)
        else:
            self.domain_locks[domain] = asyncio.Lock()
            if len(self.domain_locks) > self._domain_locks_max:
                self.domain_locks.popitem(last=False)
        return self.domain_locks[domain]

    async def wait_for_domain(self, domain: str):
        lock = self._get_domain_lock(domain)
        async with lock:
            now = time.monotonic()
            last = self.domain_last_access.get(domain, 0)
            delta = now - last
            if delta < self.domain_delay:
                await asyncio.sleep(self.domain_delay - delta)
            self.domain_last_access.set(domain, time.monotonic())

    async def fetch(
        self, session: aiohttp.ClientSession, url: str
    ) -> Optional[Tuple[str, List[str]]]:
        async with self._visited_lock:
            if url in self.visited_urls:
                return None
            self.visited_urls.add(url)

        async with self.semaphore:
            try:
                domain = urlsplit(url).hostname
            except ValueError:
                domain = None
            if not domain:
                return None

            try:
                await self.wait_for_domain(domain)

                accept_headers = SYS_RANDOM.choice(ACCEPT_HEADERS_POOL)
                headers = {"User-Agent": ua_pool.get_random(), **accept_headers}
                timeout = aiohttp.ClientTimeout(total=REQUEST_TIMEOUT)

                async with session.get(
                    url,
                    headers=headers,
                    timeout=timeout,
                    ssl=SSL_CONTEXT,
                    allow_redirects=True,
                ) as resp:
                    resp.raise_for_status()
                    raw = await resp.content.read(MAX_RESPONSE_BYTES)
                    html = raw.decode(resp.charset or "utf-8", errors="replace")

                logging.info("Visited: %s", url)

                soup = BeautifulSoup(html, "html.parser")
                links = extract_links(soup, url)
                return html, links

            except aiohttp.ClientSSLError as e:
                logging.debug("SSL error skipping %s: %s", url, e)
                return None

            except Exception as e:
                async with self._visited_lock:
                    self.visited_urls.discard(url)
                logging.warning("Fetch failed %s: %s", url, e)
                return None

        await asyncio.sleep(SYS_RANDOM.uniform(self.min_sleep, self.max_sleep))

    async def crawl_worker(self, session: aiohttp.ClientSession):
        while not self.stop_event.is_set():
            try:
                url, depth = await self.queue.get()
            except asyncio.CancelledError:
                break

            if depth > self.max_depth:
                self.queue.task_done()
                continue

            result = await self.fetch(session, url)
            self.queue.task_done()

            if result and depth < self.max_depth:
                _, links = result
                for link in links:
                    self.safe_enqueue(link, depth + 1)

    async def refresh_crux_sites(self, session: aiohttp.ClientSession):
        await asyncio.sleep(10)
        while not self.stop_event.is_set():
            try:
                sites = await fetch_crux_top_sites(session)
                for site in sites:
                    if site not in self.root_urls:
                        self.root_urls.add(site)
                        self.safe_enqueue(site, 0)
                logging.info("CRUX refresh complete")
            except Exception as e:
                logging.error("CRUX refresh failed: %s", e)
            await asyncio.sleep(self.crux_refresh_seconds)

    async def refresh_user_agents(self, session: aiohttp.ClientSession):
        await asyncio.sleep(self.ua_refresh_seconds)
        while not self.stop_event.is_set():
            agents = await fetch_user_agents(session)
            if agents:
                await ua_pool.replace(agents)
                logging.info("UA pool refreshed (%d agents)", len(agents))
            await asyncio.sleep(self.ua_refresh_seconds)

    async def stop_after_timeout(self, timeout: int):
        logging.info("Crawler will stop after %d seconds", timeout)
        await asyncio.sleep(timeout)
        logging.info("Crawler timeout reached — stopping")
        self.stop_event.set()

    async def run_forever(self, timeout: Optional[int]):
        connector = aiohttp.TCPConnector(
            limit=self.total_connections,
            limit_per_host=self.connections_per_host,
            ttl_dns_cache=DNS_CACHE_TTL,
            keepalive_timeout=self.keepalive_timeout,
        )

        async with aiohttp.ClientSession(
            connector=connector,
            max_line_size=MAX_HEADER_SIZE,
            max_field_size=MAX_HEADER_SIZE,
        ) as session:
            tasks = []
            tasks.append(asyncio.create_task(self.refresh_crux_sites(session)))
            tasks.append(asyncio.create_task(self.refresh_user_agents(session)))

            if timeout:
                tasks.append(asyncio.create_task(self.stop_after_timeout(timeout)))

            workers = [
                asyncio.create_task(self.crawl_worker(session))
                for _ in range(self.concurrency)
            ]
            tasks.extend(workers)

            await self.stop_event.wait()

            for task in tasks:
                task.cancel()

            await asyncio.gather(*tasks, return_exceptions=True)
            logging.info("Crawler shut down cleanly")


async def main_async(args):
    setup_logging(args.log, args.logfile)

    crux_refresh_seconds = int(args.crux_refresh_days * SECONDS_PER_DAY)
    ua_refresh_seconds = int(args.ua_refresh_days * SECONDS_PER_DAY)

    async with aiohttp.ClientSession() as session:
        top_sites = await fetch_crux_top_sites(session)
        initial_uas = await fetch_user_agents(session)
        if initial_uas:
            await ua_pool.replace(initial_uas)

    crawler = QueueCrawler(
        root_urls=top_sites,
        max_depth=args.max_depth,
        concurrency=args.threads,
        min_sleep=args.min_sleep,
        max_sleep=args.max_sleep,
        crux_refresh_seconds=crux_refresh_seconds,
        ua_refresh_seconds=ua_refresh_seconds,
        max_queue_size=args.max_queue_size,
        domain_delay=args.domain_delay,
        total_connections=args.total_connections,
        connections_per_host=args.connections_per_host,
        keepalive_timeout=args.keepalive_timeout,
    )

    await crawler.run_forever(timeout=args.timeout)


def main():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--log", default="info", choices=["debug", "info", "warning", "error"]
    )
    parser.add_argument("--logfile")

    parser.add_argument("--threads", type=int, default=DEFAULT_THREADS)
    parser.add_argument("--max_depth", type=int, default=DEFAULT_MAX_DEPTH)

    parser.add_argument("--min_sleep", type=float, default=DEFAULT_MIN_SLEEP)
    parser.add_argument("--max_sleep", type=float, default=DEFAULT_MAX_SLEEP)
    parser.add_argument("--domain_delay", type=float, default=DEFAULT_DOMAIN_DELAY)

    parser.add_argument(
        "--total_connections", type=int, default=DEFAULT_TOTAL_CONNECTIONS
    )
    parser.add_argument(
        "--connections_per_host", type=int, default=DEFAULT_CONNECTIONS_PER_HOST
    )
    parser.add_argument(
        "--keepalive_timeout", type=int, default=DEFAULT_KEEPALIVE_TIMEOUT
    )

    parser.add_argument(
        "--crux_refresh_days", type=float, default=DEFAULT_CRUX_REFRESH_DAYS
    )
    parser.add_argument(
        "--ua_refresh_days",
        type=float,
        default=DEFAULT_UA_REFRESH_DAYS,
        help="How often to refresh the UA pool from useragents.me (days). Default: 7",
    )

    parser.add_argument("--max_queue_size", type=int, default=DEFAULT_MAX_QUEUE_SIZE)

    parser.add_argument(
        "--timeout",
        type=int,
        default=DEFAULT_RUN_TIMEOUT_SECONDS,
        help="Stop crawler after N seconds",
    )

    args = parser.parse_args()

    try:
        asyncio.run(main_async(args))
    except KeyboardInterrupt:
        logging.info("Interrupted — exiting cleanly")


if __name__ == "__main__":
    main()
