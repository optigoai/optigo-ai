# ==================================================
# OptigoAI Backend — Website Audit Pipeline Service
# ==================================================

import uuid
from datetime import datetime
from typing import Dict, Any, List, Optional
from sqlalchemy import select, desc
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import HTTPException, status

from app.models.website_audit import WebsiteAudit
from app.models.recommendation import Recommendation, RecommendationPriority, RecommendationStatus
from app.repositories.business_repo import BusinessRepository
from app.repositories.recommendation_repo import RecommendationRepository
from app.providers.crawler.factory import WebsiteCrawlerFactory
from app.core.security_url import validate_and_sanitize_url
from app.ai.ai_service import AIService
from app.core.logging import get_logger

logger = get_logger("app.services.website_audit")


class WebsiteAuditService:
    """End-to-end pipeline: URL Validation -> Crawler -> SEO Normalizer -> Gemini AI Explanation -> Recommendations."""

    def __init__(self, db: AsyncSession):
        self.db = db
        self.biz_repo = BusinessRepository(db)
        self.rec_repo = RecommendationRepository(db)
        self.ai_service = AIService(db)

    async def run_audit(
        self,
        business_id: str,
        organization_id: str,
        user_id: Optional[str] = None,
        custom_url: Optional[str] = None,
    ) -> Dict[str, Any]:
        business = await self.biz_repo.get_by_id(business_id)
        if not business:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Business not found")
        if business.organization_id != organization_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

        target_url = custom_url or business.website
        if not target_url:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No website URL provided or found on business profile.",
            )

        # 1. Strict SSRF Protection
        safe_url = validate_and_sanitize_url(target_url)

        # 2. Execute Web Crawl
        crawler = WebsiteCrawlerFactory.get_provider()
        crawl_result = await crawler.crawl_site(safe_url, max_pages=5)

        root_page = crawl_result.pages[0] if crawl_result.pages else None

        # 3. Analyze Technical SEO & Local Signals
        findings = []
        technical_score = 90
        content_score = 85
        local_score = 80

        if not root_page or not root_page.title:
            findings.append({"status": "fail", "title": "Missing Page Title Tag", "impact": "High", "fix": "Add a descriptive <title> tag with your primary business keyword and location."})
            technical_score -= 20
        else:
            findings.append({"status": "pass", "title": f"Title Tag Detected: '{root_page.title[:45]}...'", "impact": "Positive"})

        if not root_page or not root_page.meta_description:
            findings.append({"status": "warning", "title": "Missing Meta Description", "impact": "Medium", "fix": "Add a 150-character meta description describing your products and location."})
            content_score -= 15
        else:
            findings.append({"status": "pass", "title": "Meta Description Present", "impact": "Positive"})

        if not root_page or not root_page.h1_tags:
            findings.append({"status": "warning", "title": "No <h1> Heading Tag", "impact": "Medium", "fix": "Add an <h1> heading stating your business name and main specialty."})
            technical_score -= 10

        if not root_page or not root_page.has_schema:
            findings.append({"status": "warning", "title": "LocalBusiness Schema Missing", "impact": "High", "fix": "Inject JSON-LD LocalBusiness schema to help Google Maps associate your website with your physical store."})
            local_score -= 25
        else:
            findings.append({"status": "pass", "title": f"Structured Schema Present ({', '.join(root_page.schema_types)})", "impact": "Positive"})

        if not root_page or not root_page.phone_numbers:
            findings.append({"status": "warning", "title": "No Phone Number Detected on Homepage", "impact": "Medium", "fix": "Add a clickable phone link (tel:) so mobile visitors can call immediately."})
            local_score -= 15

        overall_score = max(30, int((technical_score + content_score + local_score) / 3))

        # 4. Generate AI Explanation and Actionable Recommendations using Gemini
        findings_summary = "\n".join([f"- [{f['status'].upper()}] {f['title']}: {f.get('fix', 'Good')}" for f in findings])
        prompt = f"""You are the AI Chief Marketing Officer for {business.name}.
Analyze this website audit data and provide 3 ultra-concise, highly actionable fixes:

Website: {safe_url}
Overall SEO Health: {overall_score}/100
Technical Score: {technical_score}/100
Content Score: {content_score}/100
Local Signals Score: {local_score}/100

FINDINGS:
{findings_summary}

Respond in 3 actionable bullet points. Format each as:
- [Priority] Action Title: Specific fix for the business owner.
"""
        actionable_recs = []
        try:
            ai_res = await self.ai_service.provider.generate_text(prompt=prompt, temperature=0.3)
            ai_text = ai_res.get("text", "")
            for line in ai_text.split("\n"):
                line = line.strip().lstrip("-*# ")
                if line:
                    actionable_recs.append(line)
        except Exception:
            actionable_recs = [
                f"Add LocalBusiness Schema markup to {safe_url} to boost Google Maps local ranking.",
                f"Include primary keyword '{business.category or 'services'}' in the main homepage heading.",
                "Ensure your physical address and phone number match your Google Business Profile exactly.",
            ]

        # 5. Persist Audit Record
        audit = WebsiteAudit(
            business_id=business_id,
            site_url=safe_url,
            overall_score=overall_score,
            technical_score=technical_score,
            content_score=content_score,
            local_signals_score=local_score,
            findings=findings,
            actionable_recommendations=actionable_recs[:3],
            raw_crawl_meta={
                "total_pages": crawl_result.total_pages_crawled,
                "duration_s": crawl_result.duration_seconds,
                "provider": crawl_result.provider_used,
            },
        )
        self.db.add(audit)

        # 6. Inject top finding as an actionable recommendation in user's Actions Tab
        if actionable_recs:
            top_rec = Recommendation(
                business_id=business_id,
                title="Optimize Website for Local Search",
                explanation=f"Our latest website audit of {safe_url} found opportunities to improve local search signals.",
                reason="Search engines prioritize websites with complete local schema, structured headings, and location signals.",
                priority=RecommendationPriority.IMPORTANT,
                status=RecommendationStatus.PENDING,
                impact="+15% Local Visibility",
                effort="15 mins",
                suggested_action=actionable_recs[0],
                related_feature="seo",
            )
            self.db.add(top_rec)

        await self.db.flush()

        return {
            "id": audit.id,
            "business_id": business_id,
            "site_url": safe_url,
            "overall_score": overall_score,
            "technical_score": technical_score,
            "content_score": content_score,
            "local_signals_score": local_score,
            "findings": findings,
            "actionable_recommendations": actionable_recs[:3],
            "created_at": audit.created_at,
        }

    async def get_latest_audit(self, business_id: str, organization_id: str) -> Optional[Dict[str, Any]]:
        business = await self.biz_repo.get_by_id(business_id)
        if not business or business.organization_id != organization_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

        stmt = select(WebsiteAudit).where(WebsiteAudit.business_id == business_id).order_by(desc(WebsiteAudit.created_at)).limit(1)
        res = await self.db.execute(stmt)
        audit = res.scalar_one_or_none()
        if not audit:
            return None

        return {
            "id": audit.id,
            "business_id": business_id,
            "site_url": audit.site_url,
            "overall_score": audit.overall_score,
            "technical_score": audit.technical_score,
            "content_score": audit.content_score,
            "local_signals_score": audit.local_signals_score,
            "findings": audit.findings,
            "actionable_recommendations": audit.actionable_recommendations,
            "created_at": audit.created_at,
        }
