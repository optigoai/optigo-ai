# ==================================================
# OptigoAI Backend — ROI Analytics API Endpoints (Phase 11)
# ==================================================

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.v1.deps import get_db, get_current_user
from app.models.user import User
from app.schemas.analytics import (
    RoiDashboardResponse,
    CompetitorBenchmarkResponse,
)
from app.services.roi_service import RoiAnalyticsService

router = APIRouter(prefix="/analytics", tags=["ROI Analytics"])


@router.get("/roi", response_model=RoiDashboardResponse, status_code=status.HTTP_200_OK)
async def get_roi_analytics(
    business_id: str = Query(..., description="Business ID"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Get estimated ROI, marketing revenue impact, and customer lead attribution."""
    service = RoiAnalyticsService(db)
    return await service.get_roi_dashboard(
        business_id=business_id,
        organization_id=current_user.organization_id,
    )


@router.get("/competitors", response_model=CompetitorBenchmarkResponse, status_code=status.HTTP_200_OK)
async def get_competitor_benchmarks(
    business_id: str = Query(..., description="Business ID"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Get local competitor benchmarking and visibility comparisons."""
    service = RoiAnalyticsService(db)
    return await service.get_competitor_benchmarks(
        business_id=business_id,
        organization_id=current_user.organization_id,
    )
