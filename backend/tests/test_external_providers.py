# ==================================================
# OptigoAI Backend — SEO & Crawler Providers Test Suite
# ==================================================

import pytest
from httpx import AsyncClient

from app.providers.seo.dataforseo import DataForSEOProvider
from app.providers.seo.serper import SerperProvider
from app.providers.seo.serpapi import SerpAPIProvider
from app.providers.seo.factory import SEOProviderFactory
from app.providers.crawler.beautifulsoup import BeautifulSoupCrawlerProvider
from app.providers.crawler.factory import WebsiteCrawlerFactory
from app.services.website_audit_service import WebsiteAuditService


@pytest.mark.anyio
async def test_seo_provider_factory_and_adapters():
    # Test DataForSEO
    dataforseo = DataForSEOProvider()
    res = await dataforseo.get_keyword_rank("cold pressed oil", "panekkattmill.com", "Ponnani")
    assert "rank" in res
    assert res["domain"] == "panekkattmill.com"

    metrics = await dataforseo.get_keyword_metrics(["cold pressed oil", "flour mill"])
    assert len(metrics) == 2
    assert "search_volume" in metrics[0]

    competitors = await dataforseo.get_local_competitors("oil mill", "Ponnani", limit=3)
    assert len(competitors) >= 1

    # Test Serper Adapter
    serper = SerperProvider()
    res_serper = await serper.get_keyword_rank("organic atta", "panekkattmill.com")
    assert "rank" in res_serper

    # Test SerpAPI Adapter
    serpapi = SerpAPIProvider()
    res_serpapi = await serpapi.get_keyword_rank("sesame oil", "panekkattmill.com")
    assert "rank" in res_serpapi

    # Test Factory Default
    factory_provider = SEOProviderFactory.get_provider()
    assert factory_provider is not None


@pytest.mark.anyio
async def test_crawler_provider_and_factory():
    crawler = BeautifulSoupCrawlerProvider()
    assert crawler.is_configured() is True

    # Test factory fallback
    factory_crawler = WebsiteCrawlerFactory.get_provider()
    assert factory_crawler is not None


@pytest.mark.anyio
async def test_website_audit_workflow(client: AsyncClient):
    # 1. Setup Auth
    signup_res = await client.post(
        "/api/v1/auth/signup",
        json={
            "email": "audit_user@example.com",
            "password": "Password123!",
            "full_name": "Audit Tester",
            "organization_name": "Audit Org",
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
            "name": "Panekkatt Heritage Mill",
            "category": "Organic Flour & Oil Mill",
            "location": "Ponnani, Kerala",
            "website": "https://panekkattmill.com",
        },
    )
    assert biz_res.status_code == 201
    biz_id = biz_res.json()["id"]

    # 3. Run Website Audit via Endpoint
    audit_res = await client.post(
        f"/api/v1/seo/website/audit?business_id={biz_id}",
        headers=headers,
    )
    assert audit_res.status_code == 200
    audit_data = audit_res.json()
    assert audit_data["business_id"] == biz_id
    assert "overall_score" in audit_data
    assert "findings" in audit_data
    assert len(audit_data["actionable_recommendations"]) >= 1

    # 4. Retrieve Latest Audit
    latest_res = await client.get(
        f"/api/v1/seo/website/audit/latest?business_id={biz_id}",
        headers=headers,
    )
    assert latest_res.status_code == 200
    assert latest_res.json()["id"] == audit_data["id"]
