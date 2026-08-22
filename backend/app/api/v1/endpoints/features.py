# ==================================================
# OptigoAI Backend — Feature Flags Client Endpoint
# ==================================================

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Dict

from app.api.v1.deps import get_db
from app.services.admin_service import AdminService

router = APIRouter()


@router.get("/active", summary="Active Feature Flags for Mobile/Client")
async def get_active_features(
    db: AsyncSession = Depends(get_db),
) -> Dict[str, bool]:
    """Public/Client endpoint returning dictionary of active feature flags."""
    service = AdminService(db)
    return await service.get_active_feature_flags_dict()
