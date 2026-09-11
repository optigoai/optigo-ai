# ==================================================
# OptigoAI Backend — Lead Model
# ==================================================
"""
Lead model for single-page onboarding, business audit reports,
and conversion tracking in the admin portal.
"""

import uuid
from datetime import datetime
from typing import Optional, Any, List, TYPE_CHECKING
from sqlalchemy import String, Text, ForeignKey, JSON, Float, Integer, DateTime
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base, TimestampMixin

if TYPE_CHECKING:
    from app.models.user import User
    from app.models.business import Business
    from app.models.organization import Organization


class Lead(Base, TimestampMixin):
    __tablename__ = "leads"

    id: Mapped[str] = mapped_column(
        String(36),
        primary_key=True,
        default=lambda: str(uuid.uuid4()),
    )

    # Business Information (identified from Places search)
    business_name: Mapped[str] = mapped_column(String(255), nullable=False)
    place_id: Mapped[Optional[str]] = mapped_column(String(255), nullable=True, index=True)
    google_location_id: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    address: Mapped[Optional[str]] = mapped_column(String(500), nullable=True)
    latitude: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    longitude: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    category: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    rating: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    review_count: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    website: Mapped[Optional[str]] = mapped_column(String(500), nullable=True)
    photo_url: Mapped[Optional[str]] = mapped_column(String(1000), nullable=True)

    # Contact Information
    phone: Mapped[str] = mapped_column(String(50), nullable=False, index=True)
    country_code: Mapped[Optional[str]] = mapped_column(String(10), nullable=True, default="+91")
    email: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)

    # Raw Places Search Attributes
    raw_places_data: Mapped[Optional[dict[str, Any]]] = mapped_column(JSON, nullable=True)

    # Funnel & Onboarding Status
    # Stages: new_lead, search_started, business_selected, form_submitted,
    #         analysis_started, report_processing, report_ready, report_viewed,
    #         plan_selected, payment_pending, converted, abandoned, stuck
    status: Mapped[str] = mapped_column(String(50), default="new_lead", nullable=False, index=True)
    priority: Mapped[str] = mapped_column(String(20), default="warm", nullable=False, index=True)  # hot, warm, cold

    # Generated AI Business Report Data
    report_data: Mapped[Optional[dict[str, Any]]] = mapped_column(JSON, nullable=True)
    report_score: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    report_generated_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    report_viewed_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)

    # Plan Selection & Payment Flow
    selected_plan: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)  # starter, growth, pro
    plan_duration: Mapped[Optional[str]] = mapped_column(String(20), nullable=True, default="monthly")  # monthly, annual
    payment_status: Mapped[str] = mapped_column(String(50), default="unpaid", nullable=False)  # unpaid, pending, paid, failed
    payment_id: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    payment_amount: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    payment_currency: Mapped[str] = mapped_column(String(10), default="INR", nullable=False)

    # Linking to Customer Entities if Converted or Existing
    user_id: Mapped[Optional[str]] = mapped_column(
        String(36),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    business_id: Mapped[Optional[str]] = mapped_column(
        String(36),
        ForeignKey("businesses.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    organization_id: Mapped[Optional[str]] = mapped_column(
        String(36),
        ForeignKey("organizations.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )

    # Admin Management & Follow-up
    notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    timeline: Mapped[Optional[List[dict[str, Any]]]] = mapped_column(JSON, nullable=True)
    last_activity_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)

    # Relationships
    user: Mapped[Optional["User"]] = relationship("User", lazy="selectin")
    business: Mapped[Optional["Business"]] = relationship("Business", lazy="selectin")
    organization: Mapped[Optional["Organization"]] = relationship("Organization", lazy="selectin")
