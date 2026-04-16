"""Unit tests for LRUSet, BoundedDict, and TTLDict."""

from unittest.mock import patch

import pytest

from noisy_lib.structures import BoundedDict, LRUSet, TTLDict


class TestLRUSet:
    def test_add_and_contains(self):
        s = LRUSet(maxsize=10)
        s.add("a")
        assert "a" in s
        assert "b" not in s

    def test_eviction_at_maxsize(self):
        s = LRUSet(maxsize=3)
        s.add("a")
        s.add("b")
        s.add("c")
        s.add("d")  # evicts "a" (oldest)
        assert "a" not in s
        assert "d" in s

    def test_lru_re_add_moves_to_end(self):
        s = LRUSet(maxsize=3)
        s.add("a")
        s.add("b")
        s.add("c")
        s.add("a")  # re-add moves "a" to front; "b" becomes oldest
        s.add("d")  # evicts "b"
        assert "b" not in s
        assert "a" in s
        assert "d" in s

    def test_discard_existing(self):
        s = LRUSet(maxsize=10)
        s.add("a")
        s.discard("a")
        assert "a" not in s

    def test_discard_nonexistent_no_raise(self):
        s = LRUSet(maxsize=10)
        s.discard("ghost")  # must not raise

    def test_len(self):
        s = LRUSet(maxsize=10)
        assert len(s) == 0
        s.add("x")
        s.add("y")
        assert len(s) == 2

    def test_maxsize_one(self):
        s = LRUSet(maxsize=1)
        s.add("a")
        s.add("b")
        assert "a" not in s
        assert "b" in s
        assert len(s) == 1


class TestBoundedDict:
    def test_set_and_get(self):
        d = BoundedDict(maxsize=5)
        d.set("k", "v")
        assert d.get("k") == "v"

    def test_get_missing_returns_none(self):
        d = BoundedDict(maxsize=5)
        assert d.get("missing") is None

    def test_get_missing_returns_default(self):
        d = BoundedDict(maxsize=5)
        assert d.get("missing", 42) == 42

    def test_eviction_at_maxsize(self):
        d = BoundedDict(maxsize=2)
        d.set("a", 1)
        d.set("b", 2)
        d.set("c", 3)  # evicts "a"
        assert d.get("a") is None
        assert d.get("b") == 2
        assert d.get("c") == 3

    def test_update_moves_to_front(self):
        d = BoundedDict(maxsize=2)
        d.set("a", 1)
        d.set("b", 2)
        d.set("a", 99)  # re-set moves "a" to end; "b" is now oldest
        d.set("c", 3)   # evicts "b"
        assert d.get("b") is None
        assert d.get("a") == 99

    def test_pop_existing(self):
        d = BoundedDict(maxsize=5)
        d.set("x", 10)
        assert d.pop("x") == 10
        assert "x" not in d

    def test_pop_missing_returns_default(self):
        d = BoundedDict(maxsize=5)
        assert d.pop("ghost", -1) == -1

    def test_contains(self):
        d = BoundedDict(maxsize=5)
        d.set("k", "v")
        assert "k" in d
        assert "missing" not in d


class TestTTLDict:
    def test_set_and_get(self):
        d = TTLDict(ttl=60, maxsize=10)
        d.set("k", "v")
        assert d.get("k") == "v"

    def test_get_missing_returns_none(self):
        d = TTLDict(ttl=60, maxsize=10)
        assert d.get("absent") is None

    def test_get_missing_returns_default(self):
        d = TTLDict(ttl=60, maxsize=10)
        assert d.get("absent", 99) == 99

    def test_ttl_expiry(self):
        d = TTLDict(ttl=1.0, maxsize=10)
        with patch("noisy_lib.structures.time") as mock_time:
            mock_time.monotonic.return_value = 100.0
            d.set("k", "v")
            mock_time.monotonic.return_value = 102.0  # 2s elapsed > 1s TTL
            result = d.get("k")
        assert result is None

    def test_within_ttl_not_evicted(self):
        d = TTLDict(ttl=10.0, maxsize=10)
        with patch("noisy_lib.structures.time") as mock_time:
            mock_time.monotonic.return_value = 100.0
            d.set("k", "v")
            mock_time.monotonic.return_value = 105.0  # 5s elapsed < 10s TTL
            result = d.get("k")
        assert result == "v"

    def test_maxsize_eviction(self):
        d = TTLDict(ttl=60, maxsize=2)
        d.set("a", 1)
        d.set("b", 2)
        d.set("c", 3)  # evicts "a"
        assert d.get("a") is None
        assert d.get("c") == 3
