import pytest
from sqlalchemy import select
from app.models.ai_log import AIRequestLog
from tests.conftest import override_get_db


@pytest.mark.anyio
async def test_cmo_recommendations_workflow(client):
    """
    Test Phase 5: AI CMO Recommendation Engine:
    - Synthesizes prioritized action cards (urgent, important, opportunity)
    - Persists recommendations to PostgreSQL
    - Allows querying with priority filtering
    - Allows status transition (complete, dismiss)
    - Automatically records AI request logs with token/cost tracking
    """
    # 1. Signup & create business
    signup_res = await client.post(
        "/api/v1/auth/signup",
        json={
            "email": "cmo_owner@example.com",
            "password": "Password123!",
            "full_name": "CMO Owner",
            "organization_name": "CMO Retail Co",
        },
    )
    token = signup_res.json()["tokens"]["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    biz_res = await client.post(
        "/api/v1/businesses",
        headers=headers,
        json={
            "name": "Artisan Coffee Roasters",
            "category": "Coffee Shop",
            "location": "Downtown",
            "website": "https://artisancoffee.example.com",
        },
    )
    biz_id = biz_res.json()["id"]

    # Onboarding
    await client.post(
        f"/api/v1/businesses/{biz_id}/onboarding",
        headers=headers,
        json={
            "target_customers": "Local coffee connoisseurs, students, and remote workers",
            "services": "Single-origin espresso, Cold brew subscriptions, Pastries",
            "business_goals": "Increase morning foot traffic and grow monthly subscriptions",
            "marketing_channels": "Google Business, Instagram",
        },
    )

    # 2. Sync GBP data & run AI audit to establish baseline
    await client.post(f"/api/v1/businesses/{biz_id}/sync-gbp", headers=headers)
    await client.post(f"/api/v1/businesses/{biz_id}/analyze", headers=headers)

    # 3. Trigger AI CMO Engine recommendations generation
    gen_res = await client.post(
        f"/api/v1/recommendations/generate?business_id={biz_id}",
        headers=headers,
    )
    assert gen_res.status_code == 200
    gen_data = gen_res.json()
    assert "recommendations" in gen_data
    assert "cmo_note" in gen_data
    recs = gen_data["recommendations"]
    assert len(recs) >= 3

    # Check structure of action cards
    first_rec = recs[0]
    assert "title" in first_rec
    assert "explanation" in first_rec
    assert "priority" in first_rec
    assert "impact" in first_rec
    assert "effort" in first_rec
    assert "suggested_action" in first_rec
    assert first_rec["status"] == "pending"

    rec_id = first_rec["id"]

    # 4. List recommendations via GET
    list_res = await client.get(
        f"/api/v1/recommendations?business_id={biz_id}",
        headers=headers,
    )
    assert list_res.status_code == 200
    listed_recs = list_res.json()
    assert len(listed_recs) == len(recs)

    # 5. Filter by priority
    urgent_res = await client.get(
        f"/api/v1/recommendations?business_id={biz_id}&priority=urgent",
        headers=headers,
    )
    assert urgent_res.status_code == 200
    for u in urgent_res.json():
        assert u["priority"] == "urgent"

    # 6. Execute / update recommendation status to COMPLETED
    patch_res = await client.patch(
        f"/api/v1/recommendations/{rec_id}/status?business_id={biz_id}",
        headers=headers,
        json={"status": "completed"},
    )
    assert patch_res.status_code == 200
    assert patch_res.json()["status"] == "completed"

    # 7. Dismiss second recommendation
    if len(recs) > 1:
        second_id = recs[1]["id"]
        dismiss_res = await client.patch(
            f"/api/v1/recommendations/{second_id}/status?business_id={biz_id}",
            headers=headers,
            json={"status": "dismissed"},
        )
        assert dismiss_res.status_code == 200
        assert dismiss_res.json()["status"] == "dismissed"

        # By default, list without dismissed
        active_list_res = await client.get(
            f"/api/v1/recommendations?business_id={biz_id}",
            headers=headers,
        )
        active_ids = [r["id"] for r in active_list_res.json()]
        assert second_id not in active_ids

    # 8. Verify AI request log in database
    async for db in override_get_db():
        logs_res = await db.execute(
            select(AIRequestLog).where(
                AIRequestLog.feature == "cmo_recommendations_generation"
            )
        )
        logs = logs_res.scalars().all()
        assert len(logs) >= 1
        log = logs[0]
        assert log.success is True
        assert log.provider == "gemini"
        assert log.input_tokens > 0
        assert log.latency_ms >= 0
        break
