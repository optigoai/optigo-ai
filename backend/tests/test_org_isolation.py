import pytest


@pytest.mark.anyio
async def test_cross_organization_access_forbidden(client):
    """
    CRITICAL MULTI-TENANT TEST:
    Verify that Organization A cannot access or modify Organization B's businesses.
    """
    # 1. Register User A in Organization A
    res_a = await client.post(
        "/api/v1/auth/signup",
        json={
            "email": "owner_a@company-a.com",
            "password": "Password123!",
            "full_name": "Owner A",
            "organization_name": "Company A",
        },
    )
    token_a = res_a.json()["tokens"]["access_token"]
    headers_a = {"Authorization": f"Bearer {token_a}"}

    # 2. Register User B in Organization B
    res_b = await client.post(
        "/api/v1/auth/signup",
        json={
            "email": "owner_b@company-b.com",
            "password": "Password123!",
            "full_name": "Owner B",
            "organization_name": "Company B",
        },
    )
    token_b = res_b.json()["tokens"]["access_token"]
    headers_b = {"Authorization": f"Bearer {token_b}"}

    # 3. User A creates a business in Org A
    biz_a_res = await client.post(
        "/api/v1/businesses",
        headers=headers_a,
        json={
            "name": "Org A Confidential Business",
            "category": "Healthcare",
            "location": "Mumbai",
        },
    )
    assert biz_a_res.status_code == 201
    biz_a_id = biz_a_res.json()["id"]

    # 4. User B attempts to access Org A's business -> MUST be 404 (or 403)
    unauthorized_get = await client.get(
        f"/api/v1/businesses/{biz_a_id}",
        headers=headers_b,
    )
    assert unauthorized_get.status_code == 404
    assert "not found or you do not have permission" in unauthorized_get.json()["detail"]

    # 5. User B attempts to update onboarding for Org A's business -> MUST be 404
    unauthorized_update = await client.post(
        f"/api/v1/businesses/{biz_a_id}/onboarding",
        headers=headers_b,
        json={"target_customers": "Hacked Data"},
    )
    assert unauthorized_update.status_code == 404

    # 6. User B listing businesses only sees their own businesses
    list_b = await client.get("/api/v1/businesses", headers=headers_b)
    assert list_b.status_code == 200
    biz_ids_for_b = [b["id"] for b in list_b.json()]
    assert biz_a_id not in biz_ids_for_b
