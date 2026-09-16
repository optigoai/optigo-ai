# ==================================================
# OptigoAI Backend — V4 Loss Engine Regression Tests
# ==================================================
"""
CI-blocking regression tests for the v4 Review-Velocity Revenue-Loss Engine.

These tests verify:
1. Bottom-up customer volume estimation from review velocity
2. Parsing of Google Places review timestamps
3. Realistic revenue loss scale (~1 Lakh/mo for Casa Rasa)
4. Monotonicity, non-negativity, stability, and guardrails
"""

import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from app.services.loss_engine import (
    LossCompetitor,
    ReviewSnapshot,
    LocalMarket,
    run_loss_estimate,
    estimate_review_velocity,
    parse_review_timestamps_to_days_ago,
    estimate_customer_volumes,
    calibrate_probability_range,
    shrunk_rating,
    competitive_strength,
    pairwise_decay_shares,
    map_canonical_to_vertical,
    VERTICAL_PROFILES,
)


def _make_v4_market(casa_rasa_days=None, casa_rasa_rating=3.9) -> LocalMarket:
    """Creates the reference test market: Casa Rasa in Edappal."""
    if casa_rasa_days is None:
        casa_rasa_days = [2, 9, 15, 22, 30]

    return LocalMarket(
        business_name="Casa Rasa",
        vertical="fnb_casual",
        benchmark_monthly_revenue=250000,
        competitors=[
            LossCompetitor(
                "De Chammanti", 1, 4.5, 280,
                snapshot=ReviewSnapshot(280, recent_review_days_ago=[1, 2, 4, 6, 9])
            ),
            LossCompetitor(
                "T&T Edappal", 2, 4.1, 720,
                snapshot=ReviewSnapshot(720, recent_review_days_ago=[1, 5, 8, 11, 14])
            ),
            LossCompetitor(
                "Casa Rasa", 3, casa_rasa_rating, 735,
                snapshot=ReviewSnapshot(735, recent_review_days_ago=casa_rasa_days)
            ),
            LossCompetitor(
                "Charcoal Bay", 4, 4.0, 1200,
                snapshot=ReviewSnapshot(1200, recent_review_days_ago=[1, 4, 9, 15, 22])
            ),
        ],
    )


def test_review_velocity_measured_and_extrapolated():
    """Verify review velocity estimation modes."""
    # Measured mode from two monitoring snapshots
    snap_measured = ReviewSnapshot(
        current_total=300,
        previous_total=270,
        previous_snapshot_days_ago=30.0,
    )
    rate, tag = estimate_review_velocity(snap_measured)
    assert tag == "measured"
    assert round(rate, 1) == 30.0

    # Extrapolated mode from recent reviews spread (5 reviews over 8 days = 18.75/mo)
    snap_extrap = ReviewSnapshot(
        current_total=280,
        recent_review_days_ago=[1, 2, 4, 6, 9],
    )
    rate_ex, tag_ex = estimate_review_velocity(snap_extrap)
    assert tag_ex == "extrapolated"
    assert 18.0 <= rate_ex <= 19.5

    # Fallback mode when no timestamps
    snap_empty = ReviewSnapshot(current_total=50)
    rate_fb, tag_fb = estimate_review_velocity(snap_empty)
    assert tag_fb == "fallback"
    assert rate_fb is None


def test_parse_review_timestamps_to_days_ago():
    """Test dynamic parsing of ISO strings and relative descriptions."""
    reviews = [
        {"publish_time": "2026-09-14T10:00:00Z"},
        {"relative_time_description": "2 days ago"},
        {"relative_time_description": "a week ago"},
        {"relative_time_description": "a month ago"},
    ]
    days = parse_review_timestamps_to_days_ago(reviews)
    assert len(days) == 4
    assert any(d <= 3 for d in days)
    assert any(6 <= d <= 8 for d in days)
    assert any(28 <= d <= 32 for d in days)


