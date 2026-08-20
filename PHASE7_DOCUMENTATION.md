# OptigoAI — Phase 7: Local SEO & Visibility Optimizer Documentation

## Overview
**Phase 7 (Local SEO & Visibility Optimizer)** empowers local small businesses to dominate Google Maps 3-Pack and hyper-local search queries. By leveraging Google Gemini (`gemini-3.5-flash-lite`), OptigoAI performs automated local SEO audits, discovers high-intent local keywords, monitors ranking positions, and produces 1-tap Google Business Profile (GBP) profile attribute optimizations.

---

## Key Capabilities Implemented

### 1. AI-Powered Local SEO & Map Pack Audit
- **Overall SEO Health Score**: Calculated composite score (0–100) reflecting Map Pack presence, keyword visibility, and citations.
- **Map Pack Dominance Score**: Analyzes proximity signals and Google 3-Pack ranking strength.
- **Missing GBP Attributes**: Detects missing profile fields (e.g. `Wheelchair accessible entrance`, `Drive-through`, `Organic certifications`, `Same-day delivery`).
- **Actionable AI Recommendations**: Immediate steps for the business owner to outrank competitors.

### 2. Live Local Keyword Rank Tracker
- **Rank Tracking**: Real-time rank position tracking (e.g., `#2 in Ponnani`) with previous rank deltas (`+2`).
- **Search Volume & Competition**: Low/Medium/High keyword difficulty ratings tailored to hyper-local search intent.
- **Auto-Seeding**: Automatically initializes high-volume local keywords upon business creation.

### 3. AI Keyword Discovery
- **Gemini AI Keyword Intelligence**: Generates 6+ high-converting, hyper-local search terms based on business category, target services, and city location.
- **1-Tap Add to Tracking**: Add newly discovered keywords directly to the live tracking dashboard.

### 4. Google Business Profile (GBP) Profile Optimizer
- **Optimized Profile Title**: Generates SEO-optimized business names following Google guidelines (e.g., `Panekkatt Oil & Flour Mill | Cold Pressed Oils & Organic Flours`).
- **High-Converting Description**: Localized description rich in target search terms.
- **Primary & Secondary Category Mapping**: AI-recommended category classifications for maximum Maps impressions.

---

## Database Architecture (`PostgreSQL`)

### Tables Created via Alembic Migration (`phase7_seo_optimizer`):

#### 1. `seo_keywords`
| Column | Type | Description |
|---|---|---|
| `id` | VARCHAR(36) | Primary Key (UUID) |
| `business_id` | VARCHAR(36) | Foreign Key (`businesses.id`, CASCADE) |
| `keyword` | VARCHAR(255) | Tracked search term |
| `target_location` | VARCHAR(255) | Local geo-target |
| `current_rank` | INTEGER | Current Google Map Pack / Search rank |
| `previous_rank` | INTEGER | Previous rank for trend calculations |
| `search_volume` | VARCHAR(50) | Estimated monthly search volume |
| `difficulty` | VARCHAR(50) | Low / Medium / High difficulty |
| `intent` | VARCHAR(50) | Local Intent / Commercial |
| `is_tracked` | BOOLEAN | Tracking status |
| `created_at` / `updated_at` | TIMESTAMP | Audit timestamps |

#### 2. `seo_audits`
| Column | Type | Description |
|---|---|---|
| `id` | VARCHAR(36) | Primary Key (UUID) |
| `business_id` | VARCHAR(36) | Foreign Key (`businesses.id`, CASCADE) |
| `overall_seo_score` | INTEGER | Composite SEO score (0–100) |
| `map_pack_score` | INTEGER | Local Map Pack visibility score |
| `keyword_score` | INTEGER | Keyword coverage score |
| `citation_score` | INTEGER | Citation consistency score |
| `missing_attributes` | JSON | List of missing GBP profile attributes |
| `actionable_recommendations` | JSON | AI-generated rank optimization steps |
| `competitor_insights` | JSON | Local market insights |
| `created_at` | TIMESTAMP | Audit generation timestamp |

---

## API Endpoints (`/api/v1/seo`)

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/v1/seo/keywords?business_id={id}` | List all tracked keywords (auto-seeds defaults) |
| `POST` | `/api/v1/seo/keywords?business_id={id}` | Add a custom tracked keyword |
| `DELETE` | `/api/v1/seo/keywords/{keyword_id}?business_id={id}` | Remove keyword from tracking |
| `POST` | `/api/v1/seo/audit?business_id={id}` | Run or retrieve latest AI SEO audit |
| `POST` | `/api/v1/seo/discover-keywords?business_id={id}` | Discover new hyper-local keywords via Gemini |
| `POST` | `/api/v1/seo/optimize-profile?business_id={id}` | Generate optimized GBP title, description & categories |

---

## Mobile Application Architecture (`Flutter`)

- **Screen**: `mobile/lib/presentation/seo/seo_optimizer_screen.dart`
- **Models**: `mobile/lib/data/models/seo_model.dart`
- **Repository**: `mobile/lib/data/repositories/seo_repository.dart`
- **Navigation**: Integrated as Tab 3 in `MainShell` and linked to Home Screen quick actions and priority cards.
- **Design Aesthetic**: Ultra-clean, glanceable circular score rings, concise 1-liners, tag chips, and zero wall-of-text.

---

## Verification & Testing
- **Backend Test Suite**: 13/13 Pytest tests passing (`100% PASS`), including `test_seo_optimizer.py`.
- **Flutter Analyzer**: 0 errors, 0 warnings (`No issues found!`).
- **AI Model**: Live Google Gemini (`gemini-3.5-flash-lite`) with token logging into `ai_request_logs`.
