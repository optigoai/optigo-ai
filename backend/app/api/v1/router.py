# ==================================================
# OptigoAI Backend — API v1 Router
# ==================================================

from fastapi import APIRouter

from app.api.v1.endpoints import (
    health,
    auth,
    businesses,
    reviews,
    recommendations,
    contents,
    seo,
    campaigns,
    creatives,
    cmo,
    analytics,
    notifications,
    gsc,
    admin,
    features,
)

api_router = APIRouter(prefix="/api/v1")

# Health check (public)
api_router.include_router(health.router)

# Authentication & Users
api_router.include_router(auth.router, prefix="/auth", tags=["Authentication"])

# Businesses & Onboarding
api_router.include_router(businesses.router, prefix="/businesses", tags=["Businesses"])

# Reviews & Reputation
api_router.include_router(reviews.router, prefix="/reviews", tags=["Reviews"])

# AI CMO Recommendations
api_router.include_router(recommendations.router, prefix="/recommendations", tags=["Recommendations"])

# AI Content Engine & Social Posts
api_router.include_router(contents.router)

# SEO & Visibility Optimizer
api_router.include_router(seo.router)

# Phase 8: Multi-Channel Marketing Campaigns
api_router.include_router(campaigns.router)

# Phase 9: Smart Creatives & Promo Engine
api_router.include_router(creatives.router)

# Phase 10: Conversational AI CMO Chat
api_router.include_router(cmo.router)

# Phase 11: ROI Analytics & Real-Time Performance
api_router.include_router(analytics.router)

# Phase 12: Notifications & Proactive Intelligence
api_router.include_router(notifications.router)

# External Integrations: Google Search Console
api_router.include_router(gsc.router)

# Phase 12: Internal Admin Portal APIs
api_router.include_router(admin.router, prefix="/admin", tags=["Admin"])

# Phase 12: Dynamic Client Feature Flags
api_router.include_router(features.router, prefix="/features", tags=["Features"])

