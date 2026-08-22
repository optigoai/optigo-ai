# OptigoAI — Celery Background Tasks & Scheduling Architecture

## Overview & Architecture

OptigoAI uses **Celery 5** with **Redis** as both the message broker (`redis://redis:6379/1`) and result backend (`redis://redis:6379/2`). Long-running, external I/O, web crawling, and AI intelligence analysis are offloaded to background workers to guarantee sub-millisecond HTTP API response times and preserve AI token quotas.

```
                  ┌────────────────────────────────────────────────────────┐
                  │                 FastAPI REST Backend                   │
                  │ (HTTP Requests, Webhooks, Onboarding, Reviews, SEO)   │
                  └─────────────────────────┬──────────────────────────────┘
                                            │ Task Dispatch (.delay)
                                            ▼
                  ┌────────────────────────────────────────────────────────┐
                  │              Redis Message Broker / Queue              │
                  │                      (Port 6379)                       │
                  └─────────────────────────┬──────────────────────────────┘
                                            │
                 ┌──────────────────────────┴──────────────────────────┐
                 ▼                                                     ▼
┌──────────────────────────────────┐                 ┌──────────────────────────────────┐
│          Celery Worker           │                 │      Celery Beat Scheduler       │
│ (Asynchronous Task Execution)    │                 │ (Periodic / Cron Maintenance)    │
└──────────────────────────────────┘                 └──────────────────────────────────┘
```

---

## 🛡️ AI Token Economy & Resource Protection Principles

To ensure high performance without unnecessary cloud costs or rate-limiting:
1. **Event-Driven Triggers Only**: Background tasks run only when underlying business data is modified (e.g. review ingested, onboarding answers saved, website audited).
2. **Smart Caching & Change Detection**: AI tasks verify whether new data exists (e.g. matching `total_analyzed` against review count) before querying Google Gemini models.
3. **Idempotency & Safe Retries**: Tasks can be retried safely with exponential backoff without duplicating side-effects.
4. **Zero-Token Integrations**: Search Console and SERP rank updates use pure HTTP provider APIs without consuming LLM tokens.

---

## 📋 Comprehensive Task Catalog

| Task Name | Module | Type | Purpose | Token Guard / Optimization |
| :--- | :--- | :--- | :--- | :--- |
| `sync_onboarding_intelligence_task` | `app.workers.tasks` | Event-Driven | Synthesizes AI Business Profile and Marketing Health analysis upon onboarding completion | Runs once upon onboarding form submission |
| `analyze_review_intelligence_task` | `app.workers.tasks` | Event-Driven | Extracts real customer keywords, prevalence percentages, and sentiment distribution | Skips AI call if review count unchanged and valid cache exists |
| `generate_cmo_recommendations_task` | `app.workers.tasks` | Event-Driven | Generates/refreshes prioritized AI CMO recommendation cards ('urgent', 'important', 'opportunity') | 3-day validity window; skips if recent recommendations exist |
| `run_website_audit_task` | `app.workers.tasks` | Event-Driven | Crawls target domain, checks SEO meta tags/headings/performance, and generates fix recommendations | 24-hour audit cache per domain |
| `sync_search_console_task` | `app.workers.tasks` | Event-Driven | Syncs Google Search Console impressions, clicks, CTR, and search queries | 0 AI tokens (Direct Google API) |
| `refresh_serp_ranks_task` | `app.workers.tasks` | Event-Driven | Queries Google SERP rank positions for business keywords | 0 AI tokens (Direct SERP crawler) |
| `scheduled_daily_gbp_sync_task` | `app.workers.tasks` | Scheduled Beat | Syncs reviews and engagement metrics for all active businesses daily at **02:00 UTC** | Only syncs active onboarded businesses |
| `scheduled_daily_gsc_sync_task` | `app.workers.tasks` | Scheduled Beat | Ingests daily Google Search Console performance data at **03:00 UTC** | 0 AI tokens |
| `scheduled_weekly_cmo_health_task` | `app.workers.tasks` | Scheduled Beat | Executes full marketing health audit and recommendations refresh every **Sunday at 04:00 UTC** | Runs weekly for active tenants |

---

## ⚙️ Detailed Task Breakdown

