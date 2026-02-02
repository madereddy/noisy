# noisy.py - queue-based forever crawler

import argparse
import asyncio
import csv
import gzip
import logging
import random
import socket
import time
from typing import List, Optional, Tuple
import re
from urllib.parse import urlparse

import aiohttp
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

# ---- RUNTIME ----
DEFAULT_RUN_TIMEOUT_SECONDS = None  # None = run forever
SECONDS_PER_DAY = 24 * 60 * 60

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

LINK_REGEX = re.compile(r'href=["\'](.*?)["\']', re.IGNORECASE)

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
    for row in reader:
        origin = row.get("origin")
        if origin and origin not in sites:
            if not origin.startswith("http"):
                origin = f"https://{origin}"
            sites.append(origin)
        if len(sites) >= count:
            break

    logging.info(f"Loaded {len(sites)} CRUX sites")
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
        max_queue_size: int,
        domain_delay: float,
        total_connections: int,
        connections_per_host: int,
        keepalive_timeout: int,
    ):
        self.queue: asyncio.Queue[Tuple[str, int]] = asyncio.Queue()
        self.root_urls = set(root_urls)
        for url in root_urls:
            self.queue.put_nowait((url, 0))

        self.visited_urls = set()
        self.semaphore = asyncio.Semaphore(concurrency)
        self.stop_event = asyncio.Event()

        self.max_depth = max_depth
        self.min_sleep = min_sleep
        self.max_sleep = max_sleep

        self.crux_refresh_seconds = crux_refresh_seconds
        self.max_queue_size = max_queue_size
        self.domain_delay = domain_delay

        self.total_connections = total_connections
        self.connections_per_host = connections_per_host
        self.keepalive_timeout = keepalive_timeout

        self.domain_last_access = {}
        self.domain_locks = {}

    async def safe_enqueue(self, url: str, depth: int):
        if self.queue.qsize() >= self.max_queue_size:
            return
        await self.queue.put((url, depth))

    async def wait_for_domain(self, domain: str):
        lock = self.domain_locks.setdefault(domain, asyncio.Lock())
        async with lock:
            now = time.monotonic()
            last = self.domain_last_access.get(domain, 0)
            delta = now - last
            if delta < self.domain_delay:
                await asyncio.sleep(self.domain_delay - delta)
            self.domain_last_access[domain] = time.monotonic()

    async def fetch(self, session: aiohttp.ClientSession, url: str):
        async with self.semaphore:
            if url in self.visited_urls:
                return None

            domain = urlparse(url).hostname
            if not domain:
                return None

            try:
                await self.wait_for_domain(domain)
                headers = {"User-Agent": ua.get_random_user_agent()}

                async with session.get(
                    url,
                    headers=headers,
                    timeout=REQUEST_TIMEOUT,
                ) as resp:
                    resp.raise_for_status()
                    html = await resp.text()

                self.visited_urls.add(url)
                logging.info(f"Visited: {url}")

                await asyncio.sleep(
                    SYS_RANDOM.uniform(self.min_sleep, self.max_sleep)
                )
                return html

            except Exception as e:
                logging.warning(f"Fetch failed {url}: {e}")
                return None

    async def crawl_worker(self, session: aiohttp.ClientSession):
        while not self.stop_event.is_set():
            try:
                url, depth = await self.queue.get()
            except asyncio.CancelledError:
                break

            if depth > self.max_depth or url in self.visited_urls:
                self.queue.task_done()
                continue

            html = await self.fetch(session, url)
            self.queue.task_done()

            if html and depth < self.max_depth:
                for link in LINK_REGEX.findall(html):
                    if link.startswith("//"):
                        link = f"https:{link}"
                    elif link.startswith("/"):
                        link = f"{url.rstrip('/')}{link}"
                    if link.startswith("http"):
                        await self.safe_enqueue(link, depth + 1)

    async def refresh_crux_sites(self):
        await asyncio.sleep(10)
        async with aiohttp.ClientSession() as session:
            while not self.stop_event.is_set():
                try:
                    sites = await fetch_crux_top_sites(session)
                    for site in sites:
                        if site not in self.root_urls:
                            self.root_urls.add(site)
                            await self.safe_enqueue(site, 0)
                    logging.info("CRUX refresh complete")
                except Exception as e:
                    logging.error(f"CRUX refresh failed: {e}")

                await asyncio.sleep(self.crux_refresh_seconds)

    async def stop_after_timeout(self, timeout: int):
        logging.info(f"Crawler will stop after {timeout} seconds")
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

        async with aiohttp.ClientSession(connector=connector) as session:
            tasks = []

            tasks.append(asyncio.create_task(self.refresh_crux_sites()))

            if timeout:
                tasks.append(asyncio.create_task(self.stop_after_timeout(timeout)))

            workers = [
                asyncio.create_task(self.crawl_worker(session))
                for _ in range(self.semaphore._value)
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
    asyncio.run(main_async(args))

if __name__ == "__main__":
    main()
