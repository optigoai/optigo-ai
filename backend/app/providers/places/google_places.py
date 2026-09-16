# ==================================================
# OptigoAI Backend — Google Places API (New) Provider
# ==================================================
"""
Provider adapter for official Google Places API (New).
Supports:
- Text Search (places:searchText) for high-accuracy place discovery & autocomplete
- Place Details (places/{placeId}) for deep business attributes:
  opening hours, operational status, editorial summary, ratings, reviews, photos
- High-resolution photo media URL generation and proxying
"""

import time
from typing import Dict, Any, List, Optional
import httpx

from app.core.config import settings
from app.core.logging import get_logger
from app.schemas.lead import LeadPlacesSearchResult

logger = get_logger("app.providers.places.google_places")

PLACES_SEARCH_TEXT_ENDPOINT = "https://places.googleapis.com/v1/places:searchText"
PLACES_DETAILS_BASE_ENDPOINT = "https://places.googleapis.com/v1/places"

# In-memory TTL caches to eliminate redundant Google API calls and prevent credit waste
_search_cache: Dict[str, tuple[float, List[LeadPlacesSearchResult]]] = {}
_details_cache: Dict[str, tuple[float, Dict[str, Any]]] = {}
SEARCH_CACHE_TTL = 900  # 15 minutes
DETAILS_CACHE_TTL = 3600  # 1 hour


