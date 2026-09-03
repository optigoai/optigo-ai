# OptigoAI Enterprise — Database & Backend Data Serving Architecture

This document details the exact database architecture, backend data serving pipelines, live database records tested, and frontend integration layers in **OptigoAI Enterprise**.

---

## 1. System Architecture Overview

OptigoAI Enterprise operates as a multi-tenant, multi-location platform designed for single-store and franchise businesses.

```
┌─────────────────────────────────────────────────────────────┐
│                    React Web Client (Port 5173)             │
│   (FranchiseOverview, Insights, Reports, AI Analysis, etc.) │
└──────────────────────────────┬──────────────────────────────┘
                               │ HTTP /api Proxy (Vite)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                 FastAPI Backend Service (Port 8000)         │
│   (Endpoints: /franchise/*, /businesses/*, /auth/*)         │
└──────────────┬───────────────────────────────┬──────────────┘
               │ SQLAlchemy (Asyncpg)          │ Celery / Redis
               ▼                               ▼
┌──────────────────────────────┐ ┌────────────────────────────┐
│    PostgreSQL 16 Database    │ │    Redis Cache & Broker    │
│    (Container: optigoai-db)  │ │   (Container: optigo-redis)│
└──────────────────────────────┘ └────────────────────────────┘
```

- **Containerized Stack**:
  - `optigoai-db`: PostgreSQL 16 on internal port `5432` (`postgres:16-alpine`)
  - `optigoai-api`: Python 3.11 / FastAPI running on `0.0.0.0:8000` via Uvicorn
  - `optigoai-redis`: Redis 7 Alpine on internal port `6379`
  - `optigoai-celery-worker` & `optigoai-celery-beat`: Background tasks and periodic sync
- **Authentication**: JWT Bearer Tokens passed in the `Authorization: Bearer <token>` header, verified by `app.core.security`.
- **Tenant Isolation**: All queries filter by `organization_id` derived from the authenticated user's session.

---

## 2. PostgreSQL Database Schema & Core Models

The database models are defined in `backend/app/models/` using SQLAlchemy Declarative Base.

### 2.1 `organizations` Table
Stores enterprise account and parent franchise entities.
| Column | Type | Description |
|---|---|---|
| `id` | UUID (PK) | Unique organization identifier |
| `name` | String(255) | Organization name (e.g., `casa rasa`) |
| `slug` | String(100) | Unique URL slug |
| `plan_tier` | String(50) | Subscription level (e.g. `enterprise`, `pro`) |
| `max_locations` | Integer | Maximum branches allowed under license |
| `created_at` | Timestamp | Creation timestamp |

### 2.2 `businesses` Table (Locations / Branches)
Stores physical branch locations associated with an organization.
| Column | Type | Description |
|---|---|---|
| `id` | UUID (PK) | Branch unique identifier |
| `organization_id` | UUID (FK) | Reference to `organizations.id` |
| `name` | String(255) | Branch display name (e.g., `casaraza`, `Casarasa ponani`) |
| `category` | String(100) | Google primary business category |
| `address` | String(255) | Street address |
| `city` | String(100) | City (e.g., `Edappal`, `Ponnani`) |
| `state` | String(100) | State / Territory |
| `phone` | String(50) | Contact number |
| `health_score` | Integer | Computed profile & local SEO score (0-100) |
| `total_reviews` | Integer | Total verified Google reviews |
| `average_rating` | Float | Cumulative star rating (1.0 to 5.0) |
| `unreplied_reviews_count`| Integer | Count of reviews awaiting merchant response |
| `google_maps_rank` | Integer | Local 3-pack rank position |
| `monthly_searches` | Integer | Aggregate search impressions |
| `monthly_actions` | Integer | Phone, directions, and website conversions |
| `completeness_score` | Integer | Profile completeness percentage |
| `status` | String(50) | Operational status (`active`, `pending`, etc.) |

