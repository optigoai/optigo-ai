# ==================================================
# OptigoAI Backend — Calibration Log Model
# ==================================================
"""
Audit table for calibration runs. Each row records a single update to a
vertical profile's probability parameter, preserving the old and new ranges
plus the evidence (trials, successes) that drove the change.

This table doubles as evidence that the model is improving, not drifting.
"""

import uuid
from datetime import datetime
from sqlalchemy import String, Float, Integer, DateTime
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class CalibrationLog(Base):
    __tablename__ = "calibration_logs"

    id: Mapped[str] = mapped_column(
        String(36),
        primary_key=True,
        default=lambda: str(uuid.uuid4()),
    )
    vertical_key: Mapped[str] = mapped_column(String(50), nullable=False, index=True)

    # Which parameter was calibrated (e.g. 'p_call_to_order', 'p_direction_to_visit')
    parameter_name: Mapped[str] = mapped_column(String(100), nullable=False)

    # Old range before calibration
    old_range_min: Mapped[float] = mapped_column(Float, nullable=False)
    old_range_max: Mapped[float] = mapped_column(Float, nullable=False)

    # New range after calibration
    new_range_min: Mapped[float] = mapped_column(Float, nullable=False)
    new_range_max: Mapped[float] = mapped_column(Float, nullable=False)

    # Evidence
    trials: Mapped[int] = mapped_column(Integer, nullable=False)
    successes: Mapped[int] = mapped_column(Integer, nullable=False)

    # When this calibration was performed
    calibrated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=datetime.utcnow,
        nullable=False,
    )
