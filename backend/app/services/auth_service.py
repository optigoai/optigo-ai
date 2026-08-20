from typing import Tuple, Optional
from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import (
    hash_password,
    verify_password,
    create_access_token,
    create_refresh_token,
    decode_token,
)
from app.core.config import settings
from app.models.user import User, UserRole
from app.models.organization import Organization
from app.repositories.user_repo import UserRepository
from app.repositories.org_repo import OrganizationRepository


class AuthService:
    def __init__(self, db: AsyncSession):
        self.db = db
        self.user_repo = UserRepository(db)
        self.org_repo = OrganizationRepository(db)

    async def signup(
        self,
        email: str,
        password: str,
        full_name: str,
        organization_name: str,
    ) -> Tuple[User, Organization, str, str]:
        # Check if email is already registered
        existing_user = await self.user_repo.get_by_email(email)
        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="A user with this email address already exists.",
            )

        # 1. Create Organization
        org = await self.org_repo.create(name=organization_name)

        # 2. Hash password securely
        pwd_hash = hash_password(password)

        # 3. Create User as Owner of this Organization
        user = await self.user_repo.create(
            email=email,
            password_hash=pwd_hash,
            full_name=full_name,
            role=UserRole.OWNER,
            organization_id=org.id,
        )

        # 4. Generate JWT tokens
        access_token = create_access_token(
            user_id=user.id,
            org_id=org.id,
            role=user.role.value,
        )
        refresh_token = create_refresh_token(
            user_id=user.id,
            org_id=org.id,
            role=user.role.value,
        )

        return user, org, access_token, refresh_token

    async def login(
        self, email: str, password: str
    ) -> Tuple[User, str, str]:
        user = await self.user_repo.get_by_email(email)
        if not user or not verify_password(password, user.password_hash):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password.",
            )

        if not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Account has been suspended. Please contact support.",
            )

        access_token = create_access_token(
            user_id=user.id,
            org_id=user.organization_id,
            role=user.role.value,
        )
        refresh_token = create_refresh_token(
            user_id=user.id,
            org_id=user.organization_id,
            role=user.role.value,
        )
        return user, access_token, refresh_token

    async def refresh(self, refresh_token_str: str) -> Tuple[User, str, str]:
        payload = decode_token(refresh_token_str)
        if not payload or payload.token_type != "refresh":
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid or expired refresh token.",
            )

        user = await self.user_repo.get_by_id(payload.sub)
        if not user or not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User not found or inactive.",
            )

        new_access_token = create_access_token(
            user_id=user.id,
            org_id=user.organization_id,
            role=user.role.value,
        )
        new_refresh_token = create_refresh_token(
            user_id=user.id,
            org_id=user.organization_id,
            role=user.role.value,
        )
        return user, new_access_token, new_refresh_token
