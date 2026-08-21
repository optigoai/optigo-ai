# ==================================================
# OptigoAI Backend — ROI Analytics Schemas (Phase 11)
# ==================================================

from typing import Optional, List, Dict, Any
from pydantic import BaseModel


class RoiMetricItem(BaseModel):
    label: str
    value: str
    trend: str
    description: str


class RoiDashboardResponse(BaseModel):
    business_id: str
    marketing_health_score: int
    estimated_revenue_impact: str
    roi_multiplier: str
    metrics: List[RoiMetricItem]
    channel_breakdown: Dict[str, int]
    lead_attribution: Dict[str, Any]
    ai_summary: str


class CompetitorBenchmarkItem(BaseModel):
    name: str
    rating: float
    review_count: int
    visibility_score: int
    gap_analysis: str


class CompetitorBenchmarkResponse(BaseModel):
    business_name: str
    your_rank: int
    competitors: List[CompetitorBenchmarkItem]
    actionable_takeaway: str
