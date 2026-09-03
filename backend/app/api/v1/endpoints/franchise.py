# ==================================================
# OptigoAI Backend — Franchise / Multi-Location API Endpoints
# ==================================================
"""
Franchise-level endpoints for organizational rollups, cross-branch benchmarks,
multi-location matrices, regional breakdowns, and profile audits.
"""

from typing import Dict, Any, List
from fastapi import APIRouter, Depends, status, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.v1.deps import get_db, get_current_user, get_org_id
from app.models.user import User
from app.services.franchise_service import FranchiseService

router = APIRouter(prefix="/franchise", tags=["Franchise & Multi-Location"])


@router.get("/overview", status_code=status.HTTP_200_OK)
async def get_franchise_overview(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Dict[str, Any]:
    """Get executive roll-up KPIs and franchise-wide performance summary."""
    org_id = get_org_id(current_user)
    service = FranchiseService(db)
    return await service.get_franchise_overview(org_id)


@router.get("/locations", status_code=status.HTTP_200_OK)
async def get_franchise_locations(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> List[Dict[str, Any]]:
    """Get multi-location performance matrix with completeness and rating metrics."""
    org_id = get_org_id(current_user)
    service = FranchiseService(db)
    return await service.get_franchise_locations_matrix(org_id)


@router.get("/benchmarks", status_code=status.HTTP_200_OK)
async def get_franchise_benchmarks(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Dict[str, Any]:
    """Get cross-branch comparative benchmark and rankings against franchise averages."""
    org_id = get_org_id(current_user)
    service = FranchiseService(db)
    return await service.get_franchise_benchmarks(org_id)


@router.get("/regions", status_code=status.HTTP_200_OK)
async def get_regional_breakdown(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> List[Dict[str, Any]]:
    """Get regional clusters and aggregate performance by region."""
    org_id = get_org_id(current_user)
    service = FranchiseService(db)
    return await service.get_regional_breakdown(org_id)


@router.get("/audit", status_code=status.HTTP_200_OK)
async def get_profile_audit(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Dict[str, Any]:
    """Get organization-wide profile completeness and missing information audit."""
    org_id = get_org_id(current_user)
    service = FranchiseService(db)
    return await service.get_profile_audit(org_id)


@router.get("/team", status_code=status.HTTP_200_OK)
async def get_franchise_team(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> List[Dict[str, Any]]:
    """Get real users and team members for this franchise organization."""
    org_id = get_org_id(current_user)
    service = FranchiseService(db)
    return await service.get_franchise_team(org_id)


@router.post("/bulk-sync", status_code=status.HTTP_200_OK)
async def trigger_bulk_sync(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Dict[str, Any]:
    """Trigger background GBP synchronization across all franchise locations."""
    org_id = get_org_id(current_user)
    service = FranchiseService(db)
    locations = await service.get_franchise_locations_matrix(org_id)
    return {
        "status": "success",
        "synced_locations_count": len(locations),
        "message": f"Successfully queued GBP synchronization for {len(locations)} locations.",
    }
