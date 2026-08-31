# ==================================================
# OptigoAI Backend — Public Website Engine Endpoints
# ==================================================

from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update

from app.api.v1.deps import get_db
from app.models.business_website import BusinessWebsite
from app.models.business import Business
from app.schemas.website import PublicWebsiteResponse

router = APIRouter(prefix="/public/sites", tags=["Public Website Engine"])


@router.get("/check-slug")
async def check_slug_availability(
    slug: str,
    db: AsyncSession = Depends(get_db),
):
    """Check if a URL slug is available for publishing."""
    query = select(BusinessWebsite).where(BusinessWebsite.slug == slug.lower().strip())
    res = await db.execute(query)
    existing = res.scalars().first()
    return {"slug": slug, "available": existing is None}


@router.get("/sitemap.xml", response_class=Response)
async def generate_sitemap_xml(
    db: AsyncSession = Depends(get_db),
):
    """Generate dynamic XML sitemap of all published Optigo business websites."""
    query = (
        select(BusinessWebsite)
        .where(BusinessWebsite.status == "published")
        .order_by(BusinessWebsite.updated_at.desc())
    )
    result = await db.execute(query)
    published_sites = result.scalars().all()

    urls_xml = []
    base_domain = "https://optigoai.com"

    for site in published_sites:
        lastmod = (site.updated_at or site.created_at or datetime.utcnow()).strftime("%Y-%m-%d")
        urls_xml.append(f"""  <url>
    <loc>{base_domain}/{site.slug}</loc>
    <lastmod>{lastmod}</lastmod>
    <changefreq>weekly</changefreq>
    <priority>0.8</priority>
  </url>""")

    sitemap_content = f"""<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>{base_domain}/</loc>
    <changefreq>daily</changefreq>
    <priority>1.0</priority>
  </url>
{"".join(urls_xml)}
</urlset>"""

    return Response(content=sitemap_content, media_type="application/xml")


@router.get("/{slug}", response_model=PublicWebsiteResponse)
async def get_public_website_by_slug(
    slug: str,
    db: AsyncSession = Depends(get_db),
):
    """
    Public-safe endpoint returning verified business website data for public rendering.
    Enforces that only published websites are accessible to public visitors.
    """
    query = (
        select(BusinessWebsite)
        .where(BusinessWebsite.slug == slug.lower().strip())
    )
    result = await db.execute(query)
    site = result.scalars().first()

    if not site:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Business page not found or is currently private.",
        )

    # If site is not published, return 404 to public crawlers
    if site.status != "published":
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="This business page is currently unpublished.",
        )

    # Increment view count
    try:
        site.view_count += 1
        await db.commit()
    except Exception:
        pass

    biz = site.business
    content = site.content_json or {}
    hours_loc = content.get("hours_location", {})
    reviews_sec = content.get("reviews", {})

    # Generate Schema.org JSON-LD Structured Data
    schema_org = {
        "@context": "https://schema.org",
        "@type": "LocalBusiness",
        "name": biz.name,
        "description": site.seo_description or biz.description,
        "telephone": biz.phone or hours_loc.get("phone"),
        "url": f"https://optigoai.com/{site.slug}",
        "address": {
            "@type": "PostalAddress",
            "streetAddress": biz.location or hours_loc.get("address"),
            "addressLocality": hours_loc.get("city", "Edappal"),
            "addressCountry": "IN",
        },
    }

    if reviews_sec.get("average_rating") and reviews_sec.get("total_reviews"):
        schema_org["aggregateRating"] = {
            "@type": "AggregateRating",
            "ratingValue": str(reviews_sec["average_rating"]),
            "reviewCount": str(reviews_sec["total_reviews"]),
        }

    return PublicWebsiteResponse(
        id=site.id,
        business_name=biz.name,
        category=biz.category or "Local Business",
        location=biz.location or "Local Area",
        phone=biz.phone,
        website_url=biz.website,
        slug=site.slug,
        seo_title=site.seo_title or f"{biz.name} — Official Website",
        seo_description=site.seo_description or f"Official business page of {biz.name}.",
        content=content,
        custom_html=site.custom_html,
        custom_css=site.custom_css,
        custom_js=site.custom_js,
        published_at=site.published_at,
        canonical_url=f"https://optigoai.com/{site.slug}",
        schema_org_json=schema_org,
    )
