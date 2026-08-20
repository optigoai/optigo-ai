import re
import uuid
from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models.organization import Organization


def slugify(text: str) -> str:
    text = re.sub(r"[^\w\s-]", "", text).strip().lower()
    text = re.sub(r"[-\s]+", "-", text)
    return text or "org"


class OrganizationRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_by_id(self, org_id: str) -> Optional[Organization]:
        result = await self.db.execute(select(Organization).where(Organization.id == org_id))
        return result.scalar_one_or_none()

    async def get_by_slug(self, slug: str) -> Optional[Organization]:
        result = await self.db.execute(select(Organization).where(Organization.slug == slug))
        return result.scalar_one_or_none()

    async def create(self, name: str) -> Organization:
        base_slug = slugify(name)
        slug = base_slug

        # Ensure slug uniqueness
        existing = await self.get_by_slug(slug)
        if existing:
            slug = f"{base_slug}-{uuid.uuid4().hex[:6]}"

        org = Organization(
            name=name,
            slug=slug,
            is_active=True,
        )
        self.db.add(org)
        await self.db.flush()
        return org
