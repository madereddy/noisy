import argparse
import copy
import datetime
import json
import logging
import random
import re
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import Optional, List
from urllib.parse import urljoin, urlparse

import requests
from bs4 import BeautifulSoup
from random_user_agent.user_agent import UserAgent
from random_user_agent.params import SoftwareName, OperatingSystem
from urllib3.exceptions import LocationParseError

# Setup UserAgent generator
software_names = [SoftwareName.CHROME.value, SoftwareName.FIREFOX.value, SoftwareName.EDGE.value]
operating_systems = [OperatingSystem.WINDOWS.value, OperatingSystem.LINUX.value, OperatingSystem.MACOS.value]
ua = UserAgent(software_names=software_names, operating_systems=operating_systems, limit=100)

SYS_RANDOM = random.SystemRandom()


def setup_logging(log_level_str: str, logfile: Optional[str] = None):
    level = getattr(logging, log_level_str.upper(), logging.INFO)
    root = logging.getLogger()
    root.setLevel(logging.WARNING)

    handler_stream = logging.StreamHandler()
    handler_stream.setFormatter(logging.Formatter('%(levelname)s - %(message)s'))
    root.addHandler(handler_stream)

    if logfile:
        handler_file = logging.FileHandler(logfile)
        handler_file.setFormatter(logging.Formatter('%(asctime)s - %(levelname)s - %(message)s'))
        root.addHandler(handler_file)

    logging.getLogger("urllib3").setLevel(logging.WARNING)
    logging.getLogger("requests").setLevel(logging.WARNING)
    root.setLevel(level)


def request_with_retries(url: str, retries: int = 3, backoff_factor: float = 0.5) -> requests.Response:
    delay = backoff_factor
    for attempt in range(1, retries + 1):
        try:
            headers = {"user-agent": ua.get_random_user_agent()}
            resp = requests.get(url, headers=headers, timeout=10)
            resp.raise_for_status()
            return resp
        except Exception as e:
            logging.debug(f"Attempt {attempt} failed for {url}: {e}")
            if attempt < retries:
                time.sleep(delay)
                delay *= 2
            else:
                raise


class Crawler:
    class CrawlerTimedOut(Exception):
        pass

    def __init__(self, config: dict):
        self._config = config
        self._links: List[str] = []
        self._start_time = None

    def _request(self, url: str) -> requests.Response:
        return request_with_retries(url)

    def _normalize_link(self, link: str, root_url: str) -> Optional[str]:
        try:
            parsed = urlparse(link)
        except ValueError:
            return None
        root_parsed = urlparse(root_url)
        if link.startswith("//"):
            return f"{root_parsed.scheme}://{parsed.netloc}{parsed.path}"
        if not parsed.scheme:
            return urljoin(root_url, link)
        return link

    def _is_valid(self, url: str) -> bool:
        regex = re.compile(r"^(?:http|ftp)s?://"
                           r"(?:(?:[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?\.)+"
                           r"(?:[A-Z]{2,6}\.?|[A-Z0-9-]{2,}\.?)|"
                           r"\d{1,3}(?:\.\d{1,3}){3})"
                           r"(?::\d+)?(?:/?|[/?]\S+)$", re.IGNORECASE)
        return re.match(regex, url) is not None

    def _extract_urls(self, body: bytes, root_url: str) -> List[str]:
        soup = BeautifulSoup(body, "html.parser")
        hrefs = [a.get("href") for a in soup.find_all("a", href=True)]
        norm = [self._normalize_link(h, root_url) for h in hrefs]
        return [u for u in norm if u and self._is_valid(u) and u not in self._config["blacklisted_urls"]]

    def _browse_from_links(self, depth=0):
        if not self._links or depth >= self._config["max_depth"]:
            logging.debug("Dead end or max depth reached")
            return
        if self._is_timeout_reached():
            raise self.CrawlerTimedOut

        link = SYS_RANDOM.choice(self._links)
        try:
            logging.info(f"Visiting {link}")
            resp = self._request(link)
            sub_links = self._extract_urls(resp.content, link)
            time.sleep(SYS_RANDOM.uniform(self._config["min_sleep"], self._config["max_sleep"]))

            if len(sub_links) > 1:
                self._links = sub_links
            else:
                self._blacklist_link(link)
        except Exception as e:
            logging.warning(f"Error on {link}: {e}, blacklisting")
            self._blacklist_link(link)

        self._browse_from_links(depth + 1)

    def _blacklist_link(self, link: str):
        if link in self._links:
            self._config["blacklisted_urls"].append(link)
            self._links.remove(link)

    def _is_timeout_reached(self) -> bool:
        if not self._config.get("timeout"):
            return False
        return datetime.datetime.now() >= self._start_time + datetime.timedelta(seconds=self._config["timeout"])

    def crawl(self):
        self._start_time = datetime.datetime.now()
        fail_count = 0
        max_failures = 10

        while fail_count < max_failures:
            if self._is_timeout_reached():
                logging.info("Crawler timeout exceeded")
                return
            root = SYS_RANDOM.choice(self._config["root_urls"])
            try:
                logging.info(f"Fetching root URL: {root}")
                resp = self._request(root)
                self._links = self._extract_urls(resp.content, root)
                logging.debug(f"Found {len(self._links)} links")
                self._browse_from_links()
                fail_count = 0  # reset on success
            except self.CrawlerTimedOut:
                logging.info("Crawler timed out")
                return
            except Exception as e:
                fail_count += 1
                logging.warning(f"Error at root {root}: {e}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--log", "-l", default="info", choices=["debug", "info", "warning", "error"])
    parser.add_argument("--logfile", help="Optional log file path")
    parser.add_argument("--config", "-c", required=True)
    parser.add_argument("--threads", "-n", type=int, default=2, help="Number of concurrent crawlers")
    parser.add_argument("--timeout", "-t", type=int, default=None)
    parser.add_argument("--min_sleep", type=int, default=None)
    parser.add_argument("--max_sleep", type=int, default=None)
    args = parser.parse_args()

    setup_logging(args.log, args.logfile)

    with open(args.config) as f:
        cfg = json.load(f)

    for key in ("timeout", "min_sleep", "max_sleep"):
        if getattr(args, key) is not None:
            cfg[key] = getattr(args, key)

    with ThreadPoolExecutor(max_workers=args.threads) as exe:
        futures = [exe.submit(Crawler(copy.deepcopy(cfg)).crawl) for _ in range(args.threads)]
        for _ in as_completed(futures):
            pass


if __name__ == "__main__":
    main()
