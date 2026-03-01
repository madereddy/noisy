# noisy.py - queue-based forever crawler

import argparse
import asyncio
import csv
import gzip
import logging
import random
import time
from collections import OrderedDict
from typing import List, Optional, Tuple
from urllib.parse import urlparse, urljoin

import aiohttp
import ssl
from bs4 import BeautifulSoup
from random_user_agent.user_agent import UserAgent
from random_user_agent.params import SoftwareName, OperatingSystem

# ---- CRUX ----
CRUX_TOP_CSV = "https://raw.githubusercontent.com/zakird/crux-top-lists/main/data/global/current.csv.gz"
DEFAULT_CRUX_COUNT = 10_000
DEFAULT_CRUX_REFRESH_DAYS = 31  # crux list updates once a month

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
DNS_CACHE_TTL = 300

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

software_names = [
    SoftwareName.CHROME.value,
    SoftwareName.FIREFOX.value,
    SoftwareName.EDGE.value,
]

operating_systems = [
    OperatingSystem.WINDOWS.value,
    OperatingSystem.LINUX.value,
    OperatingSystem.MACOS.value,
]

ua = UserAgent(
    software_names=software_names,
    operating_systems=operating_systems,
    limit=100,
)

try:
    import brotli as _brotli
    _BR_SUPPORTED = True
except ImportError:
    _BR_SUPPORTED = False

_ENCODING_WITH_BR = "gzip, deflate, br"
_ENCODING_WITHOUT_BR = "gzip, deflate"
_ACCEPT_ENCODING = _ENCODING_WITH_BR if _BR_SUPPORTED else _ENCODING_WITHOUT_BR

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

def _build_ssl_context() -> ssl.SSLContext:
    """
    Return an SSL context that tolerates legacy renegotiation (fixes the
    UNSAFE_LEGACY_RENEGOTIATION_DISABLED error seen on some hosts), while
    still verifying certificates for all other sites.
    """
    ctx = ssl.create_default_context()
    ctx.options |= getattr(ssl, "OP_LEGACY_SERVER_CONNECT", 0)
    return ctx

SSL_CONTEXT = _build_ssl_context()

class LRUSet:
    """A size-capped set that evicts the oldest entry when full."""

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
            self._data.popitem(last=False)  # evict oldest

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
        # Hard cap: evict oldest when over limit
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
    handler.setFormatter(logging.Formatter('%(levelname)s - %(message)s'))
    root.addHandler(handler)

    if logfile:
        fh = logging.FileHandler(logfile)
        fh.setFormatter(
            logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
        )
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


