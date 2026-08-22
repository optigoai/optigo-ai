# ==================================================
# OptigoAI Backend — Celery Background Tasks
# ==================================================

import asyncio
from typing import Dict, Any

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

            current_analysis = business.health_analysis or {}
            current_analysis["review_intelligence"] = result_dict
            business.health_analysis = dict(current_analysis)
            await session.commit()
            return result_dict

    try:
        return run_async(_analyze())
    except Exception as e:
        logger.error("Review intelligence task failed", business_id=business_id, error=str(e))
        raise self.retry(exc=e, countdown=60)

