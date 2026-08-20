from typing import List
from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.v1.deps import get_db, get_current_user, get_org_id
from app.models.user import User
from app.schemas import (
    BusinessCreateRequest,
    BusinessOnboardingRequest,
    BusinessResponse,
    GBPSyncResponse,
    BusinessIntelligenceResponse,
)
from app.services.business_service import BusinessService
from app.services.business_intelligence_service import BusinessIntelligenceService

router = APIRouter()


@router.get("", response_model=List[BusinessResponse])
async def list_businesses(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """List all businesses for the current user's organization."""
    org_id = get_org_id(current_user)
    service = BusinessService(db)
    businesses = await service.list_businesses(org_id)
    return [BusinessResponse.model_validate(b) for b in businesses]


@router.post("", response_model=BusinessResponse, status_code=status.HTTP_201_CREATED)
async def create_business(
    req: BusinessCreateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Create a new business within the current user's organization."""
    org_id = get_org_id(current_user)
    service = BusinessService(db)
    business = await service.create_business(
        organization_id=org_id,
        name=req.name,
        category=req.category,
        location=req.location,
        website=req.website,
        phone=req.phone,
        description=req.description,
    )
    return BusinessResponse.model_validate(business)


@router.get("/{business_id}", response_model=BusinessResponse)
async def get_business(
    business_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Get a business by ID. Enforces organization-level tenant isolation."""
    org_id = get_org_id(current_user)
    service = BusinessService(db)
    business = await service.get_business(business_id, org_id)
    return BusinessResponse.model_validate(business)


@router.post("/{business_id}/onboarding", response_model=BusinessResponse)
async def submit_business_onboarding(
    business_id: str,
    req: BusinessOnboardingRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Submit onboarding answers for a business."""
    org_id = get_org_id(current_user)
    service = BusinessService(db)
    business = await service.submit_onboarding(
        business_id=business_id,
        organization_id=org_id,
        target_customers=req.target_customers,
        services=req.services,
        business_goals=req.business_goals,
        marketing_channels=req.marketing_channels,
    )
    return BusinessResponse.model_validate(business)


@router.post("/{business_id}/sync-gbp", response_model=GBPSyncResponse)
async def sync_business_gbp(
    business_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Synchronize Google Business Profile data (reviews, metrics, profile) using Provider layer."""
    from app.services.gbp_sync_service import GBPSyncService
    org_id = get_org_id(current_user)
    sync_service = GBPSyncService(db)
    result = await sync_service.sync_business_data(business_id, org_id)
    return GBPSyncResponse(**result)


@router.post("/{business_id}/analyze", response_model=BusinessIntelligenceResponse)
async def analyze_business(
    business_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Trigger AI Business Understanding & Marketing Health Score analysis."""
    org_id = get_org_id(current_user)
    service = BusinessIntelligenceService(db)
    result = await service.analyze_business(
        business_id=business_id,
        organization_id=org_id,
        user_id=current_user.id,
    )
    return BusinessIntelligenceResponse(**result)


@router.get("/{business_id}/intelligence", response_model=BusinessIntelligenceResponse)
async def get_business_intelligence(
    business_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Retrieve stored AI Business Profile & Marketing Health Analysis."""
    org_id = get_org_id(current_user)
    service = BusinessIntelligenceService(db)
    result = await service.get_intelligence(business_id, org_id)
    return BusinessIntelligenceResponse(**result)
