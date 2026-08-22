# OptigoAI

**AI Marketing Manager for Small & Medium Businesses**

OptigoAI helps business owners answer one core question: *"What should I do to get more customers?"*

---

## 🏗️ Architecture

```
optigoai/
├── mobile/                  Flutter app (Android + iOS) with 5 Core Tabs & AI CMO Drawer
├── backend/                 FastAPI + SQLAlchemy + Celery + Redis + PostgreSQL
├── web-admin/               Live Web Admin Portal (Real-time auto-sync & AI tracking)
├── docker-compose.yml       Orchestrates PostgreSQL, Redis, FastAPI, Celery Worker & Beat
├── CELERY_BACKGROUND_TASKS.md Documentation for background workers & scheduler
├── EXTERNAL_API_SETUP_GUIDE.md Guide for GSC, DataForSEO, Firecrawl, Gemini
├── .env.example             Environment configuration template
└── README.md
```

---

## 💻 Tech Stack

| Layer | Technology |
|---|---|
| **Mobile** | Flutter 3.29, Dart 3.7, Provider, Flutter Secure Storage, FL Chart |
| **Backend** | Python 3.11, FastAPI, Async SQLAlchemy 2.0, Alembic |
| **Database** | PostgreSQL 16 |
| **Cache / Queue** | Redis 7 |
| **Background Processing** | Celery 5 Worker & Celery Beat Scheduler |
| **AI Intelligence** | Google Gemini 2.0 Flash (`google-genai`) |
| **Integrations** | Google Search Console API, DataForSEO, Firecrawl, Serper, SerpAPI |
| **Admin Portal** | HTML5 / Vanilla CSS & JS (with silent 3.5s background auto-sync) |

---

## 🚀 Quick Start

### Prerequisites
- [Docker Desktop](https://docs.docker.com/desktop/install/windows-install/)
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel)
- [Python 3.11+](https://www.python.org/downloads/)

### 1. Clone & Configure

```bash
git clone https://github.com/optigoai/optigo-ai.git
cd optigo-ai

# Copy environment template
cp .env.example .env

# Edit .env and set your keys:
# - JWT_SECRET_KEY
# - GEMINI_API_KEY (from https://aistudio.google.com/apikey)
```

### 2. Start Backend Services with Docker

```bash
docker compose up -d
```

This starts:
- **PostgreSQL Database** on `localhost:5432`
- **Redis Cache & Message Broker** on `localhost:6379`
- **FastAPI Backend Server** on `http://localhost:8000`
- **Celery Worker** (Asynchronous background processing)
- **Celery Beat** (Scheduled daily & weekly maintenance tasks)

### 3. Access Portals & API Documentation

- **Web Admin Portal**: [http://localhost:8000/admin](http://localhost:8000/admin) (or open `web-admin/index.html`)
- **Interactive Swagger Docs**: [http://localhost:8000/docs](http://localhost:8000/docs)
- **Backend Health Check**: [http://localhost:8000/api/v1/health](http://localhost:8000/api/v1/health)

### 4. Run Flutter Mobile App

```bash
cd mobile
flutter pub get
flutter run
```

---

## 🌟 Key Features

1. **AI CMO Action Engine**: Analyzes marketing health score, reviews, and SEO gaps to generate prioritized action cards (`URGENT`, `IMPORTANT`, `OPPORTUNITY`).
2. **AI Review Intelligence**: Structured NLP extraction of sentiment ratios and real customer feedback keyword percentages. Features an auto-scrolling top carousel on the Customer Reviews screen.
3. **Conversational AI CMO Assistant**: Real-time business advisor drawer accessible across all screens in the mobile app.
4. **Local SEO & Google Search Console**: Ingests real search clicks, impressions, CTR, queries, and tracks Map Pack local rankings.
5. **Autonomous Multi-Channel Content Studio**: Generates promotional campaigns, social posts (GBP, Instagram, Facebook, LinkedIn), and smart visual promotional banners.
6. **Live Web Admin Dashboard**: Live auto-refreshing dashboard monitoring per-user & per-business AI token usage, tenant management, and system health.
7. **Token-Guarded Background Worker**: Asynchronous processing with caching preventing redundant LLM token expenditures (see [`CELERY_BACKGROUND_TASKS.md`](CELERY_BACKGROUND_TASKS.md)).

---

## 📊 Development Phases

| Phase | Status | Description |
|:---|:---:|:---|
| **Phase 1** | ✅ | Architecture & Monorepo Foundation |
| **Phase 2** | ✅ | Authentication & 3-Step Business Onboarding |
| **Phase 3** | ✅ | Business Data & Google Business Profile Sync Engine |
| **Phase 4** | ✅ | AI Business Understanding & Health Scoring |
| **Phase 5** | ✅ | AI CMO Engine & Prioritized Recommendations |
| **Phase 6** | ✅ | Multi-Channel Social Content & Schedule Engine |
| **Phase 7** | ✅ | Local SEO & Keyword Visibility Optimizer |
| **Phase 8** | ✅ | Multi-Channel Marketing Campaigns |
| **Phase 9** | ✅ | Smart Creatives & Promotional Banner Engine |
| **Phase 10** | ✅ | Conversational AI CMO Chat Drawer |
| **Phase 11** | ✅ | Marketing ROI & Competitor Intelligence Dashboard |
| **Phase 12** | ✅ | Proactive Notification & Alert System |
| **Phase 13** | ✅ | Live Web Admin Portal (Real-Time Auto-Sync & Token Tracking) |
| **Phase 14** | ✅ | AI Review Intelligence & Interactive Mobile Carousel |
| **Phase 15** | ✅ | Token-Guarded Celery Background Processing & Scheduling |

---

## 🧪 Testing & Verification

```bash
# Run full backend test suite inside Docker
docker compose exec api pytest tests/

# Run Flutter static analyzer
cd mobile && flutter analyze
```

---

## 📄 License

Proprietary — OptigoAI. All rights reserved.
