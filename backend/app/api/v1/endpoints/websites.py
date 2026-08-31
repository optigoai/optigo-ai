# ==================================================
# OptigoAI Backend — Business Website Builder Endpoints
# ==================================================

from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.api.v1.deps import get_db, get_current_user, get_org_id
from app.models.user import User
from app.models.business import Business
from app.models.business_website import BusinessWebsite
from app.schemas.website import (
    WebsiteResponse,
    WebsiteUpdateRequest,
    WebsiteStatusUpdateRequest,
)
from app.services.business_service import BusinessService
from app.services.website_generator_service import WebsiteGeneratorService

router = APIRouter(prefix="/businesses/{business_id}/website", tags=["Website Builder"])


@router.get("", response_model=WebsiteResponse)
async def get_business_website(
    business_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Retrieve the website configuration for a business."""
    org_id = get_org_id(current_user)
    biz_service = BusinessService(db)
    business = await biz_service.get_business(business_id, org_id)

    query = select(BusinessWebsite).where(
        BusinessWebsite.business_id == business.id,
        BusinessWebsite.organization_id == org_id,
    )
    result = await db.execute(query)
    site = result.scalars().first()

    if not site:
        # Generate initial draft if none exists
        generator = WebsiteGeneratorService(db)
        slug = await generator.get_unique_slug(business.name)
        data = await generator.generate_website_data(business)

        site = BusinessWebsite(
            business_id=business.id,
            organization_id=org_id,
            slug=slug,
            status="draft",
            seo_title=data["seo_title"],
            seo_description=data["seo_description"],
            content_json=data["content_json"],
        )
        db.add(site)
        await db.commit()
        await db.refresh(site)

    return site


@router.post("/generate", response_model=WebsiteResponse)
async def generate_business_website(
    business_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """AI generates or regenerates website content using current business data & reviews."""
    org_id = get_org_id(current_user)
    biz_service = BusinessService(db)
    business = await biz_service.get_business(business_id, org_id)

    generator = WebsiteGeneratorService(db)
    data = await generator.generate_website_data(business)

    query = select(BusinessWebsite).where(
        BusinessWebsite.business_id == business.id,
        BusinessWebsite.organization_id == org_id,
    )
    result = await db.execute(query)
    site = result.scalars().first()

    if site:
        site.seo_title = data["seo_title"]
        site.seo_description = data["seo_description"]
        site.content_json = data["content_json"]
        site.updated_at = datetime.utcnow()
    else:
        slug = await generator.get_unique_slug(business.name)
        site = BusinessWebsite(
            business_id=business.id,
            organization_id=org_id,
            slug=slug,
            status="draft",
            seo_title=data["seo_title"],
            seo_description=data["seo_description"],
            content_json=data["content_json"],
        )
        db.add(site)

    await db.commit()
    await db.refresh(site)
    return site


@router.put("", response_model=WebsiteResponse)
async def update_business_website(
    business_id: str,
    req: WebsiteUpdateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Save changes to website content, slug, SEO, and custom code overrides."""
    org_id = get_org_id(current_user)
    biz_service = BusinessService(db)
    business = await biz_service.get_business(business_id, org_id)

    query = select(BusinessWebsite).where(
        BusinessWebsite.business_id == business.id,
        BusinessWebsite.organization_id == org_id,
    )
    result = await db.execute(query)
    site = result.scalars().first()

    if not site:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Website not found. Please generate the initial draft first.",
        )

    # Validate slug uniqueness if changed
    if req.slug and req.slug != site.slug:
        generator = WebsiteGeneratorService(db)
        cleaned_slug = generator.slugify(req.slug)
        existing_query = select(BusinessWebsite).where(
            BusinessWebsite.slug == cleaned_slug,
            BusinessWebsite.id != site.id,
        )
        existing_res = await db.execute(existing_query)
        if existing_res.scalars().first():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"The URL slug '{cleaned_slug}' is already taken by another business. Please choose another.",
            )
        site.slug = cleaned_slug

    if req.seo_title is not None:
        site.seo_title = req.seo_title
    if req.seo_description is not None:
        site.seo_description = req.seo_description
    if req.content_json is not None:
        site.content_json = req.content_json
    if req.custom_html is not None:
        site.custom_html = req.custom_html
    if req.custom_css is not None:
        site.custom_css = req.custom_css
    if req.custom_js is not None:
        site.custom_js = req.custom_js

    site.updated_at = datetime.utcnow()
    await db.commit()
    await db.refresh(site)
    return site


@router.patch("/status", response_model=WebsiteResponse)
async def update_website_status(
    business_id: str,
    req: WebsiteStatusUpdateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Publish or unpublish the website."""
    org_id = get_org_id(current_user)
    biz_service = BusinessService(db)
    business = await biz_service.get_business(business_id, org_id)

    query = select(BusinessWebsite).where(
        BusinessWebsite.business_id == business.id,
        BusinessWebsite.organization_id == org_id,
    )
    result = await db.execute(query)
    site = result.scalars().first()

    if not site:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Website not found.",
        )

    site.status = req.status
    if req.status == "published" and not site.published_at:
        site.published_at = datetime.utcnow()

    site.updated_at = datetime.utcnow()
    await db.commit()
    await db.refresh(site)
    return site


@router.delete("", status_code=status.HTTP_204_NO_CONTENT)
async def delete_business_website(
    business_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Delete and reset the website for a business."""
    org_id = get_org_id(current_user)
    biz_service = BusinessService(db)
    business = await biz_service.get_business(business_id, org_id)

    query = select(BusinessWebsite).where(
        BusinessWebsite.business_id == business.id,
        BusinessWebsite.organization_id == org_id,
    )
    result = await db.execute(query)
    site = result.scalars().first()

    if site:
        await db.delete(site)
        await db.commit()

    return None
