from typing import Dict, Any, List
from datetime import date, timedelta, datetime
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.models.business import Business
from app.models.review import Review, ReviewSentiment
from app.models.analytics import BusinessAnalytics
from app.providers import get_business_data_provider
from app.repositories.business_repo import BusinessRepository
from app.repositories.review_repo import ReviewRepository


def _infer_sentiment(rating: int) -> ReviewSentiment:
    if rating >= 4:
        return ReviewSentiment.POSITIVE
    elif rating == 3:
        return ReviewSentiment.NEUTRAL
    else:
        return ReviewSentiment.NEGATIVE


class GBPSyncService:
    def __init__(self, db: AsyncSession):
        self.db = db
        self.biz_repo = BusinessRepository(db)
        self.review_repo = ReviewRepository(db)
        self.provider = get_business_data_provider()

    async def sync_business_data(self, business_id: str, organization_id: str) -> Dict[str, Any]:
        # 1. Fetch business and ensure multi-tenant ownership
        business = await self.biz_repo.get_by_id_and_org(business_id, organization_id)
        if not business:
            raise ValueError("Business not found or unauthorized")

        # 2. Fetch external profile, reviews, and performance metrics from provider
        gbp_profile = await self.provider.get_business_profile(business_id)
        gbp_reviews = await self.provider.get_reviews(business_id)
        gbp_metrics = await self.provider.get_performance_metrics(business_id)

        # 3. Update business GBP linkage
        business.gbp_account_id = gbp_profile.get("gbp_id")
        business.gbp_location_id = gbp_profile.get("gbp_id")

        # 4. Ingest reviews (avoid duplicating external IDs)
        existing_res = await self.db.execute(
            select(Review.external_id).where(Review.business_id == business_id)
        )
        existing_external_ids = set(existing_res.scalars().all())

        new_reviews: List[Review] = []
        for r in gbp_reviews:
            ext_id = r.get("external_id")
            if ext_id and ext_id in existing_external_ids:
                continue

            rating = r.get("rating", 5)
            sentiment = _infer_sentiment(rating)

            review = Review(
                business_id=business_id,
                reviewer_name=r.get("reviewer_name", "Anonymous"),
                rating=rating,
                text=r.get("text"),
                review_date=r.get("review_date"),
                sentiment=sentiment,
                source=r.get("source", "gbp"),
                external_id=ext_id,
                is_replied=False,
            )
            new_reviews.append(review)

        if new_reviews:
            await self.review_repo.bulk_create(new_reviews)

        # 5. Ingest business performance analytics
        today = date.today()
        period_start = today - timedelta(days=30)
        
        analytics_record = BusinessAnalytics(
            business_id=business_id,
            period_start=period_start,
            period_end=today,
            total_reviews=len(gbp_reviews),
            average_rating=round(
                sum(r.get("rating", 5) for r in gbp_reviews) / max(len(gbp_reviews), 1), 1
            ),
            profile_views=gbp_metrics.get("profile_views"),
            website_clicks=gbp_metrics.get("website_clicks"),
            phone_calls=gbp_metrics.get("phone_calls"),
            direction_requests=gbp_metrics.get("direction_requests"),
            photo_views=gbp_metrics.get("photo_views"),
            raw_metrics=gbp_metrics,
        )
        self.db.add(analytics_record)
        await self.db.flush()

        rating_summary = await self.review_repo.get_rating_summary(business_id)

        # 6. Trigger background AI review intelligence & CMO recommendations refresh
        try:
            from app.workers.tasks import analyze_review_intelligence_task, generate_cmo_recommendations_task
            analyze_review_intelligence_task.delay(business_id, organization_id)
            if new_reviews:
                generate_cmo_recommendations_task.delay(business_id, organization_id)
        except Exception:
            pass

        return {
            "business_id": business_id,
            "gbp_id": business.gbp_account_id,
            "reviews_synced": len(new_reviews),
            "total_reviews": rating_summary["total_reviews"],
            "average_rating": rating_summary["average_rating"],
            "metrics": gbp_metrics,
        }