def extract_links(html: str, base_url: str) -> List[str]:
    soup = BeautifulSoup(html, "html.parser")

    # Honour <base href="..."> if present
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

    async def safe_enqueue(self, url: str, depth: int):
        try:
            self.queue.put_nowait((url, depth))
        except asyncio.QueueFull:
            pass

    def _get_domain_lock(self, domain: str) -> asyncio.Lock:
        """Return (and LRU-manage) a per-domain asyncio.Lock."""
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

    async def fetch(self, session: aiohttp.ClientSession, url: str) -> Optional[str]:
        async with self.semaphore:
            async with self._visited_lock:
                if url in self.visited_urls:
                    return None
                self.visited_urls.add(url)

            domain = urlparse(url).hostname
            if not domain:
                return None

            try:
                await self.wait_for_domain(domain)
                accept_headers = SYS_RANDOM.choice(ACCEPT_HEADERS_POOL)
                headers = {"User-Agent": ua.get_random_user_agent(), **accept_headers}
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

            except aiohttp.ClientSSLError as e:
                async with self._visited_lock:
                    pass  # leave in visited so we don't keep retrying
                logging.debug("SSL error skipping %s: %s", url, e)
                return None

            except Exception as e:
                async with self._visited_lock:
                    self.visited_urls.discard(url)
                logging.warning("Fetch failed %s: %s", url, e)
                return None

        await asyncio.sleep(SYS_RANDOM.uniform(self.min_sleep, self.max_sleep))
        return html

    async def crawl_worker(self, session: aiohttp.ClientSession):
        while not self.stop_event.is_set():
            try:
                url, depth = await self.queue.get()
            except asyncio.CancelledError:
                break

            if depth > self.max_depth:
                self.queue.task_done()
                continue

            html = await self.fetch(session, url)
            self.queue.task_done()

            if html and depth < self.max_depth:
                for link in extract_links(html, url):
                    await self.safe_enqueue(link, depth + 1)

    async def refresh_crux_sites(self, session: aiohttp.ClientSession):
        await asyncio.sleep(10)
        while not self.stop_event.is_set():
            try:
                sites = await fetch_crux_top_sites(session)
                for site in sites:
                    if site not in self.root_urls:
                        self.root_urls.add(site)
                        await self.safe_enqueue(site, 0)
                logging.info("CRUX refresh complete")
            except Exception as e:
                logging.error("CRUX refresh failed: %s", e)

            await asyncio.sleep(self.crux_refresh_seconds)

    async def stop_after_timeout(self, timeout: int):
        logging.info("Crawler will stop after %d seconds", timeout)
        await asyncio.sleep(timeout)
        logging.info("Crawler timeout reached — stopping")
        self.stop_event.set()

    async def run_forever(self, timeout: Optional[int]):
        """Start all crawler workers and background tasks, run until stop_event is set."""
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

    async with aiohttp.ClientSession() as session:
        top_sites = await fetch_crux_top_sites(session)

    crawler = QueueCrawler(
        root_urls=top_sites,
        max_depth=args.max_depth,
        concurrency=args.threads,
        min_sleep=args.min_sleep,
        max_sleep=args.max_sleep,
        crux_refresh_seconds=crux_refresh_seconds,
        max_queue_size=args.max_queue_size,
        domain_delay=args.domain_delay,
        total_connections=args.total_connections,
        connections_per_host=args.connections_per_host,
        keepalive_timeout=args.keepalive_timeout,
    )

    await crawler.run_forever(timeout=args.timeout)


def main():
    parser = argparse.ArgumentParser()

    parser.add_argument("--log", default="info",
                        choices=["debug", "info", "warning", "error"])
    parser.add_argument("--logfile")

    parser.add_argument("--threads", type=int, default=DEFAULT_THREADS)
    parser.add_argument("--max_depth", type=int, default=DEFAULT_MAX_DEPTH)

    parser.add_argument("--min_sleep", type=float, default=DEFAULT_MIN_SLEEP)
    parser.add_argument("--max_sleep", type=float, default=DEFAULT_MAX_SLEEP)
    parser.add_argument("--domain_delay", type=float, default=DEFAULT_DOMAIN_DELAY)

    parser.add_argument("--total_connections", type=int,
                        default=DEFAULT_TOTAL_CONNECTIONS)
    parser.add_argument("--connections_per_host", type=int,
                        default=DEFAULT_CONNECTIONS_PER_HOST)
    parser.add_argument("--keepalive_timeout", type=int,
                        default=DEFAULT_KEEPALIVE_TIMEOUT)

    parser.add_argument("--crux_refresh_days", type=float,
                        default=DEFAULT_CRUX_REFRESH_DAYS)

    parser.add_argument("--max_queue_size", type=int,
                        default=DEFAULT_MAX_QUEUE_SIZE)

    parser.add_argument("--timeout", type=int,
                        default=DEFAULT_RUN_TIMEOUT_SECONDS,
                        help="Stop crawler after N seconds")

    args = parser.parse_args()

    try:
        asyncio.run(main_async(args))
    except KeyboardInterrupt:
        logging.info("Interrupted — exiting cleanly")


if __name__ == "__main__":
    main()

