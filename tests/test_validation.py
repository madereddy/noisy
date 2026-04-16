"""Unit tests for CLI argument validation."""

import argparse
import sys
import os

import pytest

# Make noisy.py importable from project root
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from noisy import validate_args

from noisy_lib.config import (
    DEFAULT_CONNECTIONS_PER_HOST,
    DEFAULT_CRUX_COUNT,
    DEFAULT_DOMAIN_DELAY,
    DEFAULT_KEEPALIVE_TIMEOUT,
    DEFAULT_MAX_DEPTH,
    DEFAULT_MAX_LINKS_PER_PAGE,
    DEFAULT_MAX_QUEUE_SIZE,
    DEFAULT_MAX_SLEEP,
    DEFAULT_MIN_SLEEP,
    DEFAULT_NUM_USERS,
    DEFAULT_THREADS,
    DEFAULT_TOTAL_CONNECTIONS,
)


def make_args(**overrides):
    """Build a valid args namespace; override individual fields as needed."""
    defaults = dict(
        threads=DEFAULT_THREADS,
        num_users=DEFAULT_NUM_USERS,
        max_depth=DEFAULT_MAX_DEPTH,
        min_sleep=DEFAULT_MIN_SLEEP,
        max_sleep=DEFAULT_MAX_SLEEP,
        domain_delay=DEFAULT_DOMAIN_DELAY,
        total_connections=DEFAULT_TOTAL_CONNECTIONS,
        connections_per_host=DEFAULT_CONNECTIONS_PER_HOST,
        keepalive_timeout=DEFAULT_KEEPALIVE_TIMEOUT,
        crux_count=DEFAULT_CRUX_COUNT,
        max_queue_size=DEFAULT_MAX_QUEUE_SIZE,
        max_links_per_page=DEFAULT_MAX_LINKS_PER_PAGE,
    )
    defaults.update(overrides)
    return argparse.Namespace(**defaults)


class TestValidateArgs:
    def test_valid_defaults_pass(self):
        assert validate_args(make_args()) == []

    def test_min_sleep_gt_max_sleep(self):
        errors = validate_args(make_args(min_sleep=20.0, max_sleep=5.0))
        assert any("min_sleep" in e for e in errors)

    def test_min_sleep_equal_max_sleep_passes(self):
        # Edge case: equal values should be allowed
        assert validate_args(make_args(min_sleep=5.0, max_sleep=5.0)) == []

    def test_threads_zero(self):
        errors = validate_args(make_args(threads=0))
        assert any("threads" in e for e in errors)

    def test_threads_negative(self):
        errors = validate_args(make_args(threads=-5))
        assert any("threads" in e for e in errors)

    def test_threads_positive_passes(self):
        assert validate_args(make_args(threads=1)) == []

    def test_num_users_zero(self):
        errors = validate_args(make_args(num_users=0))
        assert any("num_users" in e for e in errors)

    def test_max_depth_zero(self):
        errors = validate_args(make_args(max_depth=0))
        assert any("max_depth" in e for e in errors)

    def test_crux_count_zero(self):
        errors = validate_args(make_args(crux_count=0))
        assert any("crux_count" in e for e in errors)

    def test_negative_domain_delay(self):
        errors = validate_args(make_args(domain_delay=-1.0))
        assert any("domain_delay" in e for e in errors)

    def test_zero_domain_delay_passes(self):
        assert validate_args(make_args(domain_delay=0.0)) == []

    def test_connections_per_host_exceeds_total(self):
        errors = validate_args(make_args(connections_per_host=50, total_connections=10))
        assert any("connections" in e for e in errors)

    def test_per_user_queue_too_small(self):
        # 5 users, queue 9 => per-user = 1, below minimum of 10
        errors = validate_args(make_args(max_queue_size=9, num_users=5))
        assert any("queue" in e.lower() for e in errors)

    def test_per_user_queue_exactly_10_passes(self):
        # 1 user, queue 10 => per-user = 10
        assert validate_args(make_args(max_queue_size=10, num_users=1)) == []

    def test_multiple_errors_reported(self):
        errors = validate_args(make_args(threads=0, min_sleep=99.0, max_sleep=1.0))
        assert len(errors) >= 2