def test_casa_rasa_realistic_loss_scale():
    """Verify that Casa Rasa in Edappal produces realistic customer footfall
    and revenue loss (~1 Lakh/month) rather than the tiny ~₹1,500/mo of the old model.
    """
    m = _make_v4_market()
    r = run_loss_estimate(m, seed=42)

    # Customer volume should be in hundreds, not single digits
    assert r["your_estimated_customers_per_month"] > 100, (
        f"Customer volume should be > 100: {r['your_estimated_customers_per_month']}"
    )
    assert r["target_estimated_customers_per_month"] > r["your_estimated_customers_per_month"], (
        f"Target should be higher than user: {r['target_estimated_customers_per_month']} vs {r['your_estimated_customers_per_month']}"
    )

    lost_lo, lost_hi = r["lost_customers_range"]
    assert lost_lo > 100, f"Lost customers should be > 100: {lost_lo}"

    # Revenue loss should be realistic (~₹70,000 to ₹1,30,000/mo, roughly 1 Lakh)
    p50_loss = r["loss_estimate"]["p50"]
    assert 60000 <= p50_loss <= 130000, (
        f"Revenue loss should be in realistic ~1 Lakh range: got ₹{p50_loss}"
    )


def test_monotonicity():
    """Rank #1 has 0 loss; improving position reduces loss."""
    m_rank3 = _make_v4_market(casa_rasa_days=[2, 9, 15, 22, 30])
    r_rank3 = run_loss_estimate(m_rank3, seed=42)

    # Faster velocity (more reviews -> more customers) reduces lost customers
    m_faster = _make_v4_market(casa_rasa_days=[1, 2, 4, 6, 8])
    r_faster = run_loss_estimate(m_faster, seed=42)

    assert r_faster["loss_estimate"]["p50"] <= r_rank3["loss_estimate"]["p50"], (
        f"Faster velocity should reduce loss: faster={r_faster['loss_estimate']['p50']}, base={r_rank3['loss_estimate']['p50']}"
    )


def test_non_negative():
    """Loss is always non-negative and rank 1 is 0 loss."""
    m = _make_v4_market()
    r = run_loss_estimate(m, seed=42)
    assert r["loss_estimate"]["p50"] >= 0
    assert r["loss_estimate"]["p10"] >= 0
    assert r["loss_estimate"]["p90"] >= 0

    # Rank 1 business
    m_rank1 = LocalMarket(
        business_name="De Chammanti",
        vertical="fnb_casual",
        competitors=m.competitors,
    )
    r_rank1 = run_loss_estimate(m_rank1, seed=42)
    assert r_rank1["loss_estimate"]["p50"] == 0.0
    assert r_rank1["lost_customers_monthly"] == 0


def test_guardrail_clamps():
    """Ceiling clamps when loss exceeds max_loss_pct_of_benchmark_revenue."""
    m = _make_v4_market()
    m.benchmark_monthly_revenue = 80000  # Low benchmark revenue
    r = run_loss_estimate(m, seed=42)

    ceiling = 80000 * VERTICAL_PROFILES["fnb_casual"]["max_loss_pct_of_benchmark_revenue"]
    assert r["loss_estimate"]["p90"] <= ceiling + 1e-6, (
        f"p90 ({r['loss_estimate']['p90']}) exceeds ceiling ({ceiling})"
    )


def test_canonical_to_vertical_mapping():
    """All canonical categories map to known verticals."""
    test_categories = [
        "Restaurant", "Cafe & Coffee Shop", "Bakery & Cake Shop",
        "Ice Cream & Desserts", "Fast Food & Quick Bites",
        "Dental Clinic", "Clinic & Healthcare", "Eye Care & Opticals",
        "Beauty Salon & Spa", "Gym & Fitness Center",
        "Supermarket & Grocery", "Automobile & Garage",
        "Hotel & Lodging", "Clothing & Fashion",
        "Local Business",
    ]
    for cat in test_categories:
        vertical = map_canonical_to_vertical(cat)
        assert vertical in VERTICAL_PROFILES, f"Category '{cat}' mapped to unknown vertical '{vertical}'"


def test_shrinkage_pulls_toward_prior():
    """Shrinkage pulls low-review ratings toward 4.0."""
    raw_5_star = shrunk_rating(5.0, 3)
    assert raw_5_star < 4.5
    raw_5_lots = shrunk_rating(5.0, 1000)
    assert raw_5_lots > 4.95


def test_calibration_narrows_range():
    """Beta-binomial calibration narrows range."""
    old_range = (0.20, 0.35)
    new_range = calibrate_probability_range(old_range, successes=9, trials=40)
    assert (new_range[1] - new_range[0]) < (old_range[1] - old_range[0])
