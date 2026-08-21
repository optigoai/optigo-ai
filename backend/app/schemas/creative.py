# ==================================================
# OptigoAI Backend — Creative Schemas (Phase 9)
# ==================================================

from datetime import datetime
from typing import Optional, Any
from pydantic import BaseModel, ConfigDict
from app.models.creative import CreativeStatus


class CreativeGenerateRequest(BaseModel):
    business_id: str
    headline: Optional[str] = None
    offer_text: Optional[str] = None
    style: str = "modern_minimal"  # modern_minimal, bold_vibrant, festive_promo, organic_craft
    aspect_ratio: str = "1:1"  # 1:1, 16:9, 9:16
    campaign_id: Optional[str] = None


class CreativeCreate(BaseModel):
    business_id: str
    title: str
    description: Optional[str] = None
    style: Optional[str] = None
    prompt_used: Optional[str] = None
    file_url: Optional[str] = None
    file_path: Optional[str] = None
    file_size: Optional[int] = None
    mime_type: Optional[str] = "image/png"
    status: CreativeStatus = CreativeStatus.COMPLETED
    generation_metadata: Optional[dict[str, Any]] = None
    campaign_id: Optional[str] = None


class CreativeResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    business_id: str
    title: str
    description: Optional[str] = None
    style: Optional[str] = None
    prompt_used: Optional[str] = None
    file_url: Optional[str] = None
    status: CreativeStatus
    generation_metadata: Optional[dict[str, Any]] = None
    campaign_id: Optional[str] = None
    created_at: datetime
    updated_at: datetime
