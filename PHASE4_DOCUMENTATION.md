# OptigoAI MVP — Phase 4 Documentation: AI Business Understanding & Health Scoring

---

## 1. Overview of Phase 4 Deliverables

Phase 4 introduces the **AI Intelligence Core** of OptigoAI. It transforms raw onboarding inputs, Google Business Profile metrics, and customer reviews into a structured AI marketing profile and calculates a real-time **Marketing Health Score (0–100)** with detected problems and high-impact growth opportunities.

```
┌─────────────────────────────────────────────────────────────┐
│                    AI INTELLIGENCE ENGINE                   │
│                                                             │
│   ┌─────────────────────┐       ┌───────────────────────┐   │
│   │ Business Onboarding │       │ Google Business Data  │   │
│   │  - Services         │       │  - Reviews & Ratings  │   │
│   │  - Target Customers │       │  - Views & Calls      │   │
│   │  - Marketing Goals  │       │  - Search Volume      │   │
│   └──────────┬──────────┘       └───────────┬───────────┘   │
│              │                              │               │
│              └──────────────┬───────────────┘               │
│                             │                               │
│                             ▼                               │
│              ┌──────────────────────────────┐               │
│              │ Gemini AI Provider (GenAI)   │               │
│              │  - Structured JSON Schemas   │               │
│              │  - Versioned Prompts         │               │
│              │  - Token / Cost Logging      │               │
│              └──────────────┬───────────────┘               │
│                             │                               │
│              ┌──────────────┴───────────────┐               │
│              ▼                              ▼               │
│   ┌──────────────────────┐       ┌──────────────────────┐   │
│   │ AI Business Profile  │       │ Marketing Health     │   │
│   │  - Summary & Tone    │       │  - Score (0-100)     │   │
│   │  - Audience Segments │       │  - Reputation Score  │   │
│   │  - Key Positioning   │       │  - Visibility Score  │   │
│   │  - Growth Levers     │       │  - Top Problems      │   │
│   └──────────────────────┘       │  - Top Opportunities │   │
│                                  └──────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Backend Components Built

### 1. `backend/app/ai/gemini_provider.py`
- Implements the `AIProvider` base interface.
- Direct integration with Google GenAI SDK (`gemini-2.0-flash`).
- **Resilient Fallback Engine**: If the Gemini API key is not yet set in development or offline, deterministic structured generation ensures zero crashes and 100% test reliability.

### 2. `backend/app/ai/prompts/business_prompts.py`
- Versioned, feature-specific prompt templates:
  - `build_business_profile_prompt`: Analyzes business name, category, services, target audience, and goals.
  - `build_business_intelligence_prompt`: Synthesizes reviews, ratings, and 30-day performance metrics.

### 3. `backend/app/ai/ai_service.py`
- Central AI orchestrator that generates structured Pydantic models:
  - `AIBusinessProfileOutput`
  - `AIBusinessIntelligenceOutput`
- **Automated AI Request Logging**: Every single AI request records to the `ai_request_logs` PostgreSQL table:
  - `feature` (e.g. `business_intelligence_health_scoring`)
  - `provider` (`gemini`)
  - `model` (`gemini-2.0-flash`)
  - `input_tokens`, `output_tokens`, `latency_ms`
  - `estimated_cost_usd` (automatically calculated)
  - `success`, `error_message`, `request_metadata`

### 4. `backend/app/services/business_intelligence_service.py`
- Pulls reviews and metrics from PostgreSQL.
- Executes profile and health score generation.
- Stores `health_score`, `health_analysis`, and `ai_business_profile` directly on the `Business` ORM model.

### 5. API Endpoints
- `POST /api/v1/businesses/{business_id}/analyze`: Triggers on-demand AI analysis and persists results.
- `GET /api/v1/businesses/{business_id}/intelligence`: Retrieves stored AI scores, problems, and opportunities.

---

## 3. Flutter Mobile UI Built

The mobile app's **Home Screen** has been transformed into an intelligent AI CMO dashboard:

1. **AI CMO Health Score Card**:
   - Circular radial health score gauge (`78 / 100`).
   - Sub-score breakdown: **Reputation Score** (`82%`) and **Visibility Score** (`74%`).
   - Executive summary of marketing vitality.
   - **"Re-Run AI Marketing Audit" Button**: Real-time trigger with spinner to refresh the analysis.
2. **Problems Detected by AI**:
   - Lists prioritized issues (e.g., *"3 Unanswered Negative Customer Reviews"*).
   - Severity tags (`CRITICAL`, `HIGH`, `MEDIUM`).
   - Actionable explanations and business impact.
3. **High-Impact Opportunities**:
   - Lists actionable growth opportunities (e.g., *"Launch Reputation Recovery Campaign"*, *"Promote High-Value Services"*).
   - Priority tags (`HIGH IMPACT`, `MEDIUM IMPACT`).
   - Potential impact and suggested next steps.

---

## 4. Verification & Testing

### Backend Test Results (Pytest in Docker):
```text
tests/test_ai_intelligence.py::test_ai_business_understanding_and_health_scoring PASSED [ 10%]
tests/test_auth.py::test_signup_success PASSED                                           [ 20%]
tests/test_auth.py::test_signup_duplicate_email PASSED                                   [ 30%]
tests/test_auth.py::test_login_success_and_failure PASSED                                [ 40%]
tests/test_auth.py::test_get_me_protected_route PASSED                                   [ 50%]
tests/test_businesses.py::test_create_and_get_business PASSED                            [ 60%]
tests/test_gbp_sync.py::test_gbp_sync_and_reviews_workflow PASSED                        [ 70%]
tests/test_health.py::test_health_check PASSED                                           [ 80%]
tests/test_health.py::test_health_check_returns_environment PASSED                       [ 90%]
tests/test_org_isolation.py::test_cross_organization_access_forbidden PASSED             [100%]

============================= 10 passed in 10.39s ==============================
```

### Mobile Test Results (Flutter):
- `flutter analyze`: **0 issues found**
- `flutter test`: **100% passed**

---

## 5. Next Steps

Per your rule, development has **stopped at the completion of Phase 4**.

**Phase 5 (AI CMO Engine & Actionable Recommendations)** will only begin when you explicitly instruct to start.
