# ==================================================
# OptigoAI Backend — Lead Schemas
# ==================================================
"""
Pydantic schemas for lead creation, places search,
audit reports, plan selection, and payment verification.
"""

from typing import Optional, Dict, Any, List
from datetime import datetime
from pydantic import BaseModel, Field


class LeadPlacesSearchResult(BaseModel):
    place_id: str
    name: str
    address: str
    category: Optional[str] = None
    rating: Optional[float] = None
    review_count: Optional[int] = None
    photo_url: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    phone: Optional[str] = None
    website: Optional[str] = None


class LeadCreate(BaseModel):
    business_name: str = Field(..., min_length=1, max_length=255)
    phone: str = Field(..., min_length=5, max_length=50)
    country_code: str = Field(default="+91", max_length=10)
    email: Optional[str] = None
    place_id: Optional[str] = None
    address: Optional[str] = None
    category: Optional[str] = None
    rating: Optional[float] = None
    review_count: Optional[int] = None
    website: Optional[str] = None
    photo_url: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    raw_places_data: Optional[Dict[str, Any]] = None


class LeadResponse(BaseModel):
    id: str
    business_name: str
    phone: str
    country_code: Optional[str] = "+91"
    email: Optional[str] = None
    place_id: Optional[str] = None
    address: Optional[str] = None
    category: Optional[str] = None
    rating: Optional[float] = None
    review_count: Optional[int] = None
    website: Optional[str] = None
    photo_url: Optional[str] = None
    status: str
    priority: str
    report_data: Optional[Dict[str, Any]] = None
    report_score: Optional[int] = None
    selected_plan: Optional[str] = None
    plan_duration: Optional[str] = "monthly"
    payment_status: str = "unpaid"
    payment_id: Optional[str] = None
    notes: Optional[str] = None
    timeline: Optional[List[Dict[str, Any]]] = None
    user_id: Optional[str] = None
    business_id: Optional[str] = None
    organization_id: Optional[str] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    last_activity_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class LeadSelectPlanRequest(BaseModel):
    plan_id: str = Field(..., description="starter, growth, or pro")
    duration: str = Field(default="monthly", description="monthly or annual")


class LeadCreateOrderRequest(BaseModel):
    plan_id: str
    duration: str = "monthly"


class LeadVerifyPaymentRequest(BaseModel):
    razorpay_order_id: Optional[str] = None
    razorpay_payment_id: Optional[str] = None
    razorpay_signature: Optional[str] = None
    user_email: Optional[str] = None
    user_full_name: Optional[str] = None
    password: Optional[str] = None


class LeadStatusUpdateRequest(BaseModel):
    status: Optional[str] = None
    priority: Optional[str] = None
    notes: Optional[str] = None


class LeadAddNoteRequest(BaseModel):
    note: str = Field(..., min_length=1)


class LeadStatsResponse(BaseModel):
    total_leads: int = 0
    new_leads: int = 0
    active_onboarding: int = 0
    report_ready: int = 0
    stuck_abandoned: int = 0
    converted_leads: int = 0
    conversion_rate: float = 0.0


class HealthScoreBreakdownItem(BaseModel):
    label: str
    score: int


class HealthScoreBreakdown(BaseModel):
    profile_completeness: HealthScoreBreakdownItem
    reviews_engagement: HealthScoreBreakdownItem
    search_visibility: HealthScoreBreakdownItem
    website_seo: HealthScoreBreakdownItem
    photos_content: HealthScoreBreakdownItem


class HealthScoreData(BaseModel):
    score: int
    verdict: str
    breakdown: HealthScoreBreakdown


class QuickStatsData(BaseModel):
    monthly_searches: str
    searches_trend: str
    searches_trend_label: str = "vs last month"
    unanswered_reviews: int
    unanswered_pct: str
    unanswered_label: str = "need attention"
    competitors_ahead_count: int
    competitors_label: str = "in your area"


class ActionPlanItem(BaseModel):
    id: str
    title: str
    description: str
    impact: str  # "High Impact", "Medium Impact", "Low Impact"
    impact_level: str  # "high", "medium", "low"
    icon_type: str
    cta_label: str = "Do This →"
    solution_pillar: str


class CompetitorDetailItem(BaseModel):
    rank: int
    name: str
    rating: float
    review_count: int
    distance: str
    advantage: str
    photo_url: Optional[str] = None
    address: Optional[str] = None
    lat: Optional[float] = None
    lng: Optional[float] = None


class AuditIssueItem(BaseModel):
    id: str
    title: str
    description: str
    impact: str  # "High Impact", "Medium Impact", "Low Impact"
    severity: str  # "critical", "warning", "info"
    icon_type: str
    color: str

