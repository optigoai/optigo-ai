from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field, model_validator


class AudienceSegment(BaseModel):
    segment_name: str
    description: str
    key_pain_points: List[str] = Field(default_factory=list)


class ServicePositioning(BaseModel):
    service_name: str
    unique_selling_prop: str
    target_intent: str


class AIBusinessProfileOutput(BaseModel):
    business_summary: str = Field("Comprehensive summary of the business and value proposition")
    industry_category: str = Field("Local Business", description="Refined primary industry category")
    target_audience_segments: List[AudienceSegment] = Field(default_factory=list)
    key_service_positioning: List[ServicePositioning] = Field(default_factory=list)
    brand_tone: str = Field("Professional & Welcoming", description="Recommended tone of voice for marketing")
    initial_growth_areas: List[str] = Field(default_factory=list)

    @model_validator(mode="before")
    @classmethod
    def normalize_profile_output(cls, data: Any) -> Any:
        if isinstance(data, dict):
            if "initial_growth_areas" in data and isinstance(data["initial_growth_areas"], list):
                norm_areas = []
                for item in data["initial_growth_areas"]:
                    if isinstance(item, dict):
                        norm_areas.append(item.get("opportunity") or item.get("area") or item.get("title") or str(item))
                    elif isinstance(item, str):
                        norm_areas.append(item)
                data["initial_growth_areas"] = norm_areas
        return data


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
    title: str = Field("Strategic Opportunity")
    explanation: str = Field("Actionable marketing advice from your AI CMO")
    reason: str = Field("Identified from business analysis")
    priority: str = Field("important", description="urgent, important, opportunity")
    impact: str = Field("High", description="Estimated business return or metric increase")
    effort: str = Field("Low (5 mins)", description="Effort required: Low, Medium, High")
    suggested_action: str = Field("Implement recommended steps")
    related_feature: Optional[str] = Field("reviews", description="reviews, campaigns, posts, seo")

    @model_validator(mode="before")
    @classmethod
    def normalize_recommendation_item(cls, data: Any) -> Any:
        if isinstance(data, dict):
            if "title" not in data or not data["title"]:
                data["title"] = data.get("headline") or data.get("action_title") or "Strategic Opportunity"
            if "explanation" not in data or not data["explanation"]:
                data["explanation"] = data.get("description") or data.get("details") or data.get("advice") or ""
            if "reason" not in data or not data["reason"]:
                data["reason"] = data.get("why") or data.get("justification") or "Identified from your business performance data"
            if "suggested_action" not in data or not data["suggested_action"]:
                data["suggested_action"] = data.get("action") or data.get("how_to_implement") or "Take immediate action"
            if "priority" in data and isinstance(data["priority"], str):
                p = data["priority"].lower()
                if "urgent" in p or "high" in p:
                    data["priority"] = "urgent"
                elif "opp" in p or "low" in p:
                    data["priority"] = "opportunity"
                else:
                    data["priority"] = "important"
        return data


class AICMORecommendationsOutput(BaseModel):
    recommendations: List[AIRecommendationItem] = Field(default_factory=list)
    cmo_note: str = Field("Here is your prioritized marketing battle plan for this week.", description="Personalized strategic note from the AI CMO")

    @model_validator(mode="before")
    @classmethod
    def normalize_cmo_output(cls, data: Any) -> Any:
        if isinstance(data, dict):
            if "cmo_note" not in data or not data["cmo_note"]:
                data["cmo_note"] = data.get("note") or data.get("advice") or data.get("summary") or "Here is your prioritized battle plan."
            if "recommendations" not in data:
                data["recommendations"] = data.get("actions") or data.get("items") or []
        return data


