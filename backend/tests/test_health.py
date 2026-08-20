# ==================================================
# OptigoAI Backend — Health Check Tests
# ==================================================

import pytest


@pytest.mark.anyio
async def test_health_check(client):
    """Test health check endpoint returns 200."""
    response = await client.get("/api/v1/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert data["app_name"] == "OptigoAI"
    assert data["version"] == "0.1.0"


@pytest.mark.anyio
async def test_health_check_returns_environment(client):
    """Test health check includes environment info."""
    response = await client.get("/api/v1/health")
    data = response.json()
    assert "environment" in data
