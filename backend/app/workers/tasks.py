# ==================================================
# OptigoAI Backend — Celery Background Tasks
# ==================================================

import asyncio
from typing import Dict, Any, List
from datetime import datetime, timezone, timedelta

from app.workers.celery_app import celery_app
from app.core.database import async_session_factory
from app.core.logging import get_logger
from app.services.gsc_service import GoogleSearchConsoleService
from app.services.website_audit_service import WebsiteAuditService
from app.providers.seo.factory import SEOProviderFactory

logger = get_logger("app.workers.tasks")


def run_async(coro):
    """Utility to run asynchronous coroutines inside synchronous Celery task worker."""
    try:
        loop = asyncio.get_event_loop()
    except RuntimeError:
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
    return loop.run_until_complete(coro)


# --------------------------------------------------
# 1. Search Console Sync Task (0 AI Tokens)
# --------------------------------------------------
@celery_app.task(name="app.workers.tasks.sync_search_console_task", bind=True, max_retries=3)
def sync_search_console_task(self, business_id: str, organization_id: str) -> Dict[str, Any]:
    """Background task to sync Google Search Console queries and metrics."""
    logger.info("Starting background Search Console sync", business_id=business_id)

    async def _sync():
        async with async_session_factory() as session:
            service = GoogleSearchConsoleService(session)
            res = await service.sync_metrics(business_id=business_id, organization_id=organization_id)
            await session.commit()
            return res

    try:
        return run_async(_sync())
    except Exception as e:
        logger.error("GSC sync task failed", business_id=business_id, error=str(e))
        raise self.retry(exc=e, countdown=60)


# --------------------------------------------------
# 2. Website Crawl & AI SEO Audit Task (Token Guarded: 24h Cache)
# --------------------------------------------------
@celery_app.task(name="app.workers.tasks.run_website_audit_task", bind=True, max_retries=2)
def run_website_audit_task(self, business_id: str, organization_id: str, custom_url: str = None) -> Dict[str, Any]:
    """Background task to execute website crawl and AI SEO audit."""
    logger.info("Starting background website audit", business_id=business_id, url=custom_url)

    async def _audit():
        async with async_session_factory() as session:
            service = WebsiteAuditService(session)
            res = await service.run_audit(
                business_id=business_id,
                organization_id=organization_id,
                custom_url=custom_url,
            )
            await session.commit()
            return res

    try:
        return run_async(_audit())
    except Exception as e:
        logger.error("Website audit task failed", business_id=business_id, error=str(e))
        raise self.retry(exc=e, countdown=60)


# --------------------------------------------------
# 3. SERP Keyword Rank Refresh Task (0 AI Tokens)
# --------------------------------------------------
@celery_app.task(name="app.workers.tasks.refresh_serp_ranks_task")
def refresh_serp_ranks_task(business_id: str, domain: str, keywords: list, location: str = None) -> Dict[str, Any]:
    """Background task to query SERP rank positions via the active SEO provider."""
    logger.info("Refreshing SERP rankings", business_id=business_id, keyword_count=len(keywords))

    async def _refresh():
        provider = SEOProviderFactory.get_provider()
        ranks = []
        for kw in keywords:
            rank_data = await provider.get_keyword_rank(keyword=kw, domain=domain, location=location)
            ranks.append(rank_data)
        return {"business_id": business_id, "ranks": ranks}

    return run_async(_refresh())


