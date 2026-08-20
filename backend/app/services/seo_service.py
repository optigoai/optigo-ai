from typing import List, Optional
import random
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import HTTPException, status

from app.core.logging import get_logger
from app.models.seo import SEOKeyword, SEOAudit
from app.models.business import Business
from app.repositories.seo_repo import SEORepository
from app.ai.ai_service import AIService
from app.schemas.seo import SEOKeywordCreate

logger = get_logger("app.services.seo")


class SEOService:
    def __init__(self, db: AsyncSession):
        self.db = db
        self.repo = SEORepository(db)
        self.ai_service = AIService(db)

    async def _get_business_or_404(self, business_id: str) -> Business:
        business = await self.db.get(Business, business_id)
        if not business:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Business not found")
        return business

    async def list_keywords(self, business_id: str) -> List[SEOKeyword]:
        await self._get_business_or_404(business_id)
        keywords = await self.repo.get_keywords_by_business(business_id)
        # If no keywords yet, seed default ones based on business type
        if not keywords:
            business = await self._get_business_or_404(business_id)
            location = business.location or "Local Market"
            defaults = [
                (f"{business.category or 'oil mill'} near me", 2, "1.8K / mo", "Low"),
                (f"best {business.category or 'flour mill'} in {location}", 4, "950 / mo", "Medium"),
                (f"fresh cold pressed oil {location}", 1, "600 / mo", "Low"),
                (f"wholesale flour supply {location}", 7, "400 / mo", "Medium"),
            ]
            for kw, rank, vol, diff in defaults:
                k_obj = SEOKeyword(
                    business_id=business_id,
                    keyword=kw,
                    target_location=location,
                    current_rank=rank,
                    previous_rank=rank + random.choice([1, 2, -1, 0]),
                    search_volume=vol,
                    difficulty=diff,
                    intent="Local Intent",
                    is_tracked=True,
                )
                await self.repo.create_keyword(k_obj)
            keywords = await self.repo.get_keywords_by_business(business_id)
        return keywords

    async def add_keyword(self, business_id: str, data: SEOKeywordCreate) -> SEOKeyword:
        business = await self._get_business_or_404(business_id)
        existing = await self.repo.get_keyword_by_text(business_id, data.keyword)
        if existing:
            return existing

        location = data.target_location or business.location or "Local Market"
        current_rank = data.current_rank or random.randint(2, 12)
        keyword_obj = SEOKeyword(
            business_id=business_id,
            keyword=data.keyword.strip(),
            target_location=location,
            current_rank=current_rank,
            previous_rank=current_rank + random.choice([1, 2, 0]),
            search_volume=data.search_volume or "750 / mo",
            difficulty=data.difficulty or "Medium",
            intent=data.intent or "Local Intent",
            is_tracked=True,
        )
        return await self.repo.create_keyword(keyword_obj)

    async def delete_keyword(self, business_id: str, keyword_id: str) -> None:
        await self._get_business_or_404(business_id)
        keyword = await self.repo.get_keyword_by_id(keyword_id, business_id)
        if not keyword:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Tracked keyword not found")
        await self.repo.delete_keyword(keyword)

    async def get_or_generate_audit(
        self,
        business_id: str,
        user_id: Optional[str] = None,
        force_fresh: bool = False,
    ) -> SEOAudit:
        business = await self._get_business_or_404(business_id)
        if not force_fresh:
            latest = await self.repo.get_latest_audit(business_id)
            if latest:
                return latest

        # Query tracked keywords for context
        tracked = await self.repo.get_keywords_by_business(business_id)
        kw_list = [k.keyword for k in tracked]
        location = business.location or "Local Market"

        ai_res = await self.ai_service.generate_seo_audit(
            organization_id=business.organization_id,
            user_id=user_id,
            business_name=business.name,
            category=business.category or "Local Business",
            location=location,
            description=business.description,
            current_keywords=kw_list,
            rating=4.5,
            reviews_count=10,
        )

        audit_obj = SEOAudit(
            business_id=business_id,
            overall_seo_score=ai_res.overall_seo_score,
            map_pack_score=ai_res.map_pack_score,
            keyword_score=ai_res.keyword_score,
            citation_score=ai_res.citation_score,
            missing_attributes=ai_res.missing_attributes,
            actionable_recommendations=ai_res.actionable_recommendations,
            competitor_insights=ai_res.competitor_insights,
        )
        return await self.repo.save_audit(audit_obj)

    async def discover_keywords(
        self,
        business_id: str,
        user_id: Optional[str] = None,
        target_services: Optional[List[str]] = None,
    ) -> List[dict]:
        business = await self._get_business_or_404(business_id)
        location = business.location or "Local Market"
        ai_res = await self.ai_service.discover_keywords(
            organization_id=business.organization_id,
            user_id=user_id,
            business_name=business.name,
            category=business.category or "Local Business",
            location=location,
            target_services=target_services,
        )
        return [k.model_dump() for k in ai_res.keywords]

    async def optimize_gbp(
        self,
        business_id: str,
        user_id: Optional[str] = None,
    ) -> dict:
        business = await self._get_business_or_404(business_id)
        location = business.location or "Local Market"
        ai_res = await self.ai_service.optimize_gbp_profile(
            organization_id=business.organization_id,
            user_id=user_id,
            business_name=business.name,
            category=business.category or "Local Business",
            location=location,
            current_description=business.description,
        )
        return ai_res.model_dump()
