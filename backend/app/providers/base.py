# ==================================================
# OptigoAI Backend — Provider Base Interfaces
# ==================================================
"""
Abstract provider interfaces that decouple external
services from core business logic.

To replace a provider:
1. Create a new class implementing the interface
2. Update the provider factory in config
3. No changes needed to services, AI, or Flutter
"""

from abc import ABC, abstractmethod
from typing import Any, Optional


class BusinessDataProvider(ABC):
    """Interface for fetching external business data (e.g., GBP)."""

    @abstractmethod
    async def get_business_profile(self, business_id: str) -> dict[str, Any]:
        """Fetch the business profile from external source."""
        ...

    @abstractmethod
    async def get_reviews(self, business_id: str) -> list[dict[str, Any]]:
        """Fetch reviews from external source."""
        ...

    @abstractmethod
    async def get_performance_metrics(self, business_id: str) -> dict[str, Any]:
        """Fetch performance/analytics metrics."""
        ...

    @abstractmethod
    async def get_posts(self, business_id: str) -> list[dict[str, Any]]:
        """Fetch business posts."""
        ...


class AIProvider(ABC):
    """Interface for AI text/chat generation."""

    @abstractmethod
    async def generate_text(
        self,
        prompt: str,
        system_instruction: Optional[str] = None,
        temperature: float = 0.7,
        max_tokens: int = 4096,
    ) -> dict[str, Any]:
        """Generate text from a prompt. Returns dict with 'text', 'usage' keys."""
        ...

    @abstractmethod
    async def generate_structured(
        self,
        prompt: str,
        response_schema: dict[str, Any],
        system_instruction: Optional[str] = None,
        temperature: float = 0.3,
    ) -> dict[str, Any]:
        """Generate structured JSON output matching a schema."""
        ...

    @abstractmethod
    async def generate_image(
        self,
        prompt: str,
        size: str = "1024x1024",
    ) -> dict[str, Any]:
        """Generate an image. Returns dict with 'image_data' or 'image_url'."""
        ...


class StorageProvider(ABC):
    """Interface for file/object storage."""

    @abstractmethod
    async def upload_file(
        self,
        file_data: bytes,
        file_name: str,
        content_type: str = "application/octet-stream",
    ) -> str:
        """Upload a file and return its public URL or path."""
        ...

    @abstractmethod
    async def delete_file(self, file_path: str) -> bool:
        """Delete a file. Returns True if successful."""
        ...

    @abstractmethod
    async def get_file_url(self, file_path: str) -> str:
        """Get a URL for accessing a file."""
        ...


class SEOProvider(ABC):
    """Interface for SEO data/analysis."""

    @abstractmethod
    async def analyze_local_seo(
        self, business_data: dict[str, Any]
    ) -> dict[str, Any]:
        """Analyze local SEO for a business."""
        ...

    @abstractmethod
    async def get_keyword_data(
        self, keywords: list[str], location: str
    ) -> list[dict[str, Any]]:
        """Get keyword search data for a location."""
        ...


class CompetitorProvider(ABC):
    """Interface for competitor data/intelligence."""

    @abstractmethod
    async def find_competitors(
        self, business_data: dict[str, Any], limit: int = 5
    ) -> list[dict[str, Any]]:
        """Find competitors for a business."""
        ...

    @abstractmethod
    async def get_competitor_details(
        self, competitor_id: str
    ) -> dict[str, Any]:
        """Get detailed competitor information."""
        ...