### 2.3 `reviews` Table
Stores Google Business Profile customer reviews.
| Column | Type | Description |
|---|---|---|
| `id` | UUID (PK) | Review identifier |
| `business_id` | UUID (FK) | Reference to `businesses.id` |
| `author_name` | String(255) | Customer name |
| `rating` | Integer | Star rating (1 to 5) |
| `sentiment` | String(20) | AI sentiment classification (`positive`, `neutral`, `negative`) |
| `content` | Text | Review body text |
| `reply_content` | Text | Merchant reply text |
| `is_replied` | Boolean | True if reply published, False otherwise |
| `created_at` | Timestamp | Review posting timestamp |

### 2.4 `business_analytics` Table
Stores daily/weekly time-series traffic and conversion telemetry.
| Column | Type | Description |
|---|---|---|
| `id` | UUID (PK) | Record ID |
| `business_id` | UUID (FK) | Reference to `businesses.id` |
| `date` | Date | Record date |
| `searches_direct` | Integer | Brand direct search volume |
| `searches_discovery` | Integer | Category discovery search volume |
| `maps_views` | Integer | Google Maps views |
| `actions_phone` | Integer | Direct call button clicks |
| `actions_directions` | Integer | Driving direction requests |
| `actions_website` | Integer | Website button clicks |

### 2.5 `seo_keywords` Table
Stores tracked local search keywords and search rank tracking per branch.
| Column | Type | Description |
|---|---|---|
| `id` | UUID (PK) | Keyword record ID |
| `business_id` | UUID (FK) | Reference to `businesses.id` |
| `keyword` | String(255) | Tracked query (e.g., `family restaurant edappal`) |
| `current_rank` | Integer | Current Google Local 3-Pack rank |
| `previous_rank` | Integer | Previous rank position |

---

## 3. Live Tested Database Records

During backend and database verification, live production data was queried directly from the PostgreSQL instance for the active authenticated account:

### 3.1 Active Tenant Details
- **Organization Name**: `casa rasa`
- **Organization ID**: `4d69a79b-b985-4072-9c99-3848e95fd85a`
- **Primary User**: `Ahmed yazeen` (`casaraza@gmail.com`)

### 3.2 Live Branch Records (`businesses`)
```json
[
  {
    "id": "97e648a1-0766-4851-9e84-338706f99db7",
    "name": "casaraza",
    "category": "Family Restaurant",
    "location": "Edappal, Kerala, India",
    "city": "Edappal",
    "health_score": 62,
    "total_reviews": 8,
    "average_rating": 3.6,
    "unreplied_reviews": 0,
    "google_maps_rank": 4,
    "monthly_searches": 39390,
    "monthly_actions": 14438,
    "status": "active"
  },
  {
    "id": "1e9ca227-b719-4a4d-abcd-a48e69d2aa95",
    "name": "Casarasa ponani",
    "category": "Restaurant / Cafe",
    "location": "Ponnani, Kerala",
    "city": "Ponnani",
    "health_score": 68,
    "total_reviews": 8,
    "average_rating": 3.6,
    "unreplied_reviews": 6,
    "google_maps_rank": 2,
    "monthly_searches": 11100,
    "monthly_actions": 4069,
    "status": "active"
  }
]
```

### 3.3 Live Aggregate Network Totals
Queried via `FranchiseService.get_franchise_overview`:
```json
{
  "total_locations": 2,
  "aggregate_health_score": 65,
  "franchise_avg_rating": 3.6,
  "total_reviews": 16,
  "unreplied_reviews_count": 6,
  "positive_sentiment_pct": 62,
  "total_searches": 4875,
  "total_maps_views": 2600,
  "total_customer_actions": 1787,
  "total_calls": 325,
  "total_direction_requests": 487,
  "total_website_clicks": 975,
  "customer_actions_breakdown": {
    "direction_requests": 487,
    "phone_calls": 325,
    "website_clicks": 975
  },
  "urgent_actions": [
    {
      "title": "Respond to 6 unreplied customer reviews",
      "category": "Reviews Management",
      "impact": "High • Improves Local Ranking Velocity",
      "action_tab": "reviews"
    },
    {
      "title": "Complete missing Google Profile attributes (Hours, Photos, Offerings)",
      "category": "Profile Optimization",
      "impact": "High • +25% Google Maps Discovery",
      "action_tab": "profile"
    },
    {
      "title": "Publish Weekly Google Post with AI CMO for weekend traffic",
      "category": "Customer Engagement",
      "impact": "Medium • +18% Search Views",
      "action_tab": "content"
    },
    {
      "title": "Preview & Publish Public Website (optigoai.com)",
      "category": "Online Presence",
      "impact": "High • Direct Inquiries & Orders",
      "action_tab": "website_builder"
    }
  ]
}
```

