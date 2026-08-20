from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field


class AudienceSegment(BaseModel):
    segment_name: str
    description: str
    key_pain_points: List[str]


class ServicePositioning(BaseModel):
    service_name: str
    unique_selling_prop: str
    target_intent: str


class AIBusinessProfileOutput(BaseModel):
    business_summary: str = Field(..., description="Comprehensive summary of the business and value proposition")
    industry_category: str = Field(..., description="Refined primary industry category")
    target_audience_segments: List[AudienceSegment] = Field(default_factory=list)
    key_service_positioning: List[ServicePositioning] = Field(default_factory=list)
    brand_tone: str = Field(..., description="Recommended tone of voice for marketing")
    initial_growth_areas: List[str] = Field(default_factory=list)


class BusinessProblem(BaseModel):
    title: str
    severity: str = Field("medium", description="critical, high, medium, low")
    explanation: str
    impact: str


class BusinessOpportunity(BaseModel):
    title: str
    priority: str = Field("medium", description="high, medium, low")
    potential_impact: str
    suggested_action: str


class AIBusinessIntelligenceOutput(BaseModel):
    health_score: int = Field(..., ge=0, le=100, description="Overall business health score from 0 to 100")
    health_summary: str = Field(..., description="Executive summary of the business's current marketing health")
    reputation_score: int = Field(..., ge=0, le=100)
    visibility_score: int = Field(..., ge=0, le=100)
    customer_sentiment_summary: str
    top_problems: List[BusinessProblem] = Field(default_factory=list)
    top_opportunities: List[BusinessOpportunity] = Field(default_factory=list)
    strategic_advice: str
