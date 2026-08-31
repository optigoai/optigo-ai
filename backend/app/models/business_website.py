# ==================================================
# OptigoAI Backend — Business Website Model
# ==================================================
"""
Business Website model for dynamic public business pages on optigoai.com/{slug}.
Stores AI-generated structured website content, SEO metadata, publishing state,
and custom code overrides.
"""

import uuid
from datetime import datetime
from typing import Optional, Any, TYPE_CHECKING
from sqlalchemy import String, Text, ForeignKey, JSON, DateTime, Integer
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base, TimestampMixin

if TYPE_CHECKING:
    from app.models.business import Business
    from app.models.organization import Organization


class BusinessWebsite(Base, TimestampMixin):
    __tablename__ = "business_websites"

    id: Mapped[str] = mapped_column(
        String(36),
        primary_key=True,
        default=lambda: str(uuid.uuid4()),
    )

    # Business association (1:1 with Business)
    business_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("businesses.id", ondelete="CASCADE"),
        unique=True,
        nullable=False,
        index=True,
    )

    # Organization association for multi-tenant isolation
    organization_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("organizations.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    # Unique public URL slug e.g. "casaraza-restaurant" for optigoai.com/casaraza-restaurant
    slug: Mapped[str] = mapped_column(
        String(255),
        unique=True,
        nullable=False,
        index=True,
    )

    # Publishing state: draft, published, unpublished
    status: Mapped[str] = mapped_column(
        String(50),
        default="draft",
        nullable=False,
        index=True,
    )

    # SEO Metadata
    seo_title: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    seo_description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    # AI-generated structured content sections:
    # {
    #   "hero": {...}, "about": {...}, "services": [...],
    #   "why_choose_us": [...], "reviews": {...}, "gallery": [...],
    #   "hours_location": {...}, "faqs": [...], "cta_banner": {...},
    #   "theme_config": {...}
    # }
    content_json: Mapped[dict[str, Any]] = mapped_column(
        JSON,
        nullable=False,
        default=dict,
    )

    # Admin custom code overrides
    custom_html: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    custom_css: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    custom_js: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    # Metrics & Timestamps
    view_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    published_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)

    # Relationships
    business: Mapped["Business"] = relationship(
        "Business",
        backref="website_site",
        lazy="selectin",
    )
    organization: Mapped["Organization"] = relationship(
        "Organization",
        lazy="selectin",
    )
