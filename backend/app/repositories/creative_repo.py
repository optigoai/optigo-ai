# ==================================================
# OptigoAI Backend — Creative Repository
# ==================================================

from typing import Optional, Sequence, Dict, Any
from sqlalchemy import select, desc
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.creative import Creative, CreativeStatus


class CreativeRepository:
    """Repository for managing smart creatives and promo flyers."""

    def __init__(self, db: AsyncSession):
        self.db = db

    async def create(self, data: Dict[str, Any]) -> Creative:
        creative = Creative(**data)
        self.db.add(creative)
        await self.db.commit()
        await self.db.refresh(creative)
        return creative

    async def get_by_id(self, creative_id: str) -> Optional[Creative]:
        result = await self.db.execute(select(Creative).where(Creative.id == creative_id))
        return result.scalar_one_or_none()

    async def list_by_business(
        self,
        business_id: str,
        campaign_id: Optional[str] = None,
        limit: int = 50,
        offset: int = 0,
    ) -> Sequence[Creative]:
        query = select(Creative).where(Creative.business_id == business_id)
        if campaign_id:
            query = query.where(Creative.campaign_id == campaign_id)
        query = query.order_by(desc(Creative.created_at)).limit(limit).offset(offset)
        result = await self.db.execute(query)
        return result.scalars().all()

    async def update(self, creative: Creative, update_data: Dict[str, Any]) -> Creative:
        for field, value in update_data.items():
            if value is not None and hasattr(creative, field):
                setattr(creative, field, value)
        await self.db.commit()
        await self.db.refresh(creative)
        return creative

    async def delete(self, creative: Creative) -> None:
        await self.db.delete(creative)
        await self.db.commit()
