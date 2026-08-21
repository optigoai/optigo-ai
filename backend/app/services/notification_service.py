# ==================================================
# OptigoAI Backend — Notification Service (Phase 12)
# ==================================================

from typing import Optional, Sequence, Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import HTTPException, status

from app.models.notification import Notification, NotificationType
from app.repositories.business_repo import BusinessRepository
from app.repositories.notification_repo import NotificationRepository
from app.core.logging import get_logger

logger = get_logger("app.services.notification")


class NotificationService:
    """Service managing proactive intelligence alerts and in-app notifications."""

    def __init__(self, db: AsyncSession):
        self.db = db
        self.business_repo = BusinessRepository(db)
        self.notif_repo = NotificationRepository(db)

    async def create_notification(
        self,
        business_id: str,
        organization_id: str,
        title: str,
        message: str,
        notification_type: NotificationType = NotificationType.SYSTEM,
        action_url: Optional[str] = None,
    ) -> Notification:
        """Create a proactive alert for a business."""
        business = await self.business_repo.get_by_id(business_id)
        if not business:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Business not found")
        if business.organization_id != organization_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

        return await self.notif_repo.create({
            "business_id": business_id,
            "notification_type": notification_type,
            "title": title,
            "message": message,
            "action_url": action_url,
            "is_read": False,
        })

    async def list_notifications(
        self,
        business_id: str,
        organization_id: str,
        unread_only: bool = False,
        limit: int = 50,
        offset: int = 0,
    ) -> Sequence[Notification]:
        """List notifications for a business."""
        business = await self.business_repo.get_by_id(business_id)
        if not business:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Business not found")
        if business.organization_id != organization_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

        return await self.notif_repo.list_by_business(
            business_id=business_id,
            unread_only=unread_only,
            limit=limit,
            offset=offset,
        )

    async def mark_as_read(
        self,
        notification_id: str,
        organization_id: str,
    ) -> Notification:
        """Mark a notification as read."""
        notification = await self.notif_repo.get_by_id(notification_id)
        if not notification:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Notification not found")
        business = await self.business_repo.get_by_id(notification.business_id)
        if not business or business.organization_id != organization_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

        return await self.notif_repo.mark_as_read(notification)

    async def mark_all_as_read(
        self,
        business_id: str,
        organization_id: str,
    ) -> int:
        """Mark all notifications for a business as read."""
        business = await self.business_repo.get_by_id(business_id)
        if not business:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Business not found")
        if business.organization_id != organization_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

        return await self.notif_repo.mark_all_as_read(business_id)
