# ==================================================
# OptigoAI Backend — Campaign Schemas (Phase 8)
# ==================================================

from datetime import datetime
from typing import Optional, Any
from pydantic import BaseModel, ConfigDict
from app.models.campaign import CampaignStatus


class CampaignGenerateRequest(BaseModel):
    business_id: str
    goal: str = "increase_sales"  # foot_traffic, online_orders, brand_awareness, seasonal_promo
    channels: list[str] = ["gbp", "instagram", "facebook"]
    duration_days: int = 7
    custom_offer: Optional[str] = None
    target_audience: Optional[str] = None


class CampaignCreate(BaseModel):
    business_id: str
    name: str
    objective: str
    audience: str
    offer: Optional[str] = None
    messaging: str
    cta: str
    content_ideas: Optional[dict[str, Any]] = None
    schedule: Optional[dict[str, Any]] = None
    status: CampaignStatus = CampaignStatus.DRAFT


class CampaignUpdate(BaseModel):
    name: Optional[str] = None
    objective: Optional[str] = None
    audience: Optional[str] = None
    offer: Optional[str] = None
    messaging: Optional[str] = None
    cta: Optional[str] = None
    status: Optional[CampaignStatus] = None
    schedule: Optional[dict[str, Any]] = None


class CampaignResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    business_id: str
    name: str
    objective: str
    audience: str
    offer: Optional[str] = None
    messaging: str
    cta: str
    content_ideas: Optional[dict[str, Any]] = None
    schedule: Optional[dict[str, Any]] = None
    status: CampaignStatus
    generation_metadata: Optional[dict[str, Any]] = None
    created_at: datetime
    updated_at: datetime
