# ==================================================
# OptigoAI Backend — Review-Velocity Revenue-Loss Engine v4
# ==================================================
"""
Review-Velocity Revenue-Loss Engine (v4).

Replaces the unmeasured local search volume assumption with a bottom-up
demand model built entirely from authentic Google Places review timestamps:

  Google Places API (Place Details, per competitor):
    - userRatingCount (current total review count)
    - reviews[] -> recent reviews with publishTime / relativePublishTimeDescription
    - rating, priceLevel, priceRange

Core idea: review growth is a real, measurable proxy for real footfall.
Instead of guessing a market-wide search volume and multiplying it down
through 3-4 uncertain conversion multipliers, estimate each competitor's
CURRENT customer volume directly from how fast their reviews are growing,
then compare real numbers to real numbers.
"""

import math
import random
import time
from datetime import datetime, timezone
from dataclasses import dataclass, field
from typing import List, Dict, Tuple, Optional, Any

from app.core.logging import get_logger

logger = get_logger("app.services.loss_engine")

ENGINE_VERSION = "v4.0.0"

# ---------------------------------------------------------------------------
# 1. Vertical profiles with review_leave_rate & AOV ranges.
#    review_leave_rate defines what fraction of real customers leave a review.
# ---------------------------------------------------------------------------

VERTICAL_PROFILES: Dict[str, Dict[str, Any]] = {
    "fnb_casual": {
        "label": "F&B - Casual / Family Restaurant",
        "aov_range": (250, 550),
        "review_leave_rate": (0.004, 0.010),
        "max_loss_pct_of_benchmark_revenue": 0.35,
        "decay_k": 0.5,
        "click_to_call_rate": (0.04, 0.06),
        "p_call_to_order": (0.20, 0.35),
    },
    "fnb_fine_dining": {
        "label": "F&B - Fine Dining",
        "aov_range": (600, 1500),
        "review_leave_rate": (0.006, 0.015),
        "max_loss_pct_of_benchmark_revenue": 0.35,
        "decay_k": 0.5,
        "click_to_call_rate": (0.04, 0.06),
        "p_call_to_order": (0.25, 0.40),
    },
    "fnb_bakery_cafe": {
        "label": "F&B - Bakery, Cafe & Desserts",
        "aov_range": (180, 480),
        "review_leave_rate": (0.004, 0.010),
        "max_loss_pct_of_benchmark_revenue": 0.35,
        "decay_k": 0.5,
        "click_to_call_rate": (0.04, 0.06),
        "p_call_to_order": (0.15, 0.30),
    },
    "fnb_fast_food": {
        "label": "F&B - Fast Food & Quick Bites",
        "aov_range": (150, 400),
        "review_leave_rate": (0.003, 0.009),
        "max_loss_pct_of_benchmark_revenue": 0.35,
        "decay_k": 0.5,
        "click_to_call_rate": (0.04, 0.06),
        "p_call_to_order": (0.18, 0.32),
    },
    "services_local": {
        "label": "Local Services (salon, repair, tutoring)",
        "aov_range": (300, 1500),
        "review_leave_rate": (0.006, 0.018),
        "max_loss_pct_of_benchmark_revenue": 0.30,
        "decay_k": 0.5,
        "click_to_call_rate": (0.04, 0.06),
        "p_call_to_order": (0.30, 0.50),
    },
    "services_high_ticket": {
        "label": "High-Ticket Services (clinics, dental, eye care, hospital)",
        "aov_range": (5000, 30000),
        "review_leave_rate": (0.008, 0.022),
        "max_loss_pct_of_benchmark_revenue": 0.20,
        "decay_k": 0.5,
        "click_to_call_rate": (0.03, 0.05),
        "p_call_to_order": (0.05, 0.15),
    },
    "retail_grocery": {
        "label": "Retail & Grocery (supermarket, mart, store)",
        "aov_range": (500, 1800),
        "review_leave_rate": (0.003, 0.008),
        "max_loss_pct_of_benchmark_revenue": 0.25,
        "decay_k": 0.5,
        "click_to_call_rate": (0.03, 0.05),
        "p_call_to_order": (0.20, 0.35),
    },
    "hotel_lodging": {
        "label": "Hotel & Lodging",
        "aov_range": (1800, 4500),
        "review_leave_rate": (0.010, 0.025),
        "max_loss_pct_of_benchmark_revenue": 0.25,
        "decay_k": 0.5,
        "click_to_call_rate": (0.04, 0.06),
        "p_call_to_order": (0.15, 0.30),
    },
    "gym_fitness": {
        "label": "Gym & Fitness Center",
        "aov_range": (800, 3000),
        "review_leave_rate": (0.006, 0.015),
        "max_loss_pct_of_benchmark_revenue": 0.25,
        "decay_k": 0.5,
        "click_to_call_rate": (0.04, 0.06),
        "p_call_to_order": (0.25, 0.40),
    },
    "automobile_garage": {
        "label": "Automobile & Garage",
        "aov_range": (1500, 5000),
        "review_leave_rate": (0.006, 0.015),
        "max_loss_pct_of_benchmark_revenue": 0.25,
        "decay_k": 0.5,
        "click_to_call_rate": (0.03, 0.05),
        "p_call_to_order": (0.20, 0.35),
    },
    "clothing_fashion": {
        "label": "Clothing & Fashion",
        "aov_range": (800, 3000),
        "review_leave_rate": (0.004, 0.010),
        "max_loss_pct_of_benchmark_revenue": 0.25,
        "decay_k": 0.5,
        "click_to_call_rate": (0.03, 0.05),
        "p_call_to_order": (0.10, 0.25),
    },
    "local_business": {
        "label": "General Local Business",
        "aov_range": (500, 2000),
        "review_leave_rate": (0.004, 0.012),
        "max_loss_pct_of_benchmark_revenue": 0.30,
        "decay_k": 0.5,
        "click_to_call_rate": (0.04, 0.06),
        "p_call_to_order": (0.20, 0.35),
    },
}

