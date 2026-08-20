# ==================================================
# OptigoAI Backend — AI CMO Engine Service
# ==================================================

from typing import Optional, Sequence, Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession

from fastapi import HTTPException, status
from app.models.recommendation import Recommendation, RecommendationPriority, RecommendationStatus
from app.repositories.business_repo import BusinessRepository
from app.repositories.review_repo import ReviewRepository
from app.repositories.recommendation_repo import RecommendationRepository
from app.ai.ai_service import AIService
from app.core.logging import get_logger

logger = get_logger("app.services.cmo_engine")


class CMOEngineService:
    """Orchestrates AI CMO strategy, prioritized action synthesis, and execution tracking."""

    def __init__(self, db: AsyncSession):
        self.db = db
        self.business_repo = BusinessRepository(db)
        self.review_repo = ReviewRepository(db)
        self.rec_repo = RecommendationRepository(db)
        self.ai_service = AIService(db)

    async def generate_recommendations(
        self,
        business_id: str,
        organization_id: str,
        user_id: Optional[str] = None,
    ) -> Dict[str, Any]:
        business = await self.business_repo.get_by_id(business_id)
        if not business:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Business not found")
        if business.organization_id != organization_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

        # 1. Fetch current review stats
        reviews = await self.review_repo.list_by_business(business_id)
        unanswered_reviews = [r for r in reviews if not r.is_replied]

        # 2. Retrieve health analysis & problems
        health_analysis = business.health_analysis or {}
        health_score = business.health_score or 75
        problems = health_analysis.get("top_problems", [])
        opportunities = health_analysis.get("top_opportunities", [])

        # 3. Call AI CMO Engine
        cmo_output = await self.ai_service.generate_cmo_recommendations(
            organization_id=organization_id,
            user_id=user_id,
            business_name=business.name,
            category=business.category or "Local Business",
            location=business.location or "Local Area",
            health_score=health_score,
            problems=problems,
            opportunities=opportunities,
            reviews_count=len(reviews),
            unanswered_count=len(unanswered_reviews),
        )

        # 4. Remove stale pending recommendations for clean updates
        await self.rec_repo.delete_pending_for_business(business_id)

        # 5. Create new Recommendation models
        priority_map = {
            "urgent": (RecommendationPriority.URGENT, 0),
            "important": (RecommendationPriority.IMPORTANT, 10),
            "opportunity": (RecommendationPriority.OPPORTUNITY, 20),
        }

        rec_models = []
        for idx, item in enumerate(cmo_output.recommendations):
            p_val, base_sort = priority_map.get(
                item.priority.lower(), (RecommendationPriority.IMPORTANT, 10)
            )
            rec = Recommendation(
                business_id=business_id,
                title=item.title,
                explanation=item.explanation,
                reason=item.reason,
                priority=p_val,
                impact=item.impact,
                effort=item.effort,
                suggested_action=item.suggested_action,
                related_feature=item.related_feature,
                status=RecommendationStatus.PENDING,
                sort_order=base_sort + idx,
            )
            rec_models.append(rec)

        await self.rec_repo.bulk_create(rec_models)
        await self.db.flush()

        return {
            "business_id": business_id,
            "cmo_note": cmo_output.cmo_note,
            "recommendations": [
                {
                    "id": r.id,
                    "business_id": r.business_id,
                    "title": r.title,
                    "explanation": r.explanation,
                    "reason": r.reason,
                    "priority": r.priority.value if hasattr(r.priority, "value") else str(r.priority),
                    "impact": r.impact,
                    "effort": r.effort,
                    "suggested_action": r.suggested_action,
                    "related_feature": r.related_feature,
                    "status": r.status.value if hasattr(r.status, "value") else str(r.status),
                    "sort_order": r.sort_order,
                    "created_at": r.created_at,
                }
                for r in rec_models
            ],
        }

    async def get_recommendations(
        self,
        business_id: str,
        organization_id: str,
        priority: Optional[str] = None,
        status: Optional[str] = None,
        include_dismissed: bool = False,
    ) -> Sequence[Recommendation]:
        business = await self.business_repo.get_by_id(business_id)
        if not business:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Business not found")
        if business.organization_id != organization_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

        p_enum = None
        if priority:
            try:
                p_enum = RecommendationPriority(priority.lower())
            except ValueError:
                raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Invalid priority: {priority}")

        s_enum = None
        if status:
            try:
                s_enum = RecommendationStatus(status.lower())
            except ValueError:
                raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Invalid status: {status}")

        return await self.rec_repo.list_for_business(
            business_id=business_id,
            priority=p_enum,
            status=s_enum,
            include_dismissed=include_dismissed,
        )

    async def update_recommendation_status(
        self,
        rec_id: str,
        business_id: str,
        organization_id: str,
        new_status: str,
    ) -> Recommendation:
        business = await self.business_repo.get_by_id(business_id)
        if not business or business.organization_id != organization_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

        rec = await self.rec_repo.get_by_id(rec_id)
        if not rec or rec.business_id != business_id:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Recommendation not found")

        try:
            status_enum = RecommendationStatus(new_status.lower())
        except ValueError:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Invalid status: {new_status}")

        updated = await self.rec_repo.update_status(rec_id, status_enum)
        await self.db.flush()
        return updated
