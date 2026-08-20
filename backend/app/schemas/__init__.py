# ==================================================
# OptigoAI Backend — Pydantic Schemas
# ==================================================
"""
Request/response schemas. Never expose ORM models directly.
"""

from datetime import datetime
from typing import Optional, Any
from pydantic import BaseModel, EmailStr, Field


# ---- Generic ----

class HealthResponse(BaseModel):
    status: str = "ok"
    app_name: str
    version: str
    environment: str


class ErrorResponse(BaseModel):
    detail: str
    error_code: Optional[str] = None


class PaginatedResponse(BaseModel):
    items: list[Any]
    total: int
    page: int
    page_size: int
    total_pages: int


# ---- Auth ----

class SignupRequest(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=8, max_length=128)
    full_name: str = Field(..., min_length=2, max_length=255)
    organization_name: str = Field(..., min_length=2, max_length=255)


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int


class RefreshTokenRequest(BaseModel):
    refresh_token: str


class UserResponse(BaseModel):
    id: str
    email: str
    full_name: str
    role: str
    organization_id: Optional[str] = None
    is_active: bool
    created_at: datetime

    model_config = {"from_attributes": True}


# ---- Organization ----

class OrganizationResponse(BaseModel):
    id: str
    name: str
    slug: str
    is_active: bool
    created_at: datetime

    model_config = {"from_attributes": True}


# ---- Business ----

class BusinessCreateRequest(BaseModel):
    name: str = Field(..., min_length=2, max_length=255)
    category: Optional[str] = None
    location: Optional[str] = None
    website: Optional[str] = None
    phone: Optional[str] = None
    description: Optional[str] = None


class BusinessOnboardingRequest(BaseModel):
    target_customers: Optional[str] = None
    services: Optional[str] = None
    business_goals: Optional[str] = None
    marketing_channels: Optional[str] = None


class BusinessResponse(BaseModel):
    id: str
    name: str
    category: Optional[str] = None
    location: Optional[str] = None
    website: Optional[str] = None
    phone: Optional[str] = None
    description: Optional[str] = None
    health_score: Optional[int] = None
    onboarding_completed: bool
    ai_business_profile: Optional[dict[str, Any]] = None
    created_at: datetime

    model_config = {"from_attributes": True}