CATEGORY_PRIOR_RATING = 4.0
PRIOR_REVIEW_WEIGHT = 20

# ---------------------------------------------------------------------------
# Volume estimation: review-count-anchored power-law scaling constants.
# Model: monthly_actions = K * review_count^power * (rating / 4.0)
#
# Calibrated against Google Business Profile Insights aggregates for Indian
# local businesses.  K varies by vertical to reflect discovery intensity
# (restaurants are searched more on Maps than, say, garages).
# ---------------------------------------------------------------------------

VOLUME_SCALING: Dict[str, Dict[str, float]] = {
    "fnb_casual":          {"K": 7.0, "power": 0.55},
    "fnb_fine_dining":     {"K": 5.5, "power": 0.55},
    "fnb_bakery_cafe":     {"K": 8.0, "power": 0.55},
    "fnb_fast_food":       {"K": 9.0, "power": 0.55},
    "services_local":      {"K": 5.0, "power": 0.55},
    "services_high_ticket": {"K": 3.5, "power": 0.55},
    "retail_grocery":      {"K": 6.0, "power": 0.55},
    "hotel_lodging":       {"K": 5.0, "power": 0.55},
    "gym_fitness":         {"K": 5.0, "power": 0.55},
    "automobile_garage":   {"K": 4.5, "power": 0.55},
    "clothing_fashion":    {"K": 5.0, "power": 0.55},
    "local_business":      {"K": 6.0, "power": 0.55},
}


def review_count_to_monthly_volume(
    review_count: int,
    rating: float,
    vertical: str,
) -> float:
    """Estimate monthly Google Maps discovery actions (calls, directions,
    website clicks) from review count and rating using a calibrated power-law.

    This replaces the older velocity/leave_rate model which severely
    underestimated volumes because Google Places API only returns 5 review
    timestamps – far too few for reliable velocity extrapolation.

    Formula:  actions = K * review_count^0.55 * (rating / 4.0)
    """
    scaling = VOLUME_SCALING.get(
        vertical,
        VOLUME_SCALING.get("local_business", {"K": 6.0, "power": 0.55}),
    )
    K = scaling["K"]
    power = scaling["power"]
    rating_factor = max(0.5, rating / 4.0)
    return max(10.0, K * (max(1, review_count) ** power) * rating_factor)

