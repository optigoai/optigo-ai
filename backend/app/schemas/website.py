# ==================================================
# OptigoAI Backend — Business Website Schemas
# ==================================================

from datetime import datetime
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field


class HeroSection(BaseModel):
    headline: str
    subheadline: str
    badge: Optional[str] = "Official Business Page"
    primary_cta_text: Optional[str] = "Book Now / Visit Us"
    primary_cta_action: Optional[str] = "directions"  # "call", "directions", "website", "whatsapp"
    secondary_cta_text: Optional[str] = "Call Directly"
    secondary_cta_action: Optional[str] = "call"
    hero_image_url: Optional[str] = None


class AboutSection(BaseModel):
    title: str = "About Our Business"
    story: str
    highlights: List[str] = Field(default_factory=list)
    image_url: Optional[str] = None


class ServiceItem(BaseModel):
    name: str
    description: str
    price_range: Optional[str] = None
    badge: Optional[str] = None
    icon: Optional[str] = "Star"


class WhyChooseUsItem(BaseModel):
    title: str
    description: str
    icon: Optional[str] = "CheckCircle"


class PublicReviewItem(BaseModel):
    author_name: str
    rating: int
    text: str
    review_date: Optional[str] = None


class ReviewsSection(BaseModel):
    title: str = "Verified Customer Reviews"
    average_rating: float = 4.8
    total_reviews: int = 0
    featured_reviews: List[PublicReviewItem] = Field(default_factory=list)


class HoursLocationSection(BaseModel):
    address: str
    city: str
    phone: Optional[str] = None
    email: Optional[str] = None
    maps_query: Optional[str] = None
    opening_hours: List[str] = Field(default_factory=list)


class FAQItem(BaseModel):
    question: str
    answer: str


class CTABannerSection(BaseModel):
    title: str
    description: str
    button_text: str = "Contact & Directions"
    button_action: str = "directions"


class ThemeConfig(BaseModel):
    accent_color: str = "#0284C7"
    dark_mode: bool = False
    font_family: str = "Plus Jakarta Sans"


class WebsiteContentSchema(BaseModel):
    theme_config: Optional[ThemeConfig] = Field(default_factory=ThemeConfig)
    hero: HeroSection
    about: AboutSection
    services: List[ServiceItem] = Field(default_factory=list)
    why_choose_us: List[WhyChooseUsItem] = Field(default_factory=list)
    reviews: ReviewsSection
    gallery: List[str] = Field(default_factory=list)
    hours_location: HoursLocationSection
    faqs: List[FAQItem] = Field(default_factory=list)
    cta_banner: CTABannerSection


class WebsiteUpdateRequest(BaseModel):
    slug: Optional[str] = Field(None, min_length=2, max_length=255)
    seo_title: Optional[str] = Field(None, max_length=255)
    seo_description: Optional[str] = None
    content_json: Optional[Dict[str, Any]] = None
    custom_html: Optional[str] = None
    custom_css: Optional[str] = None
    custom_js: Optional[str] = None


class WebsiteStatusUpdateRequest(BaseModel):
    status: str = Field(..., pattern="^(draft|published|unpublished)$")


class WebsiteResponse(BaseModel):
    id: str
    business_id: str
    organization_id: str
    slug: str
    status: str
    seo_title: Optional[str] = None
    seo_description: Optional[str] = None
    content_json: Dict[str, Any]
    custom_html: Optional[str] = None
    custom_css: Optional[str] = None
    custom_js: Optional[str] = None
    view_count: int = 0
    published_at: Optional[datetime] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    model_config = {"from_attributes": True}


class PublicWebsiteResponse(BaseModel):
    """Sanitized public-safe website payload for public visitors and search engine crawlers."""
    id: str
    business_name: str
    category: str
    location: str
    phone: Optional[str] = None
    website_url: Optional[str] = None
    slug: str
    seo_title: str
    seo_description: str
    content: Dict[str, Any]
    custom_html: Optional[str] = None
    custom_css: Optional[str] = None
    custom_js: Optional[str] = None
    published_at: Optional[datetime] = None
    canonical_url: str
    schema_org_json: Dict[str, Any]
