# OptigoAI MVP — Architecture, Docker Guide & Product Roadmap

---

## 1. What Has Been Built So Far (Phases 1 – 3)

We have built a **real, production-grade foundation** with clean architecture, working APIs, database persistence, and mobile UI.

```
optigoai/
├── mobile/                  # Flutter mobile application (Android & iOS)
│   ├── lib/
│   │   ├── app/             # Design system (Theme, Light-only, Typography)
│   │   ├── core/            # API endpoints & constants
│   │   ├── data/            # ApiClient, Repositories, Models (User, Business, Review)
│   │   └── presentation/    # Login, Signup, 3-Step Business Onboarding, Home Screen
│   └── test/                # Automated Flutter widget test suite (100% Pass)
│
├── backend/                 # FastAPI backend (Python 3.11)
│   ├── app/
│   │   ├── api/v1/          # REST API endpoints (Auth, Businesses, Reviews, Health)
│   │   ├── core/            # Database (SQLAlchemy), Redis, JWT Security, Logging
│   │   ├── models/          # 15 PostgreSQL Relational Models
│   │   ├── schemas/         # Pydantic validation schemas
│   │   ├── repositories/    # User, Org, Business, Review data access
│   │   ├── services/        # AuthService, BusinessService, GBPSyncService
│   │   ├── providers/       # MockGBPProvider, AIProvider, StorageProvider
│   │   └── workers/         # Celery task queue & beat scheduler
│   ├── alembic/             # Database migrations
│   └── tests/               # Pytest suite with multi-tenant isolation tests (100% Pass)
│
├── docker-compose.yml       # Orchestrates Database, Redis, FastAPI, Celery
├── .env.example             # Safe environment variable template
├── .gitignore               # Strict secret protection (prevents .env leaks)
└── README.md                # Project documentation
```

### Key Deliverables Completed:

| Area | Features Completed |
|------|--------------------|
| **Phase 1: Architecture & Foundation** | • 15 PostgreSQL database tables designed with Alembic migrations.<br>• Abstract Provider interfaces (`BusinessDataProvider`, `AIProvider`, `StorageProvider`, `SEOProvider`, `CompetitorProvider`).<br>• Structured logging with correlation IDs.<br>• Secure JWT token engine and bcrypt password hashing.<br>• Pinned dependencies and Docker containerization. |
| **Phase 2: Authentication & Business Onboarding** | • Complete User signup, login, refresh tokens, and logout.<br>• **Multi-tenant organization isolation** (User → Organization → Business) where Org A can never see Org B data.<br>• Flutter Mobile Auth flow (LoginScreen, SignupScreen).<br>• 3-Step interactive Business Onboarding wizard in Flutter (Business Info → Target Audience & Services → Marketing Goals & Channels).<br>• Secure token storage on mobile (`flutter_secure_storage`). |
| **Phase 3: Business Data & MockGBP Provider Seeding** | • Realistic `MockGBPProvider` simulating Google Business Profile data (reviews, ratings, performance metrics, search trends).<br>• `GBPSyncService` pulling external data through the provider into PostgreSQL.<br>• Review management endpoints (`GET /reviews`, `POST /reviews/{id}/reply`) with sentiment filtering (positive/neutral/negative).<br>• Auto-syncing of GBP data immediately upon business onboarding. |

### Verification Status:
- ✅ **Backend Tests**: 9/9 Pytest tests passed (Auth, Business, GBP Sync, and Cross-Org Isolation).
- ✅ **Mobile Tests**: `flutter analyze` has **0 issues**, `flutter test` **100% passed**.
- ✅ **Security**: `.env` is ignored by Git, preventing API keys/secrets from being pushed to GitHub.

---

## 2. Docker Explained: What is it & Why are we using it?

If you have never used Docker before, think of it like this:

### 📦 The "Shipping Container" Analogy
Before shipping containers existed, loading cargo onto ships was chaotic—barrels, sacks, and crates of all different shapes and sizes had to be loaded manually, and things broke constantly depending on which port you arrived at.

