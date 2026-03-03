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
from html.parser import HTMLParser
from typing import Iterator, List, Optional
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
DEFAULT_THREADS = 50

# ---- REQUEST TIMING ----
DEFAULT_MIN_SLEEP = 2
DEFAULT_MAX_SLEEP = 15
DEFAULT_DOMAIN_DELAY = 5.0

# ---- CONNECTION POOLING ----
DEFAULT_TOTAL_CONNECTIONS = 200
DEFAULT_CONNECTIONS_PER_HOST = 10
DEFAULT_KEEPALIVE_TIMEOUT = 30
DNS_CACHE_TTL = 3600

# ---- NETWORK ----
REQUEST_TIMEOUT = 15
MAX_RESPONSE_BYTES = 512 * 1024
MAX_HEADER_SIZE = 32 * 1024

# ---- RUNTIME ----
DEFAULT_RUN_TIMEOUT_SECONDS = None
SECONDS_PER_DAY = 24 * 60 * 60

# ---- VISITED URL CACHE ----
DEFAULT_VISITED_MAX = 500_000

# ---- DOMAIN CACHE ----
DEFAULT_DOMAIN_CACHE_MAX = 50_000

# ---- FAILED URL CACHE ----
DEFAULT_FAILED_CACHE_MAX = 10_000

# ---- LINK SAMPLING ----
DEFAULT_MAX_LINKS_PER_PAGE = 50

# ---- MISC ----
_RANDOM = random.Random()


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


