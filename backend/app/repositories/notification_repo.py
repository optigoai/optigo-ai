# ==================================================
# OptigoAI Backend — Notification Repository
# ==================================================

from typing import Optional, Sequence, Dict, Any
from sqlalchemy import select, desc, update
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.notification import Notification


class NotificationRepository:
    """Repository for managing in-app notifications and alerts."""

    def __init__(self, db: AsyncSession):
        self.db = db

    async def create(self, data: Dict[str, Any]) -> Notification:
        notification = Notification(**data)
        self.db.add(notification)
        await self.db.commit()
        await self.db.refresh(notification)
        return notification

    async def get_by_id(self, notification_id: str) -> Optional[Notification]:
        result = await self.db.execute(select(Notification).where(Notification.id == notification_id))
        return result.scalar_one_or_none()

    async def list_by_business(
        self,
        business_id: str,
        unread_only: bool = False,
        limit: int = 50,
        offset: int = 0,
    ) -> Sequence[Notification]:
        query = select(Notification).where(Notification.business_id == business_id)
        if unread_only:
            query = query.where(Notification.is_read == False)
        query = query.order_by(desc(Notification.created_at)).limit(limit).offset(offset)
        result = await self.db.execute(query)
        return result.scalars().all()

    async def mark_as_read(self, notification: Notification) -> Notification:
        notification.is_read = True
        await self.db.commit()
        await self.db.refresh(notification)
        return notification

    async def mark_all_as_read(self, business_id: str) -> int:
        stmt = (
            update(Notification)
            .where(Notification.business_id == business_id, Notification.is_read == False)
            .values(is_read=True)
        )
        result = await self.db.execute(stmt)
        await self.db.commit()
        return result.rowcount