---

## 4. Backend Endpoints & Data Serving Logic

The backend endpoints are implemented in `backend/app/api/v1/endpoints/franchise.py` and powered by `backend/app/services/franchise_service.py`.

### 4.1 Franchise Overview Endpoint
- **Route**: `GET /api/v1/franchise/overview`
- **Method**: `FranchiseService.get_franchise_overview(db, org_id)`
- **Query Pipeline**:
  1. Fetch all businesses where `Business.organization_id == org_id`.
  2. Compute average `health_score` across branches.
  3. Aggregate review counts and compute average ratings:
     ```python
     reviews_stmt = select(
         func.count(Review.id).label("total_reviews"),
         func.avg(Review.rating).label("avg_rating"),
         func.count(case((Review.is_replied == False, 1))).label("unreplied")
     ).where(Review.business_id.in_(biz_ids))
     ```
  4. Aggregate analytics time-series for searches, maps views, and actions from `BusinessAnalytics`.
  5. Compute sentiment distribution from `Review.sentiment == 'positive'`.
  6. Return structured `FranchiseOverviewResponse`.

### 4.2 Franchise Locations Matrix Endpoint
- **Route**: `GET /api/v1/franchise/locations`
- **Method**: `FranchiseService.get_franchise_locations_matrix(db, org_id)`
- **Query Pipeline**:
  1. Retrieves all locations for the organization.
  2. Joins `unreplied_reviews` count and latest rank data.
  3. Computes share of traffic per location based on `monthly_searches`.

### 4.3 Benchmarks & Comparative Rankings
- **Route**: `GET /api/v1/franchise/benchmarks`
- **Method**: `FranchiseService.get_franchise_benchmarks(db, org_id)`
- **Data Served**:
  - `franchise_averages`: Average rating, health score, reviews per store, completeness score.
  - `rankings`: Sorted branches by health, rating, and actions.
  - `top_performers`: Store with highest local map visibility and lowest unreplied reviews.

### 4.4 Profile Strength & Completeness Audit
- **Route**: `GET /api/v1/franchise/audit`
- **Method**: `FranchiseService.get_franchise_audit(db, org_id)`
- **Data Served**:
  - `average_completeness_pct`: Calculated across all profile attributes (phone, description, hours, photos, website).
  - `attention_required_count`: Branches missing key attributes or with unanswered customer reviews.
  - `issues_by_type`: Breakdown of missing photos, unreplied reviews, and missing categories.

### 4.5 Single-Branch Endpoints
- `GET /api/v1/businesses/{id}`: Single location profile data.
- `GET /api/v1/businesses/{id}/reviews`: All Google reviews with sentiment tags and replies.
- `GET /api/v1/businesses/{id}/analytics`: Raw time-series telemetry for conversion and search views.
- `GET /api/v1/businesses/{id}/keywords`: Tracked search queries with current and previous ranks.

---

## 5. Frontend Integration & Elimination of Hardcoded Fallbacks

The frontend communicates with the backend through `web/src/services/franchiseService.ts` and React contexts (`FranchiseContext.tsx`, `LocationContext.tsx`).

### 5.1 Proxy Configuration
In `web/vite.config.ts`, requests to `/api` are automatically proxied to the backend:
```typescript
server: {
  port: 5173,
  proxy: {
    '/api': {
      target: 'http://localhost:8000',
      changeOrigin: true,
    }
  }
}
```

### 5.2 Elimination of Hardcoded Mock Data Across Views
All hardcoded mock fallback constants were removed and replaced with database-backed expressions:

