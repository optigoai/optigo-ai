# ==================================================
# OptigoAI Backend — Analytics Model
# ==================================================

import uuid
from sqlalchemy import String, Text, Integer, Float, ForeignKey, JSON, Date
from sqlalchemy.orm import Mapped, mapped_column, relationship
from typing import Optional, Any, TYPE_CHECKING
from datetime import date

from app.core.database import Base, TimestampMixin

if TYPE_CHECKING:
    from app.models.business import Business


class BusinessAnalytics(Base, TimestampMixin):
    __tablename__ = "business_analytics"

    id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    business_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("businesses.id", ondelete="CASCADE"),
        nullable=False, index=True,
    )

    period_start: Mapped[date] = mapped_column(Date, nullable=False)
    period_end: Mapped[date] = mapped_column(Date, nullable=False)

    # Metrics
    total_reviews: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    average_rating: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    profile_views: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    website_clicks: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    phone_calls: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    direction_requests: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    photo_views: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)

    # AI insights
    ai_performance_summary: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    ai_insights: Mapped[Optional[dict[str, Any]]] = mapped_column(JSON, nullable=True)
    what_worked: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    what_did_not_work: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    next_actions: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    # Raw data
    raw_metrics: Mapped[Optional[dict[str, Any]]] = mapped_column(JSON, nullable=True)

    # Relationships
    business: Mapped["Business"] = relationship(
        "Business", back_populates="analytics", lazy="selectin"
    )

    def __repr__(self) -> str:
        return f"<BusinessAnalytics(id={self.id}, period={self.period_start} to {self.period_end})>"
