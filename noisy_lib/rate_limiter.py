# rate_limiter.py - Délai entre requêtes par domaine
# IN: domain:str, rng | OUT: none (await) | MODIFIE: TTLDict interne, dict locks
# APPELÉ PAR: crawler.py | APPELLE: structures.TTLDict

import asyncio
import logging
import time

from .config import DEFAULT_DOMAIN_DELAY
from .structures import TTLDict

log = logging.getLogger(__name__)

MAX_LOCKS = 50_000


class DomainRateLimiter:
    """Limite partagée entre tous les crawlers pour un même domaine."""

    def __init__(self, domain_delay: float = DEFAULT_DOMAIN_DELAY):
        self._domain_delay = domain_delay
        self._access: TTLDict = TTLDict(ttl=domain_delay * 10, maxsize=50_000)
        self._locks: dict = {}

    @property
    def domain_delay(self) -> float:
        return self._domain_delay

    @domain_delay.setter
    def domain_delay(self, value: float):
        self._domain_delay = value

    def active_domains_count(self) -> int:
        return len(self._access)

    def _get_lock(self, domain: str) -> asyncio.Lock:
        if domain not in self._locks:
            if len(self._locks) >= MAX_LOCKS:
                oldest = next(iter(self._locks))
                del self._locks[oldest]
            self._locks[domain] = asyncio.Lock()
        return self._locks[domain]

    async def wait(self, domain: str, rng) -> None:
        """Attend le délai minimal avant d'accéder au domaine."""
        lock = self._get_lock(domain)
        async with lock:
            now = time.monotonic()
            last = self._access.get(domain, 0)
            wait_time = max(0.0, self._domain_delay * rng.uniform(0.8, 1.2) - (now - last))
            if wait_time > 0:
                log.debug(f"[WAIT] domain={domain} wait={wait_time:.2f}s")
                await asyncio.sleep(wait_time)
            self._access.set(domain, time.monotonic())
