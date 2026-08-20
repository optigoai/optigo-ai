from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models.user import User, UserRole


class UserRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_by_id(self, user_id: str) -> Optional[User]:
        result = await self.db.execute(select(User).where(User.id == user_id))
        return result.scalar_one_or_none()

    async def get_by_email(self, email: str) -> Optional[User]:
        result = await self.db.execute(select(User).where(User.email == email.lower()))
        return result.scalar_one_or_none()

    async def create(
        self,
        email: str,
        password_hash: str,
        full_name: str,
        role: UserRole = UserRole.OWNER,
        organization_id: Optional[str] = None,
    ) -> User:
        user = User(
            email=email.lower(),
            password_hash=password_hash,
            full_name=full_name,
            role=role,
            organization_id=organization_id,
        )
        self.db.add(user)
        await self.db.flush()
        return user
