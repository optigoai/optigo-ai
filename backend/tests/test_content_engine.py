import pytest
from sqlalchemy import select
from app.models.ai_log import AIRequestLog
from tests.conftest import override_get_db


@pytest.mark.anyio
async def test_content_engine_workflow(client):
    """
    Test Phase 6: Content Engine & Multi-Channel Social Post Generation:
    - Multi-channel post generation (Google Business, Instagram, Facebook, LinkedIn)
    - Saving drafts & scheduling posts
    - Updating, querying, and filtering posts by channel and status
    - Immediate publishing lifecycle
    - AI Request logging verification
    """
    # 1. Signup & create business
    signup_res = await client.post(
        "/api/v1/auth/signup",
        json={
            "email": "content_creator@example.com",
            "password": "Password123!",
            "full_name": "Content Creator",
            "organization_name": "Content Co",
        },
    )
    assert signup_res.status_code == 201
    token = signup_res.json()["tokens"]["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    biz_res = await client.post(
        "/api/v1/businesses",
        headers=headers,
        json={
            "name": "Spice Route Kitchen",
            "category": "Restaurant & Catering",
            "location": "Fort Kochi",
            "website": "https://spiceroute.example.com",
        },
    )
    assert biz_res.status_code == 201
    biz_id = biz_res.json()["id"]

    # 2. Test AI Content Generation endpoint
    gen_res = await client.post(
        "/api/v1/contents/generate",
        headers=headers,
        json={
            "business_id": biz_id,
            "channels": ["google_post", "instagram", "facebook", "linkedin"],
            "topic": "Weekend Kerala Seafood Feast with 20% off",
            "tone": "warm & mouthwatering",
            "goal": "drive table reservations for Saturday dinner",
            "offer_details": "Use promo code FEAST20 for 20% off all seafood platters.",
        },
    )
    assert gen_res.status_code == 200
    gen_data = gen_res.json()
    assert "campaign_theme" in gen_data
    assert len(gen_data["posts"]) >= 1

    # Check channels generated
    channels_generated = [p["channel"] for p in gen_data["posts"]]
    assert "google_post" in channels_generated or "instagram" in channels_generated

    # 3. Test Create & Schedule Post
    post_res = await client.post(
        "/api/v1/contents",
        headers=headers,
        json={
            "business_id": biz_id,
            "content_type": "google_post",
            "title": "Weekend Seafood Feast",
            "body": "Join us this Saturday for fresh catch from Fort Kochi! Reserve your table today.",
            "tone": "mouthwatering",
            "call_to_action": "Book a table online or call 9876543210",
            "status": "scheduled",
            "scheduled_at": "2026-08-25T11:00:00Z",
        },
    )
    assert post_res.status_code == 201
    post_id = post_res.json()["id"]
    assert post_res.json()["status"] == "scheduled"
    assert post_res.json()["content_type"] == "google_post"

    # 4. Test List Posts with filtering
    list_res = await client.get(
        f"/api/v1/contents?business_id={biz_id}&status=scheduled",
        headers=headers,
    )
    assert list_res.status_code == 200
    posts = list_res.json()
    assert len(posts) >= 1
    assert any(p["id"] == post_id for p in posts)

    # 5. Test Update Post
    patch_res = await client.patch(
        f"/api/v1/contents/{post_id}?business_id={biz_id}",
        headers=headers,
        json={
            "title": "Updated: Weekend Seafood Feast 20% OFF",
            "hashtags": "#KochiFood #KeralaSeafood #FortKochi",
        },
    )
    assert patch_res.status_code == 200
    assert "20% OFF" in patch_res.json()["title"]
    assert "#KochiFood" in patch_res.json()["hashtags"]

    # 6. Test Publish Post
    pub_res = await client.post(
        f"/api/v1/contents/{post_id}/publish?business_id={biz_id}",
        headers=headers,
    )
    assert pub_res.status_code == 200
    assert pub_res.json()["status"] == "published"
    assert pub_res.json()["published_at"] is not None

    # 7. Test Delete Post
    del_res = await client.delete(
        f"/api/v1/contents/{post_id}?business_id={biz_id}",
        headers=headers,
    )
    assert del_res.status_code == 204

    # 8. Verify AI request log was saved
    async for db in override_get_db():
        log_res = await db.execute(
            select(AIRequestLog).where(AIRequestLog.feature == "content_generation_multi_channel")
        )
        logs = log_res.scalars().all()
        assert len(logs) >= 1
        break
