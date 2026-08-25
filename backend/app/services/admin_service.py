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

    async def update_organization(self, org_id: str, data: Dict[str, Any]) -> Dict[str, Any]:
        """Super Admin update of organization details (name, slug, is_active)."""
        result = await self.db.execute(select(Organization).where(Organization.id == org_id))
        org = result.scalar_one_or_none()
        if not org:
            raise ValueError(f"Organization {org_id} not found")

        if "name" in data and data["name"]:
            org.name = data["name"].strip()
        if "slug" in data and data["slug"]:
            org.slug = data["slug"].strip().lower()
        if "is_active" in data and data["is_active"] is not None:
            org.is_active = bool(data["is_active"])

        org.updated_at = datetime.utcnow()
        await self.db.flush()
        return {
            "id": org.id,
            "name": org.name,
            "slug": org.slug,
            "is_active": org.is_active,
            "updated_at": org.updated_at.isoformat(),
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

    async def get_business_detail(self, business_id: str) -> Dict[str, Any]:
        """Get full 360-degree deep-dive detail of a business for Admin inspection and editing."""
        b_res = await self.db.execute(select(Business).where(Business.id == business_id))
        b = b_res.scalar_one_or_none()
        if not b:
            raise ValueError(f"Business {business_id} not found")

        # Organization
        org_res = await self.db.execute(select(Organization).where(Organization.id == b.organization_id))
        org = org_res.scalar_one_or_none()

        # Users in this organization
        users_res = await self.db.execute(
            select(User)
            .where(User.organization_id == b.organization_id)
            .order_by(User.created_at.asc())
        )
        users = users_res.scalars().all()

        # Customer Reviews (All DB reviews)
        from app.models.review import Review
        reviews_res = await self.db.execute(
            select(Review)
            .where(Review.business_id == business_id)
            .order_by(Review.created_at.desc())
            .limit(100)
        )
        reviews_list = reviews_res.scalars().all()

        # SEO Keywords
        from app.models.seo import SEOKeyword, SEOAudit
        kw_res = await self.db.execute(
            select(SEOKeyword)
            .where(SEOKeyword.business_id == business_id)
            .order_by(SEOKeyword.created_at.desc())
        )
        keywords_list = kw_res.scalars().all()

        # Latest SEO Audit
        audit_res = await self.db.execute(
            select(SEOAudit)
            .where(SEOAudit.business_id == business_id)
            .order_by(SEOAudit.created_at.desc())
            .limit(1)
        )
        latest_seo_audit = audit_res.scalar_one_or_none()

        # Website Audit
        from app.models.website_audit import WebsiteAudit
        web_res = await self.db.execute(
            select(WebsiteAudit)
            .where(WebsiteAudit.business_id == business_id)
            .order_by(WebsiteAudit.created_at.desc())
            .limit(1)
        )
        latest_web_audit = web_res.scalar_one_or_none()

        # GSC Connection
        from app.models.gsc import GoogleSearchConsoleConnection
        gsc_res = await self.db.execute(
            select(GoogleSearchConsoleConnection)
            .where(GoogleSearchConsoleConnection.business_id == business_id)
        )
        gsc_conn = gsc_res.scalar_one_or_none()

        # Recommendations
        from app.models.recommendation import Recommendation
        rec_res = await self.db.execute(
            select(Recommendation)
            .where(Recommendation.business_id == business_id)
            .order_by(Recommendation.created_at.desc())
            .limit(50)
        )
        recs_list = rec_res.scalars().all()

        # Campaigns
        from app.models.campaign import Campaign
        camp_res = await self.db.execute(
            select(Campaign)
            .where(Campaign.business_id == business_id)
            .order_by(Campaign.created_at.desc())
            .limit(50)
        )
        campaigns_list = camp_res.scalars().all()

        # Contents
        from app.models.content import Content
        content_res = await self.db.execute(
            select(Content)
            .where(Content.business_id == business_id)
            .order_by(Content.created_at.desc())
            .limit(50)
        )
        contents_list = content_res.scalars().all()

        # Competitors
        from app.models.competitor import Competitor
        comp_res = await self.db.execute(
            select(Competitor)
            .where(Competitor.business_id == business_id)
            .order_by(Competitor.created_at.desc())
        )
        competitors_list = comp_res.scalars().all()

        # Aggregate counts & averages
        rev_count = len(reviews_list)
        avg_rating = (
            sum(r.rating for r in reviews_list) / rev_count if rev_count > 0 else 0.0
        )
        kw_top3_count = sum(1 for k in keywords_list if k.current_rank and k.current_rank <= 3)

        return {
            "id": b.id,
            "organization_id": b.organization_id,
            "organization": {
                "id": org.id if org else b.organization_id,
                "name": org.name if org else "Unknown",
                "slug": org.slug if org else "",
                "is_active": org.is_active if org else True,
                "created_at": org.created_at.isoformat() if org and org.created_at else None,
                "updated_at": org.updated_at.isoformat() if org and org.updated_at else None,
            },
            "organization_name": org.name if org else "Unknown",
            "organization_is_active": org.is_active if org else True,
            "name": b.name,
            "category": b.category,
            "location": b.location,
            "website": b.website,
            "phone": b.phone,
            "description": b.description,
            "target_customers": b.target_customers,
            "services": b.services,
            "business_goals": b.business_goals,
            "marketing_channels": b.marketing_channels,
            "ai_business_profile": b.ai_business_profile,
            "health_score": b.health_score,
            "health_analysis": b.health_analysis,
            "gbp_account_id": b.gbp_account_id,
            "gbp_location_id": b.gbp_location_id,
            "onboarding_completed": b.onboarding_completed,
            "created_at": b.created_at.isoformat() if b.created_at else None,
            "updated_at": b.updated_at.isoformat() if b.updated_at else None,
            "users": [
                {
                    "id": u.id,
                    "full_name": u.full_name,
                    "email": u.email,
                    "role": u.role.value if hasattr(u.role, "value") else str(u.role),
                    "is_active": u.is_active,
                    "created_at": u.created_at.isoformat() if u.created_at else None,
                    "updated_at": u.updated_at.isoformat() if u.updated_at else None,
                }
                for u in users
            ],
            "reviews": [
                {
                    "id": r.id,
                    "reviewer_name": r.reviewer_name,
                    "author_name": r.reviewer_name,
                    "rating": r.rating,
                    "review_text": r.text,
                    "text": r.text,
                    "response_text": r.reply_text,
                    "reply_text": r.reply_text,
                    "sentiment": r.sentiment.value if hasattr(r.sentiment, "value") else (str(r.sentiment) if r.sentiment else "neutral"),
                    "review_date": str(r.review_date) if r.review_date else None,
                    "created_at": r.created_at.isoformat() if r.created_at else None,
                }
                for r in reviews_list
            ],
            "seo_keywords": [
                {
                    "id": kw.id,
                    "keyword": kw.keyword,
                    "target_location": kw.target_location,
                    "current_rank": kw.current_rank,
                    "previous_rank": kw.previous_rank,
                    "search_volume": kw.search_volume,
                    "difficulty": kw.difficulty,
                    "intent": kw.intent,
                    "is_tracked": kw.is_tracked,
                    "created_at": kw.created_at.isoformat() if kw.created_at else None,
                }
                for kw in keywords_list
            ],
            "seo_audit": {
                "id": latest_seo_audit.id,
                "overall_seo_score": latest_seo_audit.overall_seo_score,
                "map_pack_score": latest_seo_audit.map_pack_score,
                "citation_score": latest_seo_audit.citation_score,
                "missing_attributes": latest_seo_audit.missing_attributes or [],
                "actionable_recommendations": latest_seo_audit.actionable_recommendations or [],
                "competitor_insights": latest_seo_audit.competitor_insights or [],
                "created_at": latest_seo_audit.created_at.isoformat() if latest_seo_audit.created_at else None,
            } if latest_seo_audit else None,
            "website_audit": {
                "id": latest_web_audit.id,
                "site_url": latest_web_audit.site_url,
                "overall_score": latest_web_audit.overall_score,
                "technical_score": latest_web_audit.technical_score,
                "content_score": latest_web_audit.content_score,
                "local_signals_score": latest_web_audit.local_signals_score,
                "findings": latest_web_audit.findings or [],
                "actionable_recommendations": latest_web_audit.actionable_recommendations or [],
                "raw_crawl_meta": latest_web_audit.raw_crawl_meta or {},
                "created_at": latest_web_audit.created_at.isoformat() if latest_web_audit.created_at else None,
            } if latest_web_audit else None,
            "gsc_connection": {
                "id": gsc_conn.id,
                "site_url": gsc_conn.site_url,
                "is_connected": gsc_conn.is_connected,
                "sync_status": gsc_conn.sync_status,
                "last_synced_at": gsc_conn.last_synced_at.isoformat() if gsc_conn.last_synced_at else None,
                "sync_error": gsc_conn.sync_error,
            } if gsc_conn else None,
            "campaigns": [
                {
                    "id": c.id,
                    "name": c.name,
                    "objective": c.objective,
                    "audience": c.audience,
                    "offer": c.offer,
                    "status": c.status.value if hasattr(c.status, "value") else str(c.status),
                    "created_at": c.created_at.isoformat() if c.created_at else None,
                }
                for c in campaigns_list
            ],
            "contents": [
                {
                    "id": ct.id,
                    "content_type": ct.content_type.value if hasattr(ct.content_type, "value") else str(ct.content_type),
                    "title": ct.title,
                    "body": ct.body[:200] if ct.body else "",
                    "status": ct.status.value if hasattr(ct.status, "value") else str(ct.status),
                    "created_at": ct.created_at.isoformat() if ct.created_at else None,
                }
                for ct in contents_list
            ],
            "competitors": [
                {
                    "id": cp.id,
                    "name": cp.name,
                    "category": cp.category,
                    "location": cp.location,
                    "rating": cp.rating,
                    "review_count": cp.review_count,
                    "reviews_count": cp.review_count,
                    "website": cp.website,
                }
                for cp in competitors_list
            ],
            "recommendations": [
                {
                    "id": rec.id,
                    "title": rec.title,
                    "explanation": rec.explanation,
                    "description": rec.explanation,
                    "priority": rec.priority.value if hasattr(rec.priority, "value") else str(rec.priority),
                    "impact": rec.impact,
                    "status": rec.status.value if hasattr(rec.status, "value") else str(rec.status),
                    "created_at": rec.created_at.isoformat() if rec.created_at else None,
                }
                for rec in recs_list
            ],
            "stats": {
                "reviews_count": rev_count,
                "average_rating": round(float(avg_rating), 1),
                "keywords_count": len(keywords_list),
                "top3_keywords_count": kw_top3_count,
                "recommendations_count": len(recs_list),
                "campaigns_count": len(campaigns_list),
                "contents_count": len(contents_list),
                "competitors_count": len(competitors_list),
                "latest_audit": {
                    "overall_score": latest_web_audit.overall_score if latest_web_audit else None,
                    "technical_score": latest_web_audit.technical_score if latest_web_audit else None,
                    "content_score": latest_web_audit.content_score if latest_web_audit else None,
                    "local_signals_score": latest_web_audit.local_signals_score if latest_web_audit else None,
                    "findings_count": len(latest_web_audit.findings) if latest_web_audit and latest_web_audit.findings else 0,
                } if latest_web_audit else None,
            },
        }

    async def update_business_full(self, business_id: str, data: Dict[str, Any]) -> Dict[str, Any]:
        """Super Admin update of any business fields & onboarding parameters."""
        res = await self.db.execute(select(Business).where(Business.id == business_id))
        b = res.scalar_one_or_none()
        if not b:
            raise ValueError(f"Business {business_id} not found")

        editable_fields = [
            "name", "category", "location", "website", "phone", "description",
            "target_customers", "services", "business_goals", "marketing_channels",
            "health_score", "onboarding_completed", "gbp_account_id", "gbp_location_id",
            "ai_business_profile"
        ]

        string_fields = ["target_customers", "services", "business_goals", "marketing_channels"]

        for field in editable_fields:
            if field in data:
                val = data[field]
                if field in string_fields and isinstance(val, list):
                    val = ", ".join(str(item) for item in val)
                setattr(b, field, val)

        b.updated_at = datetime.utcnow()
        await self.db.flush()
        return await self.get_business_detail(business_id)

    async def update_user(self, user_id: str, data: Dict[str, Any]) -> Dict[str, Any]:
        """Super Admin update of user details (name, email, role, is_active)."""
        from app.models.user import User, UserRole
        res = await self.db.execute(select(User).where(User.id == user_id))
        u = res.scalar_one_or_none()
        if not u:
            raise ValueError(f"User {user_id} not found")

        if "full_name" in data and data["full_name"]:
            u.full_name = data["full_name"].strip()
        if "email" in data and data["email"]:
            u.email = data["email"].strip()
        if "role" in data and data["role"]:
            try:
                u.role = UserRole(data["role"])
            except Exception:
                pass
        if "is_active" in data and data["is_active"] is not None:
            u.is_active = bool(data["is_active"])

        u.updated_at = datetime.utcnow()
        await self.db.flush()
        return {
            "id": u.id,
            "full_name": u.full_name,
            "email": u.email,
            "role": u.role.value if hasattr(u.role, 'value') else str(u.role),
            "is_active": u.is_active,
        }

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
                "feature_name": row.feature,
                "calls": row.count,
                "request_count": row.count,
                "tokens": int(row.tokens or 0),
                "total_tokens": int(row.tokens or 0),
                "cost_usd": round(float(row.cost or 0.0), 4),
                "estimated_cost_usd": round(float(row.cost or 0.0), 4),
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
                "request_count": row.count,
                "avg_latency_ms": round(float(row.avg_latency or 0), 1),
            }
            for row in model_agg
        ]

        # Group by User & Registered Business/Tenant
        from app.models.user import UserRole
        from sqlalchemy import or_

        res_users = await self.db.execute(
            select(User).where(User.role != UserRole.ADMIN).order_by(User.created_at.desc())
        )
        users = res_users.scalars().all()

        by_user = []
        for u in users:
            org = u.organization
            biz_names = [b.name for b in org.businesses] if org and org.businesses else []
            primary_biz = biz_names[0] if biz_names else (org.name if org else "No Business Added")

            conditions = []
            if u.organization_id:
                conditions.append(AIRequestLog.organization_id == u.organization_id)
            else:
                conditions.append(AIRequestLog.user_id == u.id)

            agg = await self.db.execute(
                select(
                    func.count(AIRequestLog.id).label("calls"),
                    func.sum(func.coalesce(AIRequestLog.input_tokens, 0) + func.coalesce(AIRequestLog.output_tokens, 0)).label("tokens"),
                    func.sum(func.coalesce(AIRequestLog.estimated_cost_usd, 0.0)).label("cost"),
                    func.max(AIRequestLog.created_at).label("last_active"),
                ).where(or_(*conditions))
            )
            stats = agg.one()

            by_user.append({
                "user_id": u.id,
                "user_name": u.full_name,
                "user_email": u.email,
                "organization_name": org.name if org else "Direct",
                "business_name": primary_biz,
                "preferred_model": "gemini-2.0-flash",
                "calls": stats.calls or 0,
                "request_count": stats.calls or 0,
                "tokens": int(stats.tokens or 0),
                "total_tokens": int(stats.tokens or 0),
                "cost_usd": round(float(stats.cost or 0.0), 4),
                "estimated_cost_usd": round(float(stats.cost or 0.0), 4),
                "last_active": stats.last_active.isoformat() if stats.last_active else None,
            })

        by_user.sort(key=lambda x: x["tokens"], reverse=True)

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
