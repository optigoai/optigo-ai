import pytest
from app.models.user import User, UserRole
from app.core.security import hash_password, create_access_token


@pytest.mark.anyio
async def test_public_features_endpoint(client):
    """Test public active features endpoint returns valid dict."""
    res = await client.get("/api/v1/features/active")
    assert res.status_code == 200
    data = res.json()
    assert "ai_cmo_chat" in data
    assert "content_studio" in data
    assert data["ai_cmo_chat"] is True


@pytest.mark.anyio
async def test_admin_endpoints_require_admin_role(client):
    """Test non-admin users cannot access admin endpoints."""
    # 1. Signup normal user
    signup_res = await client.post(
        "/api/v1/auth/signup",
        json={
            "email": "normaluser@example.com",
            "password": "Password123!",
            "full_name": "Normal User",
            "organization_name": "Normal Org",
        },
    )
    assert signup_res.status_code == 201
    token = signup_res.json()["tokens"]["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # 2. Try to access admin stats
    stats_res = await client.get("/api/v1/admin/stats", headers=headers)
    assert stats_res.status_code == 403
    assert "Admin access required" in stats_res.json()["detail"]


@pytest.mark.anyio
async def test_admin_portal_workflow(client):
    """Full admin portal flow: stats, orgs, businesses, toggles, health."""
    # 1. Sign up a test business to populate data
    signup_res = await client.post(
        "/api/v1/auth/signup",
        json={
            "email": "bizowner@example.com",
            "password": "Password123!",
            "full_name": "Biz Owner",
            "organization_name": "Bakery Group",
        },
    )
    assert signup_res.status_code == 201
    user_token = signup_res.json()["tokens"]["access_token"]
    org_id = signup_res.json()["organization"]["id"]

    await client.post(
        "/api/v1/businesses",
        headers={"Authorization": f"Bearer {user_token}"},
        json={
            "name": "Artisan Bakery",
            "category": "Bakery / Cafe",
            "location": "Bengaluru",
        },
    )

    # 2. Create an admin user token directly
    from tests.conftest import test_session_factory
    async with test_session_factory() as session:
        admin_user = User(
            email="superadmin@optigoai.com",
            password_hash=hash_password("SuperSecretAdmin123!"),
            full_name="Super Admin",
            role=UserRole.ADMIN,
            is_active=True,
        )
        session.add(admin_user)
        await session.commit()
        admin_id = admin_user.id

    admin_token = create_access_token(user_id=admin_id, role="admin")
    admin_headers = {"Authorization": f"Bearer {admin_token}"}

    # 3. Test Admin Stats
    stats_res = await client.get("/api/v1/admin/stats", headers=admin_headers)
    assert stats_res.status_code == 200
    stats = stats_res.json()
    assert stats["total_organizations"] >= 1
    assert stats["total_businesses"] >= 1

    # 4. Test List Organizations
    orgs_res = await client.get("/api/v1/admin/organizations", headers=admin_headers)
    assert orgs_res.status_code == 200
    orgs = orgs_res.json()
    assert len(orgs) >= 1
    assert any(o["id"] == org_id for o in orgs)

    # 5. Test Toggle Organization Status (Suspend)
    suspend_res = await client.patch(
        f"/api/v1/admin/organizations/{org_id}/status",
        headers=admin_headers,
        json={"is_active": False},
    )
    assert suspend_res.status_code == 200
    assert suspend_res.json()["is_active"] is False

    # 6. Test List Businesses
    biz_res = await client.get("/api/v1/admin/businesses", headers=admin_headers)
    assert biz_res.status_code == 200
    biz_list = biz_res.json()
    assert any(b["name"] == "Artisan Bakery" for b in biz_list)

    # 7. Test Feature Toggles: List and Toggle
    features_res = await client.get("/api/v1/admin/features", headers=admin_headers)
    assert features_res.status_code == 200
    assert len(features_res.json()) >= 6

    # Turn OFF ai_cmo_chat
    toggle_res = await client.put(
        "/api/v1/admin/features/ai_cmo_chat",
        headers=admin_headers,
        json={"is_enabled": False, "description": "Disabled for maintenance"},
    )
    assert toggle_res.status_code == 200
    assert toggle_res.json()["is_enabled"] is False

    # Verify public features endpoint reflects the toggle
    pub_res = await client.get("/api/v1/features/active")
    assert pub_res.status_code == 200
    assert pub_res.json()["ai_cmo_chat"] is False

    # Turn it back ON
    await client.put(
        "/api/v1/admin/features/ai_cmo_chat",
        headers=admin_headers,
        json={"is_enabled": True},
    )
    pub_res2 = await client.get("/api/v1/features/active")
    assert pub_res2.json()["ai_cmo_chat"] is True

    # 8. Test Usage and System Health
    usage_res = await client.get("/api/v1/admin/usage", headers=admin_headers)
    assert usage_res.status_code == 200

    health_res = await client.get("/api/v1/admin/system-health", headers=admin_headers)
    assert health_res.status_code == 200
    assert "components" in health_res.json()
