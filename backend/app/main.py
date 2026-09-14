# ==================================================
# OptigoAI Backend — FastAPI Application
# ==================================================
"""
Main application entry point.
"""

import os
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse

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
    
    # Ensure all tables exist
    try:
        from app.core.database import engine, Base
        import app.models  # noqa: F401
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
        logger.info("Database schema synchronized (all tables verified)")
    except Exception as e:
        logger.warning("Database schema check failed", error=str(e))

    # Seed default admin user and feature flags
    try:
        from app.core.database import async_session_factory
        from app.services.admin_service import AdminService
        async with async_session_factory() as session:
            admin_srv = AdminService(session)
            await admin_srv.ensure_default_admin()
            await admin_srv._ensure_default_features()
            await session.commit()
            logger.info("Admin service initialization complete (default admin & feature flags verified)")
    except Exception as e:
        logger.warning("Admin initialization check failed", error=str(e))

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
        allow_origin_regex=r"^https:\/\/.*\.vercel\.app$",
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Mount API router
    app.include_router(api_router)

    # Mount Admin Web Portal static files
    admin_static_dir = os.path.join(os.path.dirname(__file__), "static", "admin")
    if os.path.exists(admin_static_dir):
        app.mount("/admin-static", StaticFiles(directory=admin_static_dir), name="admin_static")

    @app.get("/admin", include_in_schema=False)
    async def serve_admin_portal():
        index_file = os.path.join(admin_static_dir, "index.html")
        if os.path.exists(index_file):
            return FileResponse(
                index_file,
                headers={
                    "Cache-Control": "no-cache, no-store, must-revalidate",
                    "Pragma": "no-cache",
                    "Expires": "0",
                },
            )
        return {"message": "Admin portal static assets not found"}

    return app


# Application instance
app = create_app()
