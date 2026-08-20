# OptigoAI — Phase 5: AI CMO Engine & Actionable Recommendations

## 1. Executive Summary

**Phase 5** transitions OptigoAI from passive diagnostics into a **proactive AI Chief Marketing Officer (AI CMO)**. Rather than simply displaying metrics and audit scores, OptigoAI actively synthesizes and schedules **prioritized tactical action cards** for the business owner.

Each recommendation is structured with:
- **Priority Tier**: `URGENT` (immediate 24-48h actions like negative reviews), `IMPORTANT` (weekly strategic growth), or `OPPORTUNITY` (high-upside levers like SEO & referral expansion).
- **Estimated Business Impact**: Quantified conversion or traffic returns (e.g. `+15% Conversion Rate`, `Top 3 Map Pack Rank`).
- **Effort Level**: Realistic time cost (e.g. `Low (5 mins)`, `Medium (15 mins)`).
- **Why This Matters**: Clear strategic explanation connecting the action directly to revenue.
- **One-Click Actions**: Ability to mark completed, dismiss, or deep-link to the target feature.

---

## 2. Architecture & Components

```
+-----------------------------------------------------------------------------------+
|                                 Mobile App (Flutter)                              |
|  [HomeScreen (Insights)]  <-->  [RecommendationsScreen (AI CMO Feed)]  <-->  [ReviewsScreen]
+------------------------------------------+----------------------------------------+
                                           | HTTP / REST (JWT Auth)
                                           v
+-----------------------------------------------------------------------------------+
|                                 FastAPI Backend                                    |
|   /api/v1/recommendations/generate   -->  CMOEngineService                         |
|   /api/v1/recommendations            -->  RecommendationRepository                |
|   /api/v1/recommendations/{id}/status-->  PostgreSQL (`recommendations` table)    |
+------------------------------------------+----------------------------------------+
                                           | AI Generation & Telemetry Logging
                                           v
+-----------------------------------------------------------------------------------+
|                        Gemini 2.0 Flash AI CMO Engine                             |
|  - System Prompt: CMO_RECOMMENDATIONS_SYSTEM_PROMPT                                |
|  - Structured JSON Output Schema: AICMORecommendationsOutput                      |
|  - Cost & Latency Logged to PostgreSQL (`ai_request_logs` table)                  |
+-----------------------------------------------------------------------------------+
```

---

## 3. Key Backend Endpoints

| Method | Path | Description | Access |
|---|---|---|---|
| `POST` | `/api/v1/recommendations/generate?business_id={id}` | AI CMO Engine analyzes reviews and health metrics to synthesize fresh prioritized action cards | Authenticated (Org scoped) |
| `GET` | `/api/v1/recommendations?business_id={id}` | Lists active recommendations. Supports filtering by `priority` and `status` | Authenticated (Org scoped) |
| `PATCH` | `/api/v1/recommendations/{id}/status?business_id={id}` | Updates execution status (e.g. `completed`, `dismissed`, `in_progress`) | Authenticated (Org scoped) |

---

## 4. Database Schema: `recommendations` Table

```sql
CREATE TABLE recommendations (
    id VARCHAR(36) PRIMARY KEY,
    business_id VARCHAR(36) NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    title VARCHAR(500) NOT NULL,
    explanation TEXT NOT NULL,
    reason TEXT NOT NULL,
    priority VARCHAR(20) NOT NULL, -- 'urgent', 'important', 'opportunity'
    impact VARCHAR(255) NOT NULL,
    effort VARCHAR(255) NOT NULL,
    suggested_action TEXT NOT NULL,
    related_feature VARCHAR(100), -- 'reviews', 'posts', 'campaigns', 'seo'
    status VARCHAR(20) NOT NULL DEFAULT 'pending', -- 'pending', 'in_progress', 'completed', 'dismissed'
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

---

## 5. Automated Testing & Verification

All test suites were verified in Docker PostgreSQL test container:
```bash
docker compose exec api pytest -v
```

### Test Results: **11/11 PASSED (100%)**
- `tests/test_cmo_recommendations.py::test_cmo_recommendations_workflow` **PASSED**
- `tests/test_ai_intelligence.py::test_ai_business_understanding_and_health_scoring` **PASSED**
- `tests/test_auth.py` (4 tests) **PASSED**
- `tests/test_businesses.py` **PASSED**
- `tests/test_gbp_sync.py` **PASSED**
- `tests/test_health.py` (2 tests) **PASSED**
- `tests/test_org_isolation.py` **PASSED**

---

## 6. Mobile Application Features (Phase 5)

1. **3-Tab Bottom Navigation (`MainShell`)**:
   - 📊 **Insights**: Pure CMO Marketing Health Score, radial gauge, problems, opportunities, and AI brand understanding.
   - 🎯 **AI Actions (`RecommendationsScreen`)**: Dedicated AI CMO recommendations feed with interactive priority filter chips (`All`, `🚨 Urgent`, `⚡ Important`, `🚀 Opportunities`).
   - ⭐ **Reviews (`ReviewsScreen`)**: Dedicated reviews feed, rating metrics, sentiment filters, and AI reply composer.
2. **Interactive Action Cards**:
   - `Mark Done`: Sets status to completed with a visual checkmark.
   - `Dismiss`: Removes from active list.
   - `Open Reviews`: Deep links into the Reviews tab when an action involves customer reviews.
   - `Synthesize Fresh Strategy`: Triggers real-time AI CMO re-generation.

---

## 7. Next Steps (Phase 6: Multi-Channel Marketing & Social Content)
*Development will remain paused until explicit user instruction.*
- Phase 6: Automated Google Business updates, social media post creation, holiday promotions, and marketing calendar.
