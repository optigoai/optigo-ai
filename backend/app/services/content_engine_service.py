# ==================================================
# OptigoAI Backend — Content Engine Service
# ==================================================

from typing import Optional, Sequence, Dict, Any, List
from datetime import datetime
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import HTTPException, status

from app.models.content import Content, ContentType, ContentStatus
from app.repositories.business_repo import BusinessRepository
from app.repositories.content_repo import ContentRepository
from app.ai.ai_service import AIService
from app.core.logging import get_logger

logger = get_logger("app.services.content_engine")


class ContentEngineService:
    """Orchestrates AI multi-channel post generation, scheduling, and lifecycle management."""

    def __init__(self, db: AsyncSession):
        self.db = db
        self.business_repo = BusinessRepository(db)
        self.content_repo = ContentRepository(db)
        self.ai_service = AIService(db)

    async def generate_social_posts(
        self,
        business_id: str,
        organization_id: str,
        user_id: Optional[str] = None,
        channels: Optional[List[str]] = None,
        topic: Optional[str] = None,
        tone: Optional[str] = "engaging & professional",
        goal: Optional[str] = "drive customer engagement & foot traffic",
        offer_details: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Generate multi-channel marketing and social media posts using AI."""
        business = await self.business_repo.get_by_id(business_id)
        if not business:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Business not found")
        if business.organization_id != organization_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

        target_channels = channels or ["google_post", "instagram", "facebook", "linkedin"]

        ai_profile = business.ai_business_profile or {}
        summary = ai_profile.get("business_summary") or business.description

        output = await self.ai_service.generate_content(
            organization_id=organization_id,
            user_id=user_id,
            business_name=business.name,
            category=business.category or "Local Business",
            location=business.location or "Local Area",
            channels=target_channels,
            topic=topic,
            tone=tone,
            goal=goal,
            offer_details=offer_details,
            business_summary=summary,
        )

        return {
            "business_id": business_id,
            "campaign_theme": output.campaign_theme,
            "posts": [p.model_dump() for p in output.posts],
            "calendar_suggestions": output.calendar_suggestions,
        }

    async def create_post(
        self,
        business_id: str,
        organization_id: str,
        content_data: dict[str, Any],
    ) -> Content:
        """Save a new post / draft / scheduled post."""
        business = await self.business_repo.get_by_id(business_id)
        if not business:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Business not found")
        if business.organization_id != organization_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

        content_data["business_id"] = business_id
        return await self.content_repo.create_content(content_data)

    async def list_posts(
        self,
        business_id: str,
        organization_id: str,
        content_type: Optional[str] = None,
        status_filter: Optional[str] = None,
        limit: int = 50,
        offset: int = 0,
    ) -> List[Content]:
        """List posts for a business."""
        business = await self.business_repo.get_by_id(business_id)
        if not business:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Business not found")
        if business.organization_id != organization_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

        return await self.content_repo.list_contents(
            business_id=business_id,
            content_type=content_type,
            status=status_filter,
            limit=limit,
            offset=offset,
        )

    async def get_post(
        self,
        content_id: str,
        business_id: str,
        organization_id: str,
    ) -> Content:
        """Get a single post by ID."""
        business = await self.business_repo.get_by_id(business_id)
        if not business:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Business not found")
        if business.organization_id != organization_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

        content = await self.content_repo.get_content(content_id, business_id)
        if not content:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Content not found")
        return content

    async def update_post(
        self,
        content_id: str,
        business_id: str,
        organization_id: str,
        update_data: dict[str, Any],
    ) -> Content:
        """Update an existing post."""
        business = await self.business_repo.get_by_id(business_id)
        if not business:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Business not found")
        if business.organization_id != organization_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

        updated = await self.content_repo.update_content(content_id, business_id, update_data)
        if not updated:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Content not found")
        return updated

    async def publish_post(
        self,
        content_id: str,
        business_id: str,
        organization_id: str,
    ) -> Content:
        """Publish a post immediately."""
        business = await self.business_repo.get_by_id(business_id)
        if not business:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Business not found")
        if business.organization_id != organization_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

        published = await self.content_repo.publish_content(content_id, business_id)
        if not published:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Content not found")
        return published

    async def delete_post(
        self,
        content_id: str,
        business_id: str,
        organization_id: str,
    ) -> bool:
        """Delete a post."""
        business = await self.business_repo.get_by_id(business_id)
        if not business:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Business not found")
        if business.organization_id != organization_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

        deleted = await self.content_repo.delete_content(content_id, business_id)
        if not deleted:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Content not found")
        return True
