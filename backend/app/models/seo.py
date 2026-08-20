# ==================================================
# OptigoAI Backend — SEO Analysis Model
# ==================================================

import uuid
from sqlalchemy import String, Text, Integer, ForeignKey, JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship
from typing import Optional, Any, TYPE_CHECKING

from app.core.database import Base, TimestampMixin

if TYPE_CHECKING:
    from app.models.business import Business


class SEOAnalysis(Base, TimestampMixin):
    __tablename__ = "seo_analyses"

    id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    business_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("businesses.id", ondelete="CASCADE"),
        nullable=False, index=True,
    )

    seo_score: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    keyword_opportunities: Mapped[Optional[dict[str, Any]]] = mapped_column(
        JSON, nullable=True
    )
    missing_topics: Mapped[Optional[dict[str, Any]]] = mapped_column(
        JSON, nullable=True
    )
    content_opportunities: Mapped[Optional[dict[str, Any]]] = mapped_column(
        JSON, nullable=True
    )
    profile_optimizations: Mapped[Optional[dict[str, Any]]] = mapped_column(
        JSON, nullable=True
    )
    local_presence_analysis: Mapped[Optional[dict[str, Any]]] = mapped_column(
        JSON, nullable=True
    )
    full_analysis: Mapped[Optional[dict[str, Any]]] = mapped_column(
        JSON, nullable=True
    )

    # Relationships
    business: Mapped["Business"] = relationship(
        "Business", back_populates="seo_analyses", lazy="selectin"
    )

    def __repr__(self) -> str:
        return f"<SEOAnalysis(id={self.id}, score={self.seo_score})>"
