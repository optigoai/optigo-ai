# OptigoAI

**AI Marketing Manager for Small & Medium Businesses**

OptigoAI helps business owners answer one question: *"What should I do to get more customers?"*

## Architecture

```
optigoai/
├── mobile/         Flutter app (Android + iOS)
├── backend/        FastAPI + SQLAlchemy + Celery
├── admin/          Internal admin portal (Phase 12)
├── docker-compose.yml
├── .env.example
└── README.md
```

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile | Flutter 3.29, Dart 3.7 |
| Backend | Python 3.11, FastAPI, SQLAlchemy, Alembic |
| Database | PostgreSQL 16 |
| Cache/Queue | Redis 7 |
| Background Jobs | Celery |
| AI | Google Gemini API |
| Storage | Google Cloud Storage |
| Containers | Docker, Docker Compose |

## Quick Start

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

# Edit .env and set your secrets:
# - JWT_SECRET_KEY (generate with: python -c "import secrets; print(secrets.token_urlsafe(64))")
# - GEMINI_API_KEY (from https://aistudio.google.com/apikey)
```

### 2. Start Backend Services

```bash
docker compose up --build
```

This starts:
- **PostgreSQL** on port 5432
- **Redis** on port 6379
- **FastAPI** on port 8000 (http://localhost:8000/docs)
- **Celery Worker** (background tasks)
- **Celery Beat** (scheduled tasks)

### 3. Run Database Migrations

```bash
docker compose exec api alembic upgrade head
```

### 4. Run Flutter App

```bash
cd mobile
flutter pub get
flutter run
```

### 5. Verify

- Backend health: http://localhost:8000/api/v1/health
- API docs: http://localhost:8000/docs
- Flutter app: running on emulator/device

## Environment Variables

See [`.env.example`](.env.example) for all required variables.

**Critical secrets (NEVER commit):**
- `JWT_SECRET_KEY`
- `GEMINI_API_KEY`
- `GOOGLE_APPLICATION_CREDENTIALS`
- `POSTGRES_PASSWORD`

## Mock GBP Architecture

Google Business Profile integration is mocked during MVP:

```
Flutter → FastAPI → Provider Layer → MockGBPProvider → Database → AI
```

To replace with real GBP:
1. Create `GoogleGBPProvider` implementing `BusinessDataProvider`
2. Update provider factory in config
3. No changes needed to services, AI, or Flutter

## Development Phases

| Phase | Status | Description |
|-------|--------|-------------|
| 1 | ✅ | Foundation |
| 2 | ⬜ | Authentication + Onboarding |
| 3 | ⬜ | Business Data + MockGBP |
| 4 | ⬜ | AI Business Understanding |
| 5 | ⬜ | AI CMO + Recommendations |
| 6 | ⬜ | Reviews + Intelligence |
| 7 | ⬜ | SEO + Competitors |
| 8 | ⬜ | Content + Campaigns + Creatives |
| 9 | ⬜ | AI CMO Chat |
| 10 | ⬜ | Automation + Notifications |
| 11 | ⬜ | Analytics + AI Insights |
| 12 | ⬜ | Admin Portal |
| 13 | ⬜ | Integration + Testing + Security |

## Testing

```bash
# Backend tests
docker compose exec api pytest

# Flutter tests
cd mobile && flutter test
```

## License

Proprietary — OptigoAI. All rights reserved.
