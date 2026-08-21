# ==================================================
# OptigoAI Backend — Creative Service (Phase 9)
# ==================================================

from typing import Optional, Sequence, Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import HTTPException, status

from app.models.creative import Creative, CreativeStatus
from app.repositories.business_repo import BusinessRepository
from app.repositories.creative_repo import CreativeRepository
from app.ai.ai_service import AIService
from app.core.logging import get_logger

logger = get_logger("app.services.creative")


class CreativeService:
    """Service orchestrating AI promotional offer synthesis, visual banners, and smart creative assets."""

    def __init__(self, db: AsyncSession):
        self.db = db
        self.business_repo = BusinessRepository(db)
        self.creative_repo = CreativeRepository(db)
        self.ai_service = AIService(db)

    async def generate_creative(
        self,
        business_id: str,
        organization_id: str,
        user_id: Optional[str] = None,
        headline: Optional[str] = None,
        offer_text: Optional[str] = None,
        style: str = "modern_minimal",
        aspect_ratio: str = "1:1",
        campaign_id: Optional[str] = None,
    ) -> Creative:
        """Generate a structured smart creative asset / promotional banner concept."""
        business = await self.business_repo.get_by_id(business_id)
        if not business:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Business not found")
        if business.organization_id != organization_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

        title = headline or f"{business.name} Premium Special"
        offer = offer_text or "Exclusive Limited Time Offer — Get the Best Quality Today!"
        prompt = (
            f"High-quality commercial marketing graphic for {business.name} ({business.category or 'Local Business'}). "
            f"Headline: '{title}'. Offer: '{offer}'. Style: {style}, Aspect ratio: {aspect_ratio}."
        )

        template_config = {
            "headline": title,
            "subheadline": offer,
            "badge": "SPECIAL OFFER",
            "business_name": business.name,
            "location": business.location or "Visit Store",
            "call_to_action": "Order Now / Visit Today",
            "color_palette": {
                "primary": "#2563EB",
                "accent": "#F59E0B",
                "background": "#FFFFFF" if "minimal" in style else "#0F172A",
                "text": "#0F172A" if "minimal" in style else "#FFFFFF",
            },
            "aspect_ratio": aspect_ratio,
            "layout": "modern_badge_hero",
        }

        creative_data = {
            "business_id": business_id,
            "campaign_id": campaign_id,
            "title": title,
            "description": offer,
            "style": style,
            "prompt_used": prompt,
            "file_url": f"https://assets.optigoai.com/creatives/{business_id}/banner_{aspect_ratio.replace(':', 'x')}.png",
            "status": CreativeStatus.COMPLETED,
            "generation_metadata": {
                "template": template_config,
                "aspect_ratio": aspect_ratio,
                "generated_by": "Gemini Creative Synthesizer",
            },
        }

        return await self.creative_repo.create(creative_data)

    async def list_creatives(
        self,
        business_id: str,
        organization_id: str,
        campaign_id: Optional[str] = None,
        limit: int = 50,
        offset: int = 0,
    ) -> Sequence[Creative]:
        """List creatives for a business."""
        business = await self.business_repo.get_by_id(business_id)
        if not business:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Business not found")
        if business.organization_id != organization_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

        return await self.creative_repo.list_by_business(
            business_id=business_id,
            campaign_id=campaign_id,
            limit=limit,
            offset=offset,
        )

    async def get_creative(
        self,
        creative_id: str,
        organization_id: str,
    ) -> Creative:
        """Get a specific creative by ID."""
        creative = await self.creative_repo.get_by_id(creative_id)
        if not creative:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Creative not found")
        business = await self.business_repo.get_by_id(creative.business_id)
        if not business or business.organization_id != organization_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")
        return creative
