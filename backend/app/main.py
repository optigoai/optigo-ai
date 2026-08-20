# ==================================================
# OptigoAI Backend — FastAPI Application
# ==================================================
"""
Main application entry point.
"""

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.core.logging import setup_logging, get_logger
from app.api.v1.router import api_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan — startup and shutdown."""
    logger = get_logger("app.main")
    logger.info(
        "Starting OptigoAI API",
        environment=settings.app_env,
        debug=settings.debug,
    )
    yield
    logger.info("Shutting down OptigoAI API")


def create_app() -> FastAPI:
    """Application factory."""
    setup_logging()

    app = FastAPI(
        title=settings.app_name,
        description="AI Marketing Manager for SMBs",
        version="0.1.0",
        lifespan=lifespan,
        docs_url="/docs" if settings.is_development else None,
        redoc_url="/redoc" if settings.is_development else None,
    )

    # CORS middleware
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins_list,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Mount API router
    app.include_router(api_router)

    return app


# Application instance
app = create_app()
