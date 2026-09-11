# ==================================================
# OptigoAI Backend — Comprehensive Lead Gen & Onboarding Tests
# ==================================================

import pytest
from app.models.user import User, UserRole
from app.core.security import hash_password, create_access_token
from tests.conftest import test_session_factory


@pytest.mark.anyio
async def test_places_search_endpoint(client):
    """Test Places autocomplete search endpoint."""
    res = await client.get("/api/v1/leads/places/search?query=Bakery")
    assert res.status_code == 200
    data = res.json()
    assert isinstance(data, list)
    assert len(data) >= 1
    assert "name" in data[0]
    assert "place_id" in data[0]


@pytest.mark.anyio
async def test_lead_generation_and_audit_flow(client):
    """End-to-end test of lead creation, dynamic audit, report viewing, plan selection, and sandbox checkout."""
    # 1. Lead creation from single-page onboarding
    create_payload = {
        "business_name": "Royal Cafe & Roastery",
        "place_id": "plc_royal_12345",
        "phone": "+919876543210",
        "country_code": "+91",
        "address": "MG Road, Bengaluru",
        "category": "Cafe & Coffee Shop",
        "rating": 4.2,
        "review_count": 35,
    }

    create_res = await client.post("/api/v1/leads", json=create_payload)
    assert create_res.status_code == 201
    lead_data = create_res.json()
    lead_id = lead_data["id"]
    assert lead_data["business_name"] == "Royal Cafe & Roastery"
    assert lead_data["status"] == "form_submitted"

    # 2. Trigger asynchronous profile audit analysis
    analyze_res = await client.post(f"/api/v1/leads/{lead_id}/analyze")
    assert analyze_res.status_code == 200
    report = analyze_res.json()
    assert "business" in report
    assert report["business"]["name"] == "Royal Cafe & Roastery"
    assert "audit_summary" in report
    assert "issues" in report
    assert len(report["issues"]) >= 2
    assert "competitors" in report
    assert len(report["competitors"]) >= 1
    assert "business_impact" in report
    assert "plans" in report
    assert len(report["plans"]) == 3

    # 3. Retrieve Lead by ID
    get_res = await client.get(f"/api/v1/leads/{lead_id}")
    assert get_res.status_code == 200
    assert get_res.json()["status"] == "report_ready"

    # 4. Mark report as viewed by lead
    viewed_res = await client.post(f"/api/v1/leads/{lead_id}/viewed")
    assert viewed_res.status_code == 200
    assert viewed_res.json()["stage"] == "report_viewed"

    # 5. Select plan
    plan_res = await client.post(
        f"/api/v1/leads/{lead_id}/select-plan",
        json={"plan_id": "growth", "duration": "monthly"},
    )
    assert plan_res.status_code == 200
    assert plan_res.json()["plan_id"] == "growth"

    # 6. Create payment order
    order_res = await client.post(
        f"/api/v1/leads/{lead_id}/create-order",
        json={"plan_id": "growth", "duration": "monthly"},
    )
    assert order_res.status_code == 200
    order_data = order_res.json()
    assert "order_id" in order_data
    assert order_data["amount"] > 0

    # 7. Verify sandbox payment and activate account
    verify_res = await client.post(
        f"/api/v1/leads/{lead_id}/verify-payment",
        json={
            "razorpay_order_id": order_data["order_id"],
            "razorpay_payment_id": "pay_test_sandbox_1234",
        },
    )
    assert verify_res.status_code == 200
    verify_data = verify_res.json()
    assert verify_data["success"] is True
    assert "access_token" in verify_data
    assert "business_id" in verify_data

    # 8. Verify lead record converted
    lead_final = await client.get(f"/api/v1/leads/{lead_id}")
    assert lead_final.status_code == 200
    assert lead_final.json()["payment_status"] == "paid"
    assert lead_final.json()["status"] == "converted"


@pytest.mark.anyio
async def test_admin_lead_management_endpoints(client):
    """Test admin lead funnel statistics, listing, updates, and notes."""
    # 1. Create a test lead
    create_payload = {
        "business_name": "Metro Dental Hospital",
        "phone": "+919876543299",
        "country_code": "+91",
        "category": "Dental Clinic",
        "rating": 3.9,
        "review_count": 18,
    }
    lead_res = await client.post("/api/v1/leads", json=create_payload)
    assert lead_res.status_code == 201
    lead_id = lead_res.json()["id"]

    # 2. Create an admin user token
    async with test_session_factory() as session:
        admin_user = User(
            email="leadadmin@optigoai.com",
            password_hash=hash_password("AdminPass123!"),
            full_name="Lead Manager Admin",
            role=UserRole.ADMIN,
            is_active=True,
        )
        session.add(admin_user)
        await session.commit()
        admin_id = admin_user.id

    admin_token = create_access_token(user_id=admin_id, role="admin")
    admin_headers = {"Authorization": f"Bearer {admin_token}"}

    # 3. Test Admin Leads Stats
    stats_res = await client.get("/api/v1/admin/leads/stats", headers=admin_headers)
    assert stats_res.status_code == 200
    stats = stats_res.json()
    assert stats["total_leads"] >= 1

    # 4. Test List Leads with filter
    list_res = await client.get("/api/v1/admin/leads", headers=admin_headers)
    assert list_res.status_code == 200
    leads_list = list_res.json()
    assert leads_list["total"] >= 1
    assert any(l["id"] == lead_id for l in leads_list["leads"])

    # 5. Test Get Lead Details
    detail_res = await client.get(f"/api/v1/admin/leads/{lead_id}", headers=admin_headers)
    assert detail_res.status_code == 200
    detail = detail_res.json()
    assert detail["business_name"] == "Metro Dental Hospital"

    # 6. Test Update Lead Status and Priority
    patch_res = await client.patch(
        f"/api/v1/admin/leads/{lead_id}",
        headers=admin_headers,
        json={"status": "stuck", "priority": "hot", "notes": "Customer requested demo call."},
    )
    assert patch_res.status_code == 200
    patched = patch_res.json()
    assert patched["status"] == "stuck"
    assert patched["priority"] == "hot"

    # 7. Test Add Admin Note
    note_res = await client.post(
        f"/api/v1/admin/leads/{lead_id}/notes",
        headers=admin_headers,
        json={"note": "Called owner, scheduled onboarding walkthrough for Thursday."},
    )
    assert note_res.status_code == 200
    noted = note_res.json()
    assert "scheduled onboarding walkthrough" in noted["notes"]
