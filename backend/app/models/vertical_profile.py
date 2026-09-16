# ==================================================
# OptigoAI Backend — Vertical Profile Model
# ==================================================
"""
Stores per-vertical calibration parameters for the v3 revenue-loss engine.
These values are the production source of truth — the in-code fallback dict
in loss_engine.py is only used if no DB rows exist yet.
"""

import uuid
from sqlalchemy import String, Float, DateTime
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base, TimestampMixin


class VerticalProfile(Base, TimestampMixin):
    __tablename__ = "vertical_profiles"

    id: Mapped[str] = mapped_column(
        String(36),
        primary_key=True,
        default=lambda: str(uuid.uuid4()),
    )
    vertical_key: Mapped[str] = mapped_column(String(50), unique=True, nullable=False, index=True)
    label: Mapped[str] = mapped_column(String(255), nullable=False)

    # Average Order Value range
    aov_min: Mapped[float] = mapped_column(Float, nullable=False)
    aov_max: Mapped[float] = mapped_column(Float, nullable=False)

    # Call-to-order conversion probability range
    p_call_to_order_min: Mapped[float] = mapped_column(Float, nullable=False)
    p_call_to_order_max: Mapped[float] = mapped_column(Float, nullable=False)

    # Direction-to-visit conversion probability range
    p_direction_to_visit_min: Mapped[float] = mapped_column(Float, nullable=False)
    p_direction_to_visit_max: Mapped[float] = mapped_column(Float, nullable=False)

    # Fallback directions-per-call ratio when no real direction data
    directions_per_call_ratio_min: Mapped[float] = mapped_column(Float, nullable=False)
    directions_per_call_ratio_max: Mapped[float] = mapped_column(Float, nullable=False)

    # Revenue guardrail ceiling as % of benchmark monthly revenue
    max_loss_pct_of_benchmark_revenue: Mapped[float] = mapped_column(Float, nullable=False, default=0.35)

    # Click-to-call rate range (from search impression to phone call)
    click_to_call_rate_min: Mapped[float] = mapped_column(Float, nullable=False, default=0.04)
    click_to_call_rate_max: Mapped[float] = mapped_column(Float, nullable=False, default=0.06)

    # Exponential decay constant for pairwise share model (per-vertical/geo-tier)
    decay_k: Mapped[float] = mapped_column(Float, nullable=False, default=0.5)
