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

Generate 3 to 5 prioritized, high-leverage action cards across 'urgent', 'important', and 'opportunity' categories.
IMPORTANT GUIDELINES:
- Keep 'title' punchy, short, and clear (under 7 words, e.g., 'Reply to 4 Unanswered Reviews').
- Keep 'explanation' brief (1 concise sentence explaining the immediate win).
- Keep 'suggested_action' actionable and direct (1 short sentence).

Return a valid JSON object matching:
{{
  "recommendations": [
    {{
      "title": "Short punchy title (under 7 words)",
      "explanation": "One concise sentence explaining the recommendation",
      "reason": "Why this matters for business growth",
      "priority": "urgent" | "important" | "opportunity",
      "impact": "High (+15% leads) | Medium (+5% ranking)",
      "effort": "5 mins | 15 mins | 30 mins",
      "suggested_action": "One direct action step",
      "related_feature": "reviews" | "campaigns" | "posts" | "seo"
    }}
  ],
  "cmo_note": "A concise executive note from the AI CMO advising what to tackle first."
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


REVIEW_REPLY_SYSTEM_PROMPT = """You are an expert customer relations specialist and brand manager.
Generate a polite, thoughtful, and personalized response to a customer review for a business.
If the review is positive (4-5 stars): Express genuine gratitude, mention specific highlights the customer noted, and invite them back.
If the review is negative (1-2 stars): Acknowledge their experience empathetically, apologize sincerely without making excuses, and offer a direct resolution or way to get in touch offline.
If the review is neutral (3 stars): Thank them for feedback, address areas of improvement, and highlight the business commitment to excellence.
Always sound human, warm, professional, and authentic to the business type.
Output MUST be strictly valid JSON without markdown code fences."""


def build_review_reply_prompt(
    business_name: str,
    category: str,
    reviewer_name: str,
    rating: int,
    review_text: str,
    tone: Optional[str] = "warm & professional",
) -> str:
    return f"""Generate a personalized, professional business reply to this customer review:

Business Name: {business_name}
Business Type: {category}
Reviewer Name: {reviewer_name}
Star Rating: {rating}/5
Customer Review: "{review_text}"
Desired Tone: {tone}

Return valid JSON matching:
{{
  "reply_text": "The customized reply message to be posted on the public profile.",
  "sentiment_detected": "positive | neutral | negative",
  "key_points_addressed": ["list", "of", "points"]
}}"""


SEO_AUDIT_SYSTEM_PROMPT = """You are a world-class Local SEO & Google Business Profile (GBP) optimization expert.
You audit local businesses to maximize their visibility in Google Local 3-Pack, Google Maps, and nearby local search queries.
Keep all analysis concise, direct, and actionable without buzzwords or fluff.
Output MUST be strictly valid JSON without markdown code fences."""


def build_seo_audit_prompt(
    business_name: str,
    category: str,
    location: str,
    description: Optional[str] = None,
    current_keywords: Optional[List[str]] = None,
    competitors_context: Optional[List[str]] = None,
    rating: float = 4.5,
    reviews_count: int = 10,
) -> str:
    keywords_str = ", ".join(current_keywords) if current_keywords else "None tracked yet"
    competitors_str = ", ".join(competitors_context) if competitors_context else "Standard local benchmarks"
    return f"""Perform a comprehensive Local SEO and Google Maps Pack visibility audit for this business:

Business: {business_name}
Category: {category}
Location: {location}
Current Description: {description or 'Not specified'}
Rating: {rating}★ ({reviews_count} reviews)
Current Tracked Keywords: {keywords_str}
Live Google Maps Competitors: {competitors_str}

Instructions:
1. Evaluate scores (0-100) for overall_seo_score, map_pack_score, keyword_score, citation_score.
2. Identify 3-4 specific missing_attributes in their GBP (e.g. 'Wheelchair accessible', 'Online appointments', 'Exact operating hours on holidays', 'Secondary category: organic store').
3. Suggest 4-6 high-intent local search keywords with realistic search volume and rank potential.
4. Give 3 actionable, high-impact recommendations (short 1-sentence tasks).
5. Provide competitor insights comparing their local position against typical top 3 local pack competitors.

Return JSON in this format:
{{
  "overall_seo_score": 78,
  "map_pack_score": 72,
  "keyword_score": 80,
  "citation_score": 85,
  "missing_attributes": ["attribute 1", "attribute 2"],
  "suggested_keywords": [
    {{
      "keyword": "cold pressed oil near me",
      "search_volume": "1.4K / mo",
      "difficulty": "Low",
      "intent": "Local Intent",
      "estimated_rank": 3
    }}
  ],
  "actionable_recommendations": [
    "Add secondary GBP category to capture 25% more local searches.",
    "Include location keyword in profile description."
  ],
  "competitor_insights": [
    "Competitors in your area average 45 reviews and post 3x per week on Google."
  ]
}}"""


def build_seo_keyword_generator_prompt(
    business_name: str,
    category: str,
    location: str,
    target_services: Optional[List[str]] = None,
) -> str:
    services_str = ", ".join(target_services) if target_services else category
    return f"""Generate 6 high-conversion, hyper-local SEO keywords for this business to rank on Google Search & Google Maps:

Business: {business_name}
Category: {category}
Location: {location}
Focus Services/Products: {services_str}

Ensure a mix of:
- 'Near me' local intent
- High commercial intent (e.g. 'best {category} in {location}')
- Product/service specific terms

Return JSON in this format:
{{
  "keywords": [
    {{
      "keyword": "keyword text",
      "search_volume": "1.2K / mo",
      "difficulty": "Low | Medium | High",
      "intent": "Local Intent | Commercial | Transactional",
      "estimated_rank": 4
    }}
  ]
}}"""


def build_gbp_profile_optimizer_prompt(
    business_name: str,
    category: str,
    location: str,
    current_description: Optional[str] = None,
) -> str:
    return f"""Generate an optimized Google Business Profile configuration to achieve maximum local search visibility:

Business: {business_name}
Category: {category}
Location: {location}
Current Description: {current_description or 'None'}

Return JSON matching:
{{
  "optimized_title": "Business Name - Primary Keyword | Location",
  "optimized_description": "Compelling 750-character max description infused with top local keywords and strong CTA.",
  "primary_category": "Primary category",
  "secondary_categories": ["Category 1", "Category 2"],
  "recommended_attributes": ["Attr 1", "Attr 2", "Attr 3"]
}}"""
