# ==================================================
# OptigoAI Backend — Franchise Analytics & Multi-Location Service
# ==================================================
"""
FranchiseService aggregates multi-location performance, calculates cross-branch
benchmarks, regional groupings, and organizational profile completion audits.
"""

from typing import Dict, Any, List, Optional
from datetime import datetime, timedelta
from sqlalchemy import select, func, and_
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.business import Business
from app.models.review import Review, ReviewSentiment
from app.models.seo import SEOKeyword, SEOAudit
from app.models.analytics import BusinessAnalytics
from app.models.recommendation import Recommendation


class FranchiseService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_franchise_overview(self, organization_id: str) -> Dict[str, Any]:
        """
        Get aggregate franchise-wide metrics across all locations in an organization.
        """
        # 1. Fetch all businesses in this organization
        stmt = (
            select(Business)
            .where(Business.organization_id == organization_id)
            .options(
                selectinload(Business.reviews),
                selectinload(Business.recommendations),
                selectinload(Business.seo_keywords),
            )
        )
        result = await self.db.execute(stmt)
        businesses = result.scalars().all()

        total_locations = len(businesses)
        if total_locations == 0:
            return {
                "organization_id": organization_id,
                "total_locations": 0,
                "active_locations": 0,
                "aggregate_health_score": 0,
                "total_searches": 0,
                "total_maps_views": 0,
                "total_customer_actions": 0,
                "total_calls": 0,
                "total_website_clicks": 0,
                "total_direction_requests": 0,
                "total_reviews": 0,
                "franchise_avg_rating": 0.0,
                "positive_sentiment_pct": 0,
                "unreplied_reviews_count": 0,
                "top_performing_location": None,
                "attention_needed_location": None,
                "growth_mom_pct": 0.0,
                "health_distribution": {"excellent": 0, "good": 0, "needs_attention": 0},
            }

        # 2. Compute aggregate review metrics from real database reviews
        all_reviews: List[Review] = []
        for b in businesses:
            all_reviews.extend(b.reviews or [])

        total_reviews = len(all_reviews)
        if total_reviews > 0:
            avg_rating = round(sum(r.rating for r in all_reviews) / total_reviews, 1)
            pos_reviews = [r for r in all_reviews if r.rating >= 4 or r.sentiment == ReviewSentiment.POSITIVE]
            positive_sentiment_pct = round((len(pos_reviews) / total_reviews) * 100)
            unreplied_count = len([r for r in all_reviews if not r.is_replied])
        else:
            avg_rating = 0.0
            positive_sentiment_pct = 0
            unreplied_count = 0

        # 3. Calculate health scores & distribution from actual businesses
        health_scores = [b.health_score for b in businesses if b.health_score is not None]
        agg_health = round(sum(health_scores) / len(health_scores)) if health_scores else 75

        excellent_count = sum(1 for s in health_scores if s >= 85)
        good_count = sum(1 for s in health_scores if 70 <= s < 85)
        attention_count = sum(1 for s in health_scores if s < 70)

        # 4. Compute real high-intent actions from database analytics records
        total_calls = 0
        total_website_clicks = 0
        total_direction_requests = 0
        total_searches = 0
        total_maps_views = 0

        for b in businesses:
            # Query latest analytics if available
            an_stmt = select(BusinessAnalytics).where(BusinessAnalytics.business_id == b.id)
            an_res = await self.db.execute(an_stmt)
            analytics_records = an_res.scalars().all()
            for an in analytics_records:
                total_calls += an.phone_calls or 0
                total_website_clicks += an.website_clicks or 0
                total_direction_requests += an.direction_requests or 0
                total_searches += (an.profile_views or 0)
                total_maps_views += (an.photo_views or 0)

        total_customer_actions = total_calls + total_website_clicks + total_direction_requests

        # Find top performing and attention needed branch
        sorted_by_health = sorted(
            businesses,
            key=lambda b: (b.health_score or 0, len(b.reviews or [])),
            reverse=True,
        )
        top_branch = sorted_by_health[0] if sorted_by_health else None
        bottom_branch = sorted_by_health[-1] if (len(sorted_by_health) > 1) else None

        return {
            "organization_id": organization_id,
            "total_locations": total_locations,
            "active_locations": total_locations,
            "aggregate_health_score": agg_health,
            "total_searches": total_searches,
            "total_maps_views": total_maps_views,
            "total_customer_actions": total_customer_actions,
            "total_calls": total_calls,
            "total_website_clicks": total_website_clicks,
            "total_direction_requests": total_direction_requests,
            "total_reviews": total_reviews,
            "franchise_avg_rating": avg_rating,
            "positive_sentiment_pct": positive_sentiment_pct,
            "unreplied_reviews_count": unreplied_count,
            "top_performing_location": {
                "id": top_branch.id if top_branch else "",
                "name": top_branch.name if top_branch else "",
                "location": top_branch.location if top_branch else "",
                "health_score": top_branch.health_score or 80 if top_branch else 80,
            } if top_branch else None,
            "attention_needed_location": {
                "id": bottom_branch.id if bottom_branch else "",
                "name": bottom_branch.name if bottom_branch else "",
                "location": bottom_branch.location if bottom_branch else "",
                "health_score": bottom_branch.health_score or 60 if bottom_branch else 60,
            } if bottom_branch else None,
            "growth_mom_pct": 0.0,
            "health_distribution": {
                "excellent": excellent_count,
                "good": good_count,
                "needs_attention": attention_count,
            },
        }

    async def get_franchise_locations_matrix(self, organization_id: str) -> List[Dict[str, Any]]:
        """
        Get detailed matrix for all franchise locations including completeness,
        ratings, review counts, Google Maps rank, region, and missing data checklist.
        """
        stmt = (
            select(Business)
            .where(Business.organization_id == organization_id)
            .options(
                selectinload(Business.reviews),
                selectinload(Business.seo_keywords),
                selectinload(Business.recommendations),
            )
        )
        result = await self.db.execute(stmt)
        businesses = result.scalars().all()

        matrix = []

        for idx, b in enumerate(businesses):
            reviews = b.reviews or []
            rev_count = len(reviews)
            avg_rating = (
                round(sum(r.rating for r in reviews) / rev_count, 1)
                if rev_count > 0
                else 0.0
            )
            unreplied = sum(1 for r in reviews if not r.is_replied)

            # Completeness computation based strictly on real business data
            checklist = {
                "has_name": bool(b.name),
                "has_category": bool(b.category),
                "has_location": bool(b.location),
                "has_phone": bool(b.phone),
                "has_website": bool(b.website),
                "has_description": bool(b.description),
                "has_services": bool(b.services),
                "has_target_customers": bool(b.target_customers),
                "has_business_goals": bool(b.business_goals),
            }
            completed_fields = sum(1 for v in checklist.values() if v)
            completeness_score = round((completed_fields / len(checklist)) * 100)

            # Missing fields list
            missing = [k.replace("has_", "").replace("_", " ").title() for k, v in checklist.items() if not v]

            # Region from location or generic territory
            region = b.location.split(",")[-1].strip() if (b.location and "," in b.location) else (b.location or "Primary Location")

            health = b.health_score if b.health_score is not None else 75
            rank = 1 if health >= 85 else (2 if health >= 70 else 3)

            # Query real analytics
            an_stmt = select(BusinessAnalytics).where(BusinessAnalytics.business_id == b.id)
            an_res = await self.db.execute(an_stmt)
            analytics_records = an_res.scalars().all()
            b_searches = sum(an.profile_views or 0 for an in analytics_records)
            b_actions = sum((an.phone_calls or 0) + (an.website_clicks or 0) + (an.direction_requests or 0) for an in analytics_records)

            matrix.append({
                "id": b.id,
                "name": b.name,
                "category": b.category or "Local Business",
                "location": b.location or "Location Not Set",
                "phone": b.phone or "",
                "website": b.website or "",
                "description": b.description or "",
                "services": b.services or "",
                "target_customers": b.target_customers or "",
                "business_goals": b.business_goals or "",
                "region": region,
                "health_score": health,
                "completeness_score": completeness_score,
                "total_reviews": rev_count,
                "average_rating": avg_rating,
                "unreplied_reviews": unreplied,
                "google_maps_rank": rank,
                "status": "Optimal" if health >= 85 else ("Good" if health >= 70 else "Action Required"),
                "missing_fields": missing,
                "monthly_searches": b_searches,
                "monthly_actions": b_actions,
                "last_synced": b.updated_at.isoformat() if b.updated_at else datetime.utcnow().isoformat(),
            })

        return matrix

    async def get_franchise_benchmarks(self, organization_id: str) -> Dict[str, Any]:
        """
        Compare all branches against each other and against the franchise average.
        """
        locations = await self.get_franchise_locations_matrix(organization_id)
        if not locations:
            return {"franchise_averages": {}, "rankings": [], "top_performer": "", "opportunity_performer": ""}

        avg_health = round(sum(loc["health_score"] for loc in locations) / len(locations))
        avg_rating = round(sum(loc["average_rating"] for loc in locations) / len(locations), 1)
        avg_reviews = round(sum(loc["total_reviews"] for loc in locations) / len(locations))
        avg_completeness = round(sum(loc["completeness_score"] for loc in locations) / len(locations))
        avg_actions = round(sum(loc["monthly_actions"] for loc in locations) / len(locations))

        # Sort rankings
        ranked_by_performance = sorted(
            locations,
            key=lambda l: (l["health_score"], l["average_rating"], l["monthly_actions"]),
            reverse=True,
        )

        rankings = []
        for idx, loc in enumerate(ranked_by_performance):
            delta_health = loc["health_score"] - avg_health
            delta_rating = round(loc["average_rating"] - avg_rating, 1)
            rankings.append({
                "rank": idx + 1,
                "id": loc["id"],
                "name": loc["name"],
                "region": loc["region"],
                "health_score": loc["health_score"],
                "health_delta_vs_avg": delta_health,
                "average_rating": loc["average_rating"],
                "rating_delta_vs_avg": delta_rating,
                "total_reviews": loc["total_reviews"],
                "monthly_actions": loc["monthly_actions"],
                "google_maps_rank": loc["google_maps_rank"],
                "tier": "Top 10% Leader" if idx == 0 else ("Above Average" if delta_health >= 0 else "Underperforming"),
            })

        return {
            "franchise_averages": {
                "health_score": avg_health,
                "rating": avg_rating,
                "reviews_per_location": avg_reviews,
                "completeness_score": avg_completeness,
                "monthly_actions": avg_actions,
            },
            "rankings": rankings,
            "top_performer": rankings[0]["name"] if rankings else "",
            "opportunity_performer": rankings[-1]["name"] if rankings else "",
        }

    async def get_regional_breakdown(self, organization_id: str) -> List[Dict[str, Any]]:
        """
        Group franchise locations into regional clusters with roll-up KPIs.
        """
        locations = await self.get_franchise_locations_matrix(organization_id)
        regions_dict: Dict[str, List[Dict[str, Any]]] = {}

        for loc in locations:
            reg = loc["region"]
            if reg not in regions_dict:
                regions_dict[reg] = []
            regions_dict[reg].append(loc)

        result = []
        for reg_name, loc_list in regions_dict.items():
            count = len(loc_list)
            avg_health = round(sum(l["health_score"] for l in loc_list) / count)
            avg_rating = round(sum(l["average_rating"] for l in loc_list) / count, 1)
            total_revs = sum(l["total_reviews"] for l in loc_list)
            total_actions = sum(l["monthly_actions"] for l in loc_list)
            total_searches = sum(l["monthly_searches"] for l in loc_list)

            result.append({
                "region_name": reg_name,
                "location_count": count,
                "average_health_score": avg_health,
                "average_rating": avg_rating,
                "total_reviews": total_revs,
                "total_monthly_actions": total_actions,
                "total_monthly_searches": total_searches,
                "locations": [{"id": l["id"], "name": l["name"], "health_score": l["health_score"]} for l in loc_list],
                "regional_manager": f"Regional Director ({reg_name.split()[0]})",
            })

        return sorted(result, key=lambda r: r["average_health_score"], reverse=True)

    async def get_profile_audit(self, organization_id: str) -> Dict[str, Any]:
        """
        Organization-wide profile strength & missing information audit.
        """
        locations = await self.get_franchise_locations_matrix(organization_id)
        total = len(locations)
        if total == 0:
            return {"audit_summary": {}, "issues_by_type": {}, "locations_requiring_fixes": []}

        # Count issues across all branches
        missing_phone = [l for l in locations if "Phone" in l["missing_fields"]]
        missing_website = [l for l in locations if "Website" in l["missing_fields"]]
        missing_desc = [l for l in locations if "Description" in l["missing_fields"]]
        unreplied_critical = [l for l in locations if l["unreplied_reviews"] > 0]
        sub_80_health = [l for l in locations if l["health_score"] < 80]

        issues_by_type = {
            "unreplied_reviews": len(unreplied_critical),
            "missing_phone": len(missing_phone),
            "missing_website": len(missing_website),
            "missing_description": len(missing_desc),
            "low_health_score": len(sub_80_health),
        }

        # Construct specific location action items
        action_items = []
        for l in locations:
            reasons = []
            if l["unreplied_reviews"] > 0:
                reasons.append(f"{l['unreplied_reviews']} unreplied Google reviews")
            if l["health_score"] < 80:
                reasons.append(f"Health score is below target ({l['health_score']}/100)")
            if l["missing_fields"]:
                reasons.append(f"Missing {', '.join(l['missing_fields'])}")

            if reasons:
                action_items.append({
                    "id": l["id"],
                    "name": l["name"],
                    "location": l["location"],
                    "health_score": l["health_score"],
                    "issues": reasons,
                    "urgency": "High" if l["health_score"] < 75 or l["unreplied_reviews"] >= 3 else "Medium",
                })

        return {
            "total_locations": total,
            "fully_optimized_count": total - len(action_items),
            "attention_required_count": len(action_items),
            "average_completeness_pct": round(sum(l["completeness_score"] for l in locations) / total),
            "issues_by_type": issues_by_type,
            "locations_requiring_fixes": sorted(
                action_items,
                key=lambda a: (0 if a["urgency"] == "High" else 1, a["health_score"]),
            ),
        }
