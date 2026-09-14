# ==================================================
# OptigoAI Backend — Leads Public Endpoints
# ==================================================
"""
Public REST API endpoints for single-page onboarding:
- Google Places business search & autocomplete
- Lead creation & stage tracking
- Real AI audit report generation & retrieval
- Plan selection, Razorpay order, & payment conversion
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query
from fastapi.responses import RedirectResponse
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Dict, Any, List, Optional

from app.api.v1.deps import get_db
from app.services.lead_service import LeadService
from app.schemas.lead import (
    LeadCreate,
    LeadResponse,
    LeadPlacesSearchResult,
    LeadSelectPlanRequest,
    LeadCreateOrderRequest,
    LeadVerifyPaymentRequest,
)

router = APIRouter()


@router.get("/places/search", response_model=List[LeadPlacesSearchResult], summary="Search Google Places")
async def search_places(
    query: str = Query(..., min_length=2, description="Business name or search keywords"),
    location: Optional[str] = Query(None, description="Optional city or area name"),
    db: AsyncSession = Depends(get_db),
):
    """
    Search-as-you-type Google Places autocomplete.
    Uses Google Places API (New) when configured, with fallback to Serper Places and local database.
    """
    service = LeadService(db)
    return await service.search_places(query=query, location=location)


@router.get("/places/photo", summary="Proxy Google Places Photo")
async def get_place_photo(
    photo_name: str = Query(..., description="Google Places photo resource name, e.g. places/.../photos/..."),
):
    """
    Secure backend proxy for Google Places API (New) photo media.
    Prevents leaking Google Cloud API Key to client browsers.
    """
    from app.providers.places.google_places import GooglePlacesNewProvider

    provider = GooglePlacesNewProvider()
    if not provider.is_configured():
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="Google Places API not configured")

    media_url = provider.get_photo_media_url(photo_name)
    if not media_url:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Invalid photo name")

    return RedirectResponse(url=media_url, status_code=status.HTTP_307_TEMPORARY_REDIRECT)


@router.post("", response_model=LeadResponse, status_code=status.HTTP_201_CREATED, summary="Create or Update Lead")
async def create_lead(
    data: LeadCreate,
    db: AsyncSession = Depends(get_db),
):
    """
    Create a new lead from the single-page onboarding form.
    Captures selected Google business, phone number, and initializes audit pipeline.
    """
    service = LeadService(db)
    lead = await service.create_or_update_lead(data)
    return LeadResponse.model_validate(lead)


@router.post("/{lead_id}/analyze", summary="Generate AI Business Audit")
async def analyze_lead(
    lead_id: str,
    db: AsyncSession = Depends(get_db),
):
    """
    Trigger async business audit analysis for the lead.
    Discovers local competitors, calculates audit scores, and builds Optigo AI recommendations.
    """
    service = LeadService(db)
    try:
        report = await service.generate_lead_report(lead_id)
        return report
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Audit generation failed: {str(e)}")


@router.get("/{lead_id}", response_model=LeadResponse, summary="Get Lead & Report Details")
async def get_lead(
    lead_id: str,
    db: AsyncSession = Depends(get_db),
):
    """Fetch lead details, current status, and generated report data."""
    service = LeadService(db)
    lead = await service.repo.get_by_id(lead_id)
    if not lead:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lead not found")
    return LeadResponse.model_validate(lead)


@router.post("/{lead_id}/viewed", summary="Record Report Viewed")
async def record_report_viewed(
    lead_id: str,
    db: AsyncSession = Depends(get_db),
):
    """Track that the lead opened and viewed the audit report page."""
    service = LeadService(db)
    try:
        lead = await service.record_stage(lead_id, "report_viewed")
        return {"status": "ok", "stage": lead.status}
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))


@router.post("/{lead_id}/select-plan", summary="Select Subscription Plan")
async def select_plan(
    lead_id: str,
    data: LeadSelectPlanRequest,
    db: AsyncSession = Depends(get_db),
):
    """Track that the lead selected a plan tier and duration."""
    service = LeadService(db)
    try:
        lead = await service.record_stage(
            lead_id,
            "plan_selected",
            metadata={"plan_id": data.plan_id, "duration": data.duration},
        )
        return {"status": "ok", "stage": lead.status, "plan_id": data.plan_id}
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))


@router.post("/{lead_id}/create-order", summary="Create Payment Order")
async def create_payment_order(
    lead_id: str,
    data: LeadCreateOrderRequest,
    db: AsyncSession = Depends(get_db),
):
    """Create Razorpay order for plan checkout."""
    service = LeadService(db)
    try:
        order = await service.create_payment_order(lead_id, plan_id=data.plan_id, duration=data.duration)
        return order
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))


@router.post("/{lead_id}/verify-payment", summary="Verify Payment & Convert Lead")
async def verify_payment(
    lead_id: str,
    data: LeadVerifyPaymentRequest,
    db: AsyncSession = Depends(get_db),
):
    """
    Verify payment signature and convert lead into an active Optigo AI customer.
    Creates account and returns authentication access token.
    """
    service = LeadService(db)
    try:
        result = await service.verify_payment_and_convert(lead_id, data)
        return result
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Conversion failed: {str(e)}")