### 1. `sync_onboarding_intelligence_task`
- **Identifier**: `app.workers.tasks.sync_onboarding_intelligence_task`
- **Trigger**: Called immediately when a user finishes the mobile onboarding questionnaire (`POST /api/v1/businesses/{id}/onboarding`).
- **Use Case**: Eliminates 10–15s latency on mobile. While the user views their dashboard, the background worker analyzes target customers, business goals, and competitors, populating `ai_business_profile` and initial `health_score`.
- **Arguments**: `(business_id: str, organization_id: str)`

### 2. `analyze_review_intelligence_task`
- **Identifier**: `app.workers.tasks.analyze_review_intelligence_task`
- **Trigger**: Called whenever GBP reviews are synced via `GBPSyncService`.
- **Use Case**: Analyzes raw customer review texts, calculates positive/neutral/negative sentiment ratios, extracts top feedback themes with frequency percentages, and writes the results to `business.health_analysis["review_intelligence"]`.
- **Optimization Guard**: Checks `if cached and cached.get("total_analyzed") == total`. If review count is identical, it avoids invoking Google Gemini Flash.
- **Arguments**: `(business_id: str, organization_id: str)`

### 3. `generate_cmo_recommendations_task`
- **Identifier**: `app.workers.tasks.generate_cmo_recommendations_task`
- **Trigger**: Ingestion of negative/unanswered reviews, significant health score changes, or weekly beat schedule.
- **Use Case**: Formulates proactive next-step marketing strategies (e.g. "Respond to 3 negative reviews", "Optimize title tag for keyword X").
- **Optimization Guard**: Reuses existing recommendations if generated within the past 72 hours, unless `force=True`.
- **Arguments**: `(business_id: str, organization_id: str, force: bool = False)`

### 4. `run_website_audit_task`
- **Identifier**: `app.workers.tasks.run_website_audit_task`
- **Trigger**: User requests an audit on the SEO screen (`POST /api/v1/seo/website/audit`) or updates their website URL.
- **Use Case**: Crawls the web page, checks SSL, meta title/description lengths, open graph tags, viewport tags, schema markup, and generates prioritized technical SEO fixes.
- **Arguments**: `(business_id: str, organization_id: str, custom_url: str = None)`

### 5. `sync_search_console_task`
- **Identifier**: `app.workers.tasks.sync_search_console_task`
- **Trigger**: Initial OAuth callback or manual sync request (`POST /api/v1/integrations/google/search-console/sync`).
- **Use Case**: Ingests queries, clicks, impressions, and average positions into the `gsc_metrics` table.
- **Arguments**: `(business_id: str, organization_id: str)`

### 6. `refresh_serp_ranks_task`
- **Identifier**: `app.workers.tasks.refresh_serp_ranks_task`
- **Trigger**: Adding new tracked keywords in SEO screen.
- **Use Case**: Queries current search engine rank positions without blocking the mobile UI.
- **Arguments**: `(business_id: str, domain: str, keywords: list, location: str = None)`

---

## ⏰ Celery Beat Periodic Schedule

Configured in `backend/app/workers/celery_app.py`:

```python
beat_schedule = {
    # Daily Google Business Profile Sync (02:00 UTC)
    "scheduled-daily-gbp-sync": {
        "task": "app.workers.tasks.scheduled_daily_gbp_sync_task",
        "schedule": crontab(hour=2, minute=0),
    },
    # Daily Google Search Console Sync (03:00 UTC)
    "scheduled-daily-gsc-sync": {
        "task": "app.workers.tasks.scheduled_daily_gsc_sync_task",
        "schedule": crontab(hour=3, minute=0),
    },
    # Weekly CMO Marketing Health Audit (Every Sunday 04:00 UTC)
    "scheduled-weekly-cmo-health-check": {
        "task": "app.workers.tasks.scheduled_weekly_cmo_health_task",
        "schedule": crontab(day_of_week="sunday", hour=4, minute=0),
    },
}
```

---

## 🚀 Running & Monitoring

### Local Development (Docker Compose)
Celery worker and beat containers are automatically spun up with the stack:

```bash
# Start backend, worker, beat, database, and Redis
docker compose up -d

# View worker logs
docker compose logs -f celery_worker

# View beat scheduler logs
docker compose logs -f celery_beat
```

### Inspecting Active Workers in Admin Panel
The OptigoAI Web Admin Portal (`/admin`) monitors worker health and Celery connection status live via the System Health monitor.
