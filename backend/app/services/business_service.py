from typing import List, Optional, Dict, Any
from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.business import Business
from app.repositories.business_repo import BusinessRepository


class BusinessService:
    def __init__(self, db: AsyncSession):
        self.db = db
        self.repo = BusinessRepository(db)

    async def list_businesses(self, organization_id: str) -> List[Business]:
        return await self.repo.list_by_org(organization_id)

    async def get_business(self, business_id: str, organization_id: str) -> Business:
        business = await self.repo.get_by_id_and_org(business_id, organization_id)
        if not business:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Business not found or you do not have permission to access it.",
            )
        return business

    async def create_business(
        self,
        organization_id: str,
        name: str,
        category: Optional[str] = None,
        location: Optional[str] = None,
        website: Optional[str] = None,
        phone: Optional[str] = None,
        description: Optional[str] = None,
    ) -> Business:
        return await self.repo.create(
            organization_id=organization_id,
            name=name,
            category=category,
            location=location,
            website=website,
            phone=phone,
            description=description,
        )

    async def submit_onboarding(
        self,
        business_id: str,
        organization_id: str,
        target_customers: Optional[str] = None,
        services: Optional[str] = None,
        business_goals: Optional[str] = None,
        marketing_channels: Optional[str] = None,
        ai_business_profile: Optional[Dict[str, Any]] = None,
        health_score: Optional[int] = None,
    ) -> Business:
        business = await self.get_business(business_id, organization_id)
        return await self.repo.update_onboarding(
            business=business,
            target_customers=target_customers,
            services=services,
            business_goals=business_goals,
            marketing_channels=marketing_channels,
            ai_business_profile=ai_business_profile,
            health_score=health_score,
        )
