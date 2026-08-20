# ==================================================
# OptigoAI Backend — Providers Package
# ==================================================
"""
Provider factory — returns the correct provider implementation
based on environment configuration.
"""

from app.providers.base import (
    BusinessDataProvider,
    AIProvider,
    StorageProvider,
    SEOProvider,
    CompetitorProvider,
)
from app.providers.mock_gbp import MockGBPProvider


def get_business_data_provider() -> BusinessDataProvider:
    """Get the configured business data provider."""
    # MVP: always use MockGBPProvider
    # Future: check config for "google" and return GoogleGBPProvider
    return MockGBPProvider()


__all__ = [
    "BusinessDataProvider",
    "AIProvider",
    "StorageProvider",
    "SEOProvider",
    "CompetitorProvider",
    "MockGBPProvider",
    "get_business_data_provider",
]
