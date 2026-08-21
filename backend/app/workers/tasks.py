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
