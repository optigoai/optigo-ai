# ==================================================
# OptigoAI Backend — Lead Repository
# ==================================================
"""
Repository for Lead database operations.
"""

from typing import Optional, List, Dict, Any
from datetime import datetime
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, desc, or_

from app.models.lead import Lead


class LeadRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_by_id(self, lead_id: str) -> Optional[Lead]:
        result = await self.db.execute(select(Lead).where(Lead.id == lead_id))
        return result.scalar_one_or_none()

    async def get_by_phone(self, phone: str) -> Optional[Lead]:
        clean_phone = phone.strip().replace(" ", "").replace("-", "")
        result = await self.db.execute(
            select(Lead).where(
                or_(
                    Lead.phone == clean_phone,
                    Lead.phone.endswith(clean_phone[-10:]) if len(clean_phone) >= 10 else Lead.phone == clean_phone
                )
            ).order_by(Lead.created_at.desc())
        )
        return result.scalars().first()

    async def get_by_place_id(self, place_id: str) -> Optional[Lead]:
        if not place_id:
            return None
        result = await self.db.execute(
            select(Lead).where(Lead.place_id == place_id).order_by(Lead.created_at.desc())
        )
        return result.scalars().first()

    async def list_leads(
        self,
        status: Optional[str] = None,
        priority: Optional[str] = None,
        search: Optional[str] = None,
        limit: int = 50,
        offset: int = 0,
    ) -> List[Lead]:
        query = select(Lead)

        if status:
            query = query.where(Lead.status == status)
        if priority:
            query = query.where(Lead.priority == priority)
        if search:
            search_term = f"%{search.strip()}%"
            query = query.where(
                or_(
                    Lead.business_name.ilike(search_term),
                    Lead.phone.ilike(search_term),
                    Lead.address.ilike(search_term),
                    Lead.category.ilike(search_term),
                )
            )

        query = query.order_by(desc(Lead.last_activity_at)).limit(limit).offset(offset)
        result = await self.db.execute(query)
        return list(result.scalars().all())

    async def count_leads(
        self,
        status: Optional[str] = None,
        priority: Optional[str] = None,
        search: Optional[str] = None,
    ) -> int:
        query = select(func.count(Lead.id))

        if status:
            query = query.where(Lead.status == status)
        if priority:
            query = query.where(Lead.priority == priority)
        if search:
            search_term = f"%{search.strip()}%"
            query = query.where(
                or_(
                    Lead.business_name.ilike(search_term),
                    Lead.phone.ilike(search_term),
                    Lead.address.ilike(search_term),
                )
            )

        return await self.db.scalar(query) or 0

    async def create(self, lead: Lead) -> Lead:
        self.db.add(lead)
        await self.db.flush()
        await self.db.refresh(lead)
        return lead

    async def save(self, lead: Lead) -> Lead:
        lead.last_activity_at = datetime.utcnow()
        await self.db.flush()
        await self.db.refresh(lead)
        return lead

    async def get_stats(self) -> Dict[str, Any]:
        total = await self.db.scalar(select(func.count(Lead.id))) or 0
        new_leads = await self.db.scalar(
            select(func.count(Lead.id)).where(Lead.status.in_(["new_lead", "search_started", "business_selected", "form_submitted"]))
        ) or 0
        active_onboarding = await self.db.scalar(
            select(func.count(Lead.id)).where(Lead.status.in_(["analysis_started", "report_processing", "report_ready", "report_viewed", "plan_selected", "payment_pending"]))
        ) or 0
        report_ready = await self.db.scalar(
            select(func.count(Lead.id)).where(Lead.status.in_(["report_ready", "report_viewed"]))
        ) or 0
        stuck_abandoned = await self.db.scalar(
            select(func.count(Lead.id)).where(Lead.status.in_(["abandoned", "stuck"]))
        ) or 0
        converted = await self.db.scalar(
            select(func.count(Lead.id)).where(Lead.status == "converted")
        ) or 0

        conversion_rate = round((converted / total * 100), 1) if total > 0 else 0.0

        return {
            "total_leads": total,
            "new_leads": new_leads,
            "active_onboarding": active_onboarding,
            "report_ready": report_ready,
            "stuck_abandoned": stuck_abandoned,
            "converted_leads": converted,
            "conversion_rate": conversion_rate,
        }
