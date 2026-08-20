# ==================================================
# OptigoAI Backend — Creative Model
# ==================================================

import uuid
from enum import Enum as PyEnum
from sqlalchemy import String, Text, ForeignKey, Enum, JSON, Integer
from sqlalchemy.orm import Mapped, mapped_column, relationship
from typing import Optional, Any, TYPE_CHECKING

from app.core.database import Base, TimestampMixin

if TYPE_CHECKING:
    from app.models.business import Business


class CreativeStatus(str, PyEnum):
    GENERATING = "generating"
    COMPLETED = "completed"
    FAILED = "failed"


class Creative(Base, TimestampMixin):
    __tablename__ = "creatives"

    id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    business_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("businesses.id", ondelete="CASCADE"),
        nullable=False, index=True,
    )

    title: Mapped[str] = mapped_column(String(500), nullable=False)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    style: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    prompt_used: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    # Storage
    file_url: Mapped[Optional[str]] = mapped_column(String(1000), nullable=True)
    file_path: Mapped[Optional[str]] = mapped_column(String(1000), nullable=True)
    file_size: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    mime_type: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)

    status: Mapped[CreativeStatus] = mapped_column(
        Enum(CreativeStatus), default=CreativeStatus.GENERATING, nullable=False
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
        "Business", back_populates="creatives", lazy="selectin"
    )

    def __repr__(self) -> str:
        return f"<Creative(id={self.id}, title={self.title})>"