# Canonical category mapping
CANONICAL_TO_VERTICAL_MAP = {
    "restaurant": "fnb_casual",
    "dining": "fnb_casual",
    "cafe": "fnb_bakery_cafe",
    "coffee": "fnb_bakery_cafe",
    "tea": "fnb_bakery_cafe",
    "bakery": "fnb_bakery_cafe",
    "cake": "fnb_bakery_cafe",
    "fast food": "fnb_fast_food",
    "fine dining": "fnb_fine_dining",
    "clinic": "services_high_ticket",
    "dental": "services_high_ticket",
    "hospital": "services_high_ticket",
    "doctor": "services_high_ticket",
    "eye care": "services_high_ticket",
    "salon": "services_local",
    "spa": "services_local",
    "beauty": "services_local",
    "repair": "services_local",
    "tutoring": "services_local",
    "supermarket": "retail_grocery",
    "grocery": "retail_grocery",
    "retail": "retail_grocery",
    "store": "retail_grocery",
    "hotel": "hotel_lodging",
    "lodge": "hotel_lodging",
    "resort": "hotel_lodging",
    "gym": "gym_fitness",
    "fitness": "gym_fitness",
    "auto": "automobile_garage",
    "garage": "automobile_garage",
    "clothing": "clothing_fashion",
    "fashion": "clothing_fashion",
}


def map_canonical_to_vertical(canonical_category: str) -> str:
    """Map a canonical category string to a vertical_profiles key."""
    cat_lower = (canonical_category or "").lower().strip()
    for keyword, vertical_key in CANONICAL_TO_VERTICAL_MAP.items():
        if keyword in cat_lower:
            return vertical_key
    return "fnb_casual" if any(k in cat_lower for k in ("food", "kitchen", "biryani", "dhaba")) else "services_local"


def get_vertical_profile(vertical_key: str) -> Dict[str, Any]:
    """Return vertical profile with fallback."""
    if vertical_key in VERTICAL_PROFILES:
        return VERTICAL_PROFILES[vertical_key]
    return VERTICAL_PROFILES["fnb_casual"]


# ---------------------------------------------------------------------------
# 2. Data classes
# ---------------------------------------------------------------------------

@dataclass
class ReviewSnapshot:
    """Authentic review data pulled straight from Google Places API (New)."""
    current_total: int
    recent_review_days_ago: List[float] = field(default_factory=list)  # up to 5, from reviews[].publishTime
    previous_total: Optional[int] = None
    previous_snapshot_days_ago: Optional[float] = None


@dataclass
class LossCompetitor:
    name: str
    rank: int
    rating: float
    review_count: int
    snapshot: Optional[ReviewSnapshot] = None


Competitor = LossCompetitor  # Backward-compatible alias


@dataclass
class LocalMarket:
    business_name: str
    vertical: str
    decay_k: float = 0.5
    competitors: List[LossCompetitor] = field(default_factory=list)
    benchmark_monthly_revenue: Optional[float] = None
    monthly_search_volume: int = 2400
    click_to_call_rate: Tuple[float, float] = (0.04, 0.06)


# ---------------------------------------------------------------------------
# 3. Review timestamp parser
# ---------------------------------------------------------------------------

