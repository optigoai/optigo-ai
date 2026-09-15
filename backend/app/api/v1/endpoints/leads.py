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
    LeadStatusUpdateRequest,
    LeadAddNoteRequest,
    LeadStatsResponse,
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


@router.get("", summary="List Leads (CRM)")
async def list_leads(
    status: Optional[str] = Query(None),
    priority: Optional[str] = Query(None),
    plan: Optional[str] = Query(None),
    search: Optional[str] = Query(None),
    start_date: Optional[str] = Query(None),
    end_date: Optional[str] = Query(None),
    sort_by: str = Query("last_activity_at"),
    sort_order: str = Query("desc"),
    limit: int = Query(50, ge=1, le=500),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
):
    """
    List all captured leads for the CRM portal with live filtering,
    date ranges, search terms, and dynamic sorting.
    """
    from datetime import datetime
    dt_start = None
    dt_end = None
    if start_date:
        try:
            dt_start = datetime.fromisoformat(start_date.replace("Z", "+00:00"))
        except Exception:
            pass
    if end_date:
        try:
            dt_end = datetime.fromisoformat(end_date.replace("Z", "+00:00"))
        except Exception:
            pass

    service = LeadService(db)
    result = await service.list_leads_crm(
        status=status,
        priority=priority,
        plan=plan,
        search=search,
        start_date=dt_start,
        end_date=dt_end,
        sort_by=sort_by,
        sort_order=sort_order,
        limit=limit,
        offset=offset,
    )
    return {
        "leads": [LeadResponse.model_validate(l) for l in result["leads"]],
        "total": result["total"],
        "limit": result["limit"],
        "offset": result["offset"],
    }


@router.get("/stats/crm", response_model=LeadStatsResponse, summary="Get Lead CRM Funnel Stats")
async def get_crm_stats(
    db: AsyncSession = Depends(get_db),
):
    """Get aggregated CRM pipeline metrics, funnel counts, and estimated revenue loss."""
    service = LeadService(db)
    stats = await service.get_crm_stats()
    return LeadStatsResponse(**stats)


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


@router.patch("/{lead_id}", response_model=LeadResponse, summary="Update Lead Stage / CRM Fields")
async def update_lead(
    lead_id: str,
    data: LeadStatusUpdateRequest,
    db: AsyncSession = Depends(get_db),
):
    """Update lead status, priority, plan, or notes."""
    service = LeadService(db)
    try:
        lead = await service.update_lead_crm(lead_id, data)
        return LeadResponse.model_validate(lead)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))


@router.post("/{lead_id}/notes", response_model=LeadResponse, summary="Add CRM Sales Note")
async def add_lead_note(
    lead_id: str,
    data: LeadAddNoteRequest,
    db: AsyncSession = Depends(get_db),
):
    """Add time-stamped note to lead and record in timeline."""
    service = LeadService(db)
    try:
        lead = await service.add_note_crm(lead_id, note_text=data.note, author=data.author or "Sales Rep")
        return LeadResponse.model_validate(lead)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))


@router.delete("", summary="Delete All Leads")
async def delete_all_leads(
    db: AsyncSession = Depends(get_db),
):
    """Delete all leads from database for a clean slate."""
    service = LeadService(db)
    deleted_count = await service.delete_all_leads()
    return {"status": "ok", "deleted_count": deleted_count}


@router.delete("/{lead_id}", summary="Delete Lead")
async def delete_lead(
    lead_id: str,
    db: AsyncSession = Depends(get_db),
):
    """Delete a lead from database."""
    service = LeadService(db)
    success = await service.delete_lead(lead_id)
    if not success:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lead not found")
    return {"status": "ok", "deleted": True}


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
