# ==================================================
# OptigoAI Backend — SEO & SERP Provider Base Interface
# ==================================================

from abc import ABC, abstractmethod
from typing import Dict, Any, List, Optional


class BaseSEOProvider(ABC):
    """Abstract interface for interchangeable SERP and SEO data providers."""

    @abstractmethod
    def is_configured(self) -> bool:
        """Check if provider credentials are set."""
        ...

    @abstractmethod
    async def get_keyword_rank(
        self,
        keyword: str,
        domain: str,
        location: Optional[str] = None,
        device: str = "mobile",
    ) -> Dict[str, Any]:
        """Fetch current search ranking position for a domain/keyword in a specific location."""
        ...

    @abstractmethod
    async def get_keyword_metrics(
        self,
        keywords: List[str],
        location: Optional[str] = None,
    ) -> List[Dict[str, Any]]:
        """Fetch search volume, CPC, and competition difficulty for keywords."""
        ...

    @abstractmethod
    async def get_local_competitors(
        self,
        keyword: str,
        location: Optional[str] = None,
        limit: int = 5,
    ) -> List[Dict[str, Any]]:
        """Fetch top ranking local competitors on Google Maps / SERP."""
        ...

    @abstractmethod
    async def search(
        self,
        query: str,
        location: Optional[str] = None,
        device: str = "mobile",
    ) -> Dict[str, Any]:
        """Execute general Google search query."""
        ...
