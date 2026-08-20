# ==================================================
# OptigoAI Backend — Content Model
# ==================================================

import uuid
from enum import Enum as PyEnum
from sqlalchemy import String, Text, ForeignKey, Enum, JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship
from typing import Optional, Any, TYPE_CHECKING

from app.core.database import Base, TimestampMixin

if TYPE_CHECKING:
    from app.models.business import Business


class ContentType(str, PyEnum):
    GOOGLE_POST = "google_post"
    INSTAGRAM = "instagram"
    FACEBOOK = "facebook"
    ADVERTISEMENT = "advertisement"
    WEBSITE = "website"
    SEO_ARTICLE = "seo_article"
    REVIEW_REPLY = "review_reply"


class ContentStatus(str, PyEnum):
    DRAFT = "draft"
    APPROVED = "approved"
    PUBLISHED = "published"


class Content(Base, TimestampMixin):
    __tablename__ = "contents"

    id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    business_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("businesses.id", ondelete="CASCADE"),
        nullable=False, index=True,
    )

    content_type: Mapped[ContentType] = mapped_column(
        Enum(ContentType), nullable=False
    )
    title: Mapped[Optional[str]] = mapped_column(String(500), nullable=True)
    body: Mapped[str] = mapped_column(Text, nullable=False)
    tone: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    target_audience: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    marketing_goal: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    hashtags: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    call_to_action: Mapped[Optional[str]] = mapped_column(String(500), nullable=True)
    status: Mapped[ContentStatus] = mapped_column(
        Enum(ContentStatus), default=ContentStatus.DRAFT, nullable=False
    )
    generation_metadata: Mapped[Optional[dict[str, Any]]] = mapped_column(
        JSON, nullable=True
    )

    # Campaign link (optional)
    campaign_id: Mapped[Optional[str]] = mapped_column(
        String(36), ForeignKey("campaigns.id", ondelete="SET NULL"), nullable=True
    )

    # Relationships
    business: Mapped["Business"] = relationship(
        "Business", back_populates="contents", lazy="selectin"
    )

    def __repr__(self) -> str:
        return f"<Content(id={self.id}, type={self.content_type})>"