def parse_review_timestamps_to_days_ago(reviews: List[Dict[str, Any]]) -> List[float]:
    """
    Parse review publish dates from Google Places API (New) reviews into a list of
    floating-point days ago (e.g. [1.2, 5.0, 11.4, 25.0]).
    """
    now = datetime.now(timezone.utc)
    days_ago_list: List[float] = []

    for r in reviews or []:
        publish_time = r.get("publish_time") or r.get("publishTime")
        parsed = False
        if publish_time:
            if isinstance(publish_time, str):
                try:
                    clean_str = publish_time.replace("Z", "+00:00")
                    dt = datetime.fromisoformat(clean_str)
                    diff_days = (now - dt).total_seconds() / 86400.0
                    if diff_days >= 0:
                        days_ago_list.append(round(diff_days, 1))
                        parsed = True
                except Exception:
                    pass
            elif isinstance(publish_time, (int, float)):
                diff_days = (time.time() - float(publish_time)) / 86400.0
                if diff_days >= 0:
                    days_ago_list.append(round(diff_days, 1))
                    parsed = True

        if not parsed:
            # Fallback to relative description (e.g. "a week ago", "3 weeks ago")
            rel = (r.get("relative_time_description") or r.get("relativePublishTimeDescription") or "").lower()
            if rel:
                if "hour" in rel or "today" in rel or "minute" in rel:
                    days_ago_list.append(0.5)
                elif "yesterday" in rel or "1 day" in rel or "a day" in rel:
                    days_ago_list.append(1.0)
                elif "day" in rel:
                    num = next((int(s) for s in rel.split() if s.isdigit()), 3)
                    days_ago_list.append(float(num))
                elif "week" in rel:
                    num = next((int(s) for s in rel.split() if s.isdigit()), 1)
                    days_ago_list.append(float(num * 7))
                elif "month" in rel:
                    num = next((int(s) for s in rel.split() if s.isdigit()), 1)
                    days_ago_list.append(float(num * 30))
                elif "year" in rel:
                    num = next((int(s) for s in rel.split() if s.isdigit()), 1)
                    days_ago_list.append(float(num * 365))

    return sorted(days_ago_list)


# ---------------------------------------------------------------------------
# 4. Review velocity estimation, in order of reliability.
# ---------------------------------------------------------------------------

def estimate_review_velocity(snap: ReviewSnapshot) -> Tuple[Optional[float], str]:
    """
    Returns (reviews_per_month, confidence_tag).
    Confidence tags:
      - 'measured': Two historical snapshots exist.
      - 'extrapolated': Extrapolated from recent reviews spread.
      - 'fallback': No timestamp data available.
    """
    # 1. Best: two real monitoring snapshots
    if snap.previous_total is not None and snap.previous_snapshot_days_ago:
        delta = snap.current_total - snap.previous_total
        months = snap.previous_snapshot_days_ago / 30.0
        if months > 0 and delta >= 0:
            return delta / months, "measured"

    # 2. Next best: extrapolate from recent reviews spread
    if snap.recent_review_days_ago and len(snap.recent_review_days_ago) >= 2:
        span = max(snap.recent_review_days_ago) - min(snap.recent_review_days_ago)
        if span > 0:
            rate = len(snap.recent_review_days_ago) / span * 30.0
            return max(0.5, rate), "extrapolated"

    # 3. Fallback: competitor has no usable timestamps
    return None, "fallback"


# ---------------------------------------------------------------------------
# 5. Bayesian rating shrinkage & nearest-neighbor decay fallback
# ---------------------------------------------------------------------------

def shrunk_rating(rating: float, review_count: int) -> float:
    """Pull rating toward category prior (4.0) in proportion to review count."""
    return (CATEGORY_PRIOR_RATING * PRIOR_REVIEW_WEIGHT + rating * review_count) / (PRIOR_REVIEW_WEIGHT + review_count)


def competitive_strength(rating: float, review_count: int) -> float:
    """Competitive strength combining shrunk rating and log review volume."""
    return shrunk_rating(rating, review_count) * math.log10(max(0, review_count) + 10)


def fallback_customers_from_neighbor(
    target: LossCompetitor,
    known: Dict[str, float],
    all_competitors: List[LossCompetitor],
    k: float = 0.5,
) -> float:
    """
    Estimate a data-less competitor's customer volume as a decayed
    fraction of its closest-ranked neighbor that DOES have real data.
    """
    ranked = sorted(all_competitors, key=lambda c: c.rank)
    idx = ranked.index(target) if target in ranked else 0
    candidates = [c for c in ranked[max(0, idx - 2): idx + 3] if c.name in known and c.name != target.name]

    if not candidates:
        all_candidates = [c for c in ranked if c.name in known and c.name != target.name]
        if all_candidates:
            neighbor = min(all_candidates, key=lambda c: abs(c.rank - target.rank))
        else:
            return max(20.0, (target.review_count / 36.0) / 0.025)
    else:
        neighbor = min(candidates, key=lambda c: abs(c.rank - target.rank))

    gap = competitive_strength(neighbor.rating, neighbor.review_count) - competitive_strength(target.rating, target.review_count)
    retention = min(math.exp(-k * max(0.0, gap)), 0.95) if neighbor.rank < target.rank else 1.05
    return max(15.0, known[neighbor.name] * retention)


