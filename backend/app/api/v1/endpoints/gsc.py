# ==================================================
# OptigoAI Backend — Google Search Console Endpoints
# ==================================================

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.v1.deps import get_db, get_current_user
from app.models.user import User
from app.services.gsc_service import GoogleSearchConsoleService
from app.schemas.gsc import (
    GscAuthUrlResponse,
    GscOAuthCallbackRequest,
    GscStatusResponse,
    GscMetricsSummaryResponse,
)

router = APIRouter(prefix="/integrations/google/search-console", tags=["Google Search Console"])


@router.get("/auth-url", response_model=GscAuthUrlResponse)
async def get_gsc_auth_url(
    business_id: str = Query(..., description="Business ID"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Generate secure Google OAuth 2.0 authorization URL for Search Console readonly scope."""
    service = GoogleSearchConsoleService(db)
    res = service.get_oauth_url(business_id=business_id, organization_id=current_user.organization_id)
    return res


@router.post("/callback", status_code=status.HTTP_200_OK)
async def handle_gsc_oauth_callback(
    data: GscOAuthCallbackRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Complete OAuth 2.0 flow, securely store tokens, and trigger initial data sync."""
    service = GoogleSearchConsoleService(db)
    return await service.handle_oauth_callback(
        code=data.code,
        business_id=data.business_id,
        organization_id=current_user.organization_id,
    )


@router.get("/status", response_model=GscStatusResponse)
async def get_gsc_connection_status(
    business_id: str = Query(..., description="Business ID"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Get connection status and data freshness info for Google Search Console."""
    service = GoogleSearchConsoleService(db)
    return await service.get_connection_status(
        business_id=business_id,
        organization_id=current_user.organization_id,
    )


@router.post("/sync", status_code=status.HTTP_200_OK)
async def sync_gsc_metrics(
    business_id: str = Query(..., description="Business ID"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Trigger on-demand Search Console performance metrics synchronization."""
    service = GoogleSearchConsoleService(db)
    return await service.sync_metrics(
        business_id=business_id,
        organization_id=current_user.organization_id,
    )


@router.get("/metrics", response_model=GscMetricsSummaryResponse)
async def get_gsc_metrics_summary(
    business_id: str = Query(..., description="Business ID"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Get aggregated Search Console performance metrics (clicks, impressions, queries, position)."""
    service = GoogleSearchConsoleService(db)
    return await service.get_metrics_summary(
        business_id=business_id,
        organization_id=current_user.organization_id,
    )


@router.delete("", status_code=status.HTTP_204_NO_CONTENT)
async def disconnect_gsc(
    business_id: str = Query(..., description="Business ID"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Disconnect Google Search Console and remove stored credentials."""
    service = GoogleSearchConsoleService(db)
    await service.disconnect(
        business_id=business_id,
        organization_id=current_user.organization_id,
    )
