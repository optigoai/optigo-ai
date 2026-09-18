# ==================================================
# OptigoAI Backend — Lead Repository
# ==================================================
"""
Repository for Lead database operations.
"""

from typing import Optional, List, Dict, Any
from datetime import datetime
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, desc, or_, delete

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

    async def get_by_payment_id(self, payment_id: str) -> Optional[Lead]:
        if not payment_id:
            return None
        result = await self.db.execute(
            select(Lead).where(Lead.payment_id == payment_id).order_by(Lead.created_at.desc())
        )
        return result.scalars().first()

    async def list_leads(
        self,
        status: Optional[str] = None,
        priority: Optional[str] = None,
        plan: Optional[str] = None,
        search: Optional[str] = None,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
        sort_by: str = "last_activity_at",
        sort_order: str = "desc",
        limit: int = 50,
        offset: int = 0,
    ) -> List[Lead]:
        query = select(Lead)

        if status and status != "all":
            query = query.where(Lead.status == status)
        if priority and priority != "all":
            query = query.where(Lead.priority == priority)
        if plan and plan != "all":
            query = query.where(Lead.selected_plan == plan)
        if start_date:
            query = query.where(Lead.created_at >= start_date)
        if end_date:
            query = query.where(Lead.created_at <= end_date)
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

        # Dynamic Sorting
        sort_col = Lead.last_activity_at
        if sort_by == "created_at":
            sort_col = Lead.created_at
        elif sort_by == "report_score":
            sort_col = Lead.report_score
        elif sort_by == "business_name":
            sort_col = Lead.business_name
        elif sort_by == "status":
            sort_col = Lead.status
        elif sort_by == "priority":
            sort_col = Lead.priority

        if sort_order.lower() == "asc":
            query = query.order_by(sort_col.asc().nulls_last())
        else:
            query = query.order_by(sort_col.desc().nulls_last())

        query = query.limit(limit).offset(offset)
        result = await self.db.execute(query)
        return list(result.scalars().all())

    async def count_leads(
        self,
        status: Optional[str] = None,
        priority: Optional[str] = None,
        plan: Optional[str] = None,
        search: Optional[str] = None,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
    ) -> int:
        query = select(func.count(Lead.id))

        if status and status != "all":
            query = query.where(Lead.status == status)
        if priority and priority != "all":
            query = query.where(Lead.priority == priority)
        if plan and plan != "all":
            query = query.where(Lead.selected_plan == plan)
        if start_date:
            query = query.where(Lead.created_at >= start_date)
        if end_date:
            query = query.where(Lead.created_at <= end_date)
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

        return await self.db.scalar(query) or 0

    async def delete(self, lead_id: str) -> bool:
        lead = await self.get_by_id(lead_id)
        if not lead:
            return False
        await self.db.delete(lead)
        await self.db.flush()
        return True

    async def delete_all(self) -> int:
        res = await self.db.execute(delete(Lead))
        await self.db.flush()
        return res.rowcount or 0

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
        report_viewed = await self.db.scalar(
            select(func.count(Lead.id)).where(Lead.status == "report_viewed")
        ) or 0
        plan_selected = await self.db.scalar(
            select(func.count(Lead.id)).where(Lead.status.in_(["plan_selected", "payment_pending"]))
        ) or 0
        stuck_abandoned = await self.db.scalar(
            select(func.count(Lead.id)).where(Lead.status.in_(["abandoned", "stuck"]))
        ) or 0
        converted = await self.db.scalar(
            select(func.count(Lead.id)).where(Lead.status == "converted")
        ) or 0

        # Today's leads
        today_start = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
        today_count = await self.db.scalar(
            select(func.count(Lead.id)).where(Lead.created_at >= today_start)
        ) or 0

        # Calculate estimated pipeline opportunity loss from leads that have report_data
        leads_with_reports = await self.db.execute(
            select(Lead.report_data).where(Lead.report_data.isnot(None))
        )
        total_loss_pipeline = 0
        for row in leads_with_reports.scalars():
            if isinstance(row, dict):
                # Rank 1 businesses have 0 missed calls/loss
                ur = row.get("user_rank") or row.get("audit_summary", {}).get("user_rank") or row.get("business_impact", {}).get("user_rank")
                if ur == 1:
                    continue

                rb = row.get("revenue_breakdown") or (row.get("business_impact", {}).get("revenue_breakdown"))
                if isinstance(rb, dict) and rb.get("monthly_loss_low"):
                    total_loss_pipeline += int(rb.get("monthly_loss_low", 0))
                else:
                    impact = row.get("business_impact", {})
                    if isinstance(impact, dict) and impact.get("estimated_revenue_loss_monthly_low"):
                        total_loss_pipeline += int(impact.get("estimated_revenue_loss_monthly_low", 0))
                    elif isinstance(row.get("revenue_loss"), dict) and row["revenue_loss"].get("loss_min"):
                        total_loss_pipeline += int(row["revenue_loss"]["loss_min"])
                    elif isinstance(impact, dict):
                        calls = impact.get("estimated_missed_calls_monthly", 0) or 0
                        walkins = impact.get("estimated_lost_walkins_monthly", 0) or 0
                        if calls or walkins:
                            total_loss_pipeline += int((calls * 800) + (walkins * 500))

        conversion_rate = round((converted / total * 100), 1) if total > 0 else 0.0

        return {
            "total_leads": total,
            "today_leads": today_count,
            "new_leads": new_leads,
            "active_onboarding": active_onboarding,
            "report_ready": report_ready,
            "report_viewed": report_viewed,
            "plan_selected": plan_selected,
            "stuck_abandoned": stuck_abandoned,
            "converted_leads": converted,
            "conversion_rate": conversion_rate,
            "total_loss_pipeline": total_loss_pipeline,
        }
