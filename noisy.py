# noisy.py - queue-based forever crawler

import argparse
import asyncio
import csv
import gzip
import logging
import random
import re
import socket
import time
from typing import List, Optional, Tuple
from urllib.parse import urlparse

import aiohttp
from aiohttp import ClientError, ClientConnectorError, ClientResponseError, ClientPayloadError
from aiohttp.http_exceptions import LineTooLong
from bs4 import BeautifulSoup

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

# Heuristic patterns for link filtering
INTERESTING_PATTERNS = re.compile(
    r"(article|blog|news|post|item|view|id=|product|category|forum|thread|story|page)",
    re.IGNORECASE
)
BORING_PATTERNS = re.compile(
    r"(login|signin|signup|register|account|cart|checkout|admin|api|auth|logout|password|recover|subscription|bill|invoice)",
    re.IGNORECASE
)

# Curated list of modern user agents (Chrome 120+, Firefox 120+, Safari 17+, Edge 120+)
MODERN_USER_AGENTS = [
    # --- Chrome (Windows) ---
    {
        "user_agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36",
        "software_name": "chrome",
        "operating_system": "windows"
    },
    {
        "user_agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
        "software_name": "chrome",
        "operating_system": "windows"
    },
    # --- Chrome (macOS) ---
    {
        "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36",
        "software_name": "chrome",
        "operating_system": "macintosh"
    },
    {
        "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
        "software_name": "chrome",
        "operating_system": "macintosh"
    },
    # --- Chrome (Linux) ---
    {
        "user_agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36",
        "software_name": "chrome",
        "operating_system": "linux"
    },
    # --- Firefox (Windows) ---
    {
        "user_agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:124.0) Gecko/20100101 Firefox/124.0",
        "software_name": "firefox",
        "operating_system": "windows"
    },
    {
        "user_agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:125.0) Gecko/20100101 Firefox/125.0",
        "software_name": "firefox",
        "operating_system": "windows"
    },
    # --- Firefox (macOS) ---
    {
        "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:124.0) Gecko/20100101 Firefox/124.0",
        "software_name": "firefox",
        "operating_system": "macintosh"
    },
    # --- Firefox (Linux) ---
    {
        "user_agent": "Mozilla/5.0 (X11; Linux x86_64; rv:124.0) Gecko/20100101 Firefox/124.0",
        "software_name": "firefox",
        "operating_system": "linux"
    },
    # --- Edge (Windows) ---
    {
        "user_agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36 Edg/123.0.0.0",
        "software_name": "edge",
        "operating_system": "windows"
    },
    {
        "user_agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36 Edg/124.0.0.0",
        "software_name": "edge",
        "operating_system": "windows"
    },
    # --- Safari (macOS) ---
    {
        "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.3 Safari/605.1.15",
        "software_name": "safari",
        "operating_system": "macintosh"
    },
    {
        "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15",
        "software_name": "safari",
        "operating_system": "macintosh"
    },
]

UA_LIST_URL = "https://jnrbsn.github.io/user-agents/user-agents.json"
_FETCHED_UAS = []

async def fetch_user_agents(session: aiohttp.ClientSession) -> List[dict]:
    """Fetches and parses a live list of user agents."""
    logging.info(f"Fetching user agents from {UA_LIST_URL}...")
    try:
        async with session.get(UA_LIST_URL, timeout=10) as resp:
            resp.raise_for_status()
            uas = await resp.json()

        parsed_uas = []
        for ua_string in uas:
            # Parse metadata roughly from string
            software_name = "unknown"
            os_name = "unknown"

            if "Edg" in ua_string:
                software_name = "edge"
            elif "Chrome" in ua_string:
                software_name = "chrome"
            elif "Firefox" in ua_string:
                software_name = "firefox"
            elif "Safari" in ua_string:
                software_name = "safari"

            if "Windows" in ua_string:
                os_name = "windows"
            elif "Macintosh" in ua_string or "Mac OS" in ua_string:
                os_name = "macintosh"
            elif "Linux" in ua_string:
                os_name = "linux"
            elif "Android" in ua_string:
                os_name = "android"
            elif "iPhone" in ua_string or "iPad" in ua_string:
                os_name = "ios"

            parsed_uas.append({
                "user_agent": ua_string,
                "software_name": software_name,
                "operating_system": os_name
            })

        logging.info(f"Loaded {len(parsed_uas)} user agents from remote source")
        return parsed_uas
    except Exception as e:
        logging.warning(f"Failed to fetch user agents: {e}. Using fallback list.")
        return MODERN_USER_AGENTS

