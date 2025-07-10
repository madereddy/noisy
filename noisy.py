import argparse
import datetime
import json
import logging
import random
import re
import time
from urllib.parse import urljoin, urlparse

import requests
from fake_useragent import UserAgent
from urllib3.exceptions import LocationParseError

ua = UserAgent(min_version=120.0)
REQUEST_COUNTER = -1
SYS_RANDOM = random.SystemRandom()


class Crawler:
    def __init__(self):
        self._config = {}
        self._links = []
        self._start_time = None

    class CrawlerTimedOut(Exception):
        pass

    @staticmethod
    def _request(url):
        headers = {"user-agent": ua.random}
        return requests.get(url, headers=headers, timeout=10)

    @staticmethod
    def _normalize_link(link, root_url):
        try:
            parsed_url = urlparse(link)
        except ValueError:
            return None
        parsed_root_url = urlparse(root_url)

        if link.startswith("//"):
            return f"{parsed_root_url.scheme}://{parsed_url.netloc}{parsed_url.path}"
        if not parsed_url.scheme:
            return urljoin(root_url, link)
        return link

    @staticmethod
    def _is_valid_url(url):
        regex = re.compile(
            r"^(?:http|ftp)s?://"
            r"(?:(?:[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?\.)+(?:[A-Z]{2,6}\.?|[A-Z0-9-]{2,}\.?)|"
            r"\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})"
            r"(?::\d+)?"
            r"(?:/?|[/?]\S+)$",
            re.IGNORECASE,
        )
        return re.match(regex, url) is not None

    def _is_blacklisted(self, url):
        return any(b in url for b in self._config.get("blacklisted_urls", []))

    def _should_accept_url(self, url):
        return url and self._is_valid_url(url) and not self._is_blacklisted(url)

    def _extract_urls(self, body, root_url):
        pattern = r"href=[\"'](?!#)(.*?)[\"'].*?"
        urls = re.findall(pattern, str(body))
        normalize_urls = [self._normalize_link(url, root_url) for url in urls]
        return list(filter(self._should_accept_url, normalize_urls))

    def _remove_and_blacklist(self, link):
        self._config["blacklisted_urls"].append(link)
        self._links.remove(link)

    def _browse_from_links(self, depth=0):
        if not self._links or depth >= self._config["max_depth"]:
            logging.debug("Hit a dead end or reached max depth")
            return
        if self._is_timeout_reached():
            raise self.CrawlerTimedOut
        random_link = SYS_RANDOM.choice(self._links)
        try:
            logging.info(f"Visiting {random_link}")
            sub_page = self._request(random_link).content
            sub_links = self._extract_urls(sub_page, random_link)
            time.sleep(SYS_RANDOM.randrange(self._config["min_sleep"], self._config["max_sleep"]))

            if len(sub_links) > 1:
                self._links = sub_links
            else:
                self._remove_and_blacklist(random_link)
        except (requests.exceptions.RequestException, UnicodeDecodeError):
            logging.debug(f"Exception on URL: {random_link}, removing from list")
            self._remove_and_blacklist(random_link)

        self._browse_from_links(depth + 1)

    def load_config_file(self, file_path):
        with open(file_path, "r") as config_file:
            config = json.load(config_file)
            self.set_config(config)

    def set_config(self, config):
        self._config = config

    def set_option(self, option, value):
        self._config[option] = value

    def _is_timeout_reached(self):
        if not self._config["timeout"]:
            return False
        end_time = self._start_time + datetime.timedelta(seconds=self._config["timeout"])
        return datetime.datetime.now() >= end_time

    def crawl(self):
        self._start_time = datetime.datetime.now()
        while True:
            url = SYS_RANDOM.choice(self._config["root_urls"])
            try:
                body = self._request(url).content
                self._links = self._extract_urls(body, url)
                logging.debug("Found {} links".format(len(self._links)))
                self._browse_from_links()
            except (requests.exceptions.RequestException, UnicodeDecodeError):
                logging.warning(f"Error connecting to root URL: {url}")
            except MemoryError:
                logging.warning(f"Memory error from: {url}")
            except LocationParseError:
                logging.warning(f"URL parsing error: {url}")
            except self.CrawlerTimedOut:
                logging.info("Timeout exceeded, exiting crawl")
                return


def setup_logging(log_level_str):
    level = getattr(logging, log_level_str.upper(), logging.INFO)

    # Set root logger to WARNING to silence noisy libraries
    root_logger = logging.getLogger()
    root_logger.setLevel(logging.WARNING)
    if not root_logger.handlers:
        handler = logging.StreamHandler()
        formatter = logging.Formatter('%(levelname)s:%(name)s:%(message)s')
        handler.setFormatter(formatter)
        root_logger.addHandler(handler)

    # Quiet specific libraries
    logging.getLogger("urllib3").setLevel(logging.WARNING)
    logging.getLogger("requests").setLevel(logging.WARNING)

    # App logger for this script
    app_logger = logging.getLogger()
    app_logger.setLevel(level)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--log", metavar="-l", type=str, default="info",
                        choices=["debug", "info", "warning", "error", "critical"],
                        help="logging level")
    parser.add_argument("--config", metavar="-c", required=True, type=str, help="config file")
    parser.add_argument("--timeout", metavar="-t", type=int, default=False,
                        help="How long the crawler should run (in seconds)")
    parser.add_argument("--min_sleep", metavar="-min", type=int,
                        help="Minimum sleep between requests")
    parser.add_argument("--max_sleep", metavar="-max", type=int,
                        help="Maximum sleep between requests")

    args = parser.parse_args()
    setup_logging(args.log)

    crawler = Crawler()
    crawler.load_config_file(args.config)

    if args.timeout:
        crawler.set_option("timeout", args.timeout)
    if args.min_sleep:
        crawler.set_option("min_sleep", args.min_sleep)
    if args.max_sleep:
        crawler.set_option("max_sleep", args.max_sleep)

    crawler.crawl()


if __name__ == "__main__":
    main()
