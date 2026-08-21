# ==================================================
# OptigoAI Backend — Google Search Console Repository
# ==================================================

from datetime import datetime, date
from typing import Optional, List, Sequence
from sqlalchemy import select, delete, desc
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.gsc import GoogleSearchConsoleConnection, SearchConsoleMetric


class GoogleSearchConsoleRepository:
    """Multi-tenant data access layer for Google Search Console."""

    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_connection_by_business(self, business_id: str) -> Optional[GoogleSearchConsoleConnection]:
        stmt = select(GoogleSearchConsoleConnection).where(GoogleSearchConsoleConnection.business_id == business_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def upsert_connection(self, connection: GoogleSearchConsoleConnection) -> GoogleSearchConsoleConnection:
        existing = await self.get_connection_by_business(connection.business_id)
        if existing:
            existing.site_url = connection.site_url or existing.site_url
            existing.access_token = connection.access_token or existing.access_token
            existing.refresh_token = connection.refresh_token or existing.refresh_token
            existing.token_expires_at = connection.token_expires_at or existing.token_expires_at
            existing.is_connected = connection.is_connected
            existing.sync_status = connection.sync_status
            existing.last_synced_at = connection.last_synced_at or existing.last_synced_at
            existing.sync_error = connection.sync_error
            await self.db.flush()
            return existing
        else:
            self.db.add(connection)
            await self.db.flush()
            return connection

    async def disconnect(self, business_id: str) -> None:
        conn = await self.get_connection_by_business(business_id)
        if conn:
            conn.is_connected = False
            conn.access_token = None
            conn.refresh_token = None
            conn.sync_status = "disconnected"
            await self.db.flush()

    async def save_metrics(self, metrics: List[SearchConsoleMetric]) -> List[SearchConsoleMetric]:
        if not metrics:
            return []
        self.db.add_all(metrics)
        await self.db.flush()
        return metrics

    async def get_latest_metrics(self, business_id: str, limit: int = 10) -> Sequence[SearchConsoleMetric]:
        stmt = (
            select(SearchConsoleMetric)
            .where(SearchConsoleMetric.business_id == business_id)
            .order_by(desc(SearchConsoleMetric.clicks), desc(SearchConsoleMetric.impressions))
            .limit(limit)
        )
        result = await self.db.execute(stmt)
        return result.scalars().all()
