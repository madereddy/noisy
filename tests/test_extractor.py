"""Unit tests for HTML link extraction."""

import pytest

from noisy_lib.extractor import LinkExtractor, extract_links


class TestLinkExtractor:
    def test_absolute_link(self):
        parser = LinkExtractor("https://example.com")
        parser.feed('<a href="https://other.com/page">link</a>')
        assert "https://other.com/page" in parser.links

    def test_relative_link_resolved(self):
        parser = LinkExtractor("https://example.com")
        parser.feed('<a href="/about">about</a>')
        assert "https://example.com/about" in parser.links

    def test_base_tag_changes_base(self):
        parser = LinkExtractor("https://example.com")
        parser.feed('<base href="https://cdn.example.com/"><a href="file.js">f</a>')
        assert "https://cdn.example.com/file.js" in parser.links

    def test_non_http_links_excluded(self):
        parser = LinkExtractor("https://example.com")
        parser.feed('<a href="mailto:test@example.com">email</a>')
        assert not any("mailto" in lnk for lnk in parser.links)

    def test_ftp_link_excluded(self):
        parser = LinkExtractor("https://example.com")
        parser.feed('<a href="ftp://files.example.com">ftp</a>')
        assert not any("ftp" in lnk for lnk in parser.links)


class TestExtractLinks:
    def test_returns_list(self):
        links = extract_links('<a href="https://a.com">a</a>', "https://example.com")
        assert isinstance(links, list)

    def test_empty_html_returns_empty(self):
        assert extract_links("", "https://example.com") == []

    def test_no_links_returns_empty(self):
        assert extract_links("<p>no links here</p>", "https://example.com") == []

    def test_multiple_links(self):
        html = '<a href="https://a.com">a</a><a href="https://b.com">b</a>'
        links = extract_links(html, "https://example.com")
        assert len(links) == 2

    def test_blacklist_filters_matching_urls(self):
        html = (
            '<a href="https://example.com/page">ok</a>'
            '<a href="https://t.co/abc123">blocked</a>'
        )
        links = extract_links(html, "https://example.com", blacklist=["t.co"])
        assert "https://example.com/page" in links
        assert not any("t.co" in lnk for lnk in links)

    def test_blacklist_extension(self):
        html = (
            '<a href="https://example.com/login">login</a>'
            '<a href="https://example.com/about">about</a>'
        )
        links = extract_links(html, "https://example.com", blacklist=["login"])
        assert not any("login" in lnk for lnk in links)
        assert any("about" in lnk for lnk in links)

    def test_empty_blacklist_no_filtering(self):
        html = '<a href="https://t.co/xyz">link</a>'
        links = extract_links(html, "https://example.com", blacklist=[])
        assert "https://t.co/xyz" in links

    def test_malformed_html_does_not_raise(self):
        html = "<a href='https://example.com/unclosed"
        links = extract_links(html, "https://example.com")
        assert isinstance(links, list)

    def test_relative_link_in_extract(self):
        html = '<a href="/contact">contact</a>'
        links = extract_links(html, "https://example.com")
        assert "https://example.com/contact" in links
