# ==================================================
# OptigoAI Backend — Website Crawler Base Interface & Dataclasses
# ==================================================

from abc import ABC, abstractmethod
from typing import Dict, Any, List, Optional
from pydantic import BaseModel, Field


class CrawlPageResult(BaseModel):
    url: str
    status_code: int = 200
    title: Optional[str] = None
    meta_description: Optional[str] = None
    h1_tags: List[str] = Field(default_factory=list)
    h2_tags: List[str] = Field(default_factory=list)
    canonical_url: Optional[str] = None
    has_schema: bool = False
    schema_types: List[str] = Field(default_factory=list)
    phone_numbers: List[str] = Field(default_factory=list)
    emails: List[str] = Field(default_factory=list)
    addresses: List[str] = Field(default_factory=list)
    social_links: List[str] = Field(default_factory=list)
    internal_links: List[str] = Field(default_factory=list)
    word_count: int = 0
    load_time_ms: int = 0
    is_mobile_friendly: bool = True
    raw_text_snippet: Optional[str] = None


class CrawlSiteResult(BaseModel):
    root_url: str
    pages: List[CrawlPageResult] = Field(default_factory=list)
    total_pages_crawled: int = 0
    has_sitemap: bool = False
    has_robots_txt: bool = False
    provider_used: str = "beautifulsoup"
    duration_seconds: float = 0.0
    error: Optional[str] = None


class BaseCrawlerProvider(ABC):
    """Abstract interface for website intelligence and crawlers."""

    @abstractmethod
    def is_configured(self) -> bool:
        """Check if provider is configured and available."""
        ...

    @abstractmethod
    async def crawl_page(self, url: str) -> CrawlPageResult:
        """Extract SEO signals and business metadata from a single web page."""
        ...

    @abstractmethod
    async def crawl_site(self, url: str, max_pages: int = 10) -> CrawlSiteResult:
        """Crawl website up to max_pages and return normalized site intelligence."""
        ...
