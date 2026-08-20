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


class AIRecommendationItem(BaseModel):
    title: str
    explanation: str
    reason: str
    priority: str = Field("important", description="urgent, important, opportunity")
    impact: str = Field("High", description="Estimated business return or metric increase")
    effort: str = Field("Low (5 mins)", description="Effort required: Low, Medium, High")
    suggested_action: str
    related_feature: Optional[str] = Field("reviews", description="reviews, campaigns, posts, seo")


class AICMORecommendationsOutput(BaseModel):
    recommendations: List[AIRecommendationItem] = Field(default_factory=list)
    cmo_note: str = Field(..., description="Personalized strategic note from the AI CMO")


class AIGeneratedPostItem(BaseModel):
    channel: str = Field(..., description="google_post, instagram, facebook, linkedin, twitter")
    title: Optional[str] = Field(None, description="Catchy headline or subject line")
    body: str = Field(..., description="Channel-optimized body content with engaging copy")
    hashtags: Optional[str] = Field(None, description="Relevant high-reach hashtags separated by spaces")
    call_to_action: Optional[str] = Field(None, description="Clear, compelling call to action")
    image_prompt: Optional[str] = Field(None, description="DALL-E / Imagen prompt for marketing visual")
    best_time_to_post: Optional[str] = Field(None, description="Recommended time e.g., 'Tuesday at 11:00 AM'")


class AIContentGenerationOutput(BaseModel):
    campaign_theme: str = Field(..., description="Unifying creative marketing angle or theme")
    posts: List[AIGeneratedPostItem] = Field(default_factory=list)
    calendar_suggestions: List[Dict[str, Any]] = Field(default_factory=list, description="Suggested schedule dates and post ideas")
