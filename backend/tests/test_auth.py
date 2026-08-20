import pytest


@pytest.mark.anyio
async def test_signup_success(client):
    """Test successful user and organization registration."""
    payload = {
        "email": "testowner@example.com",
        "password": "SecurePassword123!",
        "full_name": "Test Owner",
        "organization_name": "Acme Marketing",
    }
    response = await client.post("/api/v1/auth/signup", json=payload)
    assert response.status_code == 201
    data = response.json()
    assert data["user"]["email"] == "testowner@example.com"
    assert data["user"]["full_name"] == "Test Owner"
    assert data["user"]["role"] == "owner"
    assert data["organization"]["name"] == "Acme Marketing"
    assert data["tokens"]["access_token"] != ""
    assert data["tokens"]["refresh_token"] != ""


@pytest.mark.anyio
async def test_signup_duplicate_email(client):
    """Test signing up with an already-used email fails."""
    payload = {
        "email": "dup@example.com",
        "password": "SecurePassword123!",
        "full_name": "User One",
        "organization_name": "Org One",
    }
    r1 = await client.post("/api/v1/auth/signup", json=payload)
    assert r1.status_code == 201

    r2 = await client.post("/api/v1/auth/signup", json=payload)
    assert r2.status_code == 409
    assert "already exists" in r2.json()["detail"]


@pytest.mark.anyio
async def test_login_success_and_failure(client):
    """Test login with valid and invalid credentials."""
    # 1. Signup
    signup_payload = {
        "email": "loginuser@example.com",
        "password": "CorrectPassword123!",
        "full_name": "Login User",
        "organization_name": "Login Org",
    }
    await client.post("/api/v1/auth/signup", json=signup_payload)

    # 2. Login with correct password
    login_res = await client.post(
        "/api/v1/auth/login",
        json={"email": "loginuser@example.com", "password": "CorrectPassword123!"},
    )
    assert login_res.status_code == 200
    login_data = login_res.json()
    assert login_data["tokens"]["access_token"] != ""

    # 3. Login with wrong password
    bad_res = await client.post(
        "/api/v1/auth/login",
        json={"email": "loginuser@example.com", "password": "WrongPassword!"},
    )
    assert bad_res.status_code == 401


@pytest.mark.anyio
async def test_get_me_protected_route(client):
    """Test accessing protected route with and without bearer token."""
    # 1. Without token -> 403 or 401
    unauth_res = await client.get("/api/v1/auth/me")
    assert unauth_res.status_code in (401, 403)

    # 2. Signup and use token
    signup_payload = {
        "email": "meuser@example.com",
        "password": "Password123!",
        "full_name": "Me User",
        "organization_name": "Me Org",
    }
    r = await client.post("/api/v1/auth/signup", json=signup_payload)
    token = r.json()["tokens"]["access_token"]

    auth_res = await client.get(
        "/api/v1/auth/me",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert auth_res.status_code == 200
    assert auth_res.json()["user"]["email"] == "meuser@example.com"
