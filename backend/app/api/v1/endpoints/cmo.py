# ==================================================
# OptigoAI Backend — AI CMO Chat API Endpoints (Phase 10)
# ==================================================

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.v1.deps import get_db, get_current_user
from app.models.user import User
from app.schemas.chat import ChatMessageRequest, ChatMessageResponse
from app.services.cmo_chat_service import CmoChatService

router = APIRouter(prefix="/cmo", tags=["AI CMO Chat"])


@router.post("/chat", response_model=ChatMessageResponse, status_code=status.HTTP_200_OK)
async def chat_with_cmo(
    request: ChatMessageRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Chat in real-time with the AI CMO strategic assistant."""
    service = CmoChatService(db)
    return await service.send_message(
        business_id=request.business_id,
        organization_id=current_user.organization_id,
        user_id=current_user.id,
        user_message=request.message,
        context_screen=request.context_screen,
    )
