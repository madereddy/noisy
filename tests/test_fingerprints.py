# tests/test_fingerprints.py
import pytest
from noisy import FingerprintManager

def test_fingerprint_family_identification():
    fm = FingerprintManager()
    
    # Chrome family
    ua_chrome = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
    assert fm.get_family(ua_chrome) == "chrome"
    
    # Firefox family
    ua_firefox = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:123.0) Gecko/20100101 Firefox/123.0"
    assert fm.get_family(ua_firefox) == "firefox"
    
    # Safari family
    ua_safari = "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_3_1) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.3.1 Safari/605.1.15"
    assert fm.get_family(ua_safari) == "safari"

def test_get_headers_for_family():
    fm = FingerprintManager()
    ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
    headers = fm.get_headers(ua)
    assert "Sec-CH-UA" in headers
    # Note: We'll set the UA in UserProfile.get_headers later, but verify basic structure

def test_user_profile_behavioral_flags():
    import random
    from noisy import UserProfile
    
    rng = random.Random(42) # Deterministic
    profile = UserProfile(user_id=1, ua="some-ua", rng=rng)
    
    # Check that flags exist
    assert hasattr(profile, "is_older_user")
    assert hasattr(profile, "behavior_scale")
    assert hasattr(profile, "afk_prob")
    
    # Check behavior_scale logic
    if profile.is_older_user:
        assert profile.behavior_scale == 1.75
        assert profile.afk_prob == 0.10
    else:
        assert profile.behavior_scale == 1.0
        assert profile.afk_prob == 0.05

def test_user_profile_header_refresh():
    import random
    from noisy import UserProfile
    
    ua_chrome = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
    ua_firefox = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:123.0) Gecko/20100101 Firefox/123.0"
    
    rng = random.Random(42)
    profile = UserProfile(user_id=1, ua=ua_chrome, rng=rng)
    
    headers_chrome = profile.get_headers()
    assert "Sec-CH-UA" in headers_chrome
    assert headers_chrome["User-Agent"] == ua_chrome
    
    # Change UA and verify headers refresh
    profile.ua = ua_firefox
    headers_firefox = profile.get_headers()
    assert "Sec-CH-UA" not in headers_firefox
    assert "Accept" in headers_firefox
    assert headers_firefox["User-Agent"] == ua_firefox

