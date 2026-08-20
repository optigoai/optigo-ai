# ==================================================
# OptigoAI Backend — Celery Application
# ==================================================
"""
Celery configuration for background task processing.
"""

from celery import Celery

from app.core.config import settings

celery_app = Celery(
    "optigoai",
    broker=settings.celery_broker_url,
    backend=settings.celery_result_backend,
)

celery_app.conf.update(
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone="UTC",
    enable_utc=True,
    task_track_started=True,
    task_acks_late=True,
    worker_prefetch_multiplier=1,
    # Retry policy
    task_default_retry_delay=60,
    task_max_retries=3,
    # Result expiry (24 hours)
    result_expires=86400,
    # Beat schedule (to be populated in later phases)
    beat_schedule={},
)

# Auto-discover tasks from workers modules
celery_app.autodiscover_tasks(["app.workers"])
