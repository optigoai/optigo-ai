# ==================================================
# OptigoAI Backend — Mock GBP Provider
# ==================================================
"""
Mock Google Business Profile provider for MVP development.
Returns realistic business data without requiring real GBP OAuth.

This provider flows through the same architecture as a real
GBP provider would — data goes through services, not directly
into Flutter widgets.
"""

from typing import Any
from datetime import datetime, timedelta
import random

from app.providers.base import BusinessDataProvider


class MockGBPProvider(BusinessDataProvider):
    """Mock GBP provider that returns realistic business data."""

    async def get_business_profile(self, business_id: str) -> dict[str, Any]:
        """Return a realistic mock business profile."""
        return {
            "gbp_id": f"mock_gbp_{business_id[:8]}",
            "verification_status": "verified",
            "profile_completeness": 78,
            "open_hours": {
                "monday": "9:00 AM - 6:00 PM",
                "tuesday": "9:00 AM - 6:00 PM",
                "wednesday": "9:00 AM - 6:00 PM",
                "thursday": "9:00 AM - 6:00 PM",
                "friday": "9:00 AM - 6:00 PM",
                "saturday": "10:00 AM - 4:00 PM",
                "sunday": "Closed",
            },
            "attributes": [
                "Wheelchair accessible",
                "Free Wi-Fi",
                "Credit cards accepted",
            ],
            "photos_count": 12,
            "posts_count": 3,
            "last_updated": datetime.utcnow().isoformat(),
        }

    async def get_reviews(self, business_id: str) -> list[dict[str, Any]]:
        """Return realistic mock reviews with varied sentiments."""
        reviews = [
            {
                "external_id": f"rev_001_{business_id[:8]}",
                "reviewer_name": "Priya Sharma",
                "rating": 5,
                "text": "Absolutely amazing service! The team went above and beyond to help me. The quality of work was exceptional and they delivered ahead of schedule. Highly recommend to anyone looking for professional service.",
                "review_date": (datetime.utcnow() - timedelta(days=2)).isoformat(),
                "source": "gbp",
            },
            {
                "external_id": f"rev_002_{business_id[:8]}",
                "reviewer_name": "Rahul Patel",
                "rating": 4,
                "text": "Good experience overall. The staff was friendly and knowledgeable. Pricing was fair. Only suggestion would be to improve the waiting area. Would visit again.",
                "review_date": (datetime.utcnow() - timedelta(days=5)).isoformat(),
                "source": "gbp",
            },
            {
                "external_id": f"rev_003_{business_id[:8]}",
                "reviewer_name": "Anita Desai",
                "rating": 2,
                "text": "Disappointed with my recent visit. Had to wait over 45 minutes despite having an appointment. The service itself was okay but the long wait was frustrating. Expected better time management.",
                "review_date": (datetime.utcnow() - timedelta(days=7)).isoformat(),
                "source": "gbp",
            },
            {
                "external_id": f"rev_004_{business_id[:8]}",
                "reviewer_name": "Vikram Singh",
                "rating": 5,
                "text": "Best in the city! I've tried multiple places and nothing compares. The attention to detail is remarkable. The owner personally ensures quality. Five stars is not enough!",
                "review_date": (datetime.utcnow() - timedelta(days=10)).isoformat(),
                "source": "gbp",
            },
            {
                "external_id": f"rev_005_{business_id[:8]}",
                "reviewer_name": "Meera Krishnan",
                "rating": 1,
                "text": "Very poor experience. The staff was rude and dismissive. My concerns were not addressed properly. I will not be returning. Management needs to seriously train their staff on customer service.",
                "review_date": (datetime.utcnow() - timedelta(days=12)).isoformat(),
                "source": "gbp",
            },
            {
                "external_id": f"rev_006_{business_id[:8]}",
                "reviewer_name": "Arjun Nair",
                "rating": 4,
                "text": "Solid service with good value for money. The team was professional and delivered as promised. Would recommend for anyone on a reasonable budget.",
                "review_date": (datetime.utcnow() - timedelta(days=15)).isoformat(),
                "source": "gbp",
            },
            {
                "external_id": f"rev_007_{business_id[:8]}",
                "reviewer_name": "Sneha Gupta",
                "rating": 3,
                "text": "Average experience. Nothing special but nothing terrible either. The service was basic and met minimum expectations. Could improve on communication.",
                "review_date": (datetime.utcnow() - timedelta(days=18)).isoformat(),
                "source": "gbp",
            },
            {
                "external_id": f"rev_008_{business_id[:8]}",
                "reviewer_name": "Deepak Verma",
                "rating": 5,
                "text": "Outstanding! From start to finish, everything was handled professionally. The results exceeded my expectations. Will definitely be a repeat customer and have already told my friends.",
                "review_date": (datetime.utcnow() - timedelta(days=20)).isoformat(),
                "source": "gbp",
            },
        ]
        return reviews

    async def get_performance_metrics(self, business_id: str) -> dict[str, Any]:
        """Return realistic mock performance metrics."""
        base = random.randint(80, 200)
        return {
            "period": "last_30_days",
            "profile_views": base * 15,
            "website_clicks": base * 3,
            "phone_calls": base,
            "direction_requests": int(base * 1.5),
            "photo_views": base * 8,
            "search_impressions": base * 50,
            "direct_searches": int(base * 20),
            "discovery_searches": int(base * 30),
            "trends": {
                "profile_views_change": round(random.uniform(-5, 15), 1),
                "website_clicks_change": round(random.uniform(-10, 20), 1),
                "phone_calls_change": round(random.uniform(-8, 12), 1),
            },
        }

    async def get_posts(self, business_id: str) -> list[dict[str, Any]]:
        """Return realistic mock business posts."""
        return [
            {
                "id": f"post_001_{business_id[:8]}",
                "type": "UPDATE",
                "text": "Excited to announce our new weekend specials! Visit us this Saturday for exclusive offers.",
                "created_at": (datetime.utcnow() - timedelta(days=3)).isoformat(),
                "views": random.randint(50, 200),
                "clicks": random.randint(5, 30),
            },
            {
                "id": f"post_002_{business_id[:8]}",
                "type": "OFFER",
                "text": "Limited time offer: 20% off on all premium services. Book now!",
                "created_at": (datetime.utcnow() - timedelta(days=14)).isoformat(),
                "views": random.randint(100, 400),
                "clicks": random.randint(15, 60),
            },
            {
                "id": f"post_003_{business_id[:8]}",
                "type": "EVENT",
                "text": "Join us for our annual customer appreciation day. Free consultations and refreshments.",
                "created_at": (datetime.utcnow() - timedelta(days=25)).isoformat(),
                "views": random.randint(80, 300),
                "clicks": random.randint(10, 45),
            },
        ]
