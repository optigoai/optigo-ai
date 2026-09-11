# ==================================================
# OptigoAI Backend — Admin Endpoints
# ==================================================

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Dict, Any, List, Optional
from pydantic import BaseModel, Field

from app.api.v1.deps import get_db, require_admin
from app.models.user import User
from app.services.admin_service import AdminService

router = APIRouter()


class ToggleFeatureRequest(BaseModel):
    is_enabled: bool
    description: Optional[str] = None


class ToggleOrgStatusRequest(BaseModel):
    is_active: bool


@router.get("/stats", summary="Platform Statistics")
async def get_stats(
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(require_admin),
) -> Dict[str, Any]:
    """Get high-level platform stats for admin dashboard."""
    service = AdminService(db)
    return await service.get_system_stats()


@router.get("/organizations", summary="List Organizations")
async def list_organizations(
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(require_admin),
) -> List[Dict[str, Any]]:
    """List all registered organizations with business and user metrics."""
    service = AdminService(db)
    return await service.get_organizations(limit=limit, offset=offset)


@router.patch("/organizations/{org_id}/status", summary="Toggle Organization Status")
async def toggle_organization_status(
    org_id: str,
    body: ToggleOrgStatusRequest,
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(require_admin),
) -> Dict[str, Any]:
    """Suspend or reinstate an organization."""
    service = AdminService(db)
    try:
        res = await service.toggle_organization_status(org_id, is_active=body.is_active)
        await db.commit()
        return res
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))


@router.put("/organizations/{org_id}", summary="Update Organization Details")
async def update_organization_details(
    org_id: str,
    body: Dict[str, Any],
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(require_admin),
) -> Dict[str, Any]:
    """Super Admin edit of organization name, slug, or active status."""
    service = AdminService(db)
    try:
        res = await service.update_organization(org_id, body)
        await db.commit()
        return res
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))


@router.get("/businesses", summary="List All Businesses")
async def list_businesses(
    limit: int = Query(100, ge=1, le=500),
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(require_admin),
) -> List[Dict[str, Any]]:
    """List all registered businesses across all tenants."""
    service = AdminService(db)
    return await service.get_all_businesses(limit=limit)


@router.get("/businesses/{business_id}", summary="Get Complete Business Detail")
async def get_business_detail(
    business_id: str,
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(require_admin),
) -> Dict[str, Any]:
    """Get 360-degree deep-dive detail of a business including owner, onboarding data, and marketing stats."""
    service = AdminService(db)
    try:
        return await service.get_business_detail(business_id)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))


@router.put("/businesses/{business_id}", summary="Update Business Details")
async def update_business_detail(
    business_id: str,
    body: Dict[str, Any],
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(require_admin),
) -> Dict[str, Any]:
    """Super Admin full edit of business info, onboarding responses, and settings."""
    service = AdminService(db)
    try:
        res = await service.update_business_full(business_id, body)
        await db.commit()
        return res
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))


@router.patch("/users/{user_id}", summary="Update User Details")
async def update_user_detail(
    user_id: str,
    body: Dict[str, Any],
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(require_admin),
) -> Dict[str, Any]:
    """Super Admin edit of user full name, email, role, or active status."""
    service = AdminService(db)
    try:
        res = await service.update_user(user_id, body)
        await db.commit()
        return res
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))


@router.get("/features", summary="List Feature Toggles")
async def list_feature_toggles(
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(require_admin),
) -> List[Dict[str, Any]]:
    """List all platform feature toggles."""
    service = AdminService(db)
    return await service.get_feature_toggles()


@router.put("/features/{feature_name}", summary="Update Feature Toggle")
async def update_feature_toggle(
    feature_name: str,
    body: ToggleFeatureRequest,
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(require_admin),
) -> Dict[str, Any]:
    """Enable or disable a feature flag globally."""
    service = AdminService(db)
    res = await service.update_feature_toggle(
        feature_name=feature_name,
        is_enabled=body.is_enabled,
        description=body.description,
    )
    await db.commit()
    return res


@router.get("/usage", summary="AI Usage & Token Metrics")
async def get_usage_metrics(
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(require_admin),
) -> Dict[str, Any]:
    """Get breakdown of AI token usage, providers, latency, and costs."""
    service = AdminService(db)
    return await service.get_ai_usage_stats()


@router.get("/system-health", summary="Live System Health")
async def get_system_health(
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(require_admin),
) -> Dict[str, Any]:
    """Check database, Redis, Celery, and AI provider status."""
    service = AdminService(db)
    return await service.get_system_health()


# ==================================================
# Leads & Onboarding Management Endpoints
# ==================================================

class UpdateLeadRequest(BaseModel):
    status: Optional[str] = None
    priority: Optional[str] = None
    notes: Optional[str] = None


class AddLeadNoteRequest(BaseModel):
    note: str


@router.get("/leads/stats", summary="Lead Funnel Statistics")
async def get_leads_stats(
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(require_admin),
) -> Dict[str, Any]:
    """Get high-level onboarding funnel and conversion stats."""
    service = AdminService(db)
    return await service.get_leads_stats()


@router.get("/leads", summary="List Onboarding Leads")
async def list_leads(
    status: Optional[str] = Query(None),
    priority: Optional[str] = Query(None),
    search: Optional[str] = Query(None),
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(require_admin),
) -> Dict[str, Any]:
    """List onboarding leads with filters and pagination."""
    service = AdminService(db)
    return await service.list_leads(
        status=status, priority=priority, search=search, limit=limit, offset=offset
    )


@router.get("/leads/{lead_id}", summary="Get Lead Details")
async def get_lead_details(
    lead_id: str,
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(require_admin),
) -> Dict[str, Any]:
    """Get complete lead detail including audit report, metrics, and timeline."""
    service = AdminService(db)
    try:
        return await service.get_lead_detail(lead_id)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))


@router.patch("/leads/{lead_id}", summary="Update Lead Status or Priority")
async def update_lead(
    lead_id: str,
    body: UpdateLeadRequest,
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(require_admin),
) -> Dict[str, Any]:
    """Update lead status, priority level, or notes with timeline audit."""
    service = AdminService(db)
    try:
        res = await service.update_lead_status(
            lead_id=lead_id,
            status=body.status,
            priority=body.priority,
            notes=body.notes,
            admin_email=admin_user.email,
        )
        await db.commit()
        return res
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))


@router.post("/leads/{lead_id}/notes", summary="Add Admin Note to Lead")
async def add_lead_note(
    lead_id: str,
    body: AddLeadNoteRequest,
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(require_admin),
) -> Dict[str, Any]:
    """Add a timestamped admin note to lead history."""
    service = AdminService(db)
    try:
        res = await service.add_lead_note(
            lead_id=lead_id,
            note_text=body.note,
            admin_email=admin_user.email,
        )
        await db.commit()
        return res
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))