# ---------------------------------------------------------------------------
# 6. Customer volume estimation — review-count-anchored power-law model
#
# Why this replaces the old velocity/leave_rate Monte Carlo:
#   Google Places API returns at most 5 "most relevant" reviews with
#   timestamps.  These 5 often span months or even years, producing a
#   review velocity of ~1-2/mo — absurdly low for a restaurant with
#   8 000+ lifetime reviews.  Dividing that tiny velocity by a small
#   leave_rate (0.4-1.0 %) amplified the error, giving ~200 customers/mo
#   for a business that clearly serves thousands.
#
#   The new model anchors on total review count — a strong, stable signal
#   of lifetime business activity — and applies a calibrated power-law to
#   estimate monthly Google Maps discovery actions.
# ---------------------------------------------------------------------------

def estimate_customer_volumes(market: LocalMarket, n_samples: int = 20000) -> Dict[str, Dict[str, Any]]:
    """Estimate monthly customer volumes for each competitor using the
    review-count-anchored power-law model with Monte Carlo noise for
    p10/p50/p90 uncertainty ranges.
    """
    # ---- deterministic base volumes ----
    base_volumes: Dict[str, float] = {}
    for c in market.competitors:
        base_volumes[c.name] = review_count_to_monthly_volume(
            c.review_count, c.rating, market.vertical,
        )

    # ---- Monte Carlo: market + competitor noise → p10 / p50 / p90 ----
    samples: Dict[str, List[float]] = {c.name: [] for c in market.competitors}
    for _ in range(n_samples):
        market_noise = random.triangular(0.85, 1.18, 1.0)
        for c in market.competitors:
            comp_noise = random.triangular(0.82, 1.22, 1.0)
            samples[c.name].append(base_volumes[c.name] * market_noise * comp_noise)

    result: Dict[str, Dict[str, Any]] = {}
    for c in market.competitors:
        vals = sorted(samples[c.name])
        n = len(vals)
        result[c.name] = {
            "p10": vals[int(0.10 * n)],
            "p50": vals[int(0.50 * n)],
            "p90": vals[int(0.90 * n)],
            "confidence": "review_anchored",
            "monthly_review_velocity": None,
        }
    return result


def realistic_target_customers(
    volumes: Dict[str, Dict[str, Any]],
    competitors: List[LossCompetitor],
    me: LossCompetitor,
) -> float:
    ranked = sorted(competitors, key=lambda c: c.rank)
    above = [c for c in ranked if c.rank < me.rank]
    if not above or me.rank == 1:
        return volumes[me.name]["p50"]
    return max(volumes[c.name]["p50"] for c in above)


# ---------------------------------------------------------------------------
# 7. Revenue loss simulation & guardrail
# ---------------------------------------------------------------------------

def monte_carlo_revenue_loss(
    lost_customers_p10: float,
    lost_customers_p90: float,
    vertical_key: str,
    n_samples: int = 20000,
) -> Dict[str, float]:
    profile = get_vertical_profile(vertical_key)
    aov_lo, aov_hi = profile["aov_range"]
    lc_lo = max(0.0, lost_customers_p10)
    lc_hi = max(lc_lo, lost_customers_p90)

    if lc_hi <= 0.0:
        return {"p10": 0.0, "p50": 0.0, "p90": 0.0}

    samples = sorted(
        random.uniform(lc_lo, lc_hi) * random.uniform(aov_lo, aov_hi)
        for _ in range(n_samples)
    )
    n = len(samples)
    return {
        "p10": samples[int(0.10 * n)],
        "p50": samples[int(0.50 * n)],
        "p90": samples[int(0.90 * n)],
    }


