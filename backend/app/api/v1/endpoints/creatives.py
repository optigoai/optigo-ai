# ==================================================
# OptigoAI Backend — Creatives API Endpoints (Phase 9)
# ==================================================

from typing import Optional, List
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.v1.deps import get_db, get_current_user
from app.models.user import User
from app.schemas.creative import (
    CreativeGenerateRequest,
    CreativeCreate,
    CreativeResponse,
)
from app.services.creative_service import CreativeService

router = APIRouter(prefix="/creatives", tags=["Creatives"])


@router.post("/generate", response_model=CreativeResponse, status_code=status.HTTP_201_CREATED)
async def generate_creative(
    request: CreativeGenerateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Generate an AI-powered smart promotional creative asset."""
    service = CreativeService(db)
    return await service.generate_creative(
        business_id=request.business_id,
        organization_id=current_user.organization_id,
        user_id=current_user.id,
        headline=request.headline,
        offer_text=request.offer_text,
        style=request.style,
        aspect_ratio=request.aspect_ratio,
        campaign_id=request.campaign_id,
    )


@router.get("", response_model=List[CreativeResponse])
async def list_creatives(
    business_id: str = Query(..., description="Business ID"),
    campaign_id: Optional[str] = Query(None, description="Filter by campaign"),
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """List creatives for a business."""
    service = CreativeService(db)
    return await service.list_creatives(
        business_id=business_id,
        organization_id=current_user.organization_id,
        campaign_id=campaign_id,
        limit=limit,
        offset=offset,
    )


@router.get("/{creative_id}", response_model=CreativeResponse)
async def get_creative(
    creative_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Get a specific creative by ID."""
    service = CreativeService(db)
    return await service.get_creative(
        creative_id=creative_id,
        organization_id=current_user.organization_id,
    )
