# ==================================================
# OptigoAI Backend — Google Search Console Test Suite
# ==================================================

import pytest
from httpx import AsyncClient


@pytest.mark.anyio
async def test_google_search_console_lifecycle(client: AsyncClient):
    # 1. Setup Auth
    signup_res = await client.post(
        "/api/v1/auth/signup",
        json={
            "email": "gsc_user@example.com",
            "password": "Password123!",
            "full_name": "GSC Executive",
            "organization_name": "GSC Enterprise",
        },
    )
    assert signup_res.status_code == 201
    token = signup_res.json()["tokens"]["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # 2. Create Business
    biz_res = await client.post(
        "/api/v1/businesses",
        headers=headers,
        json={
            "name": "Panekkatt Oil Mill",
            "category": "Flour and Oil Mill",
            "location": "Ponnani, Kerala",
            "website": "https://panekkattmill.com",
        },
    )
    assert biz_res.status_code == 201
    biz_id = biz_res.json()["id"]

    # 3. Check Initial Disconnected Status
    status_res = await client.get(
        f"/api/v1/integrations/google/search-console/status?business_id={biz_id}",
        headers=headers,
    )
    assert status_res.status_code == 200
    assert status_res.json()["is_connected"] is False

    # 4. Request OAuth Auth URL
    auth_url_res = await client.get(
        f"/api/v1/integrations/google/search-console/auth-url?business_id={biz_id}",
        headers=headers,
    )
    assert auth_url_res.status_code == 200
    assert "accounts.google.com" in auth_url_res.json()["auth_url"]
    assert "state" in auth_url_res.json()

    # 5. Handle OAuth Callback
    callback_res = await client.post(
        "/api/v1/integrations/google/search-console/callback",
        headers=headers,
        json={
            "code": "4/0AWtgzhTestCode12345",
            "business_id": biz_id,
        },
    )
    assert callback_res.status_code == 200
    assert callback_res.json()["is_connected"] is True

    # 6. Verify Connected Status & Freshness
    status_res_after = await client.get(
        f"/api/v1/integrations/google/search-console/status?business_id={biz_id}",
        headers=headers,
    )
    assert status_res_after.status_code == 200
    assert status_res_after.json()["is_connected"] is True
    assert "Updated" in status_res_after.json()["freshness_label"]

    # 7. Fetch Performance Metrics Summary
    metrics_res = await client.get(
        f"/api/v1/integrations/google/search-console/metrics?business_id={biz_id}",
        headers=headers,
    )
    assert metrics_res.status_code == 200
    metrics_data = metrics_res.json()
    assert metrics_data["is_connected"] is True
    assert metrics_data["total_clicks"] > 0
    assert len(metrics_data["top_queries"]) >= 1
    assert "actionable_insight" in metrics_data

    # 8. Disconnect Integration
    disconnect_res = await client.delete(
        f"/api/v1/integrations/google/search-console?business_id={biz_id}",
        headers=headers,
    )
    assert disconnect_res.status_code == 204

    # 9. Verify Disconnected Status
    final_status = await client.get(
        f"/api/v1/integrations/google/search-console/status?business_id={biz_id}",
        headers=headers,
    )
    assert final_status.json()["is_connected"] is False
