from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, Field


class SEOKeywordCreate(BaseModel):
    keyword: str
    target_location: Optional[str] = None
    search_volume: Optional[str] = "500 / mo"
    difficulty: Optional[str] = "Medium"
    intent: Optional[str] = "Local Intent"
    current_rank: Optional[int] = None


class SEOKeywordResponse(BaseModel):
    id: str
    business_id: str
    keyword: str
    target_location: Optional[str] = None
    current_rank: Optional[int] = None
    previous_rank: Optional[int] = None
    search_volume: Optional[str] = "500 / mo"
    difficulty: Optional[str] = "Medium"
    intent: Optional[str] = "Local Intent"
    is_tracked: bool = True
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class SEOAuditResponse(BaseModel):
    id: str
    business_id: str
    overall_seo_score: int
    map_pack_score: int
    keyword_score: int
    citation_score: int
    missing_attributes: List[str] = Field(default_factory=list)
    actionable_recommendations: List[str] = Field(default_factory=list)
    competitor_insights: List[str] = Field(default_factory=list)
    created_at: datetime

    class Config:
        from_attributes = True


class SEODiscoverKeywordsRequest(BaseModel):
    target_services: Optional[List[str]] = None


class SEOBatchKeywordsRequest(BaseModel):
    keywords: List[str]


class SEOGbpOptimizationResponse(BaseModel):
    optimized_title: str
    optimized_description: str
    primary_category: str
    secondary_categories: List[str] = Field(default_factory=list)
    recommended_attributes: List[str] = Field(default_factory=list)
