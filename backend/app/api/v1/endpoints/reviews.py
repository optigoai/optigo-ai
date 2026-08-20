from typing import List, Optional
from fastapi import APIRouter, Depends, Query, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.v1.deps import get_db, get_current_user, get_org_id
from app.models.user import User
from app.models.review import ReviewSentiment
from app.schemas import ReviewResponse, ReviewReplyRequest
from app.repositories.review_repo import ReviewRepository
from app.services.business_service import BusinessService

router = APIRouter()


@router.get("", response_model=List[ReviewResponse])
async def list_reviews(
    business_id: str = Query(..., description="Business ID to list reviews for"),
    sentiment: Optional[str] = Query(None, description="Filter by sentiment: positive, neutral, negative"),
    unanswered_only: bool = Query(False, description="Filter only unanswered reviews"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """List reviews for a business with optional sentiment and unanswered filters."""
    org_id = get_org_id(current_user)
    biz_service = BusinessService(db)
    # Ensure business belongs to user's organization
    await biz_service.get_business(business_id, org_id)

    review_repo = ReviewRepository(db)
    sentiment_enum = None
    if sentiment:
        try:
            sentiment_enum = ReviewSentiment(sentiment.lower())
        except ValueError:
            pass

    reviews = await review_repo.list_by_business(
        business_id=business_id,
        sentiment=sentiment_enum,
        unanswered_only=unanswered_only,
    )
    return [ReviewResponse.model_validate(r) for r in reviews]


@router.get("/{review_id}", response_model=ReviewResponse)
async def get_review(
    review_id: str,
    business_id: str = Query(..., description="Business ID"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Get single review by ID."""
    org_id = get_org_id(current_user)
    biz_service = BusinessService(db)
    await biz_service.get_business(business_id, org_id)

    review_repo = ReviewRepository(db)
    review = await review_repo.get_by_id(review_id, business_id)
    if not review:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Review not found.",
        )
    return ReviewResponse.model_validate(review)


@router.post("/{review_id}/reply", response_model=ReviewResponse)
async def reply_to_review(
    review_id: str,
    req: ReviewReplyRequest,
    business_id: str = Query(..., description="Business ID"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Save business owner reply to a review."""
    org_id = get_org_id(current_user)
    biz_service = BusinessService(db)
    await biz_service.get_business(business_id, org_id)

    review_repo = ReviewRepository(db)
    review = await review_repo.get_by_id(review_id, business_id)
    if not review:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Review not found.",
        )

    review.reply_text = req.reply_text
    review.is_replied = True
    await db.flush()

    return ReviewResponse.model_validate(review)


@router.post("/{review_id}/generate-reply")
async def generate_ai_review_reply(
    review_id: str,
    business_id: str = Query(..., description="Business ID"),
    tone: Optional[str] = Query("warm & professional", description="Desired tone"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Generate a high-converting, personalized AI review reply using Google Gemini."""
    from app.ai.ai_service import AIService
    org_id = get_org_id(current_user)
    biz_service = BusinessService(db)
    business = await biz_service.get_business(business_id, org_id)

    review_repo = ReviewRepository(db)
    review = await review_repo.get_by_id(review_id, business_id)
    if not review:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Review not found.",
        )

    ai_service = AIService(db=db)
    ai_reply = await ai_service.generate_review_reply(
        organization_id=org_id,
        user_id=current_user.id,
        business_name=business.name,
        category=business.category or "Local Business",
        reviewer_name=review.reviewer_name or "Valued Customer",
        rating=review.rating or 5,
        review_text=review.text or "Great service!",
        tone=tone,
    )

    return {
        "review_id": review.id,
        "reply_text": ai_reply.reply_text,
        "sentiment_detected": ai_reply.sentiment_detected,
        "key_points_addressed": ai_reply.key_points_addressed,
    }
