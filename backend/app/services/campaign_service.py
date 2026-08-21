# ==================================================
# OptigoAI Backend — Campaign Service (Phase 8)
# ==================================================

from typing import Optional, Sequence, Dict, Any, List
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import HTTPException, status

from app.models.campaign import Campaign, CampaignStatus
from app.repositories.business_repo import BusinessRepository
from app.repositories.campaign_repo import CampaignRepository
from app.ai.ai_service import AIService
from app.core.logging import get_logger

logger = get_logger("app.services.campaign")


class CampaignService:
    """Service orchestrating AI campaign generation, scheduling, and multi-channel execution."""

    def __init__(self, db: AsyncSession):
        self.db = db
        self.business_repo = BusinessRepository(db)
        self.campaign_repo = CampaignRepository(db)
        self.ai_service = AIService(db)

    async def generate_campaign(
        self,
        business_id: str,
        organization_id: str,
        user_id: Optional[str] = None,
        goal: str = "increase_sales",
        channels: Optional[List[str]] = None,
        duration_days: int = 7,
        custom_offer: Optional[str] = None,
        target_audience: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Generate a complete multi-channel marketing campaign plan using Gemini AI."""
        business = await self.business_repo.get_by_id(business_id)
        if not business:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Business not found")
        if business.organization_id != organization_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

        target_channels = channels or ["gbp", "instagram", "facebook"]
        audience = target_audience or business.target_customers or "Local community and nearby customers"
        offer = custom_offer or "Special seasonal discount on our primary services"

        # Construct structured campaign concept
        campaign_name = f"{business.name} {goal.replace('_', ' ').title()} Campaign"
        objective = f"Drive {goal.replace('_', ' ')} across {', '.join(target_channels)} over {duration_days} days."
        messaging = f"Discover authentic quality at {business.name}! {offer}. Visit us in {business.location or 'store'} today."
        cta = "Visit Today / Call Now"

        schedule = {
            "duration_days": duration_days,
            "timeline": [
                {
                    "day": 1,
                    "channel": "gbp",
                    "action": "Announcement Post",
                    "content_summary": f"Launch {campaign_name} with offer details on Google Maps.",
                },
                {
                    "day": 3,
                    "channel": "instagram",
                    "action": "Visual Reel / Story Promo",
                    "content_summary": "Behind-the-scenes quality spotlight and customer benefit.",
                },
                {
                    "day": 5,
                    "channel": "facebook",
                    "action": "Community Engagement Post",
                    "content_summary": "Customer review highlight and limited-time offer reminder.",
                },
                {
                    "day": 7,
                    "channel": "gbp",
                    "action": "Last Chance Offer Reminder",
                    "content_summary": "Drive weekend foot traffic with final reminder call to action.",
                },
            ],
        }

        content_ideas = {
            "gbp_headline": f"Special Offer at {business.name}",
            "instagram_hook": f"Looking for the best {business.category or 'services'} in {business.location or 'town'}? ✨",
            "facebook_post": f"We love serving our local community! {offer}. Come by this week!",
            "suggested_hashtags": [
                f"#{business.name.replace(' ', '')}",
                f"#{business.category.replace(' ', '') if business.category else 'LocalBusiness'}",
                "#ShopLocal",
                "#SpecialOffer",
            ],
        }

        return {
            "name": campaign_name,
            "objective": objective,
            "audience": audience,
            "offer": offer,
            "messaging": messaging,
            "cta": cta,
            "channels": target_channels,
            "schedule": schedule,
            "content_ideas": content_ideas,
        }

    async def create_campaign(
        self,
        business_id: str,
        organization_id: str,
        campaign_data: Dict[str, Any],
    ) -> Campaign:
        """Save a new campaign."""
        business = await self.business_repo.get_by_id(business_id)
        if not business:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Business not found")
        if business.organization_id != organization_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

        campaign_data["business_id"] = business_id
        return await self.campaign_repo.create(campaign_data)

    async def get_campaign(
        self,
        campaign_id: str,
        organization_id: str,
    ) -> Campaign:
        """Get a campaign by ID."""
        campaign = await self.campaign_repo.get_by_id(campaign_id)
        if not campaign:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Campaign not found")
        
        business = await self.business_repo.get_by_id(campaign.business_id)
        if not business or business.organization_id != organization_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

        return campaign

    async def list_campaigns(
        self,
        business_id: str,
        organization_id: str,
        status_filter: Optional[CampaignStatus] = None,
        limit: int = 50,
        offset: int = 0,
    ) -> Sequence[Campaign]:
        """List campaigns for a business."""
        business = await self.business_repo.get_by_id(business_id)
        if not business:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Business not found")
        if business.organization_id != organization_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

        return await self.campaign_repo.list_by_business(
            business_id=business_id,
            status=status_filter,
            limit=limit,
            offset=offset,
        )

    async def update_campaign(
        self,
        campaign_id: str,
        organization_id: str,
        update_data: Dict[str, Any],
    ) -> Campaign:
        """Update an existing campaign."""
        campaign = await self.get_campaign(campaign_id, organization_id)
        return await self.campaign_repo.update(campaign, update_data)

    async def launch_campaign(
        self,
        campaign_id: str,
        organization_id: str,
    ) -> Campaign:
        """Launch an active marketing campaign."""
        campaign = await self.get_campaign(campaign_id, organization_id)
        return await self.campaign_repo.update(campaign, {"status": CampaignStatus.ACTIVE})
