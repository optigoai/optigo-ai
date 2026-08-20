from typing import Optional, List, Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models.business import Business


class BusinessRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_by_id_and_org(self, business_id: str, organization_id: str) -> Optional[Business]:
        """Fetch business strictly scoped to the user's organization."""
        result = await self.db.execute(
            select(Business).where(
                Business.id == business_id,
                Business.organization_id == organization_id,
            )
        )
        return result.scalar_one_or_none()

    async def list_by_org(self, organization_id: str) -> List[Business]:
        """List all businesses belonging to an organization."""
        result = await self.db.execute(
            select(Business)
            .where(Business.organization_id == organization_id)
            .order_by(Business.created_at.desc())
        )
        return list(result.scalars().all())

    async def create(
        self,
        organization_id: str,
        name: str,
        category: Optional[str] = None,
        location: Optional[str] = None,
        website: Optional[str] = None,
        phone: Optional[str] = None,
        description: Optional[str] = None,
    ) -> Business:
        business = Business(
            organization_id=organization_id,
            name=name,
            category=category,
            location=location,
            website=website,
            phone=phone,
            description=description,
        )
        self.db.add(business)
        await self.db.flush()
        return business

    async def update_onboarding(
        self,
        business: Business,
        target_customers: Optional[str] = None,
        services: Optional[str] = None,
        business_goals: Optional[str] = None,
        marketing_channels: Optional[str] = None,
        ai_business_profile: Optional[Dict[str, Any]] = None,
        health_score: Optional[int] = None,
    ) -> Business:
        if target_customers is not None:
            business.target_customers = target_customers
        if services is not None:
            business.services = services
        if business_goals is not None:
            business.business_goals = business_goals
        if marketing_channels is not None:
            business.marketing_channels = marketing_channels
        if ai_business_profile is not None:
            business.ai_business_profile = ai_business_profile
        if health_score is not None:
            business.health_score = health_score

        business.onboarding_completed = True
        await self.db.flush()
        return business
