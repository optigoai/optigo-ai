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
        provider_name = (settings.seo_provider or "dataforseo").lower().strip()

        if provider_name == "serper":
            return SerperProvider()
        elif provider_name == "serpapi":
            return SerpAPIProvider()
        elif provider_name == "dataforseo":
            return DataForSEOProvider()
        else:
            logger.warning(f"Unknown SEO provider '{provider_name}', defaulting to DataForSEO")
            return DataForSEOProvider()
