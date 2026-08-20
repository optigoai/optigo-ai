from typing import List
from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.v1.deps import get_db, get_current_user, get_org_id
from app.models.user import User
from app.schemas import (
    BusinessCreateRequest,
    BusinessOnboardingRequest,
    BusinessResponse,
)
from app.services.business_service import BusinessService

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
