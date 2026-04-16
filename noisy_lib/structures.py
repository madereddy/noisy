# structures.py - Collections LRU et TTL bornées
# IN: items/clés/valeurs | OUT: items/valeurs | MODIFIE: état interne OrderedDict
# APPELÉ PAR: crawler.py, rate_limiter.py | APPELLE: rien (stdlib)

import logging
import time
from collections import OrderedDict

log = logging.getLogger(__name__)


class LRUSet:
    """Ensemble borné avec éviction LRU."""

    def __init__(self, maxsize: int):
        self._data: OrderedDict = OrderedDict()
        self._maxsize = maxsize

    def __contains__(self, item) -> bool:
        return item in self._data

    def add(self, item):
        if item in self._data:
            self._data.move_to_end(item)
            return
        self._data[item] = None
        if len(self._data) > self._maxsize:
            self._data.popitem(last=False)

    def discard(self, item):
        self._data.pop(item, None)

    def __len__(self) -> int:
        return len(self._data)


class BoundedDict:
    """Dict borné avec éviction LRU."""

    def __init__(self, maxsize: int):
        self._data: OrderedDict = OrderedDict()
        self._maxsize = maxsize

    def get(self, key, default=None):
        return self._data.get(key, default)

    def set(self, key, value):
        if key in self._data:
            self._data.move_to_end(key)
        self._data[key] = value
        if len(self._data) > self._maxsize:
            self._data.popitem(last=False)

    def pop(self, key, default=None):
        return self._data.pop(key, default)

    def __contains__(self, key):
        return key in self._data


class TTLDict:
    """Dict avec expiration automatique par TTL (secondes)."""

    def __init__(self, ttl: float, maxsize: int):
        self._data: OrderedDict = OrderedDict()
        self._times: dict = {}
        self._ttl = ttl
        self._maxsize = maxsize

    def get(self, key, default=None):
        self._maybe_evict(key)
        return self._data.get(key, default)

    def set(self, key, value):
        now = time.monotonic()
        self._data[key] = value
        self._times[key] = now
        self._data.move_to_end(key)
        while len(self._data) > self._maxsize:
            oldest = next(iter(self._data))
            del self._data[oldest]
            del self._times[oldest]

    def __len__(self):
        return len(self._data)

    def _maybe_evict(self, key):
        if key in self._times and time.monotonic() - self._times[key] > self._ttl:
            del self._data[key]
            del self._times[key]
