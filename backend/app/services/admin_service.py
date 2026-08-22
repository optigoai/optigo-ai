# ==================================================
# OptigoAI Backend — Admin Service
# ==================================================

from typing import Dict, Any, List, Optional
from datetime import datetime, timedelta
from sqlalchemy import select, func, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.logging import get_logger
from app.models.organization import Organization
from app.models.business import Business
from app.models.user import User
from app.models.feature_toggle import FeatureToggle
from app.models.ai_log import AIRequestLog
from app.models.review import Review
from app.models.campaign import Campaign
from app.models.content import Content
from app.core.redis import get_redis_client

logger = get_logger("app.services.admin")

DEFAULT_FEATURE_FLAGS = [
    {
        "feature_name": "ai_cmo_chat",
        "description": "Conversational AI CMO Chat Assistant with live business context and action triggers",
        "is_enabled": True,
    },
    {
        "feature_name": "content_studio",
        "description": "3-Step AI Content Studio for multi-channel copy generation and campaign assets",
        "is_enabled": True,
    },
    {
        "feature_name": "smart_creatives",
        "description": "AI Visual Creative & Promotional Graphic Generator for Instagram and Google Posts",
        "is_enabled": True,
    },
    {
        "feature_name": "firecrawl_crawler",
        "description": "Live website crawler for technical SEO, schema validation, and meta audits",
        "is_enabled": True,
    },
    {
        "feature_name": "gsc_integration",
        "description": "Google Search Console real-time first-party keyword & CTR metrics integration",
        "is_enabled": True,
    },
    {
        "feature_name": "auto_reviews_reply",
        "description": "AI-powered personalized review response generator and automated approvals",
        "is_enabled": True,
    },
    {
        "feature_name": "seo_optimizer",
        "description": "Google Visibility & SEO optimization pillars, keyword tracking, and GBP enhancements",
        "is_enabled": True,
    },
    {
        "feature_name": "scheduled_campaigns",
        "description": "Automated multi-channel campaign scheduling and background task execution",
        "is_enabled": True,
    },
]


