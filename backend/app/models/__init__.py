# ==================================================
# OptigoAI Backend — Models Package
# ==================================================
"""
Central model registry. Import all models here so
Alembic can discover them for migration generation.
"""

from app.models.organization import Organization
from app.models.user import User, UserRole
from app.models.business import Business
from app.models.review import Review, ReviewSentiment
from app.models.recommendation import (
    Recommendation,
    RecommendationPriority,
    RecommendationStatus,
)
from app.models.content import Content, ContentType, ContentStatus
from app.models.campaign import Campaign, CampaignStatus
from app.models.competitor import Competitor
from app.models.seo import SEOAnalysis
from app.models.creative import Creative, CreativeStatus
from app.models.notification import Notification, NotificationType
from app.models.analytics import BusinessAnalytics
from app.models.ai_log import AIRequestLog
from app.models.feature_toggle import FeatureToggle

__all__ = [
    "Organization",
    "User",
    "UserRole",
    "Business",
    "Review",
    "ReviewSentiment",
    "Recommendation",
    "RecommendationPriority",
    "RecommendationStatus",
    "Content",
    "ContentType",
    "ContentStatus",
    "Campaign",
    "CampaignStatus",
    "Competitor",
    "SEOAnalysis",
    "Creative",
    "CreativeStatus",
    "Notification",
    "NotificationType",
    "BusinessAnalytics",
    "AIRequestLog",
    "FeatureToggle",
]
