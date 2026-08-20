# ==================================================
# OptigoAI Backend — Health Check Endpoint
# ==================================================

from fastapi import APIRouter

from app.core.config import settings
from app.schemas import HealthResponse

router = APIRouter()


@router.get("/health", response_model=HealthResponse, tags=["Health"])
async def health_check():
    """Application health check."""
    return HealthResponse(
        status="ok",
        app_name=settings.app_name,
        version="0.1.0",
        environment=settings.app_env,
    )
