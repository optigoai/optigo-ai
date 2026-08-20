import pytest


@pytest.mark.anyio
async def test_create_and_get_business(client):
    # 1. Signup user
    signup_res = await client.post(
        "/api/v1/auth/signup",
        json={
            "email": "bizowner@example.com",
            "password": "SecurePassword123!",
            "full_name": "Biz Owner",
            "organization_name": "Biz Org",
        },
    )
    token = signup_res.json()["tokens"]["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # 2. Create business
    biz_res = await client.post(
        "/api/v1/businesses",
        headers=headers,
        json={
            "name": "Dr. Smile Dental Clinic",
            "category": "Dentist",
            "location": "Indiranagar, Bangalore",
            "website": "https://drsmile.example.com",
            "phone": "+91 9876543210",
            "description": "Premium cosmetic and general dentistry",
        },
    )
    assert biz_res.status_code == 201
    biz_data = biz_res.json()
    biz_id = biz_data["id"]
    assert biz_data["name"] == "Dr. Smile Dental Clinic"
    assert biz_data["onboarding_completed"] is False

    # 3. List businesses
    list_res = await client.get("/api/v1/businesses", headers=headers)
    assert list_res.status_code == 200
    assert len(list_res.json()) >= 1

    # 4. Submit onboarding
    onboard_res = await client.post(
        f"/api/v1/businesses/{biz_id}/onboarding",
        headers=headers,
        json={
            "target_customers": "Families and working professionals in East Bangalore",
            "services": "Teeth whitening, Invisalign, root canal, dental implants",
            "business_goals": "Get 30 new high-value implant and cosmetic patients per month",
            "marketing_channels": "Google Search, Instagram, Referrals",
        },
    )
    assert onboard_res.status_code == 200
    updated_biz = onboard_res.json()
    assert updated_biz["onboarding_completed"] is True
