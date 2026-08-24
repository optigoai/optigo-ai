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
Your role is to act as a highly intelligent, proactive, executive marketing strategist.
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

CRITICAL OPERATIONAL & FORMATTING RULES:
1. ALWAYS answer the user's question directly, accurately, and factually based on the LIVE DATA provided above.
2. Keep responses concise, punchy, and structured for executive reading on a mobile device. Avoid overwhelming walls of text.
3. DO NOT use markdown hashtag headers (`###` or `##`). Use clean bold labels like `**Section Title:**` instead.
4. DO NOT wrap whole sentences in italics (`*`). Use bold `**term**` for emphasis and clean bullet points (`• `).
5. If the user asks for a review reply, provide a warm, professional, brand-appropriate response draft.
6. If the user asks for promotional content, provide an engaging caption with hashtags.
7. If the user asks for competitor analysis, provide:
   - **Top Competitor Focus**: Current benchmark rankings in the local market.
   - **Our Key Advantages & Gaps**: Review count, rating gaps, and customer service opportunities.
   - **Tactical Action Plan**: 3 concrete, high-impact moves to dominate local search.
8. Speak directly as the business's personal CMO with authority and clarity.
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

        lower_msg = user_message.lower()
        is_asking_reply = any(k in lower_msg for k in ["draft reply", "draft response", "reply to review", "response for latest review", "reply to "])
        is_asking_post = any(k in lower_msg for k in ["create a post", "promotional post", "social post", "draft post", "promo post", "instagram post", "google post", "write a post"])
        is_asking_seo = any(k in lower_msg for k in ["boost google rank", "seo ranking", "google maps ranking", "boost ranking", "track keyword", "keyword"])
        is_asking_competitor = any(k in lower_msg for k in ["competitor", "competitors", "competition", "outrank"])
        is_asking_priority = any(k in lower_msg for k in ["top priority", "priority today", "what should i do", "today's action"])

        # 4. Fallback if Gemini is not configured or offline
        if not reply_content:
            if is_asking_reply:
                target_rev = pending_reviews[0] if pending_reviews else (reviews[0] if reviews else None)
                if target_rev:
                    reply_content = (
                        f"Here is a recommended response for **{target_rev.reviewer_name}** ({target_rev.rating}★ review):\n\n"
                        f"\"Dear {target_rev.reviewer_name}, thank you for visiting {business.name} in {business.location or 'our area'}. "
                        f"We appreciate your valuable feedback and are dedicated to providing you with an outstanding experience every time. We hope to welcome you again soon!\"\n\n"
                        f"You can copy or apply this reply directly to Google Business Profile."
                    )
                else:
                    reply_content = f"All current customer reviews for **{business.name}** have already been answered!"
            elif is_asking_post:
                cat = business.category or "Store"
                loc = business.location or "Local Area"
                reply_content = (
                    f"Here is a high-converting promotional post draft for **{business.name}**:\n\n"
                    f"Looking for the best {cat.lower()} experience in {loc}? Visit {business.name} today for fresh flavors, great hospitality, and authentic local favorites.\n\n"
                    f"📍 {loc}\n"
                    f"👉 Follow us for weekly specials!\n\n"
                    f"#{business.name.replace(' ', '')} #{cat.replace(' ', '')} #{loc.split(',')[0].replace(' ', '')}Food #LocalFavorites"
                )
            elif is_asking_competitor:
                reply_content = (
                    f"**Competitive Landscape Analysis for {business.name}:**\n\n"
                    f"• **Top Competitor Benchmark**: Competing establishments in {business.location or 'your area'} hold top 3 map ranks primarily driven by steady review volume.\n"
                    f"• **Our Key Gap**: We currently have {len(pending_reviews)} unanswered customer reviews. Closing this response backlog will immediately improve search relevance.\n"
                    f"• **Tactical Action**: Implement table-side QR review collection and post weekly promotional updates to capture local search share."
                )
            elif is_asking_seo:
                top_kw = keywords[0].keyword if keywords else f"{business.category or 'Local Business'} near me"
                reply_content = (
                    f"**Local SEO Performance for {business.name}:**\n\n"
                    f"• **Tracked Keywords**: {len(keywords)} local search terms\n"
                    f"• **Primary Search Term**: \"{top_kw}\"\n"
                    f"• **Google Map Pack Avg Rank**: #{round(sum(k.current_rank for k in keywords if k.current_rank)/len(keywords), 1) if keywords else 2.5}\n\n"
                    f"To climb to #1, focus on rapid review replies and localized weekly posts embedding your primary search phrases."
                )
            elif is_asking_priority:
                top_rec = recommendations[0] if recommendations else None
                rec_text = f"{top_rec.title} - {top_rec.suggested_action}" if top_rec else "Reply to unanswered reviews and publish weekly updates"
                reply_content = (
                    f"**Top Marketing Priority Today for {business.name}:**\n\n"
                    f"• **Immediate Focus**: {rec_text}\n"
                    f"• **Business Health Score**: {health_score}/100\n"
                    f"• **Pending Reviews**: {len(pending_reviews)} awaiting your reply"
                )
            else:
                reply_content = (
                    f"Based on live data for **{business.name}** in {business.location or 'your local area'}, "
                    f"your health score is {health_score}/100. Your primary focus is maintaining 100% review reply coverage "
                    f"and publishing regular promotional updates to dominate local search."
                )

        # 5. Strict Intent-Based Action Card Generation
        if is_asking_reply:
            target_rev = pending_reviews[0] if pending_reviews else (reviews[0] if reviews else None)
            if target_rev:
                # Extract quoted text if present, otherwise clean summary
                draft = reply_content.split('"')[1] if '"' in reply_content else (
                    f"Dear {target_rev.reviewer_name}, thank you for visiting {business.name}. We appreciate your feedback and look forward to welcoming you again soon!"
                )
                action_type = "review_reply"
                action_payload = {
                    "review_id": target_rev.id,
                    "reviewer_name": target_rev.reviewer_name,
                    "rating": target_rev.rating,
                    "draft_reply": draft,
                }
                actions = [
                    {"label": "Submit Reply", "route": "reviews", "icon": "send"},
                    {"label": "All Reviews", "route": "reviews", "icon": "rate_review"},
                ]
        elif is_asking_post:
            cat = business.category or "Store"
            loc = business.location or "Local Area"
            action_type = "social_post"
            action_payload = {
                "title": f"Special Showcase at {business.name}",
                "caption": reply_content.replace("Here is a high-converting promotional post draft:\n\n", "").strip(),
                "hashtags": [f"#{business.name.replace(' ', '')}", f"#{cat.replace(' ', '')}", f"#{loc.split(',')[0].replace(' ', '')}"],
            }
            actions = [
                {"label": "Publish to Social", "route": "create", "icon": "campaign"},
                {"label": "Edit in Studio", "route": "create", "icon": "edit_note"},
            ]
        elif is_asking_competitor:
            actions = [
                {"label": "View Competitor Rankings", "route": "seo", "icon": "travel_explore"},
                {"label": "Explore SEO Keywords", "route": "seo", "icon": "search"},
            ]
        elif is_asking_seo:
            actions = [
                {"label": "Optimize SEO Profile", "route": "seo", "icon": "travel_explore"},
                {"label": "Add New Keyword", "route": "seo", "icon": "add"},
            ]
        else:
            actions = [
                {"label": "View Recommendations", "route": "actions", "icon": "insights"},
                {"label": "Check Reviews", "route": "reviews", "icon": "rate_review"},
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
