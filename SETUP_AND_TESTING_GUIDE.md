# OptigoAI MVP — Setup & Testing Guide (Phases 1 – 3)

This guide walks you through starting the backend services, testing all APIs step-by-step, running the Flutter mobile app, viewing database records, and running the automated test suite.

---

## 📋 Quick Overview of Running Services

| Component | Technology | Default URL / Port | Purpose |
|---|---|---|---|
| **FastAPI Backend** | Python 3.11 | [http://localhost:8000](http://localhost:8000) | REST API Server |
| **Interactive API Docs** | Swagger UI | [http://localhost:8000/docs](http://localhost:8000/docs) | Test APIs in browser |
| **Alternative API Docs** | ReDoc | [http://localhost:8000/redoc](http://localhost:8000/redoc) | Clean API documentation |
| **PostgreSQL Database** | PostgreSQL 16 | `localhost:5432` | Relational Data Storage |
| **Redis Cache / Queue** | Redis 7 | `localhost:6379` | Message Queue & Cache |
| **Flutter Mobile App** | Flutter 3.29 | Android / iOS / Web | User Mobile Application |

---

## 🚀 Step 1: Start the Backend (Docker)

Make sure **Docker Desktop** is running, then open your terminal in `C:\Optigo Works\optigoai` and run:

```powershell
# 1. Start all backend services in the background
docker compose up -d

# 2. Check that all 5 containers are running and healthy
docker compose ps
```

You should see 5 active containers:
- `optigoai-api` (Up on port 8000)
- `optigoai-db` (healthy on port 5432)
- `optigoai-redis` (healthy on port 6379)
- `optigoai-celery-worker` (Up)
- `optigoai-celery-beat` (Up)

---

## 🌐 Step 2: Test APIs Using Swagger UI (Easiest Method)

Open your browser and navigate to:
👉 **[http://localhost:8000/docs](http://localhost:8000/docs)**

This interactive Swagger UI lets you test every endpoint without writing code!

---

## 🧪 Step 3: Complete Step-by-Step API Testing Flow

Here is the exact sequence to test the entire customer journey via API:

### 1️⃣ Health Check
* **Method**: `GET`
* **URL**: `http://localhost:8000/api/v1/health`
* **PowerShell command**:
  ```powershell
  Invoke-RestMethod -Uri "http://localhost:8000/api/v1/health" | ConvertTo-Json
  ```
* **Expected Response (`200 OK`)**:
  ```json
  {
    "status": "ok",
    "app_name": "OptigoAI",
    "version": "0.1.0",
    "environment": "development"
  }
  ```

---

### 2️⃣ Sign Up (Create Organization & User)
* **Method**: `POST`
* **URL**: `http://localhost:8000/api/v1/auth/signup`
* **PowerShell command**:
  ```powershell
  $signupBody = @{
    email = "doctor@blossomclinic.com"
    password = "SecurePassword123!"
    full_name = "Dr. Priya Sharma"
    organization_name = "Blossom Healthcare Group"
  } | ConvertTo-Json

  $signupRes = Invoke-RestMethod -Uri "http://localhost:8000/api/v1/auth/signup" -Method Post -Body $signupBody -ContentType "application/json"
  $token = $signupRes.tokens.access_token
  Write-Output "Access Token: $token"
  ```
* **Expected Response (`201 Created`)**:
  Returns the new user profile, created organization details, and JWT access + refresh tokens.

---

### 3️⃣ Log In
* **Method**: `POST`
* **URL**: `http://localhost:8000/api/v1/auth/login`
* **PowerShell command**:
  ```powershell
  $loginBody = @{
    email = "doctor@blossomclinic.com"
    password = "SecurePassword123!"
  } | ConvertTo-Json

  $loginRes = Invoke-RestMethod -Uri "http://localhost:8000/api/v1/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
  $token = $loginRes.tokens.access_token
  ```

---

### 4️⃣ Verify Authenticated Profile (`/me`)
* **Method**: `GET`
* **URL**: `http://localhost:8000/api/v1/auth/me`
* **PowerShell command**:
  ```powershell
  $headers = @{ Authorization = "Bearer $token" }
  Invoke-RestMethod -Uri "http://localhost:8000/api/v1/auth/me" -Headers $headers | ConvertTo-Json
  ```

---

### 5️⃣ Create a Business
* **Method**: `POST`
* **URL**: `http://localhost:8000/api/v1/businesses`
* **PowerShell command**:
  ```powershell
  $bizBody = @{
    name = "Blossom Dental & Aesthetic Clinic"
    category = "Dental Clinic"
    location = "Indiranagar, Bangalore"
    website = "https://blossomdental.in"
    phone = "+91 9876543210"
    description = "Specialized cosmetic dentistry and dental implants"
  } | ConvertTo-Json

  $bizRes = Invoke-RestMethod -Uri "http://localhost:8000/api/v1/businesses" -Method Post -Headers $headers -Body $bizBody -ContentType "application/json"
  $bizId = $bizRes.id
  Write-Output "Created Business ID: $bizId"
  ```

---

### 6️⃣ Submit Business Onboarding
* **Method**: `POST`
* **URL**: `http://localhost:8000/api/v1/businesses/{business_id}/onboarding`
* **PowerShell command**:
  ```powershell
  $onboardingBody = @{
    target_customers = "Families and working professionals aged 25-50 seeking premium dental care"
    services = "Teeth Whitening, Dental Implants, Invisalign, Root Canal Treatments"
    business_goals = "Get 25 new high-value cosmetic patients per month and boost 5-star Google reviews"
    marketing_channels = "Google Search, Instagram, Local Word-of-Mouth"
  } | ConvertTo-Json

  Invoke-RestMethod -Uri "http://localhost:8000/api/v1/businesses/$bizId/onboarding" -Method Post -Headers $headers -Body $onboardingBody -ContentType "application/json" | ConvertTo-Json
  ```

---

### 7️⃣ Synchronize Google Business Profile Data (`MockGBPProvider`)
* **Method**: `POST`
* **URL**: `http://localhost:8000/api/v1/businesses/{business_id}/sync-gbp`
* **PowerShell command**:
  ```powershell
  $syncRes = Invoke-RestMethod -Uri "http://localhost:8000/api/v1/businesses/$bizId/sync-gbp" -Method Post -Headers $headers
  $syncRes | ConvertTo-Json
  ```
* **What happens**:
  - Pulls realistic business profile, reviews, and 30-day performance metrics through the `MockGBPProvider`.
  - Ingests positive, neutral, and negative customer reviews into PostgreSQL.
  - Computes rating summary and profile analytics.

---

### 8️⃣ List Reviews & Filter by Sentiment
* **List All Reviews**:
  ```powershell
  Invoke-RestMethod -Uri "http://localhost:8000/api/v1/reviews?business_id=$bizId" -Headers $headers | ConvertTo-Json
  ```
* **Filter Negative Reviews Only**:
  ```powershell
  $negReviews = Invoke-RestMethod -Uri "http://localhost:8000/api/v1/reviews?business_id=$bizId&sentiment=negative" -Headers $headers
  $negReviews | ConvertTo-Json
  ```

---

### 9️⃣ Reply to a Customer Review
* **Method**: `POST`
* **URL**: `http://localhost:8000/api/v1/reviews/{review_id}/reply?business_id={business_id}`
* **PowerShell command**:
  ```powershell
  $targetReviewId = $negReviews[0].id
  $replyBody = @{
    reply_text = "Dear Anita, thank you for your feedback. We sincerely apologize for the wait time and have adjusted our scheduling system to ensure on-time appointments."
  } | ConvertTo-Json

  Invoke-RestMethod -Uri "http://localhost:8000/api/v1/reviews/$targetReviewId/reply?business_id=$bizId" -Method Post -Headers $headers -Body $replyBody -ContentType "application/json" | ConvertTo-Json
  ```

---

## 📱 Step 4: Running the Flutter Mobile App

The mobile application is built with responsive layout and light-blue SaaS theme.

### Run on Physical Android Phone (e.g. Motorola Edge 50 Pro):
Your computer's Wi-Fi IP is **`10.51.25.138`**.

1. **Ensure Phone and Computer are on the same Wi-Fi network**.
2. **Android Permissions**: `android.permission.INTERNET` and `usesCleartextTraffic="true"` have been configured.
3. **Run the App**:
   ```powershell
   flutter run -d ZD222L867X
   ```

💡 **Alternative (USB Cable ADB Reverse)**:
If you are connected via USB cable, you can forward phone traffic directly over USB by running:
```powershell
adb reverse tcp:8000 tcp:8000
```
This routes all requests on port 8000 directly through the USB cable without needing Wi-Fi!

### What You Can Do in the App:
1. **Sign Up**: Enter your name, organization name, email, and password.
2. **Onboarding Wizard**: Fill in the 3-step business onboarding form.
3. **Home Screen**: View your connected business profile, organization status, and trigger logout.

---

## 🗄️ Step 5: Inspect Data in PostgreSQL Directly

You can view the actual tables and data stored in PostgreSQL inside the Docker container:

```powershell
# Open PostgreSQL interactive terminal
docker compose exec db psql -U optigoai -d optigoai

# List all tables:
\dt

# View registered users:
SELECT id, email, full_name, role, organization_id FROM users;

# View organizations:
SELECT * FROM organizations;

# View businesses:
SELECT id, name, category, location, onboarding_completed FROM businesses;

# View synced reviews:
SELECT reviewer_name, rating, sentiment, is_replied, LEFT(text, 50) AS review_snippet FROM reviews;

# Exit PostgreSQL prompt:
\q
```

---

## 🧪 Step 6: Run Automated Tests

To verify that all backend and mobile test suites are healthy:

### Run Backend Tests (Pytest in Docker):
```powershell
docker compose exec api pytest -v
```
*Expected: **9 passed in ~7 seconds** (including strict multi-tenant isolation tests).*

### Run Mobile Tests (Flutter):
```powershell
cd "C:\Optigo Works\optigoai\mobile"
flutter test
```
*Expected: **All tests passed**.*

---

## 🛑 Step 7: Stopping & Managing Services

```powershell
# Stop all containers (preserves your database data)
docker compose stop

# Restart containers
docker compose start

# Stop and remove containers (data remains safe in named volumes)
docker compose down

# View real-time logs of the API
docker compose logs -f api
```
