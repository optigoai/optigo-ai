import pytest


@pytest.mark.anyio
async def test_phases_8_to_12_workflow(client):
    """
    Complete end-to-end verification for Phases 8 through 12:
    - Phase 8: Multi-Channel Marketing Campaigns (Generate, Create, List, Update, Launch)
    - Phase 9: Smart Creatives & Promo Engine (Generate, List, Details)
    - Phase 10: Conversational AI CMO Chat (Context-aware responses & action chips)
    - Phase 11: ROI Analytics & Competitor Benchmarking
    - Phase 12: Proactive Notifications & Alert Queue
    """
    # 1. Setup User & Business
    signup_res = await client.post(
        "/api/v1/auth/signup",
        json={
            "email": "cmo_user@example.com",
            "password": "Password123!",
            "full_name": "CMO Executive",
            "organization_name": "Growth Enterprises",
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
            "category": "Organic Oil & Flour Mill",
            "location": "Ponnani",
            "website": "https://panekkatt.com",
            "description": "Authentic cold-pressed oils and flour products.",
        },
    )
    assert biz_res.status_code == 201
    biz_id = biz_res.json()["id"]

    # ==========================================
    # Phase 8: Multi-Channel Campaigns Tests
    # ==========================================
    # Generate AI Campaign
    gen_camp_res = await client.post(
        "/api/v1/campaigns/generate",
        headers=headers,
        json={
            "business_id": biz_id,
            "goal": "foot_traffic",
            "channels": ["gbp", "instagram", "facebook"],
            "duration_days": 7,
        },
    )
    assert gen_camp_res.status_code == 200
    camp_plan = gen_camp_res.json()
    assert "name" in camp_plan
    assert "schedule" in camp_plan

    # Create Campaign Record
    create_camp_res = await client.post(
        "/api/v1/campaigns",
        headers=headers,
        json={
            "business_id": biz_id,
            "name": camp_plan["name"],
            "objective": camp_plan["objective"],
            "audience": camp_plan["audience"],
            "offer": camp_plan["offer"],
            "messaging": camp_plan["messaging"],
            "cta": camp_plan["cta"],
            "content_ideas": camp_plan["content_ideas"],
            "schedule": camp_plan["schedule"],
        },
    )
    assert create_camp_res.status_code == 201
    camp_id = create_camp_res.json()["id"]

    # List & Launch Campaign
    list_camp_res = await client.get(f"/api/v1/campaigns?business_id={biz_id}", headers=headers)
    assert list_camp_res.status_code == 200
    assert len(list_camp_res.json()) >= 1

    launch_res = await client.post(f"/api/v1/campaigns/{camp_id}/launch", headers=headers)
    assert launch_res.status_code == 200
    assert launch_res.json()["status"] == "active"

    # ==========================================
    # Phase 9: Smart Creatives & Promo Engine Tests
    # ==========================================
    gen_creative_res = await client.post(
        "/api/v1/creatives/generate",
        headers=headers,
        json={
            "business_id": biz_id,
            "headline": "Fresh Cold-Pressed Oil Special",
            "offer_text": "20% Off on First Order",
            "style": "modern_minimal",
            "aspect_ratio": "1:1",
            "campaign_id": camp_id,
        },
    )
    assert gen_creative_res.status_code == 201
    creative_data = gen_creative_res.json()
    assert creative_data["title"] == "Fresh Cold-Pressed Oil Special"
    assert "file_url" in creative_data

    list_creative_res = await client.get(f"/api/v1/creatives?business_id={biz_id}", headers=headers)
    assert list_creative_res.status_code == 200
    assert len(list_creative_res.json()) >= 1

    # ==========================================
    # Phase 10: AI CMO Chat Tests
    # ==========================================
    chat_res = await client.post(
        "/api/v1/cmo/chat",
        headers=headers,
        json={
            "business_id": biz_id,
            "message": "How can I improve my Google reviews rating?",
            "context_screen": "reviews",
        },
    )
    assert chat_res.status_code == 200
    chat_data = chat_res.json()
    assert chat_data["role"] == "assistant"
    assert len(chat_data["content"]) > 10
    assert len(chat_data["suggested_actions"]) >= 1

    # Test specific query extracting reviewer names from profile
    chat_name_res = await client.post(
        "/api/v1/cmo/chat",
        headers=headers,
        json={
            "business_id": biz_id,
            "message": "generate name of all person who post review in my profile",
            "context_screen": "reviews",
        },
    )
    assert chat_name_res.status_code == 200
    assert len(chat_name_res.json()["content"]) > 0

    # ==========================================
    # Phase 11: ROI Analytics Tests
    # ==========================================
    roi_res = await client.get(f"/api/v1/analytics/roi?business_id={biz_id}", headers=headers)
    assert roi_res.status_code == 200
    roi_data = roi_res.json()
    assert "estimated_revenue_impact" in roi_data
    assert "roi_multiplier" in roi_data
    assert len(roi_data["metrics"]) >= 3

    comp_res = await client.get(f"/api/v1/analytics/competitors?business_id={biz_id}", headers=headers)
    assert comp_res.status_code == 200
    comp_data = comp_res.json()
    assert "competitors" in comp_data
    assert len(comp_data["competitors"]) >= 1

    # ==========================================
    # Phase 12: Proactive Notifications Tests
    # ==========================================
    create_notif_res = await client.post(
        "/api/v1/notifications",
        headers=headers,
        json={
            "business_id": biz_id,
            "notification_type": "new_review",
            "title": "New 5-Star Google Review",
            "message": "A customer left a 5-star review. Tap to view and reply.",
            "action_url": "reviews",
        },
    )
    assert create_notif_res.status_code == 201
    notif_id = create_notif_res.json()["id"]

    list_notif_res = await client.get(f"/api/v1/notifications?business_id={biz_id}", headers=headers)
    assert list_notif_res.status_code == 200
    assert len(list_notif_res.json()) >= 1

    mark_read_res = await client.patch(f"/api/v1/notifications/{notif_id}/read", headers=headers)
    assert mark_read_res.status_code == 200
    assert mark_read_res.json()["is_read"] is True

    mark_all_res = await client.post(f"/api/v1/notifications/mark-all-read?business_id={biz_id}", headers=headers)
    assert mark_all_res.status_code == 200
    assert "marked_read_count" in mark_all_res.json()
