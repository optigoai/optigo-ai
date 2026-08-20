# ==================================================
# OptigoAI Backend — Redis Connection
# ==================================================
"""
Redis connection factory for caching and pub/sub.
"""

import redis.asyncio as aioredis

from app.core.config import settings


def get_redis_client() -> aioredis.Redis:
    """Create an async Redis client."""
    return aioredis.from_url(
        settings.redis_url,
        decode_responses=True,
        encoding="utf-8",
    )
