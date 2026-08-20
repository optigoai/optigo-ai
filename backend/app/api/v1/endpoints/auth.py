from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.v1.deps import get_db, get_current_user
from app.core.config import settings
from app.models.user import User
from app.schemas import (
    SignupRequest,
    LoginRequest,
    RefreshTokenRequest,
    TokenResponse,
    UserResponse,
    OrganizationResponse,
    AuthResponse,
)
from app.services.auth_service import AuthService

router = APIRouter()


@router.post("/signup", response_model=AuthResponse, status_code=status.HTTP_201_CREATED)
async def signup(
    req: SignupRequest,
    db: AsyncSession = Depends(get_db),
):
    """Register a new user and create their organization."""
    auth_service = AuthService(db)
    user, org, access_token, refresh_token = await auth_service.signup(
        email=req.email,
        password=req.password,
        full_name=req.full_name,
        organization_name=req.organization_name,
    )
    return AuthResponse(
        user=UserResponse.model_validate(user),
        organization=OrganizationResponse.model_validate(org),
        tokens=TokenResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            token_type="bearer",
            expires_in=settings.access_token_expire_minutes * 60,
        ),
    )


@router.post("/login", response_model=AuthResponse)
async def login(
    req: LoginRequest,
    db: AsyncSession = Depends(get_db),
):
    """Authenticate with email and password."""
    auth_service = AuthService(db)
    user, access_token, refresh_token = await auth_service.login(
        email=req.email,
        password=req.password,
    )
    org_response = (
        OrganizationResponse.model_validate(user.organization)
        if user.organization
        else None
    )
    return AuthResponse(
        user=UserResponse.model_validate(user),
        organization=org_response,
        tokens=TokenResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            token_type="bearer",
            expires_in=settings.access_token_expire_minutes * 60,
        ),
    )


@router.post("/refresh", response_model=TokenResponse)
async def refresh(
    req: RefreshTokenRequest,
    db: AsyncSession = Depends(get_db),
):
    """Obtain a new access token using a valid refresh token."""
    auth_service = AuthService(db)
    user, new_access_token, new_refresh_token = await auth_service.refresh(
        refresh_token_str=req.refresh_token
    )
    return TokenResponse(
        access_token=new_access_token,
        refresh_token=new_refresh_token,
        token_type="bearer",
        expires_in=settings.access_token_expire_minutes * 60,
    )


@router.get("/me", response_model=AuthResponse)
async def get_me(
    current_user: User = Depends(get_current_user),
):
    """Get profile of currently logged-in user."""
    org_response = (
        OrganizationResponse.model_validate(current_user.organization)
        if current_user.organization
        else None
    )
    return AuthResponse(
        user=UserResponse.model_validate(current_user),
        organization=org_response,
        tokens=TokenResponse(
            access_token="",
            refresh_token="",
            token_type="bearer",
            expires_in=0,
        ),
    )


@router.post("/logout")
async def logout(
    current_user: User = Depends(get_current_user),
):
    """Logout current user session."""
    return {"message": "Successfully logged out"}