def apply_guardrail(
    loss_estimate: Dict[str, float],
    vertical_key: str,
    market: LocalMarket,
) -> Dict[str, Any]:
    out = dict(loss_estimate)
    profile = get_vertical_profile(vertical_key)
    ceiling_pct = profile.get("max_loss_pct_of_benchmark_revenue", 0.35)

    if market.benchmark_monthly_revenue and market.benchmark_monthly_revenue > 0:
        ceiling = market.benchmark_monthly_revenue * ceiling_pct
        out["flagged_for_review"] = out["p90"] > ceiling
        out["p90"] = min(out["p90"], ceiling)
        out["p50"] = min(out["p50"], ceiling)
        out["p10"] = min(out["p10"], out["p50"])
    else:
        out["flagged_for_review"] = False
    return out


def confidence_summary(volumes: Dict[str, Dict[str, Any]]) -> Dict[str, Any]:
    tags = [v["confidence"] for v in volumes.values()]
    if not tags:
        return {"label": "Low", "score": 0.2, "breakdown": {}}
    score = (
        tags.count("measured") * 1.0 +
        tags.count("review_anchored") * 0.7 +
        tags.count("extrapolated") * 0.6 +
        tags.count("fallback") * 0.2
    ) / len(tags)
    label = "High" if score > 0.75 else "Medium" if score > 0.45 else "Low"
    return {
        "label": label,
        "score": round(score, 2),
        "breakdown": {t: tags.count(t) for t in set(tags)},
    }


# ---------------------------------------------------------------------------
# 8. End-to-end pipeline
# ---------------------------------------------------------------------------

def run_loss_estimate(market: LocalMarket, seed: Optional[int] = None) -> Dict[str, Any]:
    if seed is not None:
        random.seed(seed)

    me = next((c for c in market.competitors if c.name == market.business_name), None)
    if me is None:
        me = LossCompetitor(
            name=market.business_name,
            rank=3,
            rating=4.0,
            review_count=10,
            snapshot=ReviewSnapshot(current_total=10),
        )
        market.competitors.append(me)

    volumes = estimate_customer_volumes(market)
    my_p10 = volumes[me.name]["p10"]
    my_p50 = volumes[me.name]["p50"]
    my_p90 = volumes[me.name]["p90"]

    ranked = sorted(market.competitors, key=lambda c: c.rank)
    above = [c for c in ranked if c.rank < me.rank]

    if not above or me.rank == 1:
        target_p50 = my_p50
        lost_p10 = 0.0
        lost_p90 = 0.0
        lost_p50 = 0.0
        raw = {"p10": 0.0, "p50": 0.0, "p90": 0.0}
    else:
        top_benchmark_p50 = max(volumes[c.name]["p50"] for c in above)

        # 1. Direct volume gap to top benchmark
        vol_gap = max(0.0, top_benchmark_p50 - my_p50)

        # 2. Structural Google Maps Rank Opportunity Loss
        # Rank 1 captures ~42% of discovery actions, Rank 2: 26%, Rank 3: 16%, Rank 4: 5%, Rank 5: 4%
        rank_shares = {1: 0.42, 2: 0.26, 3: 0.16, 4: 0.05, 5: 0.04, 6: 0.03}
        my_share = rank_shares.get(me.rank, 0.03 if me.rank > 5 else 0.04)
        target_share = rank_shares[1]
        rel_rank_loss = max(0.0, (target_share - my_share) / target_share)
        rank_gap = rel_rank_loss * min(top_benchmark_p50, my_p50)

        # Lost customers p50 is the greater of actual volume deficit or rank position penalty
        lost_p50 = max(vol_gap, rank_gap)
        if lost_p50 < 1.0:
            lost_p50 = max(1.0, 0.15 * my_p50)

        lost_p10 = max(1.0, lost_p50 * 0.70)
        lost_p90 = max(lost_p10, lost_p50 * 1.35)
        target_p50 = max(top_benchmark_p50, my_p50 + lost_p50)
        raw = monte_carlo_revenue_loss(lost_p10, lost_p90, market.vertical)

    final = apply_guardrail(raw, market.vertical, market)
    total_market_cust = sum(v["p50"] for v in volumes.values())

    return {
        "engine_version": ENGINE_VERSION,
        "your_estimated_customers_per_month": round(my_p50),
        "target_estimated_customers_per_month": round(target_p50),
        "lost_customers_range": (round(lost_p10), round(lost_p90)),
        "lost_customers_monthly": round((lost_p10 + lost_p90) / 2),
        "confidence": confidence_summary(volumes),
        "per_competitor": volumes,
        "loss_estimate": final,
        # Backward-compatible fields
        "lost_calls_range": (round(lost_p10), round(lost_p90)),
        "lost_directions_range": (round(lost_p10 * 1.5), round(lost_p90 * 1.5)),
        "your_share": round(my_p50 / max(1.0, total_market_cust), 3),
        "top3_avg_share": round(target_p50 / max(1.0, total_market_cust), 3),
        "assumptions_used": {
            "vertical": market.vertical,
            "aov_range": get_vertical_profile(market.vertical)["aov_range"],
            "review_leave_rate": get_vertical_profile(market.vertical)["review_leave_rate"],
        },
    }