# --------------------------------------------------
# 4. Review Intelligence Analysis (Token Guarded: Change Detection)
# --------------------------------------------------
@celery_app.task(name="app.workers.tasks.analyze_review_intelligence_task", bind=True, max_retries=2)
def analyze_review_intelligence_task(self, business_id: str, organization_id: str) -> Dict[str, Any]:
    """Background task to automatically analyze customer reviews and extract real feedback keywords with AI."""
    logger.info("Starting background review intelligence analysis", business_id=business_id)

    async def _analyze():
        from app.repositories.business_repo import BusinessRepository
        from app.repositories.review_repo import ReviewRepository
        from app.ai.ai_service import AIService

        async with async_session_factory() as session:
            biz_repo = BusinessRepository(session)
            business = await biz_repo.get_by_id_and_org(business_id, organization_id)
            if not business:
                return {}

            review_repo = ReviewRepository(session)
            reviews = await review_repo.list_by_business(business_id=business_id)
            if not reviews:
                return {}

            total = len(reviews)
            # Token Guard: If review count hasn't changed and cached analysis exists, skip redundant AI call
            current_analysis = business.health_analysis or {}
            cached = current_analysis.get("review_intelligence")
            if cached and cached.get("total_analyzed") == total and cached.get("top_feedback"):
                logger.info("Review intelligence up to date, skipping redundant AI call", business_id=business_id)
                return cached

            pos_count = sum(1 for r in reviews if r.rating >= 4 or (r.sentiment and r.sentiment.value == "positive"))
            neg_count = sum(1 for r in reviews if r.rating <= 2 or (r.sentiment and r.sentiment.value == "negative"))
            neu_count = total - (pos_count + neg_count)

            pos_pct = round((pos_count / total) * 100)
            neg_pct = round((neg_count / total) * 100)
            neu_pct = max(0, 100 - (pos_pct + neg_pct))

            reviews_payload = [
                {
                    "id": r.id,
                    "reviewer_name": r.reviewer_name,
                    "rating": r.rating,
                    "text": r.text,
                    "sentiment": r.sentiment.value if r.sentiment else "positive",
                }
                for r in reviews if r.text
            ]

            if not reviews_payload:
                return {
                    "positive_percentage": pos_pct,
                    "neutral_percentage": neu_pct,
                    "negative_percentage": neg_pct,
                    "top_feedback": [],
                    "executive_summary": f"Received {total} star ratings without written comments.",
                    "total_analyzed": total,
                }

            ai_service = AIService(session)
            intel = await ai_service.analyze_review_intelligence(
                organization_id=organization_id,
                user_id=None,
                business_name=business.name,
                category=business.category or "Local Business",
                reviews=reviews_payload,
            )

            result_dict = {
                "positive_percentage": pos_pct,
                "neutral_percentage": neu_pct,
                "negative_percentage": neg_pct,
                "top_feedback": [
                    {
                        "keyword": tf.keyword,
                        "percentage": tf.percentage,
                        "sentiment": tf.sentiment,
                    }
                    for tf in intel.top_feedback
                ],
                "executive_summary": intel.executive_summary,
                "total_analyzed": total,
            }

            current_analysis["review_intelligence"] = result_dict
            business.health_analysis = dict(current_analysis)
            await session.commit()
            return result_dict

    try:
        return run_async(_analyze())
    except Exception as e:
        logger.error("Review intelligence task failed", business_id=business_id, error=str(e))
        raise self.retry(exc=e, countdown=60)


# --------------------------------------------------
# 5. Onboarding Intelligence Synthesis (Token Guarded: One-Time / On Update)
# --------------------------------------------------
@celery_app.task(name="app.workers.tasks.sync_onboarding_intelligence_task", bind=True, max_retries=2)
def sync_onboarding_intelligence_task(self, business_id: str, organization_id: str) -> Dict[str, Any]:
    """Background task to synthesize AI Business Profile and initial CMO Intelligence upon onboarding."""
    logger.info("Starting onboarding AI intelligence synthesis", business_id=business_id)

    async def _synthesize():
        from app.services.business_intelligence_service import BusinessIntelligenceService
        async with async_session_factory() as session:
            service = BusinessIntelligenceService(session)
            res = await service.analyze_business(business_id=business_id, organization_id=organization_id)
            await session.commit()
            return res

    try:
        return run_async(_synthesize())
    except Exception as e:
        logger.error("Onboarding intelligence task failed", business_id=business_id, error=str(e))
        raise self.retry(exc=e, countdown=60)


# --------------------------------------------------
# 6. Autonomous AI CMO Recommendations Refresh (Token Guarded: 3-Day Cadence)
# --------------------------------------------------
@celery_app.task(name="app.workers.tasks.generate_cmo_recommendations_task", bind=True, max_retries=2)
def generate_cmo_recommendations_task(self, business_id: str, organization_id: str, force: bool = False) -> Dict[str, Any]:
    """Background task to refresh prioritized AI CMO actionable recommendation cards."""
    logger.info("Starting background CMO recommendations generation", business_id=business_id)

    async def _refresh():
        from app.services.cmo_recommendations_service import CMORecommendationsService
        async with async_session_factory() as session:
            service = CMORecommendationsService(session)
            res = await service.get_or_generate_recommendations(
                business_id=business_id,
                organization_id=organization_id,
                force_regenerate=force,
            )
            await session.commit()
            return res

    try:
        return run_async(_refresh())
    except Exception as e:
        logger.error("CMO recommendations task failed", business_id=business_id, error=str(e))
        raise self.retry(exc=e, countdown=60)


