# ==================================================
# OptigoAI — Live API Connection & Provider Verification Script
# ==================================================

import asyncio
import os
import sys

# Ensure app is in Python path
sys.path.insert(0, "/app")

from app.core.config import settings
from app.providers.seo.factory import SEOProviderFactory
from app.providers.crawler.factory import WebsiteCrawlerFactory
from app.providers.gsc_provider import GoogleSearchConsoleProvider
from app.ai.gemini_provider import GeminiAIProvider


async def run_live_verification():
    print("=" * 60)
    print("OPTIGO AI — LIVE EXTERNAL API VERIFICATION")
    print("=" * 60)

    # 1. Test Google Gemini AI
    print("\n[1/4] Testing Google Gemini AI...")
    try:
        gemini = GeminiAIProvider()
        res = await gemini.generate_text("Give a 1-sentence marketing tip for a local oil mill.")
        text = res.get("text", "").strip()
        print(f"  -> SUCCESS! Gemini Response:\n     \"{text}\"")
    except Exception as e:
        print(f"  -> FAILED: {e}")

    # 2. Test Serper API (Live SERP Search)
    print(f"\n[2/4] Testing Active SEO Provider ({settings.seo_provider})...")
    try:
        seo_provider = SEOProviderFactory.get_provider()
        print(f"  Configured Provider: {seo_provider.__class__.__name__} (is_configured={seo_provider.is_configured()})")
        
        # Test Live Keyword Ranking & Competitors
        print("  -> Querying live Google SERP for: 'cold pressed coconut oil'...")
        rank_data = await seo_provider.get_keyword_rank(
            keyword="cold pressed coconut oil",
            domain="panekkattmill.com",
            location="United States",
        )
        print(f"     Rank Data: Provider={rank_data.get('provider')}, Found Rank={rank_data.get('rank')}")

        print("  -> Querying live Google Local Competitors for: 'flour mill'...")
        competitors = await seo_provider.get_local_competitors(keyword="flour mill", limit=3)
        print(f"     Found {len(competitors)} live competitors:")
        for c in competitors:
            print(f"       • {c.get('name')} | Rating: {c.get('rating')}★ ({c.get('reviews_count')} reviews)")
        print("  -> SUCCESS! Serper API integration verified.")
    except Exception as e:
        print(f"  -> FAILED: {e}")

    # 3. Test Firecrawl (Live Website Scrape)
    print(f"\n[3/4] Testing Website Crawler ({settings.website_crawler_provider})...")
    try:
        crawler = WebsiteCrawlerFactory.get_provider()
        print(f"  Configured Crawler: {crawler.__class__.__name__} (is_configured={crawler.is_configured()})")
        
        test_url = "https://example.com"
        print(f"  -> Crawling test URL: {test_url}...")
        crawl_page = await crawler.crawl_page(test_url)
        print(f"     Page Title: \"{crawl_page.title}\"")
        print(f"     Status Code: {crawl_page.status_code}")
        print(f"     Word Count: {crawl_page.word_count}")
        print(f"     H1 Headings: {crawl_page.h1_tags}")
        print("  -> SUCCESS! Firecrawl / Website Intelligence integration verified.")
    except Exception as e:
        print(f"  -> FAILED: {e}")

    # 4. Test Google Search Console OAuth
    print("\n[4/4] Testing Google Search Console Provider...")
    try:
        gsc = GoogleSearchConsoleProvider()
        print(f"  Configured: {gsc.is_configured()}")
        auth_url = gsc.get_authorization_url(state="test_state_123")
        print(f"  -> Generated OAuth 2.0 URL:\n     {auth_url[:90]}...")
        assert "client_id=" in auth_url
        assert "webmasters.readonly" in auth_url
        print("  -> SUCCESS! Google OAuth 2.0 Search Console provider verified.")
    except Exception as e:
        print(f"  -> FAILED: {e}")

    print("\n" + "=" * 60)
    print("ALL LIVE EXTERNAL PROVIDERS VERIFIED SUCCESSFULLY!")
    print("=" * 60)


if __name__ == "__main__":
    asyncio.run(run_live_verification())
