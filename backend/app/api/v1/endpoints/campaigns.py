# ==================================================
# OptigoAI Backend — Campaigns API Endpoints (Phase 8)
# ==================================================

from typing import Optional, List
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.v1.deps import get_db, get_current_user
from app.models.user import User
from app.models.campaign import CampaignStatus
from app.schemas.campaign import (
    CampaignGenerateRequest,
    CampaignCreate,
    CampaignUpdate,
    CampaignResponse,
)
from app.services.campaign_service import CampaignService

router = APIRouter(prefix="/campaigns", tags=["Campaigns"])


@router.post("/generate", response_model=dict, status_code=status.HTTP_200_OK)
async def generate_campaign(
    request: CampaignGenerateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Generate a multi-channel campaign plan with Gemini AI."""
    service = CampaignService(db)
    return await service.generate_campaign(
        business_id=request.business_id,
        organization_id=current_user.organization_id,
        user_id=current_user.id,
        goal=request.goal,
        channels=request.channels,
        duration_days=request.duration_days,
        custom_offer=request.custom_offer,
        target_audience=request.target_audience,
    )


@router.post("", response_model=CampaignResponse, status_code=status.HTTP_201_CREATED)
async def create_campaign(
    campaign_in: CampaignCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Create a new campaign record."""
    service = CampaignService(db)
    campaign = await service.create_campaign(
        business_id=campaign_in.business_id,
        organization_id=current_user.organization_id,
        campaign_data=campaign_in.model_dump(),
    )
    return campaign


@router.get("", response_model=List[CampaignResponse])
async def list_campaigns(
    business_id: str = Query(..., description="Business ID"),
    status: Optional[CampaignStatus] = Query(None, description="Filter by status"),
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """List campaigns for a business."""
    service = CampaignService(db)
    return await service.list_campaigns(
        business_id=business_id,
        organization_id=current_user.organization_id,
        status_filter=status,
        limit=limit,
        offset=offset,
    )


@router.get("/{campaign_id}", response_model=CampaignResponse)
async def get_campaign(
    campaign_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Get a specific campaign by ID."""
    service = CampaignService(db)
    return await service.get_campaign(
        campaign_id=campaign_id,
        organization_id=current_user.organization_id,
    )


@router.patch("/{campaign_id}", response_model=CampaignResponse)
async def update_campaign(
    campaign_id: str,
    campaign_in: CampaignUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Update a campaign."""
    service = CampaignService(db)
    return await service.update_campaign(
        campaign_id=campaign_id,
        organization_id=current_user.organization_id,
        update_data=campaign_in.model_dump(exclude_unset=True),
    )


@router.post("/{campaign_id}/launch", response_model=CampaignResponse)
async def launch_campaign(
    campaign_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Launch and activate a marketing campaign."""
    service = CampaignService(db)
    return await service.launch_campaign(
        campaign_id=campaign_id,
        organization_id=current_user.organization_id,
    )