Standardized steel shipping containers solved this: **anything placed inside the container travels anywhere in the world and fits onto any ship, truck, or train identically.**

> **Docker is a shipping container for software.**

### 🛑 The Problem Without Docker:
When developing a modern backend with Python, PostgreSQL, Redis, and background workers, you would usually have to:
1. Install PostgreSQL database on your Windows machine, configure ports, passwords, and background services.
2. Install Redis cache server on Windows (which is tricky and not officially supported on Windows).
3. Install Python 3.11, C++ build tools for PostgreSQL drivers, and match exact version numbers.
4. When moving from your computer to a cloud server (AWS / Google Cloud / Linux), something always breaks because of differences in operating systems ("*It worked on my machine!*").

### 🚀 How Docker Solves This in OptigoAI:
With Docker, your entire backend runs inside 5 isolated, lightweight "containers":

```mermaid
graph TB
    subgraph "Docker Desktop (Isolated Virtual Environment)"
        API["1. optigoai-api<br/>(FastAPI Server :8000)"]
        DB["2. optigoai-db<br/>(PostgreSQL Database :5432)"]
        REDIS["3. optigoai-redis<br/>(Redis Cache & Queue :6379)"]
        WORKER["4. optigoai-celery-worker<br/>(Background AI Task Processor)"]
        BEAT["5. optigoai-celery-beat<br/>(Periodic Scheduled Job Trigger)"]
    end

    API <--> DB
    API <--> REDIS
    WORKER <--> REDIS
    WORKER <--> DB
    BEAT --> REDIS
    
    FLUTTER["Flutter Mobile App (Your Phone / Emulator)"] -->|Sends API Requests| API
```

### What Each Container Does in OptigoAI:

1. **`optigoai-db` (PostgreSQL 16)**:
   - Stores all your business data, users, organizations, reviews, campaigns, and AI logs permanently on disk.
2. **`optigoai-redis` (Redis 7)**:
   - Super-fast in-memory database used as a message queue to pass background jobs to Celery.
3. **`optigoai-api` (FastAPI)**:
   - The web server that handles requests from Flutter (e.g. logging in, fetching recommendations, generating content).
4. **`optigoai-celery-worker` (Celery)**:
   - The background worker. Heavy AI tasks (like analyzing 50 reviews, generating images, or running weekly audits) run here in the background so your mobile app never freezes or lags.
5. **`optigoai-celery-beat` (Scheduler)**:
   - An automated clock that wakes up at scheduled intervals (e.g., daily at 9 AM) to check for new reviews and trigger automated notifications.

### 💡 The Magic:
Whenever you or your team run:
```bash
docker compose up
```
All 5 servers start up in seconds with the exact right settings, databases, and dependencies, without you having to install PostgreSQL or Redis manually on Windows!

---

## 3. Complete Feature Roadmap (Phases 4 – 13)

Here is what will be built in each remaining phase of the OptigoAI MVP:

```mermaid
flowchart TD
    P1["Phase 1: Foundation ✅"] --> P2["Phase 2: Auth & Onboarding ✅"]
    P2 --> P3["Phase 3: Business Data & MockGBP ✅"]
    P3 --> P4["Phase 4: AI Business Understanding"]
    P4 --> P5["Phase 5: AI CMO Engine & Recommendations"]
    P5 --> P6["Phase 6: Reviews & Reputation Intelligence"]
    P6 --> P7["Phase 7: Local SEO & Competitor Intelligence"]
    P7 --> P8["Phase 8: Content Studio, Campaigns & Creatives"]
    P8 --> P9["Phase 9: Context-Aware AI CMO Chat"]
    P9 --> P10["Phase 10: Automation & Notifications"]
    P10 --> P11["Phase 11: Analytics & AI Performance Insights"]
    P11 --> P12["Phase 12: Internal Admin Portal"]
    P12 --> P13["Phase 13: End-to-End Testing & Security Hardening"]
```

---

