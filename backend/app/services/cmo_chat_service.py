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
- Location: {business.location or 'Local Storefront'}
- Description: {business.description or 'Authentic local products and services'}
- Target Customers: {business.target_customers or 'Nearby local community and online buyers'}
- Services & Products: {business.services or 'Organic & Cold-Pressed Store'}
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
4. Do NOT give generic canned disclaimers. Speak directly as the business's personal CMO.
"""

        reply_content: str = ""
        actions: List[Dict[str, str]] = []

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
        if not reply_content:
            lower_msg = user_message.lower()
            if "name" in lower_msg and "review" in lower_msg:
                names = [r.reviewer_name for r in reviews if r.reviewer_name]
                if names:
                    reply_content = f"Here are all the reviewers on your Google Business Profile:\n\n" + "\n".join(f"• {name}" for name in names)
                else:
                    reply_content = f"No reviewer names were found on your profile."
                actions = [
                    {"label": "Reply to Reviews", "route": "reviews", "icon": "rate_review"},
                ]
            elif "review" in lower_msg:
                reply_content = (
                    f"You have {len(reviews)} total reviews on your Google Business Profile ({len(pending_reviews)} pending reply). "
                    f"Average rating is {round(sum(r.rating for r in reviews) / len(reviews), 1) if reviews else 5.0}★. "
                    f"Replying promptly to pending reviews helps maintain your #1 spot on Google Maps."
                )
                actions = [
                    {"label": "Reply to Reviews", "route": "reviews", "icon": "rate_review"},
                    {"label": "Generate AI Replies", "route": "reviews", "icon": "auto_awesome"},
                ]
            elif "keyword" in lower_msg or "seo" in lower_msg or "rank" in lower_msg:
                top_kw = keywords[0].keyword if keywords else "cold pressed oil"
                reply_content = (
                    f"You are currently tracking {len(keywords)} local SEO keywords for {business.name}. "
                    f"Top ranking keyword: '{top_kw}'. Embedding these high-intent terms into your weekly posts protects your local visibility."
                )
                actions = [
                    {"label": "Optimize SEO Profile", "route": "seo", "icon": "travel_explore"},
                    {"label": "Track New Keyword", "route": "seo", "icon": "add"},
                ]
            else:
                reply_content = (
                    f"Based on your profile for {business.name} in {business.location or 'your local area'}, "
                    f"your health score is {health_score}/100. Your top focus right now is maintaining fast review replies "
                    f"and publishing 2-3 weekly Google & Instagram promotional posts."
                )
                actions = [
                    {"label": "View Today's Actions", "route": "actions", "icon": "insights"},
                    {"label": "Create Post", "route": "create", "icon": "add"},
                ]

        # Deduce suggested action chips if Gemini didn't return any
        if not actions:
            lower_res = reply_content.lower() + " " + user_message.lower()
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
            "created_at": datetime.now(timezone.utc),
        }
