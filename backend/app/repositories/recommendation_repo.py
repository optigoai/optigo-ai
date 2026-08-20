# ==================================================
# OptigoAI Backend — Recommendation Repository
# ==================================================

from typing import Optional, Sequence
from sqlalchemy import select, update, delete
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.recommendation import Recommendation, RecommendationPriority, RecommendationStatus


class RecommendationRepository:
    """Multi-tenant data access layer for AI CMO Recommendations."""

    def __init__(self, db: AsyncSession):
        self.db = db

    async def create(self, recommendation: Recommendation) -> Recommendation:
        self.db.add(recommendation)
        await self.db.flush()
        return recommendation

    async def bulk_create(self, recommendations: list[Recommendation]) -> list[Recommendation]:
        self.db.add_all(recommendations)
        await self.db.flush()
        return recommendations

    async def get_by_id(self, rec_id: str) -> Optional[Recommendation]:
        stmt = select(Recommendation).where(Recommendation.id == rec_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def list_for_business(
        self,
        business_id: str,
        priority: Optional[RecommendationPriority] = None,
        status: Optional[RecommendationStatus] = None,
        include_dismissed: bool = False,
        limit: int = 50,
        offset: int = 0,
    ) -> Sequence[Recommendation]:
        stmt = select(Recommendation).where(Recommendation.business_id == business_id)

        if priority:
            stmt = stmt.where(Recommendation.priority == priority)
        if status:
            stmt = stmt.where(Recommendation.status == status)
        elif not include_dismissed:
            stmt = stmt.where(Recommendation.status != RecommendationStatus.DISMISSED)

        # Order by priority weight and sort_order
        stmt = stmt.order_by(Recommendation.sort_order.asc(), Recommendation.created_at.desc())
        stmt = stmt.limit(limit).offset(offset)
        result = await self.db.execute(stmt)
        return result.scalars().all()

    async def update_status(
        self, rec_id: str, status: RecommendationStatus
    ) -> Optional[Recommendation]:
        rec = await self.get_by_id(rec_id)
        if not rec:
            return None
        rec.status = status
        await self.db.flush()
        return rec

    async def delete_pending_for_business(self, business_id: str) -> int:
        """Clear out old unacted pending recommendations before generating fresh recommendations."""
        stmt = delete(Recommendation).where(
            Recommendation.business_id == business_id,
            Recommendation.status == RecommendationStatus.PENDING,
        )
        result = await self.db.execute(stmt)
        await self.db.flush()
        return result.rowcount
