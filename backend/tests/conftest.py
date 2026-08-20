# ==================================================
# OptigoAI Backend — Test Configuration
# ==================================================
"""
Pytest fixtures for backend testing.
Uses NullPool and cleans database tables before each test.
"""

import pytest
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import (
    create_async_engine,
    async_sessionmaker,
    AsyncSession,
)
from sqlalchemy.pool import NullPool
from sqlalchemy import text

from app.core.config import settings
from app.core.database import get_async_session
from app.api.v1.deps import get_db
from app.main import app

# Create test engine using NullPool
test_engine = create_async_engine(
    settings.database_url,
    poolclass=NullPool,
    echo=False,
)

test_session_factory = async_sessionmaker(
    test_engine,
    class_=AsyncSession,
    expire_on_commit=False,
)


async def override_get_db() -> AsyncSession:
    async with test_session_factory() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()


app.dependency_overrides[get_db] = override_get_db
app.dependency_overrides[get_async_session] = override_get_db


@pytest.fixture
def anyio_backend():
    return "asyncio"


@pytest.fixture(autouse=True)
async def clean_database():
    """Truncate tables before each test for clean isolation."""
    async with test_engine.begin() as conn:
        await conn.execute(
            text(
                "TRUNCATE TABLE users, organizations, businesses, reviews, recommendations, "
                "contents, campaigns, competitors, seo_analyses, creatives, notifications, "
                "business_analytics, ai_request_logs, feature_toggles CASCADE;"
            )
        )
    yield


@pytest.fixture
async def client():
    """Async test client for FastAPI."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac
