# ==================================================
# OptigoAI Backend — Content Repository
# ==================================================

from datetime import datetime, timezone
from typing import Optional, Any, Sequence
from sqlalchemy import select, func, and_
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.content import Content, ContentType, ContentStatus


class ContentRepository:
    """Multi-tenant data access layer for Content & Social Media Posts."""

    def __init__(self, db: AsyncSession):
        self.db = db

    async def create_content(self, content_data: dict[str, Any]) -> Content:
        """Create and persist a new content item / social post."""
        if isinstance(content_data.get("content_type"), str):
            content_data["content_type"] = ContentType(content_data["content_type"])
        if isinstance(content_data.get("status"), str):
            content_data["status"] = ContentStatus(content_data["status"])

        content = Content(**content_data)
        self.db.add(content)
        await self.db.flush()
        await self.db.refresh(content)
        return content

    async def get_content(self, content_id: str, business_id: str) -> Optional[Content]:
        """Fetch a specific content item belonging to a business."""
        query = select(Content).where(
            and_(
                Content.id == content_id,
                Content.business_id == business_id
            )
        )
        result = await self.db.execute(query)
        return result.scalar_one_or_none()

    async def list_contents(
        self,
        business_id: str,
        content_type: Optional[str] = None,
        status: Optional[str] = None,
        limit: int = 50,
        offset: int = 0,
    ) -> Sequence[Content]:
        """List content items for a business with optional filtering."""
        conditions = [Content.business_id == business_id]
        if content_type:
            try:
                conditions.append(Content.content_type == ContentType(content_type))
            except ValueError:
                pass
        if status:
            try:
                conditions.append(Content.status == ContentStatus(status))
            except ValueError:
                pass

        query = (
            select(Content)
            .where(and_(*conditions))
            .order_by(Content.created_at.desc())
            .limit(limit)
            .offset(offset)
        )
        result = await self.db.execute(query)
        return result.scalars().all()

    async def update_content(
        self, content_id: str, business_id: str, update_data: dict[str, Any]
    ) -> Optional[Content]:
        """Update fields of an existing content item."""
        content = await self.get_content(content_id, business_id)
        if not content:
            return None

        for field, value in update_data.items():
            if value is not None and hasattr(content, field):
                if field == "content_type" and isinstance(value, str):
                    value = ContentType(value)
                elif field == "status" and isinstance(value, str):
                    value = ContentStatus(value)
                setattr(content, field, value)

        await self.db.flush()
        await self.db.refresh(content)
        return content

    async def publish_content(self, content_id: str, business_id: str) -> Optional[Content]:
        """Mark content item as published with timestamp."""
        content = await self.get_content(content_id, business_id)
        if not content:
            return None

        content.status = ContentStatus.PUBLISHED
        content.published_at = datetime.now(timezone.utc)
        await self.db.flush()
        await self.db.refresh(content)
        return content

    async def delete_content(self, content_id: str, business_id: str) -> bool:
        """Delete a content item."""
        content = await self.get_content(content_id, business_id)
        if not content:
            return False

        await self.db.delete(content)
        await self.db.flush()
        return True

    async def count_contents(self, business_id: str, status: Optional[str] = None) -> int:
        """Count contents for a business."""
        conditions = [Content.business_id == business_id]
        if status:
            try:
                conditions.append(Content.status == ContentStatus(status))
            except ValueError:
                pass

        query = select(func.count(Content.id)).where(and_(*conditions))
        result = await self.db.execute(query)
        return result.scalar() or 0
