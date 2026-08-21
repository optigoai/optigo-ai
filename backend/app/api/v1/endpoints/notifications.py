# ==================================================
# OptigoAI Backend — Notifications API Endpoints (Phase 12)
# ==================================================

from typing import List
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.v1.deps import get_db, get_current_user
from app.models.user import User
from app.schemas.notification import (
    NotificationCreate,
    NotificationResponse,
)
from app.services.notification_service import NotificationService

router = APIRouter(prefix="/notifications", tags=["Notifications"])


@router.get("", response_model=List[NotificationResponse])
async def list_notifications(
    business_id: str = Query(..., description="Business ID"),
    unread_only: bool = Query(False, description="Filter unread only"),
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """List proactive notifications and alerts for a business."""
    service = NotificationService(db)
    return await service.list_notifications(
        business_id=business_id,
        organization_id=current_user.organization_id,
        unread_only=unread_only,
        limit=limit,
        offset=offset,
    )


@router.post("", response_model=NotificationResponse, status_code=status.HTTP_201_CREATED)
async def create_notification(
    notif_in: NotificationCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Create a proactive alert/notification."""
    service = NotificationService(db)
    return await service.create_notification(
        business_id=notif_in.business_id,
        organization_id=current_user.organization_id,
        title=notif_in.title,
        message=notif_in.message,
        notification_type=notif_in.notification_type,
        action_url=notif_in.action_url,
    )


@router.patch("/{notification_id}/read", response_model=NotificationResponse)
async def mark_as_read(
    notification_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Mark a specific notification as read."""
    service = NotificationService(db)
    return await service.mark_as_read(
        notification_id=notification_id,
        organization_id=current_user.organization_id,
    )


@router.post("/mark-all-read", response_model=dict)
async def mark_all_as_read(
    business_id: str = Query(..., description="Business ID"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Mark all notifications as read for a business."""
    service = NotificationService(db)
    count = await service.mark_all_as_read(
        business_id=business_id,
        organization_id=current_user.organization_id,
    )
    return {"status": "success", "marked_read_count": count}
