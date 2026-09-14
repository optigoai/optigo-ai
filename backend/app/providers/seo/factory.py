# ==================================================
# OptigoAI Backend — SEO Provider Factory
# ==================================================

from app.core.config import settings
from app.core.logging import get_logger
from app.providers.seo.base import BaseSEOProvider
from app.providers.seo.dataforseo import DataForSEOProvider
from app.providers.seo.serper import SerperProvider
from app.providers.seo.serpapi import SerpAPIProvider

logger = get_logger("app.providers.seo.factory")


class SEOProviderFactory:
    """Factory for dynamically creating and switching the active SEO/SERP provider."""

    @staticmethod
    def get_provider() -> BaseSEOProvider:
        provider_name = (settings.seo_provider or "").lower().strip()

        # If explicitly set and configured
        if provider_name == "serper":
            return SerperProvider()
        elif provider_name == "serpapi":
            return SerpAPIProvider()
        elif provider_name == "dataforseo":
            dfs = DataForSEOProvider()
            if dfs.is_configured():
                return dfs
            # If DataForSEO credentials are missing, check Serper
            serper = SerperProvider()
            if serper.is_configured():
                return serper
            return dfs

        # Auto-detect best configured provider
        serper = SerperProvider()
        if serper.is_configured():
            return serper

        dfs = DataForSEOProvider()
        if dfs.is_configured():
            return dfs

        serpapi = SerpAPIProvider()
        if serpapi.is_configured():
            return serpapi

        # Default fallback
        return SerperProvider()
