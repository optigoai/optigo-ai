# ==================================================
# OptigoAI Backend — Notification Schemas (Phase 12)
# ==================================================

from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict
from app.models.notification import NotificationType


class NotificationCreate(BaseModel):
    business_id: str
    notification_type: NotificationType = NotificationType.SYSTEM
    title: str
    message: str
    action_url: Optional[str] = None


class NotificationResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    business_id: str
    notification_type: NotificationType
    title: str
    message: str
    is_read: bool
    action_url: Optional[str] = None
    created_at: datetime
    updated_at: datetime
