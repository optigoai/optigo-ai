# ==================================================
# OptigoAI Backend — Content & Social Media Endpoints
# ==================================================

from typing import Optional, List
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.v1.deps import get_db, get_current_user
from app.models.user import User
from app.schemas import (
    ContentGenerateRequest,
    ContentGenerateResponse,
    ContentCreateRequest,
    ContentUpdateRequest,
    ContentResponse,
)
from app.services.content_engine_service import ContentEngineService

router = APIRouter(prefix="/contents", tags=["Content & Social Posts"])


@router.post(
    "/generate",
    response_model=ContentGenerateResponse,
    status_code=status.HTTP_200_OK,
    summary="Generate multi-channel marketing & social media posts",
)
async def generate_posts(
    req: ContentGenerateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Generates tailor-made posts for Google Business, Instagram, Facebook, and LinkedIn."""
    service = ContentEngineService(db)
    result = await service.generate_social_posts(
        business_id=req.business_id,
        organization_id=current_user.organization_id,
        user_id=current_user.id,
        channels=req.channels,
        topic=req.topic,
        tone=req.tone,
        goal=req.goal,
        offer_details=req.offer_details,
    )
    return ContentGenerateResponse(**result)


@router.post(
    "",
    response_model=ContentResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create or schedule a social media post",
)
async def create_post(
    req: ContentCreateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Save a post draft or scheduled post."""
    service = ContentEngineService(db)
    post = await service.create_post(
        business_id=req.business_id,
        organization_id=current_user.organization_id,
        content_data=req.model_dump(exclude_unset=True),
    )
    return post


@router.get(
    "",
    response_model=List[ContentResponse],
    status_code=status.HTTP_200_OK,
    summary="List posts and content items for a business",
)
async def list_posts(
    business_id: str = Query(..., description="Target business ID"),
    content_type: Optional[str] = Query(None, description="google_post, instagram, facebook, linkedin"),
    status: Optional[str] = Query(None, description="draft, scheduled, published, failed"),
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Retrieve posts with optional filtering by channel and status."""
    service = ContentEngineService(db)
    return await service.list_posts(
        business_id=business_id,
        organization_id=current_user.organization_id,
        content_type=content_type,
        status_filter=status,
        limit=limit,
        offset=offset,
    )


@router.get(
    "/{id}",
    response_model=ContentResponse,
    status_code=status.HTTP_200_OK,
    summary="Get single post details",
)
async def get_post(
    id: str,
    business_id: str = Query(..., description="Target business ID"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get details of a specific post."""
    service = ContentEngineService(db)
    return await service.get_post(
        content_id=id,
        business_id=business_id,
        organization_id=current_user.organization_id,
    )


@router.patch(
    "/{id}",
    response_model=ContentResponse,
    status_code=status.HTTP_200_OK,
    summary="Update an existing post or draft",
)
async def update_post(
    id: str,
    req: ContentUpdateRequest,
    business_id: str = Query(..., description="Target business ID"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Update post content, status, or schedule."""
    service = ContentEngineService(db)
    return await service.update_post(
        content_id=id,
        business_id=business_id,
        organization_id=current_user.organization_id,
        update_data=req.model_dump(exclude_unset=True),
    )


@router.post(
    "/{id}/publish",
    response_model=ContentResponse,
    status_code=status.HTTP_200_OK,
    summary="Publish a post immediately",
)
async def publish_post(
    id: str,
    business_id: str = Query(..., description="Target business ID"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Mark a post as published and record timestamp."""
    service = ContentEngineService(db)
    return await service.publish_post(
        content_id=id,
        business_id=business_id,
        organization_id=current_user.organization_id,
    )


@router.delete(
    "/{id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete a post",
)
async def delete_post(
    id: str,
    business_id: str = Query(..., description="Target business ID"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Delete a post item."""
    service = ContentEngineService(db)
    await service.delete_post(
        content_id=id,
        business_id=business_id,
        organization_id=current_user.organization_id,
    )
    return None
