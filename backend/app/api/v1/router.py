# ==================================================
# OptigoAI Backend — API v1 Router
# ==================================================

from fastapi import APIRouter

from app.api.v1.endpoints import health, auth, businesses, reviews

api_router = APIRouter(prefix="/api/v1")

# Health check (public)
api_router.include_router(health.router)

# Authentication & Users
api_router.include_router(auth.router, prefix="/auth", tags=["Authentication"])

# Businesses & Onboarding
api_router.include_router(businesses.router, prefix="/businesses", tags=["Businesses"])

# Reviews & Reputation
api_router.include_router(reviews.router, prefix="/reviews", tags=["Reviews"])
# api_router.include_router(seo.router, prefix="/seo", tags=["SEO"])
# api_router.include_router(competitors.router, prefix="/competitors", tags=["Competitors"])
# api_router.include_router(recommendations.router, prefix="/recommendations", tags=["Recommendations"])
# api_router.include_router(content.router, prefix="/content", tags=["Content"])
# api_router.include_router(campaigns.router, prefix="/campaigns", tags=["Campaigns"])
# api_router.include_router(creatives.router, prefix="/creatives", tags=["Creatives"])
# api_router.include_router(chat.router, prefix="/chat", tags=["AI Chat"])
# api_router.include_router(analytics.router, prefix="/analytics", tags=["Analytics"])
# api_router.include_router(notifications.router, prefix="/notifications", tags=["Notifications"])
# api_router.include_router(admin.router, prefix="/admin", tags=["Admin"])
