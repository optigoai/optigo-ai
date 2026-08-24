# ==================================================
# OptigoAI Backend — AI CMO Chat Schemas (Phase 10)
# ==================================================

from datetime import datetime
from typing import Optional, List, Any
from pydantic import BaseModel, Field


class ChatMessageRequest(BaseModel):
    business_id: str
    message: str = Field(..., min_length=1)
    context_screen: Optional[str] = "home"  # home, actions, create, seo, reviews


class ChatMessageResponse(BaseModel):
    id: str
    role: str  # user, assistant
    content: str
    suggested_actions: Optional[List[dict[str, Any]]] = None
    action_type: Optional[str] = None
    action_payload: Optional[dict[str, Any]] = None
    created_at: datetime
