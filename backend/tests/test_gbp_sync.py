import pytest


@pytest.mark.anyio
async def test_gbp_sync_and_reviews_workflow(client):
    """
    Test Phase 3: Synchronizing GBP data via MockGBPProvider into PostgreSQL,
    and querying reviews with filters.
    """
    # 1. Signup and create business
    signup_res = await client.post(
        "/api/v1/auth/signup",
        json={
            "email": "gbpuser@example.com",
            "password": "Password123!",
            "full_name": "GBP User",
            "organization_name": "GBP Dental Group",
        },
    )
    token = signup_res.json()["tokens"]["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    biz_res = await client.post(
        "/api/v1/businesses",
        headers=headers,
        json={
            "name": "Apex Dental Center",
            "category": "Dentist",
            "location": "Bangalore",
        },
    )
    biz_id = biz_res.json()["id"]

    # 2. Trigger GBP sync
    sync_res = await client.post(
        f"/api/v1/businesses/{biz_id}/sync-gbp",
        headers=headers,
    )
    assert sync_res.status_code == 200
    sync_data = sync_res.json()
    assert sync_data["reviews_synced"] > 0
    assert sync_data["total_reviews"] > 0
    assert sync_data["average_rating"] > 0
    assert "profile_views" in sync_data["metrics"]

    # 3. List all synced reviews
    reviews_res = await client.get(
        f"/api/v1/reviews?business_id={biz_id}",
        headers=headers,
    )
    assert reviews_res.status_code == 200
    reviews = reviews_res.json()
    assert len(reviews) == sync_data["total_reviews"]

    # 4. Filter reviews by sentiment (negative)
    neg_res = await client.get(
        f"/api/v1/reviews?business_id={biz_id}&sentiment=negative",
        headers=headers,
    )
    assert neg_res.status_code == 200
    neg_reviews = neg_res.json()
    assert len(neg_reviews) >= 1
    assert all(r["sentiment"] == "negative" for r in neg_reviews)

    # 5. Reply to a negative review
    target_review = neg_reviews[0]
    reply_res = await client.post(
        f"/api/v1/reviews/{target_review['id']}/reply?business_id={biz_id}",
        headers=headers,
        json={"reply_text": "Thank you for the feedback. We apologize for the wait and have addressed this with our staff."},
    )
    assert reply_res.status_code == 200
    reply_data = reply_res.json()
    assert reply_data["is_replied"] is True
    assert "addressed this" in reply_data["reply_text"]
