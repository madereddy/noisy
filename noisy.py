# noisy.py - queue-based high-speed forever crawler

import argparse
import asyncio
import csv
import gzip
import logging
import random
import socket
from typing import List, Optional, Tuple
import re

import aiohttp
from random_user_agent.user_agent import UserAgent
from random_user_agent.params import SoftwareName, OperatingSystem

# Config
CRUX_TOP_CSV = "https://raw.githubusercontent.com/zakird/crux-top-lists/main/data/global/current.csv.gz"
SYS_RANDOM = random.SystemRandom()

# UserAgent generator
software_names = [SoftwareName.CHROME.value, SoftwareName.FIREFOX.value, SoftwareName.EDGE.value]
operating_systems = [OperatingSystem.WINDOWS.value, OperatingSystem.LINUX.value, OperatingSystem.MACOS.value]
ua = UserAgent(software_names=software_names, operating_systems=operating_systems, limit=100)

LINK_REGEX = re.compile(r'href=["\'](.*?)["\']', re.IGNORECASE)


def setup_logging(log_level_str: str, logfile: Optional[str] = None):
    level = getattr(logging, log_level_str.upper(), logging.INFO)
    root = logging.getLogger()
    root.setLevel(level)

    handler_stream = logging.StreamHandler()
    handler_stream.setFormatter(logging.Formatter('%(levelname)s - %(message)s'))
    root.addHandler(handler_stream)

    if logfile:
        handler_file = logging.FileHandler(logfile)
        handler_file.setFormatter(logging.Formatter('%(asctime)s - %(levelname)s - %(message)s'))
        root.addHandler(handler_file)

    logging.getLogger("urllib3").setLevel(logging.WARNING)
    logging.getLogger("aiohttp").setLevel(logging.WARNING)
    logging.getLogger("requests").setLevel(logging.WARNING)


async def fetch_crux_top_sites(session: aiohttp.ClientSession, count: int = 10000) -> List[str]:
    logging.info("Fetching top sites from CrUX CSV...")
    async with session.get(CRUX_TOP_CSV) as resp:
        resp.raise_for_status()
        data = await resp.read()
    csv_text = gzip.decompress(data).decode()
    reader = csv.DictReader(csv_text.splitlines())
    sites = []
    for row in reader:
        site = row.get("origin")
        if site and site not in sites:
            if not site.startswith("http"):
                site = f"https://{site}"
            sites.append(site)
        if len(sites) >= count:
            break
    logging.info(f"Fetched {len(sites)} top sites.")
    return sites


class QueueCrawler:
    def __init__(
        self,
        root_urls: List[str],
        max_depth: int = 2,
        concurrency: int = 20,
        min_sleep: float = 0.5,
        max_sleep: float = 2.0,
        reset_interval: Optional[int] = None,
    ):
        self.queue: asyncio.Queue[Tuple[str, int]] = asyncio.Queue()
        for url in root_urls:
            self.queue.put_nowait((url, 0))
        self.visited_urls = set()
        self.semaphore = asyncio.Semaphore(concurrency)
        self.stop_event = asyncio.Event()
        self.max_depth = max_depth
        self.min_sleep = min_sleep
        self.max_sleep = max_sleep
        self.dns_cache = {}
        self.reset_interval = reset_interval

    async def resolve_host(self, url: str) -> str:
        host = url.split("/")[2]
        if host in self.dns_cache:
            return self.dns_cache[host]
        try:
            ip = socket.gethostbyname(host)
            self.dns_cache[host] = ip
            return ip
        except Exception:
            return host

    async def fetch(self, session: aiohttp.ClientSession, url: str):
        async with self.semaphore:
            if url in self.visited_urls:
                return None
            headers = {"User-Agent": ua.get_random_user_agent()}
            try:
                await self.resolve_host(url)
                async with session.get(url, headers=headers, timeout=15) as resp:
                    resp.raise_for_status()
                    self.visited_urls.add(url)
                    logging.info(f"Visited: {url}")
                    await asyncio.sleep(SYS_RANDOM.uniform(self.min_sleep, self.max_sleep))
                    return await resp.text()
            except Exception as e:
                logging.warning(f"Failed to fetch {url}: {e}")
                return None

    async def crawl_worker(self, session: aiohttp.ClientSession):
        while not self.stop_event.is_set():
            try:
                url, depth = await self.queue.get()
            except asyncio.CancelledError:
                break
            if url in self.visited_urls or depth > self.max_depth:
                self.queue.task_done()
                continue
            html = await self.fetch(session, url)
            self.queue.task_done()
            if html and depth < self.max_depth:
                links = LINK_REGEX.findall(html)
                for link in links:
                    if link.startswith("//"):
                        link = f"https:{link}"
                    elif link.startswith("/"):
                        link = f"{url.rstrip('/')}{link}"
                    if link.startswith("http") and link not in self.visited_urls:
                        await self.queue.put((link, depth + 1))

    async def run_forever(self):
        async with aiohttp.ClientSession() as session:
            # Optionally reset visited_urls periodically
            if self.reset_interval:
                asyncio.create_task(self._reset_loop())
            workers = [asyncio.create_task(self.crawl_worker(session)) for _ in range(self.semaphore._value)]
            await asyncio.gather(*workers)

    async def _reset_loop(self):
        while not self.stop_event.is_set():
            await asyncio.sleep(self.reset_interval)
            logging.info("Resetting visited URLs...")
            self.visited_urls.clear()

    async def stop_after_timeout(self, timeout: int):
        await asyncio.sleep(timeout)
        logging.info(f"Timeout reached ({timeout}s). Stopping crawler...")
        self.stop_event.set()


async def main_async(args):
    setup_logging(args.log, args.logfile)
    async with aiohttp.ClientSession() as session:
        top_sites = await fetch_crux_top_sites(session, count=10000)

    crawler = QueueCrawler(
        top_sites,
        max_depth=args.max_depth or 2,
        concurrency=args.threads or 20,
        min_sleep=args.min_sleep or 0.5,
        max_sleep=args.max_sleep or 2.0,
        reset_interval=args.reset_interval,
    )

    tasks = [crawler.run_forever()]
    if args.timeout:
        tasks.append(crawler.stop_after_timeout(args.timeout))

    await asyncio.gather(*tasks)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--log", "-l", default="info", choices=["debug", "info", "warning", "error"]
    )
    parser.add_argument("--logfile", help="Optional log file path")
    parser.add_argument("--threads", "-n", type=int, default=20, help="Number of concurrent requests")
    parser.add_argument("--min_sleep", type=float, default=2, help="Minimum sleep between requests")
    parser.add_argument("--max_sleep", type=float, default=10, help="Maximum sleep between requests")
    parser.add_argument("--timeout", "-t", type=int, help="Stop crawler after this many seconds")
    parser.add_argument("--max_depth", "-d", type=int, default=2, help="Maximum crawl depth per root site")
    parser.add_argument("--reset_interval", type=int, help="Reset visited URLs every N seconds")
    args = parser.parse_args()
    asyncio.run(main_async(args))


if __name__ == "__main__":
    main()
