# OptigoAI — Phase 6: Content Engine & Multi-Channel Social Post Studio

## 1. Overview
Phase 6 delivers the **Content Engine & Multi-Channel Social Media Studio** for OptigoAI. It leverages Google Gemini 2.0 Flash to synthesize high-converting, punchy marketing posts and updates tailored for small and medium businesses across Google Business Profile, Instagram, Facebook, and LinkedIn.

---

## 2. Key Architecture & Deliverables

### A. Data Models & Database Schema
- **`contents` PostgreSQL Table**:
  - `id` (UUID Primary Key)
  - `business_id` (Foreign Key to `businesses.id` with CASCADE delete)
  - `content_type` (`google_post`, `instagram`, `facebook`, `linkedin`, `twitter`, `advertisement`, `website`, `seo_article`, `review_reply`)
  - `title` (Headline / subject line)
  - `body` (Optimized post caption / content)
  - `tone` (Selected voice tone)
  - `target_audience`
  - `marketing_goal`
  - `hashtags` (Space-separated tags)
  - `call_to_action` (Action trigger)
  - `image_prompt` (Visual prompt for AI image generation)
  - `image_url` (Asset URL)
  - `status` (`draft`, `scheduled`, `approved`, `published`, `failed`)
  - `scheduled_at` (Timestamp with timezone)
  - `published_at` (Timestamp with timezone)
  - `generation_metadata` (JSON logs)
  - `campaign_id` (Optional link to marketing campaigns)

---

### B. Backend REST API Endpoints (`/api/v1/contents`)

| Method | Endpoint | Description | Auth Required |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/v1/contents/generate` | Synthesize multi-channel post variations & themes with Gemini AI | Bearer JWT |
| `POST` | `/api/v1/contents` | Create a new post, draft, or scheduled social update | Bearer JWT |
| `GET` | `/api/v1/contents` | List posts with channel (`content_type`) and `status` filters | Bearer JWT |
| `GET` | `/api/v1/contents/{id}` | Retrieve full details of a specific post | Bearer JWT |
| `PATCH` | `/api/v1/contents/{id}` | Update post copy, hashtags, status, or schedule time | Bearer JWT |
| `POST` | `/api/v1/contents/{id}/publish` | Instantly mark post as published with timestamp | Bearer JWT |
| `DELETE`| `/api/v1/contents/{id}` | Delete a post or draft | Bearer JWT |

---

### C. Automated Test Coverage
- `backend/tests/test_content_engine.py`:
  - Multi-channel post synthesis via AI service.
  - CRUD operations on posts and draft lifecycles.
  - Filtering by channel and status (`draft`, `scheduled`, `published`).
  - Patch updates and immediate publishing workflow.
  - Multi-tenant tenant isolation and token usage logging in `ai_request_logs`.
- **Result**: **12/12 backend tests passing (100%)**.

---

### D. Flutter Mobile UI (`ContentStudioScreen`)
- **Top View Switcher**:
  - `✨ AI Generator` vs `📅 Saved Posts & Schedule`.
- **AI Generator Experience**:
  - Channel selection chips (Google Business, Instagram, Facebook, LinkedIn).
  - Custom topic/offer input with tone selector (Engaging & Warm, Mouthwatering, Festive Special, Urgent, Professional).
  - Multi-channel results feed with individual channel styling, 1-tap Copy, Save Draft, and Schedule Post actions.
- **Saved Posts & Schedule Manager**:
  - Filter pills: `All Posts`, `Drafts`, `Scheduled`, `Published`.
  - Delete and 1-tap `Publish Now` controls.
- **Deep Integration**:
  - Directly accessible from Tab 2 (`Create`) in bottom navigation.
  - Directly accessible from Home Screen quick action (`Create Content`).

---

## 3. Verification & Compliance
- `flutter analyze`: **0 issues found**.
- `flutter test`: **All tests passed**.
- `pytest`: **12 passed in Docker container**.
