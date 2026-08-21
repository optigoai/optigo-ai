# ==================================================
# OptigoAI Backend — Lightweight HTML Parser / Crawler
# ==================================================

import re
import time
import json
from html.parser import HTMLParser
from urllib.parse import urljoin, urlparse
from typing import Dict, Any, List, Optional, Set
import httpx

from app.core.config import settings
from app.core.logging import get_logger
from app.core.security_url import validate_and_sanitize_url
from app.providers.crawler.base import BaseCrawlerProvider, CrawlPageResult, CrawlSiteResult

logger = get_logger("app.providers.crawler.bs4")

PHONE_REGEX = re.compile(r"(?:\+?\d{1,3}[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}")
EMAIL_REGEX = re.compile(r"[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+")
SOCIAL_DOMAINS = {"instagram.com", "facebook.com", "linkedin.com", "twitter.com", "x.com", "youtube.com"}


class PageHTMLParser(HTMLParser):
    def __init__(self, base_url: str):
        super().__init__()
        self.base_url = base_url
        self.title: Optional[str] = None
        self.meta_description: Optional[str] = None
        self.canonical_url: Optional[str] = None
        self.h1_tags: List[str] = []
        self.h2_tags: List[str] = []
        self.links: Set[str] = set()
        self.social_links: Set[str] = set()
        self.schema_types: List[str] = []
        self.text_chunks: List[str] = []
        
        self._current_tag: Optional[str] = None
        self._in_script = False
        self._in_style = False
        self._in_json_ld = False
        self._json_ld_data = ""

    def handle_starttag(self, tag: str, attrs: list):
        self._current_tag = tag.lower()
        attr_dict = {k.lower(): (v or "") for k, v in attrs}

        if self._current_tag == "script":
            if attr_dict.get("type") == "application/ld+json":
                self._in_json_ld = True
                self._json_ld_data = ""
            else:
                self._in_script = True
        elif self._current_tag == "style":
            self._in_style = True
        elif self._current_tag == "meta":
            name = attr_dict.get("name", "").lower() or attr_dict.get("property", "").lower()
            content = attr_dict.get("content", "").strip()
            if name in ("description", "og:description") and not self.meta_description:
                self.meta_description = content
        elif self._current_tag == "link":
            rel = attr_dict.get("rel", "").lower()
            href = attr_dict.get("href", "").strip()
            if "canonical" in rel and href:
                self.canonical_url = urljoin(self.base_url, href)
        elif self._current_tag == "a":
            href = attr_dict.get("href", "").strip()
            if href:
                full_url = urljoin(self.base_url, href)
                parsed = urlparse(full_url)
                if any(domain in parsed.netloc for domain in SOCIAL_DOMAINS):
                    self.social_links.add(full_url)
                elif parsed.netloc == urlparse(self.base_url).netloc:
                    self.links.add(full_url)

    def handle_endtag(self, tag: str):
        t = tag.lower()
        if t == "script":
            if self._in_json_ld:
                self._parse_json_ld(self._json_ld_data)
                self._in_json_ld = False
            self._in_script = False
        elif t == "style":
            self._in_style = False
        self._current_tag = None

    def handle_data(self, data: str):
        text = data.strip()
        if not text:
            return

        if self._in_json_ld:
            self._json_ld_data += data
            return

        if self._in_script or self._in_style:
            return

        if self._current_tag == "title" and not self.title:
            self.title = text
        elif self._current_tag == "h1":
            self.h1_tags.append(text)
        elif self._current_tag == "h2":
            self.h2_tags.append(text)
        else:
            self.text_chunks.append(text)

    def _parse_json_ld(self, raw_json: str):
        try:
            parsed = json.loads(raw_json)
            if isinstance(parsed, dict):
                st = parsed.get("@type")
                if st:
                    self.schema_types.append(st if isinstance(st, str) else str(st))
            elif isinstance(parsed, list):
                for item in parsed:
                    if isinstance(item, dict) and "@type" in item:
                        self.schema_types.append(item["@type"])
        except Exception:
            pass


class BeautifulSoupCrawlerProvider(BaseCrawlerProvider):
    """Lightweight, safe HTTP HTML parser and metadata extractor."""

    def __init__(self):
        self.timeout = settings.crawler_timeout_seconds or 30
        self.max_size = settings.crawler_max_response_size_bytes or 5242880

    def is_configured(self) -> bool:
        return True

    async def crawl_page(self, url: str) -> CrawlPageResult:
        # SSRF Security Validation
        safe_url = validate_and_sanitize_url(url)
        start_time = time.time()

        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) OptigoAI/1.0 Website Intelligence Bot",
            "Accept": "text/html,application/xhtml+xml",
        }

        async with httpx.AsyncClient(timeout=float(self.timeout), follow_redirects=True) as client:
            try:
                res = await client.get(safe_url, headers=headers)
                load_time_ms = int((time.time() - start_time) * 1000)

                # Check max response size
                if len(res.content) > self.max_size:
                    html_content = res.content[: self.max_size].decode("utf-8", errors="ignore")
                else:
                    html_content = res.text

                parser = PageHTMLParser(base_url=safe_url)
                parser.feed(html_content)

                full_text = " ".join(parser.text_chunks)
                phones = list(set(PHONE_REGEX.findall(full_text)))[:5]
                emails = list(set(EMAIL_REGEX.findall(full_text)))[:5]

                return CrawlPageResult(
                    url=safe_url,
                    status_code=res.status_code,
                    title=parser.title,
                    meta_description=parser.meta_description,
                    h1_tags=parser.h1_tags[:5],
                    h2_tags=parser.h2_tags[:10],
                    canonical_url=parser.canonical_url,
                    has_schema=len(parser.schema_types) > 0,
                    schema_types=parser.schema_types,
                    phone_numbers=phones,
                    emails=emails,
                    social_links=list(parser.social_links)[:10],
                    internal_links=list(parser.links)[:30],
                    word_count=len(full_text.split()),
                    load_time_ms=load_time_ms,
                    raw_text_snippet=full_text[:500] if full_text else None,
                )
            except Exception as e:
                logger.error("HTTP crawl failed", url=safe_url, error=str(e))
                return CrawlPageResult(
                    url=safe_url,
                    status_code=500,
                    title=None,
                    raw_text_snippet=f"Crawl error: {str(e)}",
                )

    async def crawl_site(self, url: str, max_pages: int = 10) -> CrawlSiteResult:
        safe_url = validate_and_sanitize_url(url)
        start_time = time.time()

        root_page = await self.crawl_page(safe_url)
        crawled_pages = [root_page]
        visited_urls = {safe_url}

        # Crawl child internal pages up to limit
        for link in root_page.internal_links:
            if len(crawled_pages) >= max_pages:
                break
            if link not in visited_urls:
                visited_urls.add(link)
                try:
                    child_page = await self.crawl_page(link)
                    crawled_pages.append(child_page)
                except Exception:
                    continue

        duration = round(time.time() - start_time, 2)
        return CrawlSiteResult(
            root_url=safe_url,
            pages=crawled_pages,
            total_pages_crawled=len(crawled_pages),
            has_sitemap=any("/sitemap" in p.url for p in crawled_pages),
            has_robots_txt=True,
            provider_used="beautifulsoup",
            duration_seconds=duration,
        )
