# ==================================================
# OptigoAI Backend — Notification Model
# ==================================================

import uuid
from enum import Enum as PyEnum
from sqlalchemy import String, Text, ForeignKey, Enum, Boolean
from sqlalchemy.orm import Mapped, mapped_column, relationship
from typing import Optional, TYPE_CHECKING

from app.core.database import Base, TimestampMixin

if TYPE_CHECKING:
    from app.models.business import Business


class NotificationType(str, PyEnum):
    NEW_REVIEW = "new_review"
    PROBLEM = "problem"
    OPPORTUNITY = "opportunity"
    ANALYSIS_COMPLETE = "analysis_complete"
    RECOMMENDATION = "recommendation"
    CAMPAIGN_UPDATE = "campaign_update"
    SYSTEM = "system"


class Notification(Base, TimestampMixin):
    __tablename__ = "notifications"

    id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    business_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("businesses.id", ondelete="CASCADE"),
        nullable=False, index=True,
    )
    user_id: Mapped[Optional[str]] = mapped_column(
        String(36), ForeignKey("users.id", ondelete="CASCADE"),
        nullable=True, index=True,
    )

    notification_type: Mapped[NotificationType] = mapped_column(
        Enum(NotificationType), nullable=False
    )
    title: Mapped[str] = mapped_column(String(500), nullable=False)
    message: Mapped[str] = mapped_column(Text, nullable=False)
    is_read: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    action_url: Mapped[Optional[str]] = mapped_column(String(500), nullable=True)

    # Relationships
    business: Mapped["Business"] = relationship(
        "Business", back_populates="notifications", lazy="selectin"
    )

    def __repr__(self) -> str:
        return f"<Notification(id={self.id}, type={self.notification_type}, read={self.is_read})>"
