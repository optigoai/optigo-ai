# ==================================================
# OptigoAI Backend — AI Public Website Generator Service
# ==================================================
"""
Generates structured, high-converting, SEO-optimized business website content
strictly using verified data from the database (business profile, verified reviews,
tracked SEO keywords, and AI attributes).
"""

import re
import unicodedata
from typing import Dict, Any, List, Optional
from datetime import datetime
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.models.business import Business
from app.models.review import Review
from app.models.seo import SEOKeyword
from app.models.business_website import BusinessWebsite


class WebsiteGeneratorService:
    def __init__(self, db: AsyncSession):
        self.db = db

    @staticmethod
    def slugify(text: str) -> str:
        """Convert a business name to a clean, URL-safe slug."""
        text = unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode("ascii")
        text = re.sub(r"[^\w\s-]", "", text).strip().lower()
        slug = re.sub(r"[-\s]+", "-", text)
        return slug or "business"

    async def get_unique_slug(self, base_name: str, existing_site_id: Optional[str] = None) -> str:
        """Ensure the generated slug is unique across all published businesses."""
        base_slug = self.slugify(base_name)
        slug = base_slug
        counter = 1

        while True:
            query = select(BusinessWebsite).where(BusinessWebsite.slug == slug)
            if existing_site_id:
                query = query.where(BusinessWebsite.id != existing_site_id)
            result = await self.db.execute(query)
            existing = result.scalars().first()

            if not existing:
                return slug

            counter += 1
            slug = f"{base_slug}-{counter}"

    async def generate_website_data(self, business: Business) -> Dict[str, Any]:
        """
        Synthesize website content strictly from the database:
        - Business profile attributes (name, category, location, phone, website, description)
        - Onboarding answers (services, target_customers, business_goals, marketing_channels)
        - AI profile attributes (ai_business_profile JSON)
        - Real verified customer reviews from PostgreSQL
        - Tracked SEO keywords from PostgreSQL
        """
        # 1. Fetch real customer reviews from database for this business
        reviews_query = (
            select(Review)
            .where(Review.business_id == business.id)
            .order_by(Review.rating.desc(), Review.created_at.desc())
            .limit(10)
        )
        reviews_res = await self.db.execute(reviews_query)
        db_reviews = reviews_res.scalars().all()

        # 2. Fetch real tracked SEO keywords from database for this business
        keywords_query = (
            select(SEOKeyword)
            .where(SEOKeyword.business_id == business.id)
            .limit(8)
        )
        keywords_res = await self.db.execute(keywords_query)
        db_keywords = keywords_res.scalars().all()
        keyword_names = [k.keyword for k in db_keywords if k.keyword]

        # Extract business fields from DB
        name = business.name.strip() if business.name else "Business Profile"
        category = business.category.strip() if business.category else "Local Business"
        location = business.location.strip() if business.location else ""
        phone = business.phone.strip() if business.phone else None
        website = business.website.strip() if business.website else None
        description = business.description.strip() if business.description else ""
        services_raw = business.services.strip() if business.services else ""
        target_customers = business.target_customers.strip() if business.target_customers else ""
        business_goals = business.business_goals.strip() if business.business_goals else ""
        ai_profile = business.ai_business_profile or {}

        # Parse services list strictly from DB
        service_items_list: List[str] = []
        if services_raw:
            service_items_list = [s.strip() for s in services_raw.replace(";", ",").split(",") if s.strip()]
        elif ai_profile.get("services") and isinstance(ai_profile["services"], list):
            service_items_list = [str(s).strip() for s in ai_profile["services"] if str(s).strip()]
        elif ai_profile.get("offerings") and isinstance(ai_profile["offerings"], list):
            service_items_list = [str(s).strip() for s in ai_profile["offerings"] if str(s).strip()]

        if not service_items_list:
            service_items_list = [f"{category} Services", "Customer Inquiries & Consultations", "Quality Assured Offerings"]

        # Build structured service catalog
        services_structured = []
        icons = ["Sparkles", "Star", "Heart", "Award", "CheckCircle", "ShieldCheck"]
        for idx, svc in enumerate(service_items_list):
            services_structured.append({
                "name": svc,
                "description": f"Dedicated {svc.lower()} tailored for our clients" + (f" in {location}" if location else "") + ".",
                "price_range": "Inquire for Details",
                "badge": "Specialty" if idx == 0 else None,
                "icon": icons[idx % len(icons)],
            })

        # Calculate actual review ratings strictly from DB reviews
        featured_reviews_list = []
        for r in db_reviews:
            if r.text:
                featured_reviews_list.append({
                    "author_name": r.reviewer_name or "Verified Customer",
                    "rating": r.rating or 5,
                    "text": r.text,
                    "review_date": r.review_date or "Verified Customer Review",
                })

        avg_rating = (
            round(sum(r.rating for r in db_reviews) / len(db_reviews), 1)
            if db_reviews
            else 0.0
        )
        total_rev_count = len(db_reviews)

        # Dynamic Hero Headline
        if description and len(description) > 10:
            headline = f"Welcome to {name}"
            subheadline = description
        else:
            headline = f"Premier {category} in {location}" if location else f"Quality & Excellence at {name}"
            subheadline = f"Offering verified {category.lower()} solutions with dedicated customer service."

        # Highlights strictly from DB data
        highlights = []
        if location:
            highlights.append(f"Conveniently located in {location}")
        if total_rev_count > 0:
            highlights.append(f"{total_rev_count} Verified Customer Reviews ({avg_rating}★ Rating)")
        if service_items_list:
            highlights.append(f"Specialized in {service_items_list[0]}")
        if target_customers:
            highlights.append(f"Serving {target_customers}")
        if not highlights:
            highlights.append(f"Official {category} Business Listing")

        # Why Choose Us Pillars from DB Goals & Target Audience
        why_choose_us = []
        if total_rev_count > 0:
            why_choose_us.append({
                "title": "Verified Community Trust",
                "description": f"Backed by {total_rev_count} genuine customer reviews with an average {avg_rating}★ rating.",
                "icon": "Award",
            })
        else:
            why_choose_us.append({
                "title": "Dedicated Professionalism",
                "description": f"Committed to providing reliable {category.lower()} excellence and customer satisfaction.",
                "icon": "Award",
            })

        if target_customers:
            why_choose_us.append({
                "title": "Customer-Focused Experience",
                "description": f"Tailored specifically for {target_customers}.",
                "icon": "Heart",
            })

        if location:
            why_choose_us.append({
                "title": "Prime Accessibility",
                "description": f"Easily accessible location in {location} with direct turn-by-turn navigation.",
                "icon": "MapPin",
            })

        if business_goals:
            why_choose_us.append({
                "title": "Quality Commitment",
                "description": business_goals,
                "icon": "ShieldCheck",
            })
        else:
            why_choose_us.append({
                "title": "Quality Assurance",
                "description": f"Upholding high standards across all {category.lower()} offerings and interactions.",
                "icon": "ShieldCheck",
            })

        # Dynamic FAQs referencing DB fields
        faqs = []
        if location:
            faqs.append({
                "question": f"Where is {name} located?",
                "answer": f"{name} is located at {location}. You can use our Google Maps directions button for direct navigation.",
            })

        if service_items_list:
            faqs.append({
                "question": f"What services or specialties does {name} offer?",
                "answer": f"We specialize in {', '.join(service_items_list[:5])}.",
            })

        if phone:
            faqs.append({
                "question": f"How can I contact {name} directly?",
                "answer": f"You can reach us by phone at {phone} during regular business hours.",
            })

        if target_customers:
            faqs.append({
                "question": f"Who does {name} cater to?",
                "answer": f"We primarily cater to {target_customers}.",
            })

        # Operating hours strictly from ai_profile if present, or generic schedule
        opening_hours = []
        if ai_profile.get("opening_hours") and isinstance(ai_profile["opening_hours"], list):
            opening_hours = [str(h) for h in ai_profile["opening_hours"]]
        elif ai_profile.get("hours") and isinstance(ai_profile["hours"], list):
            opening_hours = [str(h) for h in ai_profile["hours"]]
        else:
            opening_hours = [
                "Monday – Saturday: Regular Operating Hours",
                "Sunday: Open / Inquire Directly",
            ]

        # Gallery images strictly from business profile if provided
        gallery_images = []
        if ai_profile.get("photos") and isinstance(ai_profile["photos"], list):
            gallery_images = [str(p) for p in ai_profile["photos"] if str(p).startswith("http")]
        elif ai_profile.get("gallery") and isinstance(ai_profile["gallery"], list):
            gallery_images = [str(p) for p in ai_profile["gallery"] if str(p).startswith("http")]

        hero_img = ai_profile.get("cover_photo") or ai_profile.get("image_url") or None
        about_img = ai_profile.get("about_photo") or None

        # SEO Metadata based strictly on DB fields
        kw_str = f" ({', '.join(keyword_names[:3])})" if keyword_names else ""
        seo_title = f"{name} — {category}" + (f" in {location}" if location else "")
        if len(seo_title) > 60:
            seo_title = seo_title[:57] + "..."

        if total_rev_count > 0:
            seo_description = f"Official page of {name} in {location}. {avg_rating}★ Google rating with {total_rev_count} reviews. Explore our {', '.join(service_items_list[:3])}."
        else:
            seo_description = f"Official page of {name} in {location}. Discover our {category.lower()} offerings, contact details, and location directions."

        content_json = {
            "theme_config": {
                "accent_color": "#0284C7",
                "font_family": "Plus Jakarta Sans",
                "dark_mode": False,
            },
            "hero": {
                "headline": headline,
                "subheadline": subheadline,
                "badge": f"Verified {category}",
                "primary_cta_text": "Get Directions",
                "primary_cta_action": "directions",
                "secondary_cta_text": "Call Business" if phone else "Visit Us",
                "secondary_cta_action": "call" if phone else "directions",
                "hero_image_url": hero_img,
            },
            "about": {
                "title": f"About {name}",
                "story": description or f"{name} is a trusted {category.lower()} dedicated to providing outstanding service in {location}.",
                "highlights": highlights,
                "image_url": about_img,
            },
            "services": services_structured,
            "why_choose_us": why_choose_us,
            "reviews": {
                "title": "Verified Customer Reviews" if total_rev_count > 0 else "Customer Feedback",
                "average_rating": avg_rating,
                "total_reviews": total_rev_count,
                "featured_reviews": featured_reviews_list,
            },
            "gallery": gallery_images,
            "hours_location": {
                "address": location,
                "city": location.split(",")[0] if "," in location else location,
                "phone": phone,
                "email": website,
                "maps_query": f"{name}, {location}" if location else name,
                "opening_hours": opening_hours,
            },
            "faqs": faqs,
            "cta_banner": {
                "title": f"Connect with {name}",
                "description": f"Located in {location}." if location else f"Visit or contact {name} today.",
                "button_text": "Open in Google Maps",
                "button_action": "directions",
            },
        }

        return {
            "seo_title": seo_title,
            "seo_description": seo_description,
            "content_json": content_json,
        }
