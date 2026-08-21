# ==================================================
# OptigoAI Backend — Playwright Crawler Provider
# ==================================================

import time
from typing import Dict, Any, List, Optional

from app.core.logging import get_logger
from app.core.security_url import validate_and_sanitize_url
from app.providers.crawler.base import BaseCrawlerProvider, CrawlPageResult, CrawlSiteResult
from app.providers.crawler.beautifulsoup import BeautifulSoupCrawlerProvider

logger = get_logger("app.providers.crawler.playwright")


class PlaywrightCrawlerProvider(BaseCrawlerProvider):
    """
    Headless browser crawler adapter for JavaScript-rendered SPA websites.
    Gracefully falls back to BeautifulSoupCrawlerProvider if Playwright is not installed in the current environment.
    """

    def __init__(self):
        self._bs4_fallback = BeautifulSoupCrawlerProvider()

    def is_configured(self) -> bool:
        try:
            import playwright  # noqa: F401
            return True
        except ImportError:
            return False

    async def crawl_page(self, url: str) -> CrawlPageResult:
        safe_url = validate_and_sanitize_url(url)

        if not self.is_configured():
            logger.info("Playwright not installed in worker; using high-speed HTML parser fallback", url=safe_url)
            return await self._bs4_fallback.crawl_page(safe_url)

        try:
            from playwright.async_api import async_playwright
            start_time = time.time()

            async with async_playwright() as p:
                browser = await p.chromium.launch(headless=True)
                page = await browser.new_page()
                await page.goto(safe_url, timeout=25000, wait_until="domcontentloaded")

                title = await page.title()
                content = await page.content()
                load_time_ms = int((time.time() - start_time) * 1000)

                await browser.close()

                # Parse the rendered DOM using parser
                from app.providers.crawler.beautifulsoup import PageHTMLParser
                parser = PageHTMLParser(base_url=safe_url)
                parser.feed(content)

                return CrawlPageResult(
                    url=safe_url,
                    status_code=200,
                    title=title or parser.title,
                    meta_description=parser.meta_description,
                    h1_tags=parser.h1_tags,
                    h2_tags=parser.h2_tags,
                    canonical_url=parser.canonical_url,
                    has_schema=len(parser.schema_types) > 0,
                    schema_types=parser.schema_types,
                    phone_numbers=list(parser.links)[:5],
                    internal_links=list(parser.links)[:30],
                    social_links=list(parser.social_links)[:10],
                    word_count=len(" ".join(parser.text_chunks).split()),
                    load_time_ms=load_time_ms,
                )
        except Exception as e:
            logger.warning("Playwright rendering failed, falling back to BeautifulSoup", error=str(e))
            return await self._bs4_fallback.crawl_page(safe_url)

    async def crawl_site(self, url: str, max_pages: int = 10) -> CrawlSiteResult:
        return await self._bs4_fallback.crawl_site(url, max_pages=max_pages)
