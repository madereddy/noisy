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