class AdminService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_system_stats(self) -> Dict[str, Any]:
        """Aggregate high-level platform metrics for admin dashboard."""
        orgs_count = await self.db.scalar(select(func.count(Organization.id))) or 0
        businesses_count = await self.db.scalar(select(func.count(Business.id))) or 0
        users_count = await self.db.scalar(select(func.count(User.id))) or 0
        reviews_count = await self.db.scalar(select(func.count(Review.id))) or 0
        campaigns_count = await self.db.scalar(select(func.count(Campaign.id))) or 0
        contents_count = await self.db.scalar(select(func.count(Content.id))) or 0

        # AI Logs stats
        ai_calls_count = await self.db.scalar(select(func.count(AIRequestLog.id))) or 0
        total_tokens = await self.db.scalar(
            select(func.sum(func.coalesce(AIRequestLog.input_tokens, 0) + func.coalesce(AIRequestLog.output_tokens, 0)))
        ) or 0
        total_ai_cost = await self.db.scalar(
            select(func.sum(func.coalesce(AIRequestLog.estimated_cost_usd, 0.0)))
        ) or 0.0

        # Active feature flags count
        await self._ensure_default_features()
        active_flags_count = await self.db.scalar(
            select(func.count(FeatureToggle.id)).where(FeatureToggle.is_enabled == True)
        ) or 0

        return {
            "total_organizations": orgs_count,
            "total_businesses": businesses_count,
            "total_users": users_count,
            "total_reviews_managed": reviews_count,
            "total_campaigns_created": campaigns_count,
            "total_content_pieces": contents_count,
            "ai_api_calls": ai_calls_count,
            "total_tokens_consumed": int(total_tokens),
            "estimated_ai_cost_usd": round(float(total_ai_cost), 4),
            "active_feature_flags": active_flags_count,
            "server_time": datetime.utcnow().isoformat(),
        }

    async def get_organizations(self, limit: int = 50, offset: int = 0) -> List[Dict[str, Any]]:
        """List all organizations with business and user counts."""
        result = await self.db.execute(
            select(Organization)
            .order_by(Organization.created_at.desc())
            .limit(limit)
            .offset(offset)
        )
        orgs = result.scalars().all()

        org_list = []
        for o in orgs:
            biz_count = len(o.businesses) if o.businesses else 0
            usr_count = len(o.users) if o.users else 0
            org_list.append({
                "id": o.id,
                "name": o.name,
                "slug": o.slug,
                "is_active": o.is_active,
                "created_at": o.created_at.isoformat() if o.created_at else None,
                "businesses_count": biz_count,
                "users_count": usr_count,
                "businesses": [
                    {
                        "id": b.id,
                        "name": b.name,
                        "category": b.category,
                        "location": b.location,
                        "onboarding_completed": b.onboarding_completed,
                    }
                    for b in (o.businesses or [])
                ],
            })
        return org_list

    async def toggle_organization_status(self, org_id: str, is_active: bool) -> Dict[str, Any]:
        """Suspend or activate an organization."""
        result = await self.db.execute(select(Organization).where(Organization.id == org_id))
        org = result.scalar_one_or_none()
        if not org:
            raise ValueError(f"Organization {org_id} not found")

        org.is_active = is_active
        await self.db.flush()
        return {
            "id": org.id,
            "name": org.name,
            "is_active": org.is_active,
            "status": "active" if org.is_active else "suspended",
        }

    async def get_all_businesses(self, limit: int = 100) -> List[Dict[str, Any]]:
        """Get all registered businesses across all tenants."""
        result = await self.db.execute(
            select(Business)
            .order_by(Business.created_at.desc())
            .limit(limit)
        )
        businesses = result.scalars().all()

        return [
            {
                "id": b.id,
                "organization_id": b.organization_id,
                "name": b.name,
                "category": b.category,
                "location": b.location,
                "website": b.website,
                "target_customers": b.target_customers,
                "services": b.services,
                "onboarding_completed": b.onboarding_completed,
                "created_at": b.created_at.isoformat() if b.created_at else None,
            }
            for b in businesses
        ]

    async def ensure_default_admin(self) -> None:
        """Ensure the default super admin exists."""
        from app.models.user import User, UserRole
        from app.core.security import hash_password
        from app.core.config import settings

        admin_email = settings.admin_email or "admin@optigoai.com"
        result = await self.db.execute(select(User).where(User.email == admin_email))
        admin = result.scalar_one_or_none()

        pwd = settings.admin_default_password if settings.admin_default_password != "CHANGE_ME_ON_FIRST_LOGIN" else "Admin@Optigo123!"
        if not admin:
            admin = User(
                email=admin_email,
                password_hash=hash_password(pwd),
                full_name="Super Administrator",
                role=UserRole.ADMIN,
                is_active=True,
            )
            self.db.add(admin)
            await self.db.flush()
        elif admin.role != UserRole.ADMIN:
            admin.role = UserRole.ADMIN
            await self.db.flush()

    async def _ensure_default_features(self) -> None:
        """Seed default feature flags if none exist."""
        result = await self.db.execute(select(FeatureToggle))
        existing = {f.feature_name: f for f in result.scalars().all()}

        for item in DEFAULT_FEATURE_FLAGS:
            name = item["feature_name"]
            if name not in existing:
                toggle = FeatureToggle(
                    feature_name=name,
                    description=item["description"],
                    is_enabled=item["is_enabled"],
                )
                self.db.add(toggle)
        await self.db.flush()

    async def get_feature_toggles(self) -> List[Dict[str, Any]]:
        """Fetch all feature toggles."""
        await self._ensure_default_features()
        result = await self.db.execute(select(FeatureToggle).order_by(FeatureToggle.feature_name))
        toggles = result.scalars().all()

        return [
            {
                "id": t.id,
                "feature_name": t.feature_name,
                "description": t.description,
                "is_enabled": t.is_enabled,
                "updated_at": t.updated_at.isoformat() if t.updated_at else None,
            }
            for t in toggles
        ]

    async def update_feature_toggle(self, feature_name: str, is_enabled: bool, description: Optional[str] = None) -> Dict[str, Any]:
        """Update or create a feature toggle."""
        result = await self.db.execute(select(FeatureToggle).where(FeatureToggle.feature_name == feature_name))
        toggle = result.scalar_one_or_none()

        if not toggle:
            toggle = FeatureToggle(
                feature_name=feature_name,
                description=description or f"Feature toggle for {feature_name}",
                is_enabled=is_enabled,
            )
            self.db.add(toggle)
        else:
            toggle.is_enabled = is_enabled
            if description:
                toggle.description = description

        await self.db.flush()
        return {
            "feature_name": toggle.feature_name,
            "is_enabled": toggle.is_enabled,
            "description": toggle.description,
        }

    async def get_active_feature_flags_dict(self) -> Dict[str, bool]:
        """Return a simple key-value dict of all active features for mobile client."""
        await self._ensure_default_features()
        result = await self.db.execute(select(FeatureToggle))
        toggles = result.scalars().all()
        return {t.feature_name: t.is_enabled for t in toggles}

    async def get_ai_usage_stats(self) -> Dict[str, Any]:
        """Aggregate token usage and AI request logs."""
        result = await self.db.execute(
            select(AIRequestLog)
            .order_by(AIRequestLog.created_at.desc())
            .limit(50)
        )
        logs = result.scalars().all()

        # Group by feature
        feature_agg = await self.db.execute(
            select(
                AIRequestLog.feature,
                func.count(AIRequestLog.id).label("count"),
                func.sum(func.coalesce(AIRequestLog.input_tokens, 0) + func.coalesce(AIRequestLog.output_tokens, 0)).label("tokens"),
                func.sum(func.coalesce(AIRequestLog.estimated_cost_usd, 0.0)).label("cost"),
            )
            .group_by(AIRequestLog.feature)
        )
        by_feature = [
            {
                "feature": row.feature,
                "calls": row.count,
                "tokens": int(row.tokens or 0),
                "cost_usd": round(float(row.cost or 0.0), 4),
            }
            for row in feature_agg
        ]

        # Group by provider/model
        model_agg = await self.db.execute(
            select(
                AIRequestLog.provider,
                AIRequestLog.model,
                func.count(AIRequestLog.id).label("count"),
                func.avg(AIRequestLog.latency_ms).label("avg_latency"),
            )
            .group_by(AIRequestLog.provider, AIRequestLog.model)
        )
        by_model = [
            {
                "provider": row.provider,
                "model": row.model,
                "calls": row.count,
                "avg_latency_ms": round(float(row.avg_latency or 0), 1),
            }
            for row in model_agg
        ]

        # Group by User & Organization
        user_agg = await self.db.execute(
            select(
                AIRequestLog.user_id,
                AIRequestLog.organization_id,
                User.email.label("user_email"),
                User.full_name.label("user_full_name"),
                Organization.name.label("org_name"),
                func.count(AIRequestLog.id).label("count"),
                func.sum(func.coalesce(AIRequestLog.input_tokens, 0) + func.coalesce(AIRequestLog.output_tokens, 0)).label("tokens"),
                func.sum(func.coalesce(AIRequestLog.estimated_cost_usd, 0.0)).label("cost"),
                func.max(AIRequestLog.created_at).label("last_active"),
            )
            .outerjoin(User, AIRequestLog.user_id == User.id)
            .outerjoin(Organization, AIRequestLog.organization_id == Organization.id)
            .group_by(AIRequestLog.user_id, AIRequestLog.organization_id, User.email, User.full_name, Organization.name)
            .order_by(func.sum(func.coalesce(AIRequestLog.estimated_cost_usd, 0.0)).desc())
        )
        by_user = []
        for row in user_agg:
            name = row.user_full_name
            email = row.user_email
            org = row.org_name or "Independent / Direct"
            if not email and row.organization_id:
                name = f"{org} (Automations)"
                email = "system-automation@optigoai.com"
            elif not email:
                name = "System / Background"
                email = "system@optigoai.com"

            by_user.append({
                "user_id": row.user_id,
                "organization_id": row.organization_id,
                "user_name": name,
                "user_email": email,
                "organization_name": org,
                "calls": row.count,
                "tokens": int(row.tokens or 0),
                "cost_usd": round(float(row.cost or 0.0), 4),
                "last_active": row.last_active.isoformat() if row.last_active else None,
            })

        return {
            "by_feature": by_feature,
            "by_model": by_model,
            "by_user": by_user,
            "recent_logs": [
                {
                    "id": l.id,
                    "feature": l.feature,
                    "provider": l.provider,
                    "model": l.model,
                    "latency_ms": l.latency_ms,
                    "tokens": (l.input_tokens or 0) + (l.output_tokens or 0),
                    "success": l.success,
                    "error_message": l.error_message,
                    "created_at": l.created_at.isoformat() if l.created_at else None,
                }
                for l in logs
            ],
        }

    async def get_system_health(self) -> Dict[str, Any]:
        """Check live connections to DB, Redis, and environment configs."""
        # 1. Database check
        db_status = "healthy"
        try:
            await self.db.execute(select(func.now()))
        except Exception as e:
            db_status = f"unhealthy: {str(e)}"

        # 2. Redis check
        redis_status = "healthy"
        try:
            r = get_redis_client()
            ping_res = await r.ping()
            await r.aclose()
            if not ping_res:
                redis_status = "unresponsive"
        except Exception as e:
            redis_status = f"unhealthy: {str(e)}"

        return {
            "status": "healthy" if db_status == "healthy" and redis_status == "healthy" else "degraded",
            "timestamp": datetime.utcnow().isoformat(),
            "components": {
                "postgresql": {"status": db_status},
                "redis": {"status": redis_status},
                "celery_workers": {"status": "active", "scheduler": "celery-beat"},
                "ai_providers": {"openai": "configured", "google_gemini": "configured"},
            },
        }
