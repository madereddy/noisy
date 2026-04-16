# profiles.py - Profils utilisateurs, pool UA, modèle diurnal
# IN: user_id, ua:str, rng | OUT: UserProfile, UAPool | MODIFIE: pool interne
# APPELÉ PAR: noisy.py, crawler.py, workers.py | APPELLE: rien (stdlib)

import asyncio
import logging
import math
import random
import ssl
import time
from typing import List, Optional

log = logging.getLogger(__name__)

try:
    import brotli as _brotli
    _BR_SUPPORTED = True
except ImportError:
    _BR_SUPPORTED = False

_ACCEPT_ENCODING = "gzip, deflate, br" if _BR_SUPPORTED else "gzip, deflate"

ACCEPT_HEADERS_POOL = [
    {"Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
     "Accept-Language": "en-US,en;q=0.9", "Accept-Encoding": _ACCEPT_ENCODING,
     "Cache-Control": "no-cache", "Pragma": "no-cache", "Upgrade-Insecure-Requests": "1"},
    {"Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
     "Accept-Language": "en-GB,en;q=0.8,en-US;q=0.6", "Accept-Encoding": _ACCEPT_ENCODING,
     "Cache-Control": "max-age=0", "Upgrade-Insecure-Requests": "1"},
    {"Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8",
     "Accept-Language": "en-US,en;q=0.7", "Accept-Encoding": _ACCEPT_ENCODING,
     "Upgrade-Insecure-Requests": "1"},
]

_UA_FALLBACK = [
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:123.0) Gecko/20100101 Firefox/123.0",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 14.3; rv:123.0) Gecko/20100101 Firefox/123.0",
    "Mozilla/5.0 (X11; Linux x86_64; rv:123.0) Gecko/20100101 Firefox/123.0",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36 Edg/122.0.0.0",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_3_1) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.3.1 Safari/605.1.15",
    "Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36",
]


def _build_ssl_context() -> ssl.SSLContext:
    ctx = ssl.create_default_context()
    ctx.options |= getattr(ssl, "OP_LEGACY_SERVER_CONNECT", 0)
    return ctx


SSL_CONTEXT = _build_ssl_context()


def _diurnal_weight(hour: float) -> float:
    """Poids d'activité selon l'heure locale (0.05–1.0)."""
    t = (hour - 4) / 24 * 2 * math.pi
    daytime = 0.5 + 0.5 * math.cos(t + math.pi)
    evening_boost = max(0.0, math.cos((hour - 20) / 6 * math.pi) * 0.4)
    return max(0.05, min(1.0, daytime + evening_boost))


def _activity_pause_seconds(rng: random.Random) -> float:
    """5% de chance de pause AFK (5–30 min)."""
    return rng.uniform(300, 1800) if rng.random() < 0.05 else 0.0


class UserProfile:
    """Empreinte de navigation par utilisateur virtuel."""

    def __init__(self, user_id: int, ua: str, rng: random.Random):
        self.user_id = user_id
        self.ua = ua
        self.rng = rng
        self.accept_headers = rng.choice(ACCEPT_HEADERS_POOL).copy()
        self.sleep_phase_offset = rng.uniform(-1.5, 1.5)

    def get_headers(self, referrer: Optional[str] = None) -> dict:
        h = {**self.accept_headers, "User-Agent": self.ua}
        if referrer:
            h["Referer"] = referrer
        return h

    def diurnal_weight(self) -> float:
        hour = time.localtime().tm_hour + time.localtime().tm_min / 60
        return _diurnal_weight((hour + self.sleep_phase_offset) % 24)


class UAPool:
    """Pool thread-safe de user agents avec remplacement async."""

    def __init__(self, initial: List[str]):
        self._pool: List[str] = list(initial)
        self._lock = asyncio.Lock()

    def get_random(self, rng: Optional[random.Random] = None) -> str:
        return (rng or random).choice(self._pool)

    def sample(self, n: int, rng: Optional[random.Random] = None) -> List[str]:
        r = rng or random.Random()
        return r.sample(self._pool, n) if len(self._pool) >= n else [r.choice(self._pool) for _ in range(n)]

    async def replace(self, agents: List[str]) -> None:
        log.info(f"[DEBUT] UAPool.replace | count={len(agents)}")
        async with self._lock:
            self._pool = list(agents)
        log.info(f"[FIN] UAPool.replace")

    def __len__(self) -> int:
        return len(self._pool)
