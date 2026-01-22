import argparse
import asyncio
import copy
import csv
import gzip
import logging
import random
import time
import socket
from typing import List, Optional
from urllib.parse import urljoin

import aiohttp
from bs4 import BeautifulSoup
from random_user_agent.user_agent import UserAgent
from random_user_agent.params import SoftwareName, OperatingSystem

# Configurable constants
CRUX_TOP_CSV = "https://raw.githubusercontent.com/zakird/crux-top-lists/main/data/global/current.csv.gz"
SYS_RANDOM = random.SystemRandom()

# Setup UserAgent generator (dynamic, random per request)
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


async def fetch_text(session: aiohttp.ClientSession, url: str, user_agents: list[str]) -> Optional[str]:
    """Fetch page text with random User-Agent, handling DNS and connection errors gracefully."""
    headers = {"User-Agent": SYS_RANDOM.choice(user_agents)}
    try:
        async with session.get(url, headers=headers, timeout=15) as resp:
            resp.raise_for_status()
            return await resp.text()
    except (aiohttp.ClientConnectorError, socket.gaierror) as e:
        logging.warning(f"DNS/connection error fetching {url}: {e}")
    except aiohttp.ClientResponseError as e:
        logging.warning(f"HTTP error fetching {url}: {e.status} {e.message}")
    except asyncio.TimeoutError:
        logging.warning(f"Timeout fetching {url}")
    except Exception as e:
        logging.debug(f"Unexpected error fetching {url}: {e}")
    return None


async def fetch_crux_top_sites(session: aiohttp.ClientSession, count: int = 10000) -> List[str]:
    logging.info("Fetching top sites from CrUX CSV...")
    async with session.get(CRUX_TOP_CSV) as resp:
        resp.raise_for_status()
        data = await resp.read()
    csv_text = gzip.decompress(data).decode()
    reader = csv.DictReader(csv_text.splitlines())
    sites = []
    for row in reader:
        site = row.get("origin")  # 'origin' column from CrUX CSV
        if site and site not in sites:
            if not site.startswith("http"):
                site = f"https://{site}"
            sites.append(site)
        if len(sites) >= count:
            break
    logging.info(f"Fetched {len(sites)} top sites.")
    return sites


class Crawler:
    def __init__(self, root_urls: List[str], min_sleep: float = 2.0, max_sleep: float = 5.0, max_retries: int = 2):
        self.root_urls = root_urls
        self.min_sleep = min_sleep
        self.max_sleep = max_sleep
        self.visited = set()
        self.max_retries = max_retries
        self.user_agents = [ua.get_random_user_agent() for _ in range(50)]  # Dynamic pool

    async def fetch_and_parse(self, session: aiohttp.ClientSession, url: str) -> List[str]:
        """Fetch a page and parse links, handling errors and sleeping randomly."""
        retries = 0
        while retries <= self.max_retries:
            html = await fetch_text(session, url, self.user_agents)
            if html:
                break
            retries += 1
            await asyncio.sleep(SYS_RANDOM.uniform(self.min_sleep, self.max_sleep) * 2)  # backoff
        if not html:
            return []

        self.visited.add(url)
        logging.info(f"Visited: {url}")

        soup = BeautifulSoup(html, "html.parser")
        links = []
        for a in soup.find_all("a", href=True):
            link = a["href"].strip()
            if link.startswith("//"):
                link = f"https:{link}"
            elif link.startswith("/"):
                link = urljoin(url, link)
            if link.startswith("http") and link not in self.visited:
                links.append(link)

        await asyncio.sleep(SYS_RANDOM.uniform(self.min_sleep, self.max_sleep))
        return links

    async def crawl_root(self, session: aiohttp.ClientSession, url: str):
        to_visit = [url]
        while to_visit:
            current = to_visit.pop(0)
            new_links = await self.fetch_and_parse(session, current)
            to_visit.extend(new_links)

    async def run(self, threads: int = 5):
        async with aiohttp.ClientSession() as session:
            while True:
                tasks = [self.crawl_root(session, url) for url in self.root_urls]
                await asyncio.gather(*tasks)


async def main_async(args):
    setup_logging(args.log, args.logfile)
    async with aiohttp.ClientSession() as session:
        top_sites = await fetch_crux_top_sites(session, count=10000)

    crawler = Crawler(top_sites, min_sleep=args.min_sleep, max_sleep=args.max_sleep)
    await crawler.run(threads=args.threads)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--log", "-l", default="info", choices=["debug", "info", "warning", "error"])
    parser.add_argument("--logfile", help="Optional log file path")
    parser.add_argument("--threads", "-n", type=int, default=5, help="Number of concurrent crawlers")
    parser.add_argument("--min_sleep", type=float, default=2.0, help="Minimum sleep between requests")
    parser.add_argument("--max_sleep", type=float, default=5.0, help="Maximum sleep between requests")
    args = parser.parse_args()
    asyncio.run(main_async(args))


if __name__ == "__main__":
    main()