class UAPool:
    def __init__(self, initial: List[str]):
        self._pool: List[str] = list(initial)
        self._lock = asyncio.Lock()

    def get_random(self) -> str:
        return _RANDOM.choice(self._pool)

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
    root.handlers.clear()
    root.setLevel(level)
    formatter = logging.Formatter("%(levelname)s - %(message)s")
    stream_handler = logging.StreamHandler()
    stream_handler.setFormatter(formatter)
    root.addHandler(stream_handler)
    if logfile:
        file_handler = logging.FileHandler(logfile)
        file_handler.setFormatter(
            logging.Formatter("%(asctime)s - %(levelname)s - %(message)s")
        )
        root.addHandler(file_handler)
    logging.getLogger("aiohttp").setLevel(
        logging.DEBUG if level == logging.DEBUG else logging.ERROR
    )


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
        seed_crux_on_start: bool = False,
        visited_max: int = DEFAULT_VISITED_MAX,
        domain_cache_max: int = DEFAULT_DOMAIN_CACHE_MAX,
        failed_cache_max: int = DEFAULT_FAILED_CACHE_MAX,
        max_links_per_page: int = DEFAULT_MAX_LINKS_PER_PAGE,
    ):
        self.queue: asyncio.Queue = asyncio.Queue(maxsize=max_queue_size)
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
        self.max_links_per_page = max_links_per_page
        self._seed_crux_on_start = seed_crux_on_start
        self.domain_last_access: TTLDict = TTLDict(
            ttl=domain_delay * 10, maxsize=domain_cache_max
        )
        self._domain_locks: weakref.WeakValueDictionary = weakref.WeakValueDictionary()
        self._domain_locks_hard: dict = {}
        self._domain_lock_refcounts: dict = {}
        self.stats = {"visited": 0, "failed": 0, "queued": 0}
        self.failed_counts: BoundedDict = BoundedDict(maxsize=failed_cache_max)
        self.max_failures = 3

    async def report_stats(self):
        while not self.stop_event.is_set():
            await asyncio.sleep(60)
            logging.info(
                "Stats | visited=%d failed=%d queued=%d queue_size=%d",
                self.stats["visited"],
                self.stats["failed"],
                self.stats["queued"],
                self.queue.qsize(),
            )

    def safe_enqueue(self, url: str, depth: int):
        try:
            self.queue.put_nowait((url, depth))
            self.stats["queued"] += 1
        except asyncio.QueueFull:
            logging.debug("Queue full, dropping %s", url)

    def _get_domain_lock(self, domain: str) -> asyncio.Lock:
        lock = self._domain_locks.get(domain)
        if lock is None:
            lock = asyncio.Lock()
            self._domain_locks[domain] = lock

        self._domain_locks_hard[domain] = lock
        self._domain_lock_refcounts[domain] = (
            self._domain_lock_refcounts.get(domain, 0) + 1
        )
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
                wait_time = max(0, self.domain_delay * _RANDOM.uniform(0.8, 1.2) - delta)
                if wait_time > 0:
                    await asyncio.sleep(wait_time)
                self.domain_last_access.set(domain, time.monotonic())
        finally:
            self._release_domain_lock_ref(domain)

    async def _try_mark_visited(self, url: str) -> bool:
        async with self._visited_lock:
            if url in self.visited_urls:
                return False
            self.visited_urls.add(url)
            return True

    async def fetch(
        self, session: aiohttp.ClientSession, url: str, depth: int
    ) -> Optional[List[str]]:
        async with self.semaphore:
            try:
                domain = urlsplit(url).hostname
            except ValueError:
                domain = None
            if not domain:
                return None

            if not await self._try_mark_visited(url):
                return None

            logging.debug("Visiting URL: %s", url)

            try:
                await self.wait_for_domain(domain)
                headers = _RANDOM.choice(ACCEPT_HEADERS_POOL).copy()
                if _RANDOM.random() < 0.7:
                    headers["User-Agent"] = ua_pool.get_random()
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

                if links:
                    if len(links) > self.max_links_per_page:
                        links = _RANDOM.sample(links, self.max_links_per_page)
                    else:
                        _RANDOM.shuffle(links)

                if _RANDOM.random() < 0.05:
                    for root_url in self.root_urls:
                        self.safe_enqueue(root_url, 0)

                await asyncio.sleep(
                    _RANDOM.uniform(self.min_sleep, self.max_sleep)
                    * (1 + depth * 0.3)
                    * _RANDOM.uniform(0.8, 1.5)
                )

                self.failed_counts.pop(url, None)
                return links

            except (aiohttp.ClientError, asyncio.TimeoutError, ssl.SSLError):
                self.visited_urls.discard(url)
                self.stats["failed"] += 1
                count = (self.failed_counts.get(url, 0) or 0) + 1
                if count >= self.max_failures:
                    self.failed_counts.pop(url, None)
                    self.root_urls.discard(url)
                    logging.info(
                        "Removing %s from root list after %d failures",
                        url,
                        self.max_failures,
                    )
                else:
                    self.failed_counts.set(url, count)
                return None

            except Exception:
                self.visited_urls.discard(url)
                logging.exception("Unexpected error fetching %s", url)
                count = (self.failed_counts.get(url, 0) or 0) + 1
                if count >= self.max_failures:
                    self.failed_counts.pop(url, None)
                    self.root_urls.discard(url)
                    logging.info(
                        "Removing %s from root list after %d failures",
                        url,
                        self.max_failures,
                    )
                else:
                    self.failed_counts.set(url, count)
                return None

    async def crawl_worker(self, session: aiohttp.ClientSession):
        while not self.stop_event.is_set():
            try:
                url, depth = await self.queue.get()
            except asyncio.CancelledError:
                break
            if depth > self.max_depth:
                self.queue.task_done()
                continue
            links = await self.fetch(session, url, depth)
            self.queue.task_done()
            if links is not None and depth < self.max_depth:
                for link in links:
                    self.safe_enqueue(link, depth + 1)

    async def refresh_crux_sites(self, session: aiohttp.ClientSession):
        first_run_done = not self._seed_crux_on_start
        while not self.stop_event.is_set():
            if first_run_done:
                await asyncio.sleep(self.crux_refresh_seconds)
                if self.stop_event.is_set():
                    break
            else:
                first_run_done = True

            try:
                sites = await fetch_crux_top_sites(session)
                for site in sites:
                    if site not in self.root_urls:
                        self.root_urls.add(site)
                        self.safe_enqueue(site, 0)
                logging.info("CRUX refresh complete")
            except (aiohttp.ClientError, asyncio.TimeoutError, ssl.SSLError):
                pass
            except Exception:
                logging.exception("Unexpected error during CRUX refresh")

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
        logging.info("Crawler timeout reached -- stopping")
        self.stop_event.set()

    async def run_forever(self, timeout: Optional[int]):
        logging.info(
            "Initial Stats | visited=%d failed=%d queued=%d queue_size=%d",
            self.stats["visited"],
            self.stats["failed"],
            self.stats["queued"],
            self.queue.qsize(),
        )

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

            if not self.root_urls:
                tasks.append(asyncio.create_task(self.refresh_crux_sites(session)))

            tasks.append(asyncio.create_task(self.refresh_user_agents(session)))
            tasks.append(asyncio.create_task(self.report_stats()))

            if timeout is not None:
                tasks.append(asyncio.create_task(self.stop_after_timeout(timeout)))

            workers = [
                asyncio.create_task(self.crawl_worker(session))
                for _ in range(self.concurrency)
            ]
            tasks.extend(workers)

            await self.stop_event.wait()

            logging.info(
                "Final Stats | visited=%d failed=%d queued=%d queue_size=%d",
                self.stats["visited"],
                self.stats["failed"],
                self.stats["queued"],
                self.queue.qsize(),
            )

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
        max_links_per_page=args.max_links_per_page,
        seed_crux_on_start=False,
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
        "--max_links_per_page",
        type=int,
        default=DEFAULT_MAX_LINKS_PER_PAGE,
        help="Max links to sample and enqueue per page. Default: 50",
    )
    parser.add_argument(
        "--timeout",
        type=int,
        default=DEFAULT_RUN_TIMEOUT_SECONDS,
        help="Stop crawler after N seconds. Default: run forever",
    )
    args = parser.parse_args()
    try:
        asyncio.run(main_async(args))
    except KeyboardInterrupt:
        logging.info("Interrupted -- exiting cleanly")


if __name__ == "__main__":
    main()