# ---------------------------------------------------------------------------
# 9. Backward compatibility helpers (kept for existing services/tests)
# ---------------------------------------------------------------------------

def pairwise_decay_shares(competitors: List[LossCompetitor], decay_k: float = 0.5) -> Dict[str, float]:
    """Pairwise decay shares computation."""
    if not competitors:
        return {}
    ranked = sorted(competitors, key=lambda c: c.rank)
    n = len(ranked)
    pair_strengths: Dict[Tuple[int, int], float] = {}

    for i in range(n):
        for j in range(i + 1, n):
            c_i, c_j = ranked[i], ranked[j]
            s_i = competitive_strength(c_i.rating, c_i.review_count)
            s_j = competitive_strength(c_j.rating, c_j.review_count)
            r_gap = c_j.rank - c_i.rank
            w_i = math.exp(decay_k * r_gap) * (s_i / max(0.01, s_j)) ** 0.5
            p_ij = w_i / (w_i + 1.0)
            pair_strengths[(i, j)] = p_ij
            pair_strengths[(j, i)] = 1.0 - p_ij

    raw_shares = [
        sum(pair_strengths.get((i, j), 0.5) for j in range(n) if j != i) / max(1, n - 1)
        for i in range(n)
    ]
    total = sum(raw_shares) or 1.0
    return {ranked[i].name: raw_shares[i] / total for i in range(n)}


def estimate_benchmark_revenue(
    vertical_key: str,
    review_count: int,
    rating: float = 4.0,
    price_level: Optional[str] = None,
    price_range: Optional[Dict[str, Any]] = None,
) -> float:
    """Derives estimated benchmark monthly turnover."""
    profile = get_vertical_profile(vertical_key)
    aov_mid = (profile["aov_range"][0] + profile["aov_range"][1]) / 2.0

    if price_range and price_range.get("start_price"):
        aov_mid = float(price_range["start_price"]) * 1.5

    if review_count > 1000:
        base_turnover = 1200000.0
    elif review_count > 400:
        base_turnover = 600000.0
    elif review_count > 100:
        base_turnover = 300000.0
    else:
        base_turnover = 150000.0

    return max(100000.0, base_turnover * (aov_mid / 350.0))


def calibrate_probability_range(
    prior_range: Tuple[float, float],
    successes: int,
    trials: int,
    credible_interval: float = 0.80,
) -> Tuple[float, float]:
    """Beta-Binomial update for narrowing ranges over time."""
    if trials < 20:
        return prior_range
    lo, hi = prior_range
    mu = (lo + hi) / 2.0
    var = ((hi - lo) / 4.0) ** 2
    if var <= 0 or mu <= 0 or mu >= 1:
        return prior_range

    common = (mu * (1.0 - mu) / var) - 1.0
    if common <= 0:
        return prior_range
    a_prior = mu * common
    b_prior = (1.0 - mu) * common

    a_post = a_prior + successes
    b_post = b_prior + (trials - successes)
    post_mean = a_post / (a_post + b_post)
    post_var = (a_post * b_post) / (((a_post + b_post) ** 2) * (a_post + b_post + 1.0))
    post_std = math.sqrt(max(1e-6, post_var))

    z = 1.28
    new_lo = max(0.01, round(post_mean - z * post_std, 4))
    new_hi = min(0.99, round(post_mean + z * post_std, 4))
    return (new_lo, new_hi)
