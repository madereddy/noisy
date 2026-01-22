import argparse
import asyncio
import copy
import csv
import gzip
import logging
import random
import time
from typing import List, Optional

import aiohttp
from random_user_agent.user_agent import UserAgent
from random_user_agent.params import SoftwareName, OperatingSystem
from bs4 import BeautifulSoup

# Configurable constants
CRUX_TOP_CSV = "https://raw.githubusercontent.com/zakird/crux-top-lists/main/data/global/current.csv.gz"
SYS_RANDOM = random.SystemRandom()

# Setup UserAgent generator
software_names = [SoftwareName.CHROME.value, SoftwareName.FIREFOX.value, SoftwareName.EDGE.value]
operating_systems = [OperatingSystem.WINDOWS.value, OperatingSystem.LINUX.value, OperatingSystem.MACOS.value]
ua = UserAgent(software_names=software_names, operating_systems=operating_systems, limit=100)


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


async def fetch_text(session: aiohttp.ClientSession, url: str) -> str:
    headers = {"User-Agent": ua.get_random_user_agent()}
    async with session.get(url, headers=headers, timeout=10) as resp:
        resp.raise_for_status()
        return await resp.text()


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


class Crawler:
    def __init__(self, root_urls: List[str], min_sleep: float = 2.0, max_sleep: float = 5.0):
        self.root_urls = root_urls
        self.min_sleep = min_sleep
        self.max_sleep = max_sleep
        self.visited = set()
        self.stop_event = asyncio.Event()

    async def fetch(self, session: aiohttp.ClientSession, url: str):
        try:
            headers = {"User-Agent": ua.get_random_user_agent()}
            async with session.get(url, headers=headers, timeout=10) as resp:
                resp.raise_for_status()
                self.visited.add(url)
                logging.info(f"Visited: {url}")
                return await resp.text()
        except Exception as e:
            logging.warning(f"Failed to fetch {url}: {e}")
            return None

    async def crawl_page(self, session: aiohttp.ClientSession, url: str):
        html = await self.fetch(session, url)
        if not html:
            return []
        soup = BeautifulSoup(html, "html.parser")
        links = [a.get("href") for a in soup.find_all("a", href=True)]
        normalized = []
        for link in links:
            if link.startswith("//"):
                link = f"https:{link}"
            elif link.startswith("/"):
                link = f"{url.rstrip('/')}{link}"
            if link.startswith("http") and link not in self.visited:
                normalized.append(link)
        await asyncio.sleep(SYS_RANDOM.uniform(self.min_sleep, self.max_sleep))
        return normalized

    async def crawl_root(self, session: aiohttp.ClientSession, url: str):
        to_visit = [url]
        while to_visit and not self.stop_event.is_set():
            current = to_visit.pop(0)
            new_links = await self.crawl_page(session, current)
            to_visit.extend(new_links)

    async def run(self, threads: int = 5):
        async with aiohttp.ClientSession() as session:
            tasks = [self.crawl_root(session, url) for url in self.root_urls]
            # Run all tasks concurrently
            await asyncio.gather(*tasks)

    async def stop_after_timeout(self, timeout: int):
        await asyncio.sleep(timeout)
        logging.info(f"Timeout reached ({timeout} seconds). Stopping crawler...")
        self.stop_event.set()


async def main_async(args):
    setup_logging(args.log, args.logfile)
    async with aiohttp.ClientSession() as session:
        top_sites = await fetch_crux_top_sites(session, count=10000)

    crawler = Crawler(top_sites, min_sleep=args.min_sleep or 2, max_sleep=args.max_sleep or 5)

    # Schedule crawler stop if timeout is set
    tasks = [crawler.run(threads=args.threads or 5)]
    if args.timeout:
        tasks.append(crawler.stop_after_timeout(args.timeout))

    await asyncio.gather(*tasks)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--log", "-l", default="info", choices=["debug", "info", "warning", "error"])
    parser.add_argument("--logfile", help="Optional log file path")
    parser.add_argument("--threads", "-n", type=int, default=5, help="Number of concurrent crawlers")
    parser.add_argument("--min_sleep", type=float, default=2.0, help="Minimum sleep between requests")
    parser.add_argument("--max_sleep", type=float, default=5.0, help="Maximum sleep between requests")
    parser.add_argument("--timeout", "-t", type=int, help="Stop the crawler after this many seconds")
    args = parser.parse_args()
    asyncio.run(main_async(args))


if __name__ == "__main__":
    main()
