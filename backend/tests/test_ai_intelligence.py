import pytest
from sqlalchemy import select
from app.models.ai_log import AIRequestLog
from app.core.database import get_async_session
from tests.conftest import override_get_db


@pytest.mark.anyio
async def test_ai_business_understanding_and_health_scoring(client):
    """
    Test Phase 4: AI Business Profile generation, Marketing Health Score calculation,
    and automatic AI Request Logging with token/cost tracking.
    """
    # 1. Signup & create business
    signup_res = await client.post(
        "/api/v1/auth/signup",
        json={
            "email": "aiuser@example.com",
            "password": "Password123!",
            "full_name": "AI User",
            "organization_name": "AI Dental Org",
        },
    )
    token = signup_res.json()["tokens"]["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    biz_res = await client.post(
        "/api/v1/businesses",
        headers=headers,
        json={
            "name": "Starlight Dental Spa",
            "category": "Dentist",
            "location": "Bangalore",
            "website": "https://starlight.example.com",
        },
    )
    biz_id = biz_res.json()["id"]

    # Submit onboarding
    await client.post(
        f"/api/v1/businesses/{biz_id}/onboarding",
        headers=headers,
        json={
            "target_customers": "Families and professionals seeking cosmetic dentistry",
            "services": "Invisalign, Teeth Whitening, Implants",
            "business_goals": "Increase monthly revenue by 20% and acquire 30 new patients",
            "marketing_channels": "Google Search, Instagram",
        },
    )

    # 2. Trigger AI Analysis
    analyze_res = await client.post(
        f"/api/v1/businesses/{biz_id}/analyze",
        headers=headers,
    )
    assert analyze_res.status_code == 200
    intel_data = analyze_res.json()
    assert intel_data["health_score"] is not None
    assert 0 <= intel_data["health_score"] <= 100
    assert "business_summary" in intel_data["ai_profile"]
    assert "top_problems" in intel_data["health_analysis"]
    assert "top_opportunities" in intel_data["health_analysis"]
    assert len(intel_data["health_analysis"]["top_problems"]) > 0
    assert len(intel_data["health_analysis"]["top_opportunities"]) > 0

    # 3. Retrieve stored intelligence
    get_res = await client.get(
        f"/api/v1/businesses/{biz_id}/intelligence",
        headers=headers,
    )
    assert get_res.status_code == 200
    stored_data = get_res.json()
    assert stored_data["health_score"] == intel_data["health_score"]
    assert stored_data["ai_profile"]["business_summary"] == intel_data["ai_profile"]["business_summary"]

    # 4. Verify AI request was logged in database for auditing
    async for db in override_get_db():
        logs_res = await db.execute(
            select(AIRequestLog).where(AIRequestLog.feature.like("business_%"))
        )
        logs = logs_res.scalars().all()
        assert len(logs) >= 2  # Profile generation + intelligence scoring
        for log in logs:
            assert log.success is True
            assert log.provider == "gemini"
            assert log.input_tokens > 0
            assert log.latency_ms >= 0
        break
