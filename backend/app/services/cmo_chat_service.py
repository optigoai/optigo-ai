# ==================================================
# OptigoAI Backend — AI CMO Conversational Chat Service (Phase 10)
# ==================================================

import uuid
from datetime import datetime, timezone
from typing import Optional, Dict, Any, List
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import HTTPException, status

from app.repositories.business_repo import BusinessRepository
from app.repositories.recommendation_repo import RecommendationRepository
from app.repositories.seo_repo import SEORepository
from app.repositories.review_repo import ReviewRepository
from app.ai.ai_service import AIService
from app.core.logging import get_logger

logger = get_logger("app.services.cmo_chat")


class CmoChatService:
    """Provides real-time conversational marketing advice grounded in the business's live data using Gemini AI."""

    def __init__(self, db: AsyncSession):
        self.db = db
        self.business_repo = BusinessRepository(db)
        self.rec_repo = RecommendationRepository(db)
        self.seo_repo = SEORepository(db)
        self.review_repo = ReviewRepository(db)
        self.ai_service = AIService(db)

    async def send_message(
        self,
        business_id: str,
        organization_id: str,
        user_id: str,
        user_message: str,
        context_screen: Optional[str] = "home",
    ) -> Dict[str, Any]:
        """Process user message with Gemini AI grounded in full live profile and review data."""
        business = await self.business_repo.get_by_id(business_id)
        if not business:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Business not found")
        if business.organization_id != organization_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

        # 1. Gather comprehensive live context
        health_score = business.health_score or 84
        reviews = await self.review_repo.list_by_business(business_id=business_id)
        pending_reviews = [r for r in reviews if not r.is_replied]
        keywords = await self.seo_repo.get_keywords_by_business(business_id=business_id)
        recommendations = await self.rec_repo.list_for_business(business_id=business_id)

        # Format Reviews List
        reviews_summary = []
        for i, r in enumerate(reviews, 1):
            status_str = "Replied" if r.is_replied else "Unanswered / Pending Reply"
            date_str = r.review_date or (r.created_at.strftime("%Y-%m-%d") if r.created_at else "Recent")
            reviews_summary.append(
                f"{i}. Reviewer: {r.reviewer_name} | Rating: {r.rating}★ | Date: {date_str} | Status: {status_str}\n"
                f"   Comment: \"{r.text or 'No text'}\""
            )
        formatted_reviews = "\n".join(reviews_summary) if reviews_summary else "No reviews recorded yet."

        # Format Keywords List
        keywords_summary = [
            f"- '{kw.keyword}' (Current Google Maps Rank: #{kw.current_rank or 'N/A'}, Search Volume: {kw.search_volume or '500+'})"
            for kw in keywords
        ]
        formatted_keywords = "\n".join(keywords_summary) if keywords_summary else "No tracked keywords yet."

        # Format Recommendations
        rec_summary = [
            f"- [{rec.priority.value.upper()}] {rec.title}: {rec.suggested_action}"
            for rec in recommendations[:5]
        ]
        formatted_recs = "\n".join(rec_summary) if rec_summary else "No pending recommendations."

        # 2. Construct System Instruction for Gemini
        system_instruction = f"""You are the AI Chief Marketing Officer (AI CMO) for "{business.name}".
Your role is to act as a highly intelligent, proactive, and factual marketing strategist.
You have direct, real-time access to the business's database and Google Business profile.

LIVE BUSINESS PROFILE & CONTEXT:
- Business Name: {business.name}
- Category: {business.category or 'Local Business'}
- Location: {business.location or 'Local Area'}
- Description: {business.description or 'Quality local offerings and dedicated customer service'}
- Target Customers: {business.target_customers or 'Nearby community, local diners, and visitors'}
- Services & Products: {business.services or 'Local offerings and customer dining'}
- Marketing Health Score: {health_score}/100
- Active User Screen: {context_screen}

LIVE CUSTOMER REVIEWS ({len(reviews)} total reviews, {len(pending_reviews)} pending reply):
{formatted_reviews}

TRACKED LOCAL SEO KEYWORDS:
{formatted_keywords}

TOP CMO RECOMMENDATIONS:
{formatted_recs}

CRITICAL OPERATIONAL RULES:
1. ALWAYS answer the user's question directly, accurately, and factually based on the LIVE DATA provided above.
2. If the user asks for specific details (such as names of reviewers, customer feedback, rating counts, keyword ranks, or business info), extract the exact data from the context.
3. Keep responses concise, clear, and structured (use bullet points when listing items).
4. If the user asks you to draft a review reply or write a promotional post, create an executive-level, ready-to-use draft tailored to the business.
5. Do NOT give generic canned disclaimers. Speak directly as the business's personal CMO.
"""

        reply_content: str = ""
        actions: List[Dict[str, str]] = []
        action_type: Optional[str] = None
        action_payload: Optional[Dict[str, Any]] = None

        # 3. Call Gemini AI LLM
        try:
            ai_res = await self.ai_service.provider.generate_text(
                prompt=user_message,
                system_instruction=system_instruction,
                temperature=0.3,
            )
            raw_text = ai_res.get("text", "").strip()
            if raw_text and "Gemini API key is not configured" not in raw_text:
                reply_content = raw_text

                # Log AI request
                await self.ai_service._log_ai_request(
                    feature="cmo_chat",
                    organization_id=organization_id,
                    user_id=user_id,
                    model=self.ai_service.provider.model_name,
                    prompt_preview=user_message,
                    response_preview=reply_content,
                    usage=ai_res.get("usage", {}),
                    is_success=True,
                )
        except Exception as e:
            logger.error("Gemini CMO Chat generation failed, using intelligent context fallback", error=str(e))

        # 4. Fallback if Gemini is not configured or offline
        lower_msg = user_message.lower()
        if not reply_content:
            if "name" in lower_msg and "review" in lower_msg:
                names = [r.reviewer_name for r in reviews if r.reviewer_name]
                if names:
                    reply_content = f"Here are the reviewers on your Google Business Profile for {business.name}:\n\n" + "\n".join(f"• {name}" for name in names)
                else:
                    reply_content = f"No reviewer names were found on your profile."
                actions = [
                    {"label": "Reply to Reviews", "route": "reviews", "icon": "rate_review"},
                ]
            elif "reply" in lower_msg or ("review" in lower_msg and ("draft" in lower_msg or "negative" in lower_msg or "unanswered" in lower_msg)):
                target_rev = pending_reviews[0] if pending_reviews else (reviews[0] if reviews else None)
                if target_rev:
                    reply_content = (
                        f"Here is a recommended response for {target_rev.reviewer_name}'s {target_rev.rating}-star review:\n\n"
                        f"\"Dear {target_rev.reviewer_name}, thank you for visiting {business.name} in {business.location or 'our area'}. "
                        f"We appreciate your valuable feedback and are dedicated to providing you with an outstanding experience every time. We hope to welcome you again soon!\"\n\n"
                        f"You can apply this reply directly to Google Business Profile."
                    )
                    action_type = "review_reply"
                    action_payload = {
                        "review_id": target_rev.id,
                        "reviewer_name": target_rev.reviewer_name,
                        "rating": target_rev.rating,
                        "draft_reply": f"Dear {target_rev.reviewer_name}, thank you for visiting {business.name}. We appreciate your feedback and look forward to welcoming you again soon!",
                    }
                    actions = [
                        {"label": "Submit Reply", "route": "reviews", "icon": "send"},
                        {"label": "All Reviews", "route": "reviews", "icon": "rate_review"},
                    ]
                else:
                    reply_content = f"All current customer reviews for {business.name} have already been answered!"
                    actions = [{"label": "View Reviews", "route": "reviews", "icon": "rate_review"}]
            elif "post" in lower_msg or "promo" in lower_msg or "social" in lower_msg:
                cat = business.category or "Store"
                loc = business.location or "Local Area"
                reply_content = (
                    f"Here is a high-converting promotional post draft for {business.name}:\n\n"
                    f"📢 **Special Focus at {business.name}!**\n"
                    f"Looking for the best {cat.lower()} experience in {loc}? Visit us today for fresh flavors, great hospitality, and authentic local favorites.\n\n"
                    f"📍 {loc}\n"
                    f"👉 Follow us for weekly specials!\n\n"
                    f"#{business.name.replace(' ', '')} #{cat.replace(' ', '')} #{loc.split(',')[0].replace(' ', '')}Food #LocalFavorites"
                )
                action_type = "social_post"
                action_payload = {
                    "title": f"Special Showcase at {business.name}",
                    "caption": f"Looking for the best {cat.lower()} in {loc}? Visit {business.name} today for an authentic culinary experience.",
                    "hashtags": [f"#{business.name.replace(' ', '')}", f"#{cat.replace(' ', '')}", f"#{loc.split(',')[0].replace(' ', '')}"],
                }
                actions = [
                    {"label": "Publish to Social", "route": "create", "icon": "campaign"},
                    {"label": "Edit in Studio", "route": "create", "icon": "edit_note"},
                ]
            elif "keyword" in lower_msg or "seo" in lower_msg or "rank" in lower_msg:
                top_kw = keywords[0].keyword if keywords else f"{business.category or 'Local Business'} near me"
                reply_content = (
                    f"You are currently tracking {len(keywords)} local SEO keywords for {business.name}.\n\n"
                    f"• Primary keyword: \"{top_kw}\"\n"
                    f"• Google Map Pack Average Rank: #{round(sum(k.current_rank for k in keywords if k.current_rank)/len(keywords), 1) if keywords else 2.5}\n\n"
                    f"Focusing on table-side review collection and localized GBP posts will push your business to the #1 spot in {business.location or 'your market'}."
                )
                action_type = "keyword_audit"
                action_payload = {
                    "tracked_count": len(keywords),
                    "primary_keyword": top_kw,
                }
                actions = [
                    {"label": "Optimize SEO Profile", "route": "seo", "icon": "travel_explore"},
                    {"label": "Track New Keyword", "route": "seo", "icon": "add"},
                ]
            else:
                reply_content = (
                    f"Based on your live profile for {business.name} in {business.location or 'your local area'}, "
                    f"your health score is {health_score}/100. Your primary focus right now is maintaining 100% review reply coverage "
                    f"and publishing 2-3 weekly promotional updates to dominate local search."
                )
                actions = [
                    {"label": "View Today's Actions", "route": "actions", "icon": "insights"},
                    {"label": "Create Post", "route": "create", "icon": "add"},
                ]

        # 5. Detect and attach functional actions from Gemini response if present
        if not action_type:
            lower_res = reply_content.lower()
            if "dear " in lower_res or "thank you for visiting" in lower_res or "we appreciate your" in lower_res:
                action_type = "review_reply"
                action_payload = {
                    "draft_reply": reply_content.split('"')[1] if '"' in reply_content else reply_content,
                }
            elif "#" in lower_res and ("📢" in lower_res or "looking for" in lower_res or "special" in lower_res):
                action_type = "social_post"
                action_payload = {
                    "caption": reply_content,
                }

        # Deduce suggested action chips if none present
        if not actions:
            lower_res = reply_content.lower() + " " + lower_msg
            if "review" in lower_res:
                actions = [
                    {"label": "View Reviews", "route": "reviews", "icon": "rate_review"},
                    {"label": "Draft AI Reply", "route": "reviews", "icon": "auto_awesome"},
                ]
            elif "post" in lower_res or "campaign" in lower_res or "social" in lower_res:
                actions = [
                    {"label": "Create Post", "route": "create", "icon": "edit_note"},
                    {"label": "Launch Campaign", "route": "create", "icon": "campaign"},
                ]
            elif "seo" in lower_res or "keyword" in lower_res or "rank" in lower_res:
                actions = [
                    {"label": "Check SEO Rank", "route": "seo", "icon": "search"},
                    {"label": "Add Keyword", "route": "seo", "icon": "add"},
                ]
            else:
                actions = [
                    {"label": "Today's Actions", "route": "actions", "icon": "insights"},
                    {"label": "Create Post", "route": "create", "icon": "edit_note"},
                ]

        return {
            "id": str(uuid.uuid4()),
            "role": "assistant",
            "content": reply_content,
            "suggested_actions": actions,
            "action_type": action_type,
            "action_payload": action_payload,
            "created_at": datetime.now(timezone.utc),
        }