| View File | Previous Hardcoded Fallback | Replaced With Live Database Expression |
|---|---|---|
| `FranchiseOverviewView.tsx` | `overview.total_searches \|\| 3555` | `overview.total_searches \|\| 0` |
| `FranchiseOverviewView.tsx` | `overview.total_maps_views \|\| 1896` | `overview.total_maps_views \|\| 0` |
| `FranchiseOverviewView.tsx` | `overview.total_customer_actions \|\| 1303` | `overview.total_customer_actions \|\| 0` |
| `FranchiseOverviewView.tsx` | `directionRequests = totalActions * 0.54` | `overview.total_direction_requests \|\| overview.customer_actions_breakdown.direction_requests` |
| `FranchiseOverviewView.tsx` | `phoneCalls = totalActions * 0.26` | `overview.total_calls \|\| overview.customer_actions_breakdown.phone_calls` |
| `FranchiseOverviewView.tsx` | `websiteClicks = totalActions * 0.20` | `overview.total_website_clicks \|\| overview.customer_actions_breakdown.website_clicks` |
| `FranchiseOverviewView.tsx` | Static `branch1` & `branch2` mock objects | Dynamic mapping over `locations` with `loc.monthly_searches`, `loc.total_reviews`, `loc.unreplied_reviews`, `loc.average_rating` |
| `FranchiseOverviewView.tsx` | Fixed `65%` and `35%` search share | Dynamic calculation: `Math.round((loc.monthly_searches / totalSearches) * 100)` |
| `FranchiseOverviewView.tsx` | Hardcoded Sparkline numbers `[780, ... 1303]` | Computed sparkline scaled from real `totalActions`, `avgRating`, `totalImpressions`, `unrepliedReviews` |
| `FranchiseOverviewView.tsx` | Static hardcoded Directives JSX blocks | Dynamic mapping over `overview.urgent_actions` from backend |
| `FranchiseInsightsView.tsx` | `\|\| 3555`, `\|\| 1896`, `\|\| 1303`, `neutralPct = 25` | Real database fields and review sentiment distribution |
| `FranchiseReportsView.tsx` | `\|\| 3555`, `\|\| 1303`, `\|\| 237`, `\|\| 355`, `\|\| 65`, `\|\| 3.6` | Real `overview` fields and dynamic location rows |
| `FranchiseAiAnalysisView.tsx`| Hardcoded numbers & static branch names | Dynamic interpolation from `locations` and `overview` |
| `FranchiseAuditView.tsx` | `audit.average_completeness_pct \|\| 90` | `audit.average_completeness_pct \|\| 0` |
| `FranchiseBenchmarksView.tsx`| Hardcoded averages object | Dynamic calculation from `overview` and `locations` |

---

## 6. How to Query and Verify Data Directly

### 6.1 Direct PostgreSQL Inspection via Docker
To run SQL queries against the running database container:
```bash
docker exec -it optigoai-db psql -U optigoai -d optigoai
```

Common verification queries:
```sql
-- 1. View all organizations
SELECT id, name, slug, plan_tier FROM organizations;

-- 2. View all branches for an organization
SELECT id, name, city, health_score, total_reviews, average_rating, unreplied_reviews_count, monthly_searches
FROM businesses
WHERE organization_id = '4d69a79b-b985-4072-9c99-3848e95fd85a';

-- 3. Review counts & sentiment breakdown
SELECT business_id, rating, sentiment, is_replied, COUNT(*)
FROM reviews
GROUP BY business_id, rating, sentiment, is_replied;
```

### 6.2 Testing Backend Endpoints via Curl
```bash
# Health check
curl -X GET http://localhost:8000/api/v1/health

# Franchise Overview (with Bearer Token)
curl -X GET http://localhost:8000/api/v1/franchise/overview \
  -H "Authorization: Bearer <YOUR_JWT_TOKEN>"
```

### 6.3 Building and Validating the Frontend
```bash
cd web
npm run build
```
Build verification outputs `dist/` with 0 compilation or lint errors.
