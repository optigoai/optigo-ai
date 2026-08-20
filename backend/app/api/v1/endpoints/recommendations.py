# ==================================================
# OptigoAI Backend — Recommendations Router
# ==================================================

from typing import Optional, List
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.v1.deps import get_db, get_current_user, get_org_id
from app.models.user import User
from app.schemas import (
    RecommendationResponse,
    RecommendationStatusUpdateRequest,
    CMOGenerateRecommendationsResponse,
)
from app.services.cmo_engine_service import CMOEngineService

router = APIRouter()


@router.post("/generate", response_model=CMOGenerateRecommendationsResponse)
async def generate_cmo_recommendations(
    business_id: str = Query(..., description="ID of the business to generate recommendations for"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Trigger the AI CMO Engine to analyze business health, reviews, and generate prioritized action cards."""
    org_id = get_org_id(current_user)
    service = CMOEngineService(db)
    result = await service.generate_recommendations(
        business_id=business_id,
        organization_id=org_id,
        user_id=current_user.id,
    )
    return CMOGenerateRecommendationsResponse(**result)


@router.get("", response_model=List[RecommendationResponse])
async def list_recommendations(
    business_id: str = Query(..., description="Business ID to retrieve recommendations for"),
    priority: Optional[str] = Query(None, description="Filter by priority: urgent, important, opportunity"),
    status: Optional[str] = Query(None, description="Filter by status: pending, in_progress, completed, dismissed"),
    include_dismissed: bool = Query(False, description="Include dismissed items in response"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Retrieve prioritized AI action recommendations for a business."""
    org_id = get_org_id(current_user)
    service = CMOEngineService(db)
    recs = await service.get_recommendations(
        business_id=business_id,
        organization_id=org_id,
        priority=priority,
        status=status,
        include_dismissed=include_dismissed,
    )
    return [RecommendationResponse.model_validate(r) for r in recs]


@router.patch("/{recommendation_id}/status", response_model=RecommendationResponse)
async def update_recommendation_status(
    recommendation_id: str,
    payload: RecommendationStatusUpdateRequest,
    business_id: str = Query(..., description="Business ID that owns this recommendation"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Update recommendation execution status (e.g. completed, dismissed)."""
    org_id = get_org_id(current_user)
    service = CMOEngineService(db)
    updated = await service.update_recommendation_status(
        rec_id=recommendation_id,
        business_id=business_id,
        organization_id=org_id,
        new_status=payload.status,
    )
    return RecommendationResponse.model_validate(updated)
