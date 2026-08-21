# ==================================================
# OptigoAI Backend — Google Search Console Schemas
# ==================================================

from datetime import datetime, date
from typing import Optional, List
from pydantic import BaseModel, ConfigDict


class GscAuthUrlResponse(BaseModel):
    auth_url: str
    state: str


class GscOAuthCallbackRequest(BaseModel):
    code: str
    state: Optional[str] = None
    business_id: str


class GscSiteItem(BaseModel):
    site_url: str
    permission_level: str


class GscSelectSiteRequest(BaseModel):
    business_id: str
    site_url: str


class GscQueryItem(BaseModel):
    query: str
    clicks: int
    impressions: int
    ctr: float
    position: float


class GscStatusResponse(BaseModel):
    business_id: str
    is_connected: bool
    site_url: Optional[str] = None
    sync_status: str  # idle, syncing, success, error
    last_synced_at: Optional[datetime] = None
    freshness_label: str  # e.g. "Updated 2 hours ago", "Never synced"


class GscMetricsSummaryResponse(BaseModel):
    business_id: str
    is_connected: bool
    site_url: Optional[str] = None
    total_clicks: int
    total_impressions: int
    average_ctr: float
    average_position: float
    date_range_label: str  # e.g. "Last 28 Days"
    top_queries: List[GscQueryItem]
    freshness_label: str
    actionable_insight: str
