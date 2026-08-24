from typing import List, Optional
from datetime import datetime, timedelta
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc

from app.models.seo import SEOKeyword, SEOAudit, SEOAuditSnapshot


class SEORepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_keywords_by_business(self, business_id: str) -> List[SEOKeyword]:
        stmt = (
            select(SEOKeyword)
            .where(SEOKeyword.business_id == business_id)
            .order_by(SEOKeyword.current_rank.asc().nulls_last(), SEOKeyword.created_at.desc())
        )
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def get_keyword_by_id(self, keyword_id: str, business_id: str) -> Optional[SEOKeyword]:
        stmt = select(SEOKeyword).where(
            SEOKeyword.id == keyword_id,
            SEOKeyword.business_id == business_id,
        )
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def get_keyword_by_text(self, business_id: str, keyword: str) -> Optional[SEOKeyword]:
        stmt = select(SEOKeyword).where(
            SEOKeyword.business_id == business_id,
            SEOKeyword.keyword.ilike(keyword.strip()),
        )
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def create_keyword(self, keyword_obj: SEOKeyword) -> SEOKeyword:
        self.db.add(keyword_obj)
        await self.db.commit()
        await self.db.refresh(keyword_obj)
        return keyword_obj

    async def delete_keyword(self, keyword_obj: SEOKeyword) -> None:
        await self.db.delete(keyword_obj)
        await self.db.commit()

    async def get_latest_audit(self, business_id: str) -> Optional[SEOAudit]:
        stmt = (
            select(SEOAudit)
            .where(SEOAudit.business_id == business_id)
            .order_by(desc(SEOAudit.created_at))
            .limit(1)
        )
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def save_audit(self, audit_obj: SEOAudit) -> SEOAudit:
        self.db.add(audit_obj)
        await self.db.commit()
        await self.db.refresh(audit_obj)
        return audit_obj

    async def save_snapshot(self, snapshot: SEOAuditSnapshot) -> SEOAuditSnapshot:
        self.db.add(snapshot)
        await self.db.commit()
        await self.db.refresh(snapshot)
        return snapshot

    async def get_snapshots(self, business_id: str, days: int = 7) -> List[SEOAuditSnapshot]:
        since = datetime.utcnow() - timedelta(days=days)
        stmt = (
            select(SEOAuditSnapshot)
            .where(SEOAuditSnapshot.business_id == business_id, SEOAuditSnapshot.recorded_at >= since)
            .order_by(SEOAuditSnapshot.recorded_at.asc())
        )
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

