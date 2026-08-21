# ==================================================
# OptigoAI Backend — Website Crawler Factory
# ==================================================

from app.core.config import settings
from app.core.logging import get_logger
from app.providers.crawler.base import BaseCrawlerProvider
from app.providers.crawler.firecrawl import FirecrawlProvider
from app.providers.crawler.beautifulsoup import BeautifulSoupCrawlerProvider
from app.providers.crawler.playwright import PlaywrightCrawlerProvider

logger = get_logger("app.providers.crawler.factory")


class WebsiteCrawlerFactory:
    """Factory creating and resolving crawler providers with automatic fallback hierarchy."""

    @staticmethod
    def get_provider() -> BaseCrawlerProvider:
        preferred = (settings.website_crawler_provider or "firecrawl").lower().strip()

        if preferred == "firecrawl":
            fc = FirecrawlProvider()
            if fc.is_configured():
                return fc
            # If not configured, fall back to BeautifulSoup
            logger.info("Firecrawl API key not set, using BeautifulSoupCrawlerProvider")
            return BeautifulSoupCrawlerProvider()

        elif preferred == "playwright":
            pw = PlaywrightCrawlerProvider()
            if pw.is_configured():
                return pw
            logger.info("Playwright not installed, using BeautifulSoupCrawlerProvider")
            return BeautifulSoupCrawlerProvider()

        elif preferred == "beautifulsoup":
            return BeautifulSoupCrawlerProvider()

        return BeautifulSoupCrawlerProvider()
