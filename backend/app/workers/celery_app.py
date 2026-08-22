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

from celery.schedules import crontab

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
    # Periodic Beat Schedule
    beat_schedule={
        # 1. Daily Google Business Profile Sync (02:00 UTC)
        "scheduled-daily-gbp-sync": {
            "task": "app.workers.tasks.scheduled_daily_gbp_sync_task",
            "schedule": crontab(hour=2, minute=0),
        },
        # 2. Daily Google Search Console Sync (03:00 UTC)
        "scheduled-daily-gsc-sync": {
            "task": "app.workers.tasks.scheduled_daily_gsc_sync_task",
            "schedule": crontab(hour=3, minute=0),
        },
        # 3. Weekly CMO Marketing Health & Recommendations Audit (Every Sunday 04:00 UTC)
        "scheduled-weekly-cmo-health-check": {
            "task": "app.workers.tasks.scheduled_weekly_cmo_health_task",
            "schedule": crontab(day_of_week="sunday", hour=4, minute=0),
        },
    },
)

# Auto-discover tasks from workers modules
celery_app.autodiscover_tasks(["app.workers"])

