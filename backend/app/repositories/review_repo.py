from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from app.models.review import Review, ReviewSentiment


class ReviewRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def list_by_business(
        self,
        business_id: str,
        sentiment: Optional[ReviewSentiment] = None,
        unanswered_only: bool = False,
    ) -> List[Review]:
        query = select(Review).where(Review.business_id == business_id)
        if sentiment:
            query = query.where(Review.sentiment == sentiment)
        if unanswered_only:
            query = query.where(Review.is_replied == False)
        query = query.order_by(Review.created_at.desc())
        result = await self.db.execute(query)
        return list(result.scalars().all())

    async def get_by_id(self, review_id: str, business_id: str) -> Optional[Review]:
        result = await self.db.execute(
            select(Review).where(
                Review.id == review_id,
                Review.business_id == business_id,
            )
        )
        return result.scalar_one_or_none()

    async def create(
        self,
        business_id: str,
        reviewer_name: str,
        rating: int,
        text: Optional[str] = None,
        review_date: Optional[str] = None,
        sentiment: Optional[ReviewSentiment] = None,
        source: str = "gbp",
        external_id: Optional[str] = None,
    ) -> Review:
        review = Review(
            business_id=business_id,
            reviewer_name=reviewer_name,
            rating=rating,
            text=text,
            review_date=review_date,
            sentiment=sentiment,
            source=source,
            external_id=external_id,
        )
        self.db.add(review)
        await self.db.flush()
        return review

    async def bulk_create(self, reviews: List[Review]) -> List[Review]:
        self.db.add_all(reviews)
        await self.db.flush()
        return reviews

    async def get_rating_summary(self, business_id: str) -> dict:
        result = await self.db.execute(
            select(
                func.count(Review.id).label("total"),
                func.avg(Review.rating).label("avg_rating"),
            ).where(Review.business_id == business_id)
        )
        row = result.one()
        return {
            "total_reviews": row.total or 0,
            "average_rating": round(float(row.avg_rating), 1) if row.avg_rating else 0.0,
        }
