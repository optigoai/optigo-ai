from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.v1.deps import get_db, get_current_user
from app.models.user import User
from app.services.seo_service import SEOService
from app.schemas.seo import (
    SEOKeywordCreate,
    SEOKeywordResponse,
    SEOAuditResponse,
    SEODiscoverKeywordsRequest,
    SEOBatchKeywordsRequest,
    SEOGbpOptimizationResponse,
)

router = APIRouter(prefix="/seo", tags=["SEO & Visibility Optimizer"])


@router.get("/keywords", response_model=List[SEOKeywordResponse])
async def list_tracked_keywords(
    business_id: str = Query(..., description="Business ID"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """List all tracked local SEO keywords and their current rankings for a business."""
    service = SEOService(db)
    return await service.list_keywords(business_id)


@router.post("/keywords", response_model=SEOKeywordResponse, status_code=status.HTTP_201_CREATED)
async def add_tracked_keyword(
    data: SEOKeywordCreate,
    business_id: str = Query(..., description="Business ID"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Add a new keyword to track."""
    service = SEOService(db)
    return await service.add_keyword(business_id, data)


@router.delete("/keywords/{keyword_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_tracked_keyword(
    keyword_id: str,
    business_id: str = Query(..., description="Business ID"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Stop tracking and remove a keyword."""
    service = SEOService(db)
    await service.delete_keyword(business_id, keyword_id)


@router.post("/audit", response_model=SEOAuditResponse)
async def run_seo_audit(
    business_id: str = Query(..., description="Business ID"),
    force_fresh: bool = Query(False, description="Force re-generation with Gemini"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Run an AI-powered Local SEO and Google Maps Pack visibility audit."""
    service = SEOService(db)
    return await service.get_or_generate_audit(
        business_id=business_id,
        user_id=current_user.id,
        force_fresh=force_fresh,
    )


@router.post("/discover-keywords", response_model=List[dict])
async def discover_keywords(
    data: SEODiscoverKeywordsRequest,
    business_id: str = Query(..., description="Business ID"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Discover high-intent local SEO keywords using Gemini AI."""
    service = SEOService(db)
    return await service.discover_keywords(
        business_id=business_id,
        user_id=current_user.id,
        target_services=data.target_services,
    )


@router.post("/optimize-profile", response_model=SEOGbpOptimizationResponse)
async def optimize_gbp_profile(
    business_id: str = Query(..., description="Business ID"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Generate AI-optimized GBP profile description, categories, and attributes."""
    service = SEOService(db)
    return await service.optimize_gbp(
        business_id=business_id,
        user_id=current_user.id,
    )


@router.post("/website/audit")
async def run_website_audit(
    business_id: str = Query(..., description="Business ID"),
    url: Optional[str] = Query(None, description="Custom URL to audit, defaults to business website"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Run an automated website crawl, technical SEO audit, and generate AI recommendations."""
    from app.services.website_audit_service import WebsiteAuditService
    service = WebsiteAuditService(db)
    return await service.run_audit(
        business_id=business_id,
        organization_id=current_user.organization_id,
        user_id=current_user.id,
        custom_url=url,
    )


@router.get("/website/audit/latest")
async def get_latest_website_audit(
    business_id: str = Query(..., description="Business ID"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Get the latest website audit findings and actionable fixes."""
    from app.services.website_audit_service import WebsiteAuditService
    service = WebsiteAuditService(db)
    return await service.get_latest_audit(
        business_id=business_id,
        organization_id=current_user.organization_id,
    )


@router.get("/history", response_model=List[dict])
async def get_visibility_history(
    business_id: str = Query(..., description="Business ID"),
    days: int = Query(7, ge=1, le=90, description="Timeframe days (7, 14, 30)"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Get database-backed historical visibility trend points for interactive chart."""
    service = SEOService(db)
    return await service.get_visibility_history(business_id=business_id, days=days)


@router.post("/keywords/batch", response_model=List[SEOKeywordResponse])
async def add_keywords_batch(
    data: SEOBatchKeywordsRequest,
    business_id: str = Query(..., description="Business ID"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Batch-add multiple keywords with 1 tap (e.g. from AI Discovery)."""
    service = SEOService(db)
    return await service.add_keywords_batch(business_id=business_id, keywords=data.keywords)


@router.post("/website/generate-schema", response_model=dict)
async def generate_json_ld_schema(
    business_id: str = Query(..., description="Business ID"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Generate Google-compliant JSON-LD LocalBusiness Schema markup for webmasters."""
    service = SEOService(db)
    return await service.generate_json_ld_schema(business_id=business_id)


