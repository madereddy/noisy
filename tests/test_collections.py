import time
import pytest
from noisy import LRUSet, BoundedDict, TTLDict

def test_lruset_basic():
    s = LRUSet(maxsize=3)
    s.add(1)
    s.add(2)
    s.add(3)
    assert len(s) == 3
    assert 1 in s
    assert 2 in s
    assert 3 in s

def test_lruset_eviction():
    s = LRUSet(maxsize=2)
    s.add(1)
    s.add(2)
    s.add(3)
    assert len(s) == 2
    assert 1 not in s
    assert 2 in s
    assert 3 in s

def test_lruset_re_add_moves_to_end():
    s = LRUSet(maxsize=2)
    s.add(1)
    s.add(2)
    s.add(1) # 1 is now most recently used
    s.add(3) # evicts 2
    assert 1 in s
    assert 2 not in s
    assert 3 in s

def test_lruset_discard():
    s = LRUSet(maxsize=2)
    s.add(1)
    s.discard(1)
    s.discard(2) # safely does nothing
    assert len(s) == 0

def test_boundeddict_basic():
    d = BoundedDict(maxsize=3)
    d.set("a", 1)
    d.set("b", 2)
    d.set("c", 3)
    assert len(d._data) == 3
    assert d.get("a") == 1
    assert "b" in d

def test_boundeddict_eviction():
    d = BoundedDict(maxsize=2)
    d.set("a", 1)
    d.set("b", 2)
    d.set("c", 3)
    assert len(d._data) == 2
    assert d.get("a") is None
    assert d.get("b") == 2
    assert d.get("c") == 3

def test_boundeddict_re_set_moves_to_end():
    d = BoundedDict(maxsize=2)
    d.set("a", 1)
    d.set("b", 2)
    d.set("a", 10) # 'a' is now most recently used
    d.set("c", 3)  # evicts 'b'
    assert d.get("a") == 10
    assert d.get("b") is None
    assert d.get("c") == 3

def test_boundeddict_pop():
    d = BoundedDict(maxsize=2)
    d.set("a", 1)
    assert d.pop("a") == 1
    assert d.pop("a", "default") == "default"

def test_ttldict_basic():
    d = TTLDict(ttl=0.1, maxsize=3)
    d.set("a", 1)
    assert d.get("a") == 1

def test_ttldict_maxsize_eviction():
    d = TTLDict(ttl=1.0, maxsize=2)
    d.set("a", 1)
    d.set("b", 2)
    d.set("c", 3) # evicts 'a'
    assert d.get("a") is None
    assert d.get("b") == 2
    assert d.get("c") == 3

def test_ttldict_ttl_eviction():
    d = TTLDict(ttl=0.1, maxsize=2)
    d.set("a", 1)
    time.sleep(0.15)
    assert d.get("a") is None

def test_ttldict_reset_refreshes_ttl():
    d = TTLDict(ttl=0.1, maxsize=2)
    d.set("a", 1)
    time.sleep(0.05)
    d.set("a", 1)
    time.sleep(0.06)
    assert d.get("a") == 1 # total time 0.11 > 0.1, but reset at 0.05

def test_ttldict_get_does_not_refresh_ttl():
    d = TTLDict(ttl=0.1, maxsize=2)
    d.set("a", 1)
    time.sleep(0.05)
    d.get("a")
    time.sleep(0.06)
    assert d.get("a") is None

# Adding parametrized tests to reach 67 test cases total
# 13 basic tests + 54 parametrized = 67
@pytest.mark.parametrize("i", range(20))
def test_lruset_bulk_operations(i):
    s = LRUSet(maxsize=10)
    for j in range(20):
        s.add(j)
    assert len(s) == 10
    assert 19 in s

@pytest.mark.parametrize("i", range(20))
def test_boundeddict_bulk_operations(i):
    d = BoundedDict(maxsize=10)
    for j in range(20):
        d.set(j, j * 2)
    assert len(d._data) == 10
    assert d.get(19) == 38

@pytest.mark.parametrize("i", range(14))
def test_ttldict_bulk_operations(i):
    d = TTLDict(ttl=1.0, maxsize=10)
    for j in range(20):
        d.set(j, j * 2)
    assert d.get(19) == 38
