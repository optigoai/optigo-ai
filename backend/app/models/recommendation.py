# ==================================================
# OptigoAI Backend — Recommendation Model
# ==================================================

import uuid
from enum import Enum as PyEnum
from sqlalchemy import String, Text, Integer, ForeignKey, Enum, Boolean
from sqlalchemy.orm import Mapped, mapped_column, relationship
from typing import Optional, TYPE_CHECKING

from app.core.database import Base, TimestampMixin

if TYPE_CHECKING:
    from app.models.business import Business


class RecommendationPriority(str, PyEnum):
    URGENT = "urgent"
    IMPORTANT = "important"
    OPPORTUNITY = "opportunity"


class RecommendationStatus(str, PyEnum):
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    DISMISSED = "dismissed"


class Recommendation(Base, TimestampMixin):
    __tablename__ = "recommendations"

    id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    business_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("businesses.id", ondelete="CASCADE"),
        nullable=False, index=True,
    )

    title: Mapped[str] = mapped_column(String(500), nullable=False)
    explanation: Mapped[str] = mapped_column(Text, nullable=False)
    reason: Mapped[str] = mapped_column(Text, nullable=False)
    priority: Mapped[RecommendationPriority] = mapped_column(
        Enum(RecommendationPriority), nullable=False
    )
    impact: Mapped[str] = mapped_column(String(255), nullable=False)
    effort: Mapped[str] = mapped_column(String(255), nullable=False)
    suggested_action: Mapped[str] = mapped_column(Text, nullable=False)
    related_feature: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    status: Mapped[RecommendationStatus] = mapped_column(
        Enum(RecommendationStatus), default=RecommendationStatus.PENDING, nullable=False
    )
    sort_order: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    # Relationships
    business: Mapped["Business"] = relationship(
        "Business", back_populates="recommendations", lazy="selectin"
    )

    def __repr__(self) -> str:
        return f"<Recommendation(id={self.id}, priority={self.priority}, title={self.title[:50]})>"
