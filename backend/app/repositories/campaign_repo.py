# ==================================================
# OptigoAI Backend — Campaign Repository
# ==================================================

from typing import Optional, Sequence, Dict, Any
from sqlalchemy import select, desc
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.campaign import Campaign, CampaignStatus


class CampaignRepository:
    """Repository for managing multi-channel marketing campaigns."""

    def __init__(self, db: AsyncSession):
        self.db = db

    async def create(self, data: Dict[str, Any]) -> Campaign:
        campaign = Campaign(**data)
        self.db.add(campaign)
        await self.db.commit()
        await self.db.refresh(campaign)
        return campaign

    async def get_by_id(self, campaign_id: str) -> Optional[Campaign]:
        result = await self.db.execute(select(Campaign).where(Campaign.id == campaign_id))
        return result.scalar_one_or_none()

    async def list_by_business(
        self,
        business_id: str,
        status: Optional[CampaignStatus] = None,
        limit: int = 50,
        offset: int = 0,
    ) -> Sequence[Campaign]:
        query = select(Campaign).where(Campaign.business_id == business_id)
        if status:
            query = query.where(Campaign.status == status)
        query = query.order_by(desc(Campaign.created_at)).limit(limit).offset(offset)
        result = await self.db.execute(query)
        return result.scalars().all()

    async def update(self, campaign: Campaign, update_data: Dict[str, Any]) -> Campaign:
        for field, value in update_data.items():
            if value is not None and hasattr(campaign, field):
                setattr(campaign, field, value)
        await self.db.commit()
        await self.db.refresh(campaign)
        return campaign

    async def delete(self, campaign: Campaign) -> None:
        await self.db.delete(campaign)
        await self.db.commit()
