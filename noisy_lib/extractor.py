# extractor.py - Extraction et filtrage de liens HTML
# IN: html:str, base_url:str, blacklist:list | OUT: List[str] URLs | MODIFIE: rien
# APPELÉ PAR: crawler.py | APPELLE: html.parser (stdlib)

import logging
from html.parser import HTMLParser
from typing import List, Optional
from urllib.parse import urljoin

log = logging.getLogger(__name__)


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
            resolved = resolved.split("#")[0]
            if resolved.startswith("http"):
                self.links.append(resolved)


def extract_links(html: str, base_url: str, blacklist: Optional[List[str]] = None) -> List[str]:
    """Extrait les liens http(s) du HTML, filtre la blacklist."""
    parser = LinkExtractor(base_url)
    try:
        parser.feed(html)
    except (ValueError, RuntimeError) as e:
        log.debug(f"[WARN] parsing | url={base_url} {e}")
    except Exception as e:
        log.error(f"[ERREUR] parsing | url={base_url} {e}")

    links = parser.links
    if blacklist:
        links = [lnk for lnk in links if not any(b in lnk for b in blacklist)]
    return links
