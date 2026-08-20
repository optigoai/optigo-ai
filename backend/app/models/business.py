# ==================================================
# OptigoAI Backend — Business Model
# ==================================================
"""
Business model — the core entity that all AI analysis,
reviews, SEO, campaigns, and content are linked to.
"""

import uuid
from sqlalchemy import String, Text, ForeignKey, JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship
from typing import Optional, Any, List, TYPE_CHECKING

from app.core.database import Base, TimestampMixin

if TYPE_CHECKING:
    from app.models.organization import Organization
    from app.models.review import Review
    from app.models.recommendation import Recommendation
    from app.models.content import Content
    from app.models.campaign import Campaign
    from app.models.competitor import Competitor
    from app.models.seo import SEOAnalysis
    from app.models.analytics import BusinessAnalytics
    from app.models.notification import Notification
    from app.models.creative import Creative


class Business(Base, TimestampMixin):
    __tablename__ = "businesses"

    id: Mapped[str] = mapped_column(
        String(36),
        primary_key=True,
        default=lambda: str(uuid.uuid4()),
    )

    # Organization association (multi-tenant)
    organization_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("organizations.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    # Basic information (from onboarding)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    category: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    location: Mapped[Optional[str]] = mapped_column(String(500), nullable=True)
    website: Mapped[Optional[str]] = mapped_column(String(500), nullable=True)
    phone: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    # Onboarding data
    target_customers: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    services: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    business_goals: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    marketing_channels: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    # AI-generated structured business profile
    ai_business_profile: Mapped[Optional[dict[str, Any]]] = mapped_column(
        JSON, nullable=True
    )

    # Business health score (from AI analysis)
    health_score: Mapped[Optional[int]] = mapped_column(nullable=True)
    health_analysis: Mapped[Optional[dict[str, Any]]] = mapped_column(
        JSON, nullable=True
    )

    # GBP Provider ID (for future real GBP integration)
    gbp_account_id: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    gbp_location_id: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)

    # Status
    onboarding_completed: Mapped[bool] = mapped_column(default=False, nullable=False)

    # Relationships
    organization: Mapped["Organization"] = relationship(
        "Organization", back_populates="businesses", lazy="selectin"
    )
    reviews: Mapped[List["Review"]] = relationship(
        "Review", back_populates="business", lazy="select",
        cascade="all, delete-orphan",
    )
    recommendations: Mapped[List["Recommendation"]] = relationship(
        "Recommendation", back_populates="business", lazy="select",
        cascade="all, delete-orphan",
    )
    contents: Mapped[List["Content"]] = relationship(
        "Content", back_populates="business", lazy="select",
        cascade="all, delete-orphan",
    )
    campaigns: Mapped[List["Campaign"]] = relationship(
        "Campaign", back_populates="business", lazy="select",
        cascade="all, delete-orphan",
    )
    competitors: Mapped[List["Competitor"]] = relationship(
        "Competitor", back_populates="business", lazy="select",
        cascade="all, delete-orphan",
    )
    seo_analyses: Mapped[List["SEOAnalysis"]] = relationship(
        "SEOAnalysis", back_populates="business", lazy="select",
        cascade="all, delete-orphan",
    )
    analytics: Mapped[List["BusinessAnalytics"]] = relationship(
        "BusinessAnalytics", back_populates="business", lazy="select",
        cascade="all, delete-orphan",
    )
    notifications: Mapped[List["Notification"]] = relationship(
        "Notification", back_populates="business", lazy="select",
        cascade="all, delete-orphan",
    )
    creatives: Mapped[List["Creative"]] = relationship(
        "Creative", back_populates="business", lazy="select",
        cascade="all, delete-orphan",
    )

    def __repr__(self) -> str:
        return f"<Business(id={self.id}, name={self.name})>"
