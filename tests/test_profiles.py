"""Unit tests for diurnal weight model and UAPool."""

import random

import pytest

from noisy_lib.profiles import UAPool, UserProfile, _diurnal_weight, _activity_pause_seconds


class TestDiurnalWeight:
    def test_range_all_hours(self):
        for hour in range(24):
            w = _diurnal_weight(float(hour))
            assert 0.05 <= w <= 1.0, f"Weight {w} out of [0.05, 1.0] at hour {hour}"

    def test_fractional_hours(self):
        for tenth in range(240):
            hour = tenth / 10.0
            w = _diurnal_weight(hour)
            assert 0.05 <= w <= 1.0

    def test_midday_higher_than_midnight(self):
        assert _diurnal_weight(12.0) > _diurnal_weight(0.0)

    def test_evening_boost_around_9pm(self):
        evening = _diurnal_weight(21.0)
        pre_dawn = _diurnal_weight(4.0)
        assert evening > pre_dawn

    def test_minimum_never_zero(self):
        for hour in range(24):
            assert _diurnal_weight(float(hour)) >= 0.05


class TestActivityPause:
    def test_usually_no_pause(self):
        rng = random.Random(42)
        pauses = [_activity_pause_seconds(rng) for _ in range(200)]
        non_zero = [p for p in pauses if p > 0]
        # Expect roughly 5%; allow generous range 0–15%
        assert len(non_zero) / len(pauses) < 0.15

    def test_pause_duration_in_range(self):
        rng = random.Random(0)
        for _ in range(1000):
            p = _activity_pause_seconds(rng)
            if p > 0:
                assert 300 <= p <= 1800


class TestUAPool:
    def test_get_random_returns_member(self):
        pool = UAPool(["ua1", "ua2", "ua3"])
        ua = pool.get_random()
        assert ua in ["ua1", "ua2", "ua3"]

    def test_sample_correct_count(self):
        pool = UAPool(["ua1", "ua2", "ua3", "ua4", "ua5"])
        sampled = pool.sample(3)
        assert len(sampled) == 3

    def test_sample_with_repeat_when_pool_small(self):
        pool = UAPool(["ua1", "ua2"])
        sampled = pool.sample(5)
        assert len(sampled) == 5
        assert all(s in ["ua1", "ua2"] for s in sampled)

    def test_len(self):
        pool = UAPool(["ua1", "ua2", "ua3"])
        assert len(pool) == 3

    @pytest.mark.asyncio
    async def test_replace_updates_pool(self):
        pool = UAPool(["old_ua"])
        await pool.replace(["new1", "new2", "new3"])
        assert len(pool) == 3
        ua = pool.get_random()
        assert ua in ["new1", "new2", "new3"]

    @pytest.mark.asyncio
    async def test_replace_empty_list(self):
        pool = UAPool(["ua"])
        await pool.replace([])
        assert len(pool) == 0


class TestUserProfile:
    def test_get_headers_contains_ua(self):
        rng = random.Random(1)
        profile = UserProfile(user_id=0, ua="TestBrowser/1.0", rng=rng)
        headers = profile.get_headers()
        assert headers["User-Agent"] == "TestBrowser/1.0"

    def test_get_headers_with_referrer(self):
        rng = random.Random(2)
        profile = UserProfile(user_id=0, ua="TestBrowser/1.0", rng=rng)
        headers = profile.get_headers(referrer="https://ref.com")
        assert headers.get("Referer") == "https://ref.com"

    def test_get_headers_no_referrer_no_referer_key(self):
        rng = random.Random(3)
        profile = UserProfile(user_id=0, ua="TestBrowser/1.0", rng=rng)
        headers = profile.get_headers()
        assert "Referer" not in headers

    def test_diurnal_weight_in_range(self):
        rng = random.Random(4)
        profile = UserProfile(user_id=0, ua="TestBrowser/1.0", rng=rng)
        w = profile.diurnal_weight()
        assert 0.05 <= w <= 1.0
