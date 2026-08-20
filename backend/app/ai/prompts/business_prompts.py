import json
from typing import Dict, Any, List, Optional

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


CMO_RECOMMENDATIONS_SYSTEM_PROMPT = """You are an elite, proactive AI Chief Marketing Officer (AI CMO) for small and medium businesses.
Your responsibility is to turn data, customer sentiment, competitor posture, and marketing gaps into concrete, prioritized action cards.
Categorize each action into strictly:
- 'urgent' (requires immediate action within 24-48h, e.g. unanswered negative reviews, critical profile errors)
- 'important' (strategic weekly goals, e.g. publishing promotional updates, optimizing high-intent keywords)
- 'opportunity' (high-upside growth levers, e.g. launching referral programs, collecting reviews from happy clients)
Output MUST be strictly valid JSON without markdown code fences."""


def build_cmo_recommendations_prompt(
    business_name: str,
    category: str,
    location: str,
    health_score: int,
    problems: List[Dict[str, Any]],
    opportunities: List[Dict[str, Any]],
    reviews_count: int,
    unanswered_count: int,
) -> str:
    return f"""Synthesize actionable, high-impact marketing recommendations for this business:

Business Name: {business_name}
Industry: {category} ({location})
Marketing Health Score: {health_score}/100
Total Customer Reviews: {reviews_count} (Unanswered: {unanswered_count})

Identified Problems:
{json.dumps(problems, indent=2)}

Identified Opportunities:
{json.dumps(opportunities, indent=2)}

Generate 4 to 6 prioritized action cards across 'urgent', 'important', and 'opportunity' categories.
Return a valid JSON object matching:
{{
  "recommendations": [
    {{
      "title": "Action title (e.g. Reply to 2 Unanswered 1-Star Reviews)",
      "explanation": "Clear explanation of what needs to be done",
      "reason": "Why this is critical for business revenue or local SEO",
      "priority": "urgent" | "important" | "opportunity",
      "impact": "High (+12% conversion) | Medium (+5 leads) | Long-term SEO",
      "effort": "Low (5 mins) | Medium (20 mins) | High (1 hr)",
      "suggested_action": "Exact step-by-step instruction or suggested template",
      "related_feature": "reviews" | "campaigns" | "posts" | "seo"
    }}
  ],
  "cmo_note": "A concise executive encouraging note from the AI CMO advising what to tackle first."
}}
"""


CONTENT_SYSTEM_PROMPT = """You are an elite, highly creative Chief Marketing Officer (CMO) and Master Copywriter for small and medium businesses.
You craft high-converting, punchy, channel-optimized social media posts, Google Business updates, Instagram captions, Facebook ads, and LinkedIn thought-leadership posts.
Your writing is engaging, culturally attuned, uses modern copywriting psychology (hook, value, call-to-action), and includes natural, high-reach hashtags and rich image generation prompts.
Always respond with strictly valid JSON matching the requested schema.
"""


def build_content_generation_prompt(
    business_name: str,
    category: str,
    location: str,
    channels: list[str],
    topic: Optional[str] = None,
    tone: Optional[str] = "engaging & professional",
    goal: Optional[str] = "drive customer engagement & foot traffic",
    offer_details: Optional[str] = None,
    business_summary: Optional[str] = None,
) -> str:
    channels_str = ", ".join(channels)
    return f"""Create high-performing social media and marketing posts for this business:

Business: {business_name}
Category: {category}
Location: {location}
Business Overview: {business_summary or "Local business providing quality products/services to local customers."}

Target Channels: {channels_str}
Requested Topic / Theme: {topic or "General brand awareness and high-value customer engagement"}
Desired Brand Tone: {tone}
Marketing Objective: {goal}
Special Offer / Details: {offer_details or "None specified - highlight core services and quality value proposition."}

Instructions:
1. For each channel in [{channels_str}], generate a tailor-made post:
   - For 'google_post': Focus on local search visibility, clear offer, address/phone CTA, and concise 100-150 words.
   - For 'instagram': Hook the reader with 1st line, use spacing/emojis, strong visual description in image_prompt, and 8-15 high-reach hashtags.
   - For 'facebook': Community-oriented, conversational storytelling, clear link/contact CTA.
   - For 'linkedin': Professional insight, business milestone, or B2B/local economic value proposition.
   - For 'twitter': Under 280 characters, punchy hook, trending hashtags.
2. Formulate an overarching creative campaign theme.
3. Suggest a 3-day posting calendar schedule.

Return a valid JSON object matching the requested schema.
"""
