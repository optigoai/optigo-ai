# ==================================================
# OptigoAI Backend — Feature Toggle Model
# ==================================================

import uuid
from sqlalchemy import String, Boolean, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base, TimestampMixin


class FeatureToggle(Base, TimestampMixin):
    __tablename__ = "feature_toggles"

    id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    feature_name: Mapped[str] = mapped_column(
        String(100), unique=True, nullable=False, index=True
    )
    is_enabled: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)

    def __repr__(self) -> str:
        return f"<FeatureToggle(name={self.feature_name}, enabled={self.is_enabled})>"
