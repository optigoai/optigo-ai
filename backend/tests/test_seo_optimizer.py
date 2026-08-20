import pytest
from sqlalchemy import select
from app.models.ai_log import AIRequestLog
from tests.conftest import override_get_db


@pytest.mark.anyio
async def test_seo_optimizer_workflow(client):
    """
    Test Phase 7: Local SEO & Visibility Optimizer Workflow:
    - AI-Powered SEO & Map Pack Visibility Audit
    - Listing, adding, and deleting tracked local keywords
    - Keyword discovery with Gemini AI
    - Google Business Profile (GBP) profile attribute optimization
    - AI Request logging verification
    """
    # 1. Signup & create business
    signup_res = await client.post(
        "/api/v1/auth/signup",
        json={
            "email": "seo_master@example.com",
            "password": "Password123!",
            "full_name": "SEO Specialist",
            "organization_name": "SEO Agency",
        },
    )
    assert signup_res.status_code == 201
    token = signup_res.json()["tokens"]["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    biz_res = await client.post(
        "/api/v1/businesses",
        headers=headers,
        json={
            "name": "Panekkatt Oil & Flour Mill",
            "category": "Organic Oil Mill & Flour Store",
            "location": "Ponnani, Malappuram",
            "website": "https://panekkatt.example.com",
            "description": "Authentic cold pressed coconut oil and freshly milled organic flours in Ponnani.",
        },
    )
    assert biz_res.status_code == 201
    biz_id = biz_res.json()["id"]

    # 2. Test Listing Tracked Keywords (seeds defaults)
    kw_list_res = await client.get(
        f"/api/v1/seo/keywords?business_id={biz_id}",
        headers=headers,
    )
    assert kw_list_res.status_code == 200
    keywords = kw_list_res.json()
    assert len(keywords) >= 1
    assert "current_rank" in keywords[0]

    # 3. Test Adding a Custom Tracked Keyword
    add_kw_res = await client.post(
        f"/api/v1/seo/keywords?business_id={biz_id}",
        headers=headers,
        json={
            "keyword": "pure coconut oil ponnani",
            "search_volume": "1.5K / mo",
            "difficulty": "Low",
            "intent": "Local Intent",
            "current_rank": 2,
        },
    )
    assert add_kw_res.status_code == 201
    added_kw = add_kw_res.json()
    assert added_kw["keyword"] == "pure coconut oil ponnani"
    assert added_kw["current_rank"] == 2
    kw_id = added_kw["id"]

    # 4. Test Deleting Tracked Keyword
    del_res = await client.delete(
        f"/api/v1/seo/keywords/{kw_id}?business_id={biz_id}",
        headers=headers,
    )
    assert del_res.status_code == 204

    # 5. Test AI SEO & Map Pack Audit Endpoint
    audit_res = await client.post(
        f"/api/v1/seo/audit?business_id={biz_id}&force_fresh=true",
        headers=headers,
    )
    assert audit_res.status_code == 200
    audit_data = audit_res.json()
    assert "overall_seo_score" in audit_data
    assert "map_pack_score" in audit_data
    assert "keyword_score" in audit_data
    assert "citation_score" in audit_data
    assert isinstance(audit_data["missing_attributes"], list)
    assert isinstance(audit_data["actionable_recommendations"], list)

    # 6. Test AI Keyword Discovery Endpoint
    disc_res = await client.post(
        f"/api/v1/seo/discover-keywords?business_id={biz_id}",
        headers=headers,
        json={
            "target_services": ["cold pressed coconut oil", "organic wheat flour", "sesame oil"],
        },
    )
    assert disc_res.status_code == 200
    discovered = disc_res.json()
    assert isinstance(discovered, list)
    assert len(discovered) >= 1
    assert "keyword" in discovered[0]

    # 7. Test AI GBP Profile Optimization Endpoint
    opt_res = await client.post(
        f"/api/v1/seo/optimize-profile?business_id={biz_id}",
        headers=headers,
    )
    assert opt_res.status_code == 200
    opt_data = opt_res.json()
    assert "optimized_title" in opt_data
    assert "optimized_description" in opt_data
    assert "primary_category" in opt_data

    # 8. Verify AI Logs in Database
    async for db in override_get_db():
        result = await db.execute(
            select(AIRequestLog).where(AIRequestLog.feature == "seo_local_audit")
        )
        log = result.scalars().first()
        assert log is not None
        assert log.success is True
        assert log.model in ["gemini-3.5-flash-lite", "gemini-2.0-flash", "mock-gemini"]
        break