class GooglePlacesNewProvider:
    """Official Google Places API (New) Provider Client."""

    def __init__(self, api_key: Optional[str] = None):
        self.api_key = api_key or settings.google_places_api_key

    def is_configured(self) -> bool:
        """Check if Google Places API key is configured."""
        return bool(
            self.api_key
            and self.api_key.strip()
            and self.api_key.strip() not in ("YOUR_GOOGLE_PLACES_API_KEY", "")
        )

    def _get_headers(self, field_mask: str) -> Dict[str, str]:
        return {
            "Content-Type": "application/json",
            "X-Goog-Api-Key": self.api_key.strip(),
            "X-Goog-FieldMask": field_mask,
        }

    async def search_places(
        self,
        query: str,
        location: Optional[str] = None,
        limit: int = 8,
    ) -> List[LeadPlacesSearchResult]:
        """
        Search for places using Google Places API (New) Text Search.
        Optimized with Basic SKU field_mask to prevent unnecessary contact/atmosphere surcharges.
        """
        if not self.is_configured():
            logger.debug("Google Places API (New) not configured, skipping")
            return []

        clean_query = " ".join(query.strip().split())
        if not clean_query or len(clean_query) < 3:
            return []

        clean_location = " ".join(location.strip().split()) if location and location.strip() else ""
        search_query = f"{clean_query} {clean_location}".strip() if clean_location else clean_query

        # Check in-memory cache to save API credits on repeated queries/keystrokes
        cache_key = f"{clean_query.lower()}|{clean_location.lower()}|{limit}"
        now = time.time()
        if cache_key in _search_cache:
            ts, cached_results = _search_cache[cache_key]
            if now - ts < SEARCH_CACHE_TTL:
                logger.info("Google Places search cache hit (0 API credits used)", query=search_query)
                return cached_results

        # Optimized Basic SKU: Only requests fields needed for the dropdown list.
        # Avoids requesting opening hours, phone, website, or photos on keystrokes (saves ~60% cost).
        field_mask = (
            "places.id,"
            "places.displayName,"
            "places.formattedAddress,"
            "places.rating,"
            "places.userRatingCount,"
            "places.primaryTypeDisplayName,"
            "places.primaryType,"
            "places.location,"
            "places.businessStatus"
        )

        payload = {
            "textQuery": search_query,
            "languageCode": "en",
            "maxResultCount": min(max(1, limit), 20),
        }

        async with httpx.AsyncClient(timeout=10.0) as client:
            try:
                response = await client.post(
                    PLACES_SEARCH_TEXT_ENDPOINT,
                    json=payload,
                    headers=self._get_headers(field_mask),
                )

                if response.status_code != 200:
                    logger.warning(
                        "Google Places API (New) search failed",
                        status_code=response.status_code,
                        body=response.text[:300],
                    )
                    return []

                data = response.json()
                places_raw = data.get("places", [])
                results: List[LeadPlacesSearchResult] = []

                for p in places_raw:
                    place_id = p.get("id")
                    if not place_id:
                        continue

                    # Extract display name
                    display_name_obj = p.get("displayName") or {}
                    title = display_name_obj.get("text") or clean_query

                    # Extract address
                    formatted_addr = p.get("formattedAddress") or ""

                    # Extract category
                    cat_obj = p.get("primaryTypeDisplayName") or {}
                    raw_cat = cat_obj.get("text")
                    if not raw_cat and p.get("primaryType"):
                        raw_cat = p.get("primaryType", "").replace("_", " ").title()

                    category = raw_cat or "Local Business"

                    # Extract coordinates
                    loc_obj = p.get("location") or {}
                    lat = loc_obj.get("latitude")
                    lng = loc_obj.get("longitude")

                    # Extract photo media URL if available
                    photos = p.get("photos") or []
                    photo_url = None
                    if photos and isinstance(photos, list):
                        first_photo = photos[0]
                        photo_name = first_photo.get("name")
                        if photo_name:
                            # Use secure backend photo proxy URL to protect Google Cloud API Key
                            photo_url = f"/api/v1/leads/places/photo?photo_name={photo_name}"

                    # Extract contact
                    phone = p.get("nationalPhoneNumber") or p.get("internationalPhoneNumber")
                    website = p.get("websiteUri")

                    results.append(
                        LeadPlacesSearchResult(
                            place_id=place_id,
                            name=title,
                            address=formatted_addr,
                            category=category or "Local Business",
                            rating=float(p.get("rating", 4.0)) if p.get("rating") is not None else None,
                            review_count=int(p.get("userRatingCount", 0)) if p.get("userRatingCount") is not None else None,
                            photo_url=photo_url,
                            latitude=lat,
                            longitude=lng,
                            phone=phone,
                            website=website,
                        )
                    )

                # Cache both matching and empty results to prevent repeated external billing on non-matching queries
                _search_cache[cache_key] = (time.time(), results)

                logger.info(
                    "Google Places API (New) search succeeded",
                    query=search_query,
                    count=len(results),
                )
                return results

            except Exception as e:
                logger.error("Google Places API (New) search exception", error=str(e))
                return []

    async def get_place_details(self, place_id: str) -> Optional[Dict[str, Any]]:
        """
        Fetch full business details for a place using Google Places API (New).
        Returns opening hours, operational status, editorial summary, ratings, reviews, photos.
        Uses in-memory cache to prevent re-querying the same place ID.
        """
        if not self.is_configured() or not place_id:
            return None

        # Clean place_id: strip 'places/' prefix if present
        clean_id = place_id.replace("places/", "").strip()

        # Check in-memory details cache
        now = time.time()
        if clean_id in _details_cache:
            ts, cached_details = _details_cache[clean_id]
            if now - ts < DETAILS_CACHE_TTL:
                logger.info("Google Places details cache hit (0 API credits used)", place_id=clean_id)
                return cached_details

        endpoint = f"{PLACES_DETAILS_BASE_ENDPOINT}/{clean_id}"

        field_mask = (
            "id,"
            "displayName,"
            "formattedAddress,"
            "rating,"
            "userRatingCount,"
            "primaryTypeDisplayName,"
            "primaryType,"
            "location,"
            "photos,"
            "nationalPhoneNumber,"
            "internationalPhoneNumber,"
            "websiteUri,"
            "regularOpeningHours,"
            "currentOpeningHours,"
            "businessStatus,"
            "priceLevel,"
            "priceRange,"
            "reviews,"
            "editorialSummary"
        )

        async with httpx.AsyncClient(timeout=10.0) as client:
            try:
                response = await client.get(
                    endpoint,
                    headers=self._get_headers(field_mask),
                )

                if response.status_code != 200:
                    logger.warning(
                        "Google Places API (New) details failed",
                        place_id=clean_id,
                        status_code=response.status_code,
                        body=response.text[:300],
                    )
                    return None

                p = response.json()

                # Process opening hours
                reg_hours = p.get("regularOpeningHours") or {}
                cur_hours = p.get("currentOpeningHours") or {}
                open_now = cur_hours.get("openNow") if "openNow" in cur_hours else reg_hours.get("openNow")
                weekday_descriptions = reg_hours.get("weekdayDescriptions") or []

                # Format primary photo
                photos = p.get("photos") or []
                photo_url = None
                photo_names = []
                for ph in photos:
                    p_name = ph.get("name")
                    if p_name:
                        photo_names.append(p_name)
                if photo_names:
                    photo_url = f"/api/v1/leads/places/photo?photo_name={photo_names[0]}"

                # Format reviews
                reviews_raw = p.get("reviews") or []
                clean_reviews = []
                for r in reviews_raw[:5]:
                    author_obj = r.get("authorAttribution") or {}
                    text_obj = r.get("originalText") or r.get("text") or {}
                    review_text = text_obj.get("text") if isinstance(text_obj, dict) else str(text_obj or "")
                    clean_reviews.append({
                        "author_name": author_obj.get("displayName") or "Google Customer",
                        "author_photo_url": author_obj.get("photoUri"),
                        "rating": float(r.get("rating", 5)),
                        "text": review_text,
                        "relative_time_description": r.get("relativePublishTimeDescription") or "",
                        "publish_time": r.get("publishTime"),
                    })

                # Editorial summary
                summary_obj = p.get("editorialSummary") or {}
                editorial_summary = summary_obj.get("text") if isinstance(summary_obj, dict) else None

                # Process category
                cat_obj = p.get("primaryTypeDisplayName") or {}
                raw_cat = cat_obj.get("text") or p.get("primaryType", "").replace("_", " ").title()
                category = raw_cat or "Local Business"

                result_data = {
                    "place_id": clean_id,
                    "name": (p.get("displayName") or {}).get("text") or "",
                    "address": p.get("formattedAddress") or "",
                    "category": category,
                    "primary_type": p.get("primaryType"),  # Raw snake_case type e.g. "coworking_space"
                    "rating": float(p.get("rating", 4.0)) if p.get("rating") is not None else None,
                    "review_count": int(p.get("userRatingCount", 0)) if p.get("userRatingCount") is not None else None,
                    "phone": p.get("nationalPhoneNumber") or p.get("internationalPhoneNumber"),
                    "website": p.get("websiteUri"),
                    "latitude": (p.get("location") or {}).get("latitude"),
                    "longitude": (p.get("location") or {}).get("longitude"),
                    "photo_url": photo_url,
                    "photo_names": photo_names,
                    "open_now": open_now,
                    "weekday_descriptions": weekday_descriptions,
                    "regular_opening_hours": reg_hours,
                    "business_status": p.get("businessStatus") or "OPERATIONAL",
                    "price_level": p.get("priceLevel"),
                    "price_range": (
                        {
                            "start_price": float(p["priceRange"]["startPrice"]["units"]) if "startPrice" in p.get("priceRange", {}) and "units" in p["priceRange"]["startPrice"] else None,
                            "end_price": float(p["priceRange"]["endPrice"]["units"]) if "endPrice" in p.get("priceRange", {}) and "units" in p["priceRange"]["endPrice"] else None,
                            "currency": (p.get("priceRange", {}).get("startPrice") or p.get("priceRange", {}).get("endPrice") or {}).get("currencyCode", "INR"),
                        }
                        if p.get("priceRange")
                        else None
                    ),
                    "editorial_summary": editorial_summary,
                    "reviews": clean_reviews,
                }
                _details_cache[clean_id] = (time.time(), result_data)
                return result_data

            except Exception as e:
                logger.error("Google Places API (New) details exception", place_id=clean_id, error=str(e))
                return None

    def get_photo_media_url(
        self,
        photo_name: str,
        max_height: int = 800,
        max_width: int = 1200,
    ) -> Optional[str]:
        """
        Build Google Places API (New) Photo Media URL.
        Endpoint: GET https://places.googleapis.com/v1/{name=places/*/photos/*/media}
        """
        if not self.is_configured() or not photo_name:
            return None

        clean_name = photo_name.strip().lstrip("/")
        return (
            f"https://places.googleapis.com/v1/{clean_name}/media"
            f"?maxHeightPx={max_height}&maxWidthPx={max_width}&key={self.api_key.strip()}"
        )