class AIGeneratedPostItem(BaseModel):
    channel: str = Field("google_post", description="google_post, instagram, facebook, linkedin, twitter")
    title: Optional[str] = Field(None, description="Catchy headline or subject line")
    body: str = Field(..., description="Channel-optimized body content with engaging copy")
    hashtags: Optional[str] = Field(None, description="Relevant high-reach hashtags separated by spaces")
    call_to_action: Optional[str] = Field(None, description="Clear, compelling call to action")
    image_prompt: Optional[str] = Field(None, description="DALL-E / Imagen prompt for marketing visual")
    best_time_to_post: Optional[str] = Field(None, description="Recommended time e.g., 'Tuesday at 11:00 AM'")

    @model_validator(mode="before")
    @classmethod
    def normalize_post_item(cls, data: Any) -> Any:
        if isinstance(data, dict):
            # Resolve body from aliases
            if "body" not in data or not data["body"]:
                data["body"] = (
                    data.get("post_content")
                    or data.get("caption")
                    or data.get("content")
                    or data.get("text")
                    or data.get("copy")
                    or data.get("post_body")
                    or data.get("message")
                    or ""
                )
            if "hashtags" in data and isinstance(data["hashtags"], list):
                data["hashtags"] = " ".join(
                    f"#{tag.lstrip('#')}" for tag in data["hashtags"] if isinstance(tag, str)
                )
            if "title" not in data or not data["title"]:
                data["title"] = data.get("headline") or data.get("subject") or data.get("topic")
            cta_val = data.get("call_to_action") or data.get("cta") or data.get("callToAction") or data.get("marketing_objective")
            if isinstance(cta_val, dict):
                data["call_to_action"] = cta_val.get("text") or cta_val.get("label") or cta_val.get("type") or cta_val.get("action") or str(cta_val)
            elif isinstance(cta_val, str):
                data["call_to_action"] = cta_val
            else:
                data["call_to_action"] = None

            if "best_time_to_post" not in data or isinstance(data.get("best_time_to_post"), dict):
                data["best_time_to_post"] = str(data.get("schedule") or data.get("recommended_time") or data.get("timing") or "")
        return data


class AIContentGenerationOutput(BaseModel):
    campaign_theme: str = Field("Multi-Channel Promotional Campaign", description="Unifying creative marketing angle or theme")
    posts: List[AIGeneratedPostItem] = Field(default_factory=list)
    calendar_suggestions: List[Dict[str, Any]] = Field(default_factory=list, description="Suggested schedule dates and post ideas")

    @model_validator(mode="before")
    @classmethod
    def normalize_content_output(cls, data: Any) -> Any:
        if isinstance(data, dict):
            if "campaign_theme" not in data or not data["campaign_theme"]:
                meta = data.get("meta") or data.get("metadata") or {}
                if isinstance(meta, dict):
                    data["campaign_theme"] = meta.get("campaign_theme") or meta.get("theme") or "Multi-Channel Campaign"
                else:
                    data["campaign_theme"] = data.get("theme") or data.get("title") or "Multi-Channel Campaign"
            raw_posts = data.get("posts") or data.get("social_posts") or data.get("variations") or data.get("content") or []
            if isinstance(raw_posts, dict):
                formatted_list = []
                for channel_key, post_data in raw_posts.items():
                    if isinstance(post_data, dict):
                        post_dict = dict(post_data)
                        if "channel" not in post_dict:
                            post_dict["channel"] = channel_key
                        formatted_list.append(post_dict)
                    elif isinstance(post_data, str):
                        formatted_list.append({"channel": channel_key, "body": post_data})
                data["posts"] = formatted_list
            elif isinstance(raw_posts, list):
                data["posts"] = raw_posts
            else:
                data["posts"] = []
        return data


class AIReviewReplyOutput(BaseModel):
    reply_text: str = Field(..., description="Customized response to customer review")
    sentiment_detected: str = Field("neutral", description="positive, neutral, negative")
    key_points_addressed: List[str] = Field(default_factory=list)

    @model_validator(mode="before")
    @classmethod
    def normalize_reply_output(cls, data: Any) -> Any:
        if isinstance(data, dict):
            if "reply_text" not in data or not data["reply_text"]:
                data["reply_text"] = data.get("reply") or data.get("response") or data.get("message") or ""
            if "sentiment_detected" not in data:
                data["sentiment_detected"] = data.get("sentiment") or "neutral"
        return data
