# ==================================================
# OptigoAI Backend — Review Model
# ==================================================

import uuid
from enum import Enum as PyEnum
from sqlalchemy import String, Text, Integer, Float, ForeignKey, Enum, Boolean
from sqlalchemy.orm import Mapped, mapped_column, relationship
from typing import Optional, TYPE_CHECKING

from app.core.database import Base, TimestampMixin

if TYPE_CHECKING:
    from app.models.business import Business


class ReviewSentiment(str, PyEnum):
    POSITIVE = "positive"
    NEUTRAL = "neutral"
    NEGATIVE = "negative"


class Review(Base, TimestampMixin):
    __tablename__ = "reviews"

    id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    business_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("businesses.id", ondelete="CASCADE"),
        nullable=False, index=True,
    )
    # Review data
    reviewer_name: Mapped[str] = mapped_column(String(255), nullable=False)
    rating: Mapped[int] = mapped_column(Integer, nullable=False)
    text: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    review_date: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)

    # AI analysis
    sentiment: Mapped[Optional[ReviewSentiment]] = mapped_column(
        Enum(ReviewSentiment), nullable=True
    )
    ai_summary: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    key_themes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    # Reply
    reply_text: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    ai_generated_reply: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    is_replied: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    # Source
    source: Mapped[str] = mapped_column(String(50), default="gbp", nullable=False)
    external_id: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)

    # Relationships
    business: Mapped["Business"] = relationship(
        "Business", back_populates="reviews", lazy="selectin"
    )

    def __repr__(self) -> str:
        return f"<Review(id={self.id}, rating={self.rating}, sentiment={self.sentiment})>"
