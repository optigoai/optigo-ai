# OptigoAI — External API & Provider Integration Guide

This guide provides official instructions for setting up and configuring all real external data providers and APIs used by Optigo AI.

---

## Provider Overview Matrix

| Provider | Purpose | Status in Codebase | Required Env Variables | Free Tier |
| :--- | :--- | :--- | :--- | :--- |
| **Google Gemini AI** | Business analysis, AI CMO chat, content & recommendations | **Integrated & Working** | `GEMINI_API_KEY` | 15 RPM Free |
| **Google Search Console** | First-party search performance, real queries, clicks & impressions | **Integrated & Ready** | `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `GOOGLE_REDIRECT_URI` | Free |
| **DataForSEO** | Primary SERP rank tracking, Google Maps local pack rankings, keyword volume | **Integrated & Default** (`SEO_PROVIDER=dataforseo`) | `DATAFORSEO_LOGIN`, `DATAFORSEO_PASSWORD` | $1 Free Credit on Signup |
| **Serper** | Alternative Google search & local pack provider | **Integrated Adapter** (`SEO_PROVIDER=serper`) | `SERPER_API_KEY` | 2,500 Free Searches |
| **SerpAPI** | Alternative Google search provider | **Integrated Adapter** (`SEO_PROVIDER=serpapi`) | `SERPAPI_API_KEY` | 100 Searches/Month |
| **Firecrawl** | Primary managed website crawler for technical SEO & schema extraction | **Integrated & Default** (`WEBSITE_CRAWLER_PROVIDER=firecrawl`) | `FIRECRAWL_API_KEY` | 500 Credits Free |
| **BeautifulSoup / HTTP** | Lightweight, zero-cost fallback HTML crawler with SSRF protection | **Integrated & Active** | None (Built-in) | Unlimited / Free |
| **Playwright** | Headless browser crawler fallback for JS-rendered SPA websites | **Integrated & Active** | None (Local Worker) | Unlimited / Free |

---

## 1. Google Search Console API (OAuth 2.0)

### 1.1 What Optigo AI uses it for
- Retrieves first-party customer search queries, impressions, clicks, click-through rates (CTR), and average Google search positions for the business website.
- Displays data in the mobile **SEO Screen** and calculates real SEO trends.

### 1.2 Setup Instructions
1. Go to the [Google Cloud Console](https://console.cloud.google.com/).
2. Create a new project (e.g. `OptigoAI-Production`).
3. Navigate to **APIs & Services > Library** and enable **Google Search Console API** (Webmasters API).
4. Go to **APIs & Services > OAuth consent screen**:
   - User Type: **External**.
   - App Name: `Optigo AI`.
   - Scopes: Add `https://www.googleapis.com/auth/webmasters.readonly`.
5. Go to **APIs & Services > Credentials**:
   - Click **Create Credentials > OAuth client ID**.
   - Application type: **Web application**.
   - Authorized redirect URIs: `http://localhost:8000/api/v1/integrations/google/search-console/callback` (or your production domain).
6. Copy the **Client ID** and **Client Secret**.

### 1.3 Environment Variables
```env
GOOGLE_CLIENT_ID=your-google-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your-google-client-secret
GOOGLE_REDIRECT_URI=http://localhost:8000/api/v1/integrations/google/search-console/callback
GOOGLE_TOKEN_ENCRYPTION_KEY=OPTIGOAI_SECRET_KEY_FOR_OAUTH_TOKEN_ENCRYPTION_32B
```

---

## 2. DataForSEO (Primary SERP & Keyword Provider)

### 2.1 What Optigo AI uses it for
- Live Google Maps and organic SERP rank tracking for local keywords (e.g. *"best flour mill in ponnani"*).
- Monthly search volume, keyword difficulty, and local competitor ranking snapshots.

### 2.2 Setup Instructions
1. Register at [DataForSEO Registration](https://app.dataforseo.com/register).
2. DataForSEO provides **$1 free testing balance** upon account creation and email verification.
3. Navigate to your **Dashboard > API Access** to view your **API Login** (email) and **API Password**.

### 2.3 Environment Variables
```env
SEO_PROVIDER=dataforseo
DATAFORSEO_LOGIN=your_login_email@example.com
DATAFORSEO_PASSWORD=your_dataforseo_password
```

---

## 3. Serper (Alternative SERP Provider)

### 3.1 What Optigo AI uses it for
- Fast Google search and Google Places / Maps results querying as an interchangeable alternative to DataForSEO.

### 3.2 Setup Instructions
1. Sign up at [Serper.dev](https://serper.dev/).
2. You receive **2,500 free queries** instantly upon registration without entering a credit card.
3. Copy your API Key from the dashboard.

### 3.3 Environment Variables
```env
SEO_PROVIDER=serper
SERPER_API_KEY=your_serper_api_key_here
```

---

## 4. SerpAPI (Alternative SERP Provider)

### 4.1 What Optigo AI uses it for
- Live Google SERP and Google Maps search results extraction.

### 4.2 Setup Instructions
1. Sign up at [SerpAPI.com](https://serpapi.com/).
2. You receive **100 free searches per month**.
3. Copy your **Private API Key** from your SerpAPI Account page.

### 4.3 Environment Variables
```env
SEO_PROVIDER=serpapi
SERPAPI_API_KEY=your_serpapi_api_key_here
```

---

## 5. Firecrawl (Primary Managed Website Crawler)

### 5.1 What Optigo AI uses it for
- Crawls business storefront websites to extract structured metadata, headers, LocalBusiness Schema (JSON-LD), phone numbers, and location signals for automated AI SEO audits.

### 5.2 Setup Instructions
1. Sign up at [Firecrawl.dev](https://www.firecrawl.dev/).
2. You receive **500 free credits** on the free tier.
3. Copy your API Key from the Firecrawl Dashboard.

### 5.3 Environment Variables
```env
WEBSITE_CRAWLER_PROVIDER=firecrawl
FIRECRAWL_API_KEY=fc-your-api-key-here
```
*(Note: If Firecrawl API key is not configured, Optigo AI automatically falls back to its built-in BeautifulSoup / Playwright crawler engine with zero disruption).*

---

## 6. Background Task Integration & Scheduling

All external provider calls (Google Search Console sync, DataForSEO rank checks, Firecrawl website audits, and Gemini Review Intelligence) can be triggered asynchronously via **Celery background workers** and **Celery Beat schedulers** to avoid blocking API latency.

See [`CELERY_BACKGROUND_TASKS.md`](file:///c:/Optigo%20Works/optigoai/CELERY_BACKGROUND_TASKS.md) for full background task catalogs, token optimization guards, and cron schedules.

---

## 7. How to Test Connections & Integrations

```bash
# 1. Run full backend test suite (26 passing test suites)
docker compose exec api pytest tests/

# 2. Trigger on-demand GSC sync test via API
curl -X POST "http://localhost:8000/api/v1/integrations/google/search-console/sync?business_id=<BIZ_ID>" \
     -H "Authorization: Bearer <TOKEN>"

# 3. Trigger on-demand Website Audit test via API
curl -X POST "http://localhost:8000/api/v1/seo/website/audit?business_id=<BIZ_ID>" \
     -H "Authorization: Bearer <TOKEN>"

# 4. View Celery worker task execution logs
docker compose logs -f celery_worker
```