def generate_headers(ua_data: dict) -> dict:
    headers = {
        "Accept-Encoding": "gzip, deflate, br",
        "Accept-Language": "en-US,en;q=0.9",
        "Upgrade-Insecure-Requests": "1",
        "Sec-Fetch-Dest": "document",
        "Sec-Fetch-Mode": "navigate",
        "Sec-Fetch-Site": "none",
        "Sec-Fetch-User": "?1",
        "User-Agent": ua_data["user_agent"],
    }

    ua_string = ua_data["user_agent"]
    software_name = ua_data["software_name"]
    operating_system = ua_data["operating_system"]

    # --- Chrome / Edge (Chromium) ---
    if software_name in ("chrome", "edge", "chromium"):
        # Version extraction
        version_match = re.search(r"(?:Chrome|Edg|Chromium)/(\d+)", ua_string)
        version = version_match.group(1) if version_match else "120"

        # Brand list for Sec-CH-UA
        brand_name = "Microsoft Edge" if software_name == "edge" else "Google Chrome"
        headers["Sec-Ch-Ua"] = f'"Not_A Brand";v="8", "Chromium";v="{version}", "{brand_name}";v="{version}"'
        headers["Sec-Ch-Ua-Mobile"] = "?0"

        # Platform
        platform_map = {
            "windows": "Windows",
            "linux": "Linux",
            "mac-os-x": "macOS",
            "macos": "macOS",
        }
        # random-user-agent OS names are lowercase usually
        os_lower = operating_system.lower()
        # Default to "Unknown" if not found, but we filter for Win/Linux/Mac so it should be fine.
        # Check against partial matches if exact string differs
        if "windows" in os_lower:
            headers["Sec-Ch-Ua-Platform"] = '"Windows"'
        elif "mac" in os_lower:
            headers["Sec-Ch-Ua-Platform"] = '"macOS"'
        elif "linux" in os_lower:
            headers["Sec-Ch-Ua-Platform"] = '"Linux"'
        else:
             headers["Sec-Ch-Ua-Platform"] = '"Unknown"'

        headers["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7"

    # --- Firefox ---
    elif software_name == "firefox":
        headers["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8"
        # Firefox doesn't typically send Sec-CH-UA headers by default (yet)

    # --- Fallback ---
    else:
        headers["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7"

    return headers

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
        dns_ttl: int,
    ):
        self.queue: asyncio.Queue[Tuple[str, int, Optional[str]]] = asyncio.Queue()
        self.root_urls = set(root_urls)
        for url in root_urls:
            self.queue.put_nowait((url, 0, None))

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
        self.dns_ttl = dns_ttl

        self.domain_last_access = {}
        self.domain_locks = {}
        self.domain_penalties = {}

    async def safe_enqueue(self, url: str, depth: int, referer: Optional[str] = None):
        if self.queue.qsize() >= self.max_queue_size:
            return
        await self.queue.put((url, depth, referer))

    async def wait_for_domain(self, domain: str):
        lock = self.domain_locks.setdefault(domain, asyncio.Lock())
        async with lock:
            now = time.monotonic()
            last = self.domain_last_access.get(domain, 0)
            delta = now - last

            penalty = self.domain_penalties.get(domain, 0)
            wait_time = self.domain_delay + penalty

            if delta < wait_time:
                await asyncio.sleep(wait_time - delta)
            self.domain_last_access[domain] = time.monotonic()

    async def fetch(self, session: aiohttp.ClientSession, url: str, referer: Optional[str] = None):
        async with self.semaphore:
            if url in self.visited_urls:
                return None

            domain = urlparse(url).hostname
            if not domain:
                return None

            try:
                await self.wait_for_domain(domain)

                # Pick random UA with metadata
                ua_list = _FETCHED_UAS if _FETCHED_UAS else MODERN_USER_AGENTS
                ua_data = SYS_RANDOM.choice(ua_list)
                headers = generate_headers(ua_data)

                if referer:
                    headers["Referer"] = referer

                async with session.get(
                    url,
                    headers=headers,
                    timeout=REQUEST_TIMEOUT,
                ) as resp:
                    resp.raise_for_status()
                    html = await resp.text(errors="replace")

                # Success - clear any existing penalty for this domain
                if domain in self.domain_penalties:
                    del self.domain_penalties[domain]

                self.visited_urls.add(url)
                logging.info(f"Visited: {url}")

                await asyncio.sleep(
                    SYS_RANDOM.uniform(self.min_sleep, self.max_sleep)
                )
                return html

            except (ClientError, LineTooLong, asyncio.TimeoutError, UnicodeDecodeError) as e:
                # Specific handling for "expected" errors to reduce log noise
                if isinstance(e, ClientResponseError):
                    if 400 <= e.status < 500:
                        logging.info(f"Fetch failed {url}: {e.status} {e.message}")
                        # Apply penalty for 4xx errors to avoid bot detection
                        current_penalty = self.domain_penalties.get(domain, 0)
                        self.domain_penalties[domain] = current_penalty + 60.0
                    else:
                        logging.warning(f"Fetch failed {url}: {e}")
                elif isinstance(e, LineTooLong):
                    logging.info(f"Fetch failed {url}: Line too long - {e}")
                elif isinstance(e, ClientConnectorError):
                    logging.info(f"Fetch failed {url}: Connection error - {e}")
                elif isinstance(e, asyncio.TimeoutError):
                    logging.info(f"Fetch failed {url}: Timeout")
                elif isinstance(e, UnicodeDecodeError):
                    logging.info(f"Fetch failed {url}: Encoding error - {e}")
                elif isinstance(e, ClientPayloadError):
                     logging.info(f"Fetch failed {url}: Payload/Encoding error - {e}")
                else:
                    logging.warning(f"Fetch failed {url}: {e}")
                return None

            except Exception as e:
                logging.warning(f"Fetch failed {url}: {e}")
                return None

    async def crawl_worker(self, session: aiohttp.ClientSession):
        while not self.stop_event.is_set():
            try:
                url, depth, referer = await self.queue.get()
            except asyncio.CancelledError:
                break

            if depth > self.max_depth or url in self.visited_urls:
                self.queue.task_done()
                continue

            html = await self.fetch(session, url, referer)
            self.queue.task_done()

            if html and depth < self.max_depth:
                try:
                    soup = BeautifulSoup(html, "html.parser")
                    for tag in soup.find_all("a", href=True):
                        link = tag["href"]
                        if link.startswith("//"):
                            link = f"https:{link}"
                        elif link.startswith("/"):
                            link = f"{url.rstrip('/')}{link}"

                        if not link.startswith("http"):
                            continue

                        # Link Filtering Heuristics
                        # 1. Skip boring/administrative links to avoid getting stuck in auth loops
                        if BORING_PATTERNS.search(link):
                            logging.debug(f"Skipping boring link: {link}")
                            continue

                        # 2. Prioritize interesting content (though with simple FIFO queue, this just adds it)
                        # Ideally, a priority queue would be better, but this filter at least reduces junk.
                        if INTERESTING_PATTERNS.search(link):
                             logging.debug(f"Found interesting link: {link}")
                             await self.safe_enqueue(link, depth + 1, referer=url)
                        else:
                             # 3. Enqueue neutral links normally
                             await self.safe_enqueue(link, depth + 1, referer=url)

                except Exception as e:
                    logging.warning(f"HTML parsing failed for {url}: {e}")

    async def refresh_crux_sites(self):
        await asyncio.sleep(10)
        async with aiohttp.ClientSession() as session:
            while not self.stop_event.is_set():
                try:
                    sites = await fetch_crux_top_sites(session)
                    for site in sites:
                        if site not in self.root_urls:
                            self.root_urls.add(site)
                            await self.safe_enqueue(site, 0, None)
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
            ttl_dns_cache=self.dns_ttl,
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
        # Fetch initial data concurrently
        top_sites_task = asyncio.create_task(fetch_crux_top_sites(session))
        ua_task = asyncio.create_task(fetch_user_agents(session))

        top_sites, uas = await asyncio.gather(top_sites_task, ua_task)

        global _FETCHED_UAS
        if uas:
            _FETCHED_UAS = uas

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
        dns_ttl=args.dns_ttl,
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
    parser.add_argument("--dns_ttl", type=int, default=DNS_CACHE_TTL)

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
