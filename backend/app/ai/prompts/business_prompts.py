import json
from typing import Dict, Any, List

BUSINESS_PROFILE_SYSTEM_PROMPT = """You are an expert Chief Marketing Officer and small business strategist.
Your task is to analyze onboarding information from a local business owner and produce a highly structured, actionable marketing profile.
You MUST output strictly valid JSON matching the exact schema requested, without markdown formatting or code fences."""

def build_business_profile_prompt(
    name: str,
    category: str,
    location: str,
    website: str,
    target_customers: str,
    services: str,
    business_goals: str,
    marketing_channels: str,
) -> str:
    return f"""Analyze this business and generate a structured marketing profile:

Business Name: {name}
Category: {category}
Location: {location}
Website: {website}
Target Customers: {target_customers}
Services Offered: {services}
Business Goals: {business_goals}
Current Marketing Channels: {marketing_channels}

Return a valid JSON object with:
- "business_summary": 2-3 sentences explaining what makes this business special and its market positioning.
- "industry_category": refined category.
- "target_audience_segments": list of {{"segment_name": string, "description": string, "key_pain_points": [string]}}.
- "key_service_positioning": list of {{"service_name": string, "unique_selling_prop": string, "target_intent": string}}.
- "brand_tone": recommended brand personality and voice (e.g. Warm, Professional & Empathetic).
- "initial_growth_areas": list of 3-4 specific tactical opportunities to acquire customers.
"""

BUSINESS_INTELLIGENCE_SYSTEM_PROMPT = """You are an elite AI Chief Marketing Officer (AI CMO) analyzing local business metrics, reviews, and market posture.
You evaluate the business's current marketing health and identify high-leverage problems and opportunities.
Output MUST be strictly valid JSON without code blocks."""

def build_business_intelligence_prompt(
    business_name: str,
    category: str,
    location: str,
    goals: str,
    reviews: List[Dict[str, Any]],
    metrics: Dict[str, Any],
) -> str:
    reviews_summary = []
    for r in reviews[:10]:
        reviews_summary.append(
            f"- [{r.get('rating')} Stars] {r.get('reviewer_name')}: \"{r.get('text', '')}\" (Replied: {r.get('is_replied', False)})"
        )
    reviews_text = "\n".join(reviews_summary) if reviews_summary else "No reviews available yet."

    return f"""Perform an AI CMO marketing health analysis for this business:

Business Name: {business_name}
Category: {category}
Location: {location}
Primary Goals: {goals}

Recent Customer Reviews:
{reviews_text}

Last 30 Days Performance Metrics:
{json.dumps(metrics, indent=2)}

Return a valid JSON object with:
- "health_score": integer (0 to 100) reflecting overall marketing vitality and reputation.
- "health_summary": 2 sentences summarizing the overall business health.
- "reputation_score": integer (0 to 100) based on review sentiment, ratings, and responsiveness.
- "visibility_score": integer (0 to 100) based on profile views, search discovery, and clicks.
- "customer_sentiment_summary": clear takeaway on what customers love and where friction exists.
- "top_problems": list of {{"title": string, "severity": "critical"|"high"|"medium", "explanation": string, "impact": string}}.
- "top_opportunities": list of {{"title": string, "priority": "high"|"medium", "potential_impact": string, "suggested_action": string}}.
- "strategic_advice": 2-3 sentences of direct executive advice from the AI CMO on what to focus on this week.
"""
