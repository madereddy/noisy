# fetch_client.py - Requête HTTP avec retry exponentiel
# IN: session, url:str, headers:dict | OUT: FetchResult | MODIFIE: rien
# APPELÉ PAR: crawler.py | APPELLE: aiohttp, config, profiles.SSL_CONTEXT

import asyncio
import logging
import ssl
from typing import Optional

import aiohttp

from .config import MAX_RESPONSE_BYTES, MAX_RETRIES, REQUEST_TIMEOUT, RETRY_BASE_DELAY
from .profiles import SSL_CONTEXT

log = logging.getLogger(__name__)


class FetchResult:
    """Résultat d'un fetch : html, status, bytes, ou erreur réseau."""
    __slots__ = ("html", "status", "bytes_received", "error_msg")

    def __init__(self, html: Optional[str], status: int, bytes_received: int = 0, error_msg: str = ""):
        self.html = html
        self.status = status
        self.bytes_received = bytes_received
        self.error_msg = error_msg

    @property
    def ok(self) -> bool:
        return self.html is not None

    @property
    def is_client_error(self) -> bool:
        return 400 <= self.status < 500

    @property
    def is_server_error(self) -> bool:
        return self.status >= 500


async def fetch_with_retry(
    session: aiohttp.ClientSession,
    url: str,
    headers: dict,
) -> FetchResult:
    """GET avec backoff exponentiel (MAX_RETRIES tentatives). Retourne FetchResult."""
    timeout = aiohttp.ClientTimeout(total=REQUEST_TIMEOUT)
    last_exc: Optional[Exception] = None

    for attempt in range(MAX_RETRIES):
        try:
            async with session.get(
                url, headers=headers, timeout=timeout,
                ssl=SSL_CONTEXT, allow_redirects=True,
            ) as resp:
                if resp.status >= 500:
                    if attempt < MAX_RETRIES - 1:
                        await asyncio.sleep(RETRY_BASE_DELAY * (2 ** attempt))
                        continue
                    return FetchResult(None, resp.status, error_msg=f"HTTP {resp.status}")
                if resp.status >= 400:
                    return FetchResult(None, resp.status, error_msg=f"HTTP {resp.status}")
                raw = await resp.content.read(MAX_RESPONSE_BYTES)
                html = raw.decode(resp.charset or "utf-8", errors="replace")
                return FetchResult(html, resp.status, bytes_received=len(raw))
        except (aiohttp.ClientError, asyncio.TimeoutError, ssl.SSLError) as e:
            last_exc = e
            log.debug(f"[RETRY] attempt={attempt + 1}/{MAX_RETRIES} url={url} err={e}")
            if attempt < MAX_RETRIES - 1:
                await asyncio.sleep(RETRY_BASE_DELAY * (2 ** attempt))

    if last_exc:
        raise last_exc
    return FetchResult(None, 0)