# --------------------------------------------------
# 7. Scheduled Daily GBP Sync (Beat Task: 02:00 UTC)
# --------------------------------------------------
@celery_app.task(name="app.workers.tasks.scheduled_daily_gbp_sync_task")
def scheduled_daily_gbp_sync_task() -> Dict[str, Any]:
    """Periodic Celery Beat task to sync Google Business Profile reviews and metrics for all active onboarded businesses."""
    logger.info("Executing scheduled daily GBP sync for active businesses")

    async def _sync_all():
        from app.models.business import Business
        from app.services.gbp_sync_service import GBPSyncService
        from sqlalchemy import select

        synced_count = 0
        async with async_session_factory() as session:
            result = await session.execute(
                select(Business).where(Business.onboarding_completed == True)
            )
            businesses = result.scalars().all()
            for b in businesses:
                try:
                    sync_service = GBPSyncService(session)
                    await sync_service.sync_business_data(b.id, b.organization_id)
                    synced_count += 1
                except Exception as e:
                    logger.error("Scheduled GBP sync failed for business", business_id=b.id, error=str(e))
            await session.commit()
        return {"status": "completed", "businesses_synced": synced_count}

    return run_async(_sync_all())


# --------------------------------------------------
# 8. Scheduled Daily GSC Sync (Beat Task: 03:00 UTC)
# --------------------------------------------------
@celery_app.task(name="app.workers.tasks.scheduled_daily_gsc_sync_task")
def scheduled_daily_gsc_sync_task() -> Dict[str, Any]:
    """Periodic Celery Beat task to sync Search Console keyword rankings and traffic for active businesses."""
    logger.info("Executing scheduled daily GSC sync for active businesses")

    async def _sync_all():
        from app.models.business import Business
        from sqlalchemy import select

        synced_count = 0
        async with async_session_factory() as session:
            result = await session.execute(
                select(Business).where(Business.onboarding_completed == True)
            )
            businesses = result.scalars().all()
            for b in businesses:
                try:
                    service = GoogleSearchConsoleService(session)
                    await service.sync_metrics(b.id, b.organization_id)
                    synced_count += 1
                except Exception as e:
                    logger.error("Scheduled GSC sync failed for business", business_id=b.id, error=str(e))
            await session.commit()
        return {"status": "completed", "businesses_synced": synced_count}

    return run_async(_sync_all())


# --------------------------------------------------
# 9. Scheduled Weekly CMO Health Check (Beat Task: Sunday 04:00 UTC)
# --------------------------------------------------
@celery_app.task(name="app.workers.tasks.scheduled_weekly_cmo_health_task")
def scheduled_weekly_cmo_health_task() -> Dict[str, Any]:
    """Periodic Celery Beat task to run weekly marketing health checks and update recommendation cards."""
    logger.info("Executing scheduled weekly CMO health audit for active businesses")

    async def _audit_all():
        from app.models.business import Business
        from app.services.cmo_recommendations_service import CMORecommendationsService
        from sqlalchemy import select

        audited_count = 0
        async with async_session_factory() as session:
            result = await session.execute(
                select(Business).where(Business.onboarding_completed == True)
            )
            businesses = result.scalars().all()
            for b in businesses:
                try:
                    cmo_service = CMORecommendationsService(session)
                    await cmo_service.get_or_generate_recommendations(
                        business_id=b.id,
                        organization_id=b.organization_id,
                        force_regenerate=True,
                    )
                    audited_count += 1
                except Exception as e:
                    logger.error("Scheduled CMO health check failed for business", business_id=b.id, error=str(e))
            await session.commit()
        return {"status": "completed", "businesses_audited": audited_count}

    return run_async(_audit_all())