### 🔹 Phase 4 — AI Business Understanding & Health Scoring
- **Real Gemini AI Integration**: Connects Google Gemini API behind the `AIProvider` abstraction.
- **AI Business Profile Generator**: Takes onboarding answers and generates a structured marketing identity (target audience segments, value propositions, tone of voice, growth levers).
- **Business Health Score Engine**: Evaluates current business condition and calculates a **Health Score (0–100)**, identifying top problems and opportunities.
- **AI Usage Tracking**: Automatically logs tokens, latency, and costs to `AIRequestLog`.

---

### 🔹 Phase 5 — AI CMO Engine & Recommendations
- **Central AI CMO Service**: Analyzes the business holistically: *"What is happening? Why does it matter? What should the owner do today?"*
- **Actionable Recommendation Engine**: Produces prioritized cards (`Urgent`, `Important`, `Opportunity`) that connect directly to one-click AI actions (e.g., *"Respond to 3 negative reviews"*, *"Run a promotion for dental implants"*).
- **AI CMO Home Screen**: Mobile dashboard focused on *"What should I do today?"* rather than overwhelming data charts.

---

### 🔹 Phase 6 — Reviews & Reputation Intelligence
- **AI Sentiment & Theme Extraction**: Identifies common customer praise (staff quality, speed) and common complaints (wait times, pricing).
- **"What Customers Are Telling You" Report**: Executive summary of customer feedback.
- **AI Review Reply Generator**: Generates contextual, professional replies in multiple tones (Appreciative, Professional, Apologetic) with Edit / Regenerate / Approve actions.

---

### 🔹 Phase 7 — Local SEO & Competitor Intelligence
- **Local SEO Engine**: Analyzes local search presence, category optimization, and keyword opportunities.
- **Competitor Intelligence**: Analyzes local competitors to identify their weaknesses and highlight opportunities where your business can win customers.

---

### 🔹 Phase 8 — AI Content Studio, Campaigns & Creative Generation
- **AI Content Studio**: Generates marketing copy for Google Business Posts, Instagram/Facebook, Local Ads, and SEO Articles tailored to the business's audience and tone.
- **AI Campaign Generator**: Turns goals (e.g., *"Get 20 new customers for teeth whitening this month"*) into full multi-week campaigns with messaging, schedule, and CTAs.
- **AI Creative Generation**: Generates marketing banners and graphics linked to campaigns, stored in object storage.

---

### 🔹 Phase 9 — AI CMO Chat
- **Context-Aware Marketing Assistant**: Conversational assistant that knows the business's profile, recent reviews, competitors, and ongoing campaigns.
- **Action Triggers**: Can trigger real workflows directly from the conversation (e.g., *"Draft a post for our weekend offer"*).

---

### 🔹 Phase 10 — Automation & Notifications
- **Background Scheduled Tasks (Celery + Redis)**: Automated review monitoring, weekly marketing health checks, and campaign schedule execution.
- **Notification Center**: Real-time alerts for new reviews, detected marketing problems, and high-impact opportunities.

---

### 🔹 Phase 11 — Analytics & AI Performance Insights
- **Business-Focused Metrics**: Track customer calls, profile views, website clicks, and campaign engagement.
- **AI Explanations**: Answers *"What worked, what didn't work, and what should happen next"* in clear business terms.

---

### 🔹 Phase 12 — Internal Admin Web Portal
- **Separate Lightweight Web Portal**: Accessible only to OptigoAI administrators (not visible in the mobile app).
- **Feature Toggles**: Enable/disable features (Content Studio, Creatives, AI Chat) dynamically without redeploying code.
- **Usage & Cost Monitoring**: Track token consumption, API calls, and error rates per organization.
- **Organization Management**: Suspend/reinstate user and business access.

---

### 🔹 Phase 13 — Integration, Security & Deployment
- **Full End-to-End Test Journey**: Automated verification of the entire flow from signup to AI recommendations and campaign generation.
- **Security Audit**: Organization isolation verification, rate limiting, and input sanitization.
- **Production Deployment Config**: Production Docker setup, database migration scripts, and documentation.
