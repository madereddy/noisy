# tests/test_behavior.py
import pytest
import asyncio
import time
from unittest.mock import MagicMock
from noisy import UserCrawler, UserProfile, LRUSet

@pytest.mark.asyncio
async def test_resource_pacer_delay():
    profile = MagicMock(spec=UserProfile)
    profile.rng = MagicMock()
    profile.behavior_scale = 1.0
    profile.is_older_user = False
    
    crawler = UserCrawler(
        profile=profile,
        shared_root_urls=[],
        shared_visited=LRUSet(100),
        max_depth=1,
        concurrency=1,
        min_sleep=1,
        max_sleep=1,
        domain_delay=1,
        total_connections=1,
        connections_per_host=1,
        keepalive_timeout=1,
        max_queue_size=1,
        max_links_per_page=1,
        stop_event=asyncio.Event()
    )
    
    # Set pacer to 1 second in the future
    crawler.active_loading_until = time.monotonic() + 1.0
    
    start = time.monotonic()
    await crawler.wait_for_pacer()
    end = time.monotonic()
    
    assert end - start >= 0.9 # Should have waited
