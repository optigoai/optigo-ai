// ==================================================
// OptigoAI Enterprise — Enhanced Franchise Insights View
// Tab 1: Overview Trends (TrendChartGrid + Branch comparison preview + Sentiment summary)
// Tab 2: Compare Branches (Ranked list + Horizontal bar chart)
// Tab 3: Reviews & Sentiment (DonutChart breakdown + Reply Queue)
// ==================================================

import React, { useState } from 'react';
import { useFranchise } from '../../context/FranchiseContext';
import { useLocation } from '../../context/LocationContext';
import { BranchCompareList, getHealthBadgeStyle } from '../../components/common/BranchCompareList';
import { TrendChartGrid } from '../../components/common/TrendChartGrid';
import { DonutChart } from '../../components/common/DonutChart';
import {
  TrendingUp,
  BarChart3,
  Star,
  CheckCircle2,
  AlertCircle,
  ArrowRight,
} from 'lucide-react';

export const FranchiseInsightsView: React.FC = () => {
  const { overview, locations, selectedDateRange } = useFranchise();
  const { selectLocation, setActiveBranchTab } = useLocation();

  const [activeTab, setActiveTab] = useState<'overview' | 'compare' | 'reviews'>('overview');

  // Time-range multiplier
  const multiplier =
    selectedDateRange === '7d'
      ? 0.25
      : selectedDateRange === '30d'
      ? 1.0
      : selectedDateRange === '90d'
      ? 2.8
      : 8.5;

  const totalDiscovery = Math.round(((overview.total_searches || 0) + (overview.total_maps_views || 0)) * multiplier);
  const totalActions = Math.round((overview.total_customer_actions || 0) * multiplier);
  const aggHealth = overview.aggregate_health_score || 0;
  const avgRating = overview.franchise_avg_rating || 0;
  const totalReviews = overview.total_reviews || 0;

  // Unreplied reviews list across branches for Tab 3 (Reply Queue)
  const unrepliedLocations = locations.filter((l) => (l.unreplied_reviews ?? 0) > 0);

  // Sentiment Segments for Donut Chart dynamically derived from database reviews
  const positivePct = overview.positive_sentiment_pct || 0;
  const criticalPct = totalReviews > 0 ? Math.round(((overview.unreplied_reviews_count || 0) / totalReviews) * 100) : 0;
  const neutralPct = Math.max(0, 100 - positivePct - criticalPct);

  const sentimentSegments = [
    {
      label: 'Positive (4-5★)',
      percentage: positivePct,
      count: Math.round((positivePct / 100) * totalReviews),
      color: '#16a34a',
    },
    {
      label: 'Neutral (3★)',
      percentage: neutralPct,
      count: Math.round((neutralPct / 100) * totalReviews),
      color: '#f59e0b',
    },
    {
      label: 'Critical (1-2★)',
      percentage: criticalPct,
      count: totalReviews > 0 ? (overview.unreplied_reviews_count || 0) : 0,
      color: '#dc2626',
    },
  ];

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '20px', maxWidth: '1280px', margin: '0 auto', width: '100%' }}>
      {/* 1. Top Tab Navigation Bar */}
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          borderBottom: '1px solid #e2e8f0',
          paddingBottom: '12px',
          flexWrap: 'wrap',
          gap: '12px',
        }}
      >
        <div style={{ display: 'flex', gap: '10px' }}>
          <button
            onClick={() => setActiveTab('overview')}
            style={{
              padding: '10px 20px',
              borderRadius: '24px',
              border: 'none',
              fontSize: '0.88rem',
              fontWeight: activeTab === 'overview' ? 800 : 600,
              backgroundColor: activeTab === 'overview' ? '#1255E6' : '#f1f5f9',
              color: activeTab === 'overview' ? '#ffffff' : '#475569',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: '8px',
              boxShadow: activeTab === 'overview' ? '0 2px 8px rgba(18, 85, 230, 0.25)' : 'none',
              transition: 'all 0.15s ease',
            }}
          >
            <TrendingUp size={16} />
            <span>Overview Trends</span>
          </button>

          <button
            onClick={() => setActiveTab('compare')}
            style={{
              padding: '10px 20px',
              borderRadius: '24px',
              border: 'none',
              fontSize: '0.88rem',
              fontWeight: activeTab === 'compare' ? 800 : 600,
              backgroundColor: activeTab === 'compare' ? '#1255E6' : '#f1f5f9',
              color: activeTab === 'compare' ? '#ffffff' : '#475569',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: '8px',
              boxShadow: activeTab === 'compare' ? '0 2px 8px rgba(18, 85, 230, 0.25)' : 'none',
              transition: 'all 0.15s ease',
            }}
          >
            <BarChart3 size={16} />
            <span>Compare Branches ({locations.length})</span>
          </button>

          <button
            onClick={() => setActiveTab('reviews')}
            style={{
              padding: '10px 20px',
              borderRadius: '24px',
              border: 'none',
              fontSize: '0.88rem',
              fontWeight: activeTab === 'reviews' ? 800 : 600,
              backgroundColor: activeTab === 'reviews' ? '#1255E6' : '#f1f5f9',
              color: activeTab === 'reviews' ? '#ffffff' : '#475569',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: '8px',
              boxShadow: activeTab === 'reviews' ? '0 2px 8px rgba(18, 85, 230, 0.25)' : 'none',
              transition: 'all 0.15s ease',
            }}
          >
            <Star size={16} />
            <span>Reviews & Sentiment</span>
            {overview.unreplied_reviews_count > 0 && (
              <span
                style={{
                  backgroundColor: activeTab === 'reviews' ? '#ffffff' : '#dc2626',
                  color: activeTab === 'reviews' ? '#dc2626' : '#ffffff',
                  fontSize: '0.7rem',
                  fontWeight: 800,
                  padding: '1px 6px',
                  borderRadius: '10px',
                  marginLeft: '2px',
                }}
              >
                {overview.unreplied_reviews_count}
              </span>
            )}
          </button>
        </div>

        <div style={{ fontSize: '0.78rem', color: '#64748b' }}>
          Network Benchmark Baseline: <strong>{aggHealth}/100</strong>
        </div>
      </div>

      {/* ======================================================== */}
      {/* TAB 1: OVERVIEW TRENDS (WITH TREND GRID + BENCHMARK & REVIEWS SUMMARY) */}
      {/* ======================================================== */}
      {activeTab === 'overview' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '18px' }}>
          {/* Main Selectable Trend Chart Grid with 8 Points & Area Fill */}
          <TrendChartGrid
            totalDiscoveryViews={totalDiscovery}
            totalCustomerActions={totalActions}
            aggregateHealthScore={aggHealth}
            averageRating={avgRating}
            selectedDateRange={selectedDateRange}
          />

          {/* Two-Column Summary Row below Trend Chart */}
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(360px, 1fr))', gap: '18px' }}>
            {/* Left: Branch Health Score Dispersion Preview */}
            <div className="prody-card" style={{ padding: '20px', display: 'flex', flexDirection: 'column', justifyContent: 'space-between', gap: '14px' }}>
              <div>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
                  <h3 style={{ fontSize: '0.96rem', fontWeight: 800, color: '#0f172a', margin: 0 }}>
                    Branch Health Comparison
                  </h3>
                  <span className="prody-pill blue" style={{ fontSize: '0.7rem' }}>
                    Target: ≥70
                  </span>
                </div>
                <p style={{ fontSize: '0.78rem', color: '#64748b', margin: '0 0 14px 0' }}>
                  Visual health score bars measured against the network baseline ({aggHealth}/100).
                </p>

                <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                  {locations.map((loc) => {
                    const style = getHealthBadgeStyle(loc.health_score || 0);
                    const barWidthPct = Math.min(Math.max(loc.health_score || 0, 10), 100);

                    return (
                      <div key={loc.id} style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontSize: '0.8rem' }}>
                          <span style={{ fontWeight: 700, color: '#0f172a' }}>{loc.name}</span>
                          <span style={{ fontWeight: 800, color: style.text }}>
                            {loc.health_score || 0}/100
                          </span>
                        </div>

                        <div style={{ height: '10px', width: '100%', backgroundColor: '#f1f5f9', borderRadius: '5px', overflow: 'hidden' }}>
                          <div
                            style={{
                              height: '100%',
                              width: `${barWidthPct}%`,
                              backgroundColor: style.barColor || style.dotColor,
                              borderRadius: '5px',
                              transition: 'width 0.4s ease',
                            }}
                          />
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>

              <div style={{ borderTop: '1px solid #f1f5f9', paddingTop: '10px', display: 'flex', justifyContent: 'flex-end' }}>
                <button
                  onClick={() => setActiveTab('compare')}
                  style={{
                    background: 'transparent',
                    border: 'none',
                    color: '#2563eb',
                    fontSize: '0.78rem',
                    fontWeight: 700,
                    cursor: 'pointer',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '4px',
                  }}
                >
                  <span>View detailed branch ranking</span>
                  <ArrowRight size={13} />
                </button>
              </div>
            </div>

            {/* Right: Review Sentiment Summary Preview */}
            <div className="prody-card" style={{ padding: '20px', display: 'flex', flexDirection: 'column', justifyContent: 'space-between', gap: '14px' }}>
              <div>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
                  <h3 style={{ fontSize: '0.96rem', fontWeight: 800, color: '#0f172a', margin: 0 }}>
                    Customer Sentiment & Reputation
                  </h3>
                  <span className="prody-pill green" style={{ fontSize: '0.7rem' }}>
                    {positivePct}% Positive
                  </span>
                </div>
                <p style={{ fontSize: '0.78rem', color: '#64748b', margin: '0 0 14px 0' }}>
                  Average rating of {avgRating} ★ across {totalReviews} verified Google reviews.
                </p>

                {/* Sentiment Distribution Bar */}
                <div style={{ height: '14px', width: '100%', display: 'flex', borderRadius: '7px', overflow: 'hidden', marginBottom: '14px' }}>
                  <div style={{ width: `${positivePct}%`, backgroundColor: '#16a34a' }} title={`Positive: ${positivePct}%`} />
                  <div style={{ width: `${neutralPct}%`, backgroundColor: '#f59e0b' }} title={`Neutral: ${neutralPct}%`} />
                  <div style={{ width: `${criticalPct}%`, backgroundColor: '#dc2626' }} title={`Critical: ${criticalPct}%`} />
                </div>

                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.76rem', color: '#64748b' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '5px' }}>
                    <div style={{ width: '8px', height: '8px', borderRadius: '50%', backgroundColor: '#16a34a' }} />
                    <span>Positive ({positivePct}%)</span>
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '5px' }}>
                    <div style={{ width: '8px', height: '8px', borderRadius: '50%', backgroundColor: '#f59e0b' }} />
                    <span>Neutral ({neutralPct}%)</span>
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '5px' }}>
                    <div style={{ width: '8px', height: '8px', borderRadius: '50%', backgroundColor: '#dc2626' }} />
                    <span>Critical ({criticalPct}%)</span>
                  </div>
                </div>
              </div>

              <div style={{ borderTop: '1px solid #f1f5f9', paddingTop: '10px', display: 'flex', justifyContent: 'flex-end' }}>
                <button
                  onClick={() => setActiveTab('reviews')}
                  style={{
                    background: 'transparent',
                    border: 'none',
                    color: '#2563eb',
                    fontSize: '0.78rem',
                    fontWeight: 700,
                    cursor: 'pointer',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '4px',
                  }}
                >
                  <span>Open reviews & reply queue</span>
                  <ArrowRight size={13} />
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* ======================================================== */}
      {/* TAB 2: COMPARE BRANCHES (RANKED LIST + HORIZONTAL BARS) */}
      {/* ======================================================== */}
      {activeTab === 'compare' && (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(360px, 1fr))', gap: '18px' }}>
          {/* Left: ONE Ranked List */}
          <div className="prody-card" style={{ padding: '22px', display: 'flex', flexDirection: 'column', gap: '16px' }}>
            <div>
              <h2 style={{ fontSize: '1.05rem', fontWeight: 800, color: '#0f172a', margin: 0 }}>
                Branch Health Ranking
              </h2>
              <p style={{ fontSize: '0.78rem', color: '#64748b', margin: '3px 0 0 0' }}>
                Ranked by overall Google profile optimization, reviews, and search conversions.
              </p>
            </div>

            <BranchCompareList locations={locations} />
          </div>

          {/* Right: Horizontal Bar Chart Visualization */}
          <div className="prody-card" style={{ padding: '22px', display: 'flex', flexDirection: 'column', justifyContent: 'space-between', gap: '16px' }}>
            <div>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '4px' }}>
                <h2 style={{ fontSize: '1.05rem', fontWeight: 800, color: '#0f172a', margin: 0 }}>
                  Health Score Comparison
                </h2>
                <span className="prody-pill blue" style={{ fontSize: '0.7rem' }}>
                  Target: ≥70
                </span>
              </div>
              <p style={{ fontSize: '0.78rem', color: '#64748b', margin: '0 0 16px 0' }}>
                Visual health score bars measured against the network baseline ({aggHealth}/100).
              </p>

              {/* Horizontal Bars */}
              <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                {locations.map((loc) => {
                  const style = getHealthBadgeStyle(loc.health_score || 0);
                  const barWidthPct = Math.min(Math.max(loc.health_score || 0, 10), 100);

                  return (
                    <div key={loc.id} style={{ display: 'flex', flexDirection: 'column', gap: '6px' }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontSize: '0.82rem' }}>
                        <span style={{ fontWeight: 700, color: '#0f172a' }}>{loc.name}</span>
                        <span style={{ fontWeight: 800, color: style.text }}>
                          {loc.health_score || 0}/100
                        </span>
                      </div>

                      <div style={{ height: '14px', width: '100%', backgroundColor: '#f1f5f9', borderRadius: '7px', overflow: 'hidden' }}>
                        <div
                          style={{
                            height: '100%',
                            width: `${barWidthPct}%`,
                            backgroundColor: style.barColor || style.dotColor,
                            borderRadius: '7px',
                            transition: 'width 0.4s ease',
                          }}
                        />
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>

            {/* Consistent Color Code Legend */}
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderTop: '1px solid #f1f5f9', paddingTop: '12px', fontSize: '0.74rem', color: '#64748b' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '5px' }}>
                <div style={{ width: '8px', height: '8px', borderRadius: '50%', backgroundColor: '#16a34a' }} />
                <span>Healthy (≥70)</span>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '5px' }}>
                <div style={{ width: '8px', height: '8px', borderRadius: '50%', backgroundColor: '#f59e0b' }} />
                <span>Attention (50–69)</span>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '5px' }}>
                <div style={{ width: '8px', height: '8px', borderRadius: '50%', backgroundColor: '#dc2626' }} />
                <span>Urgent (&lt;50)</span>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* ======================================================== */}
      {/* TAB 3: REVIEWS & SENTIMENT (DONUT CHART + REPLY QUEUE) */}
      {/* ======================================================== */}
      {activeTab === 'reviews' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '18px' }}>
          {/* Top Row: Donut Chart + Sentiment Stats */}
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))', gap: '18px' }}>
            <DonutChart
              title="Review Sentiment Breakdown"
              subtitle="Distribution of verified customer reviews by rating and sentiment"
              segments={sentimentSegments}
              centerValue={`${positivePct}%`}
              centerLabel="Positive"
            />

            <div style={{ display: 'flex', flexDirection: 'column', gap: '14px', justifyContent: 'space-between' }}>
              <div className="prody-card" style={{ padding: '18px', flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center' }}>
                <span style={{ fontSize: '0.74rem', fontWeight: 700, color: '#64748b', textTransform: 'uppercase' }}>
                  Network Avg Rating
                </span>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginTop: '4px' }}>
                  <span style={{ fontSize: '2rem', fontWeight: 900, color: '#0f172a' }}>
                    {avgRating} ★
                  </span>
                  <div style={{ display: 'flex', gap: '2px' }}>
                    {[1, 2, 3, 4, 5].map((s) => (
                      <Star
                        key={s}
                        size={16}
                        fill={s <= Math.round(avgRating) ? '#f59e0b' : '#e2e8f0'}
                        color={s <= Math.round(avgRating) ? '#f59e0b' : '#cbd5e1'}
                      />
                    ))}
                  </div>
                </div>
                <span style={{ fontSize: '0.76rem', color: '#64748b', marginTop: '4px' }}>
                  Calculated across {totalReviews} total customer reviews
                </span>
              </div>

              <div className="prody-card" style={{ padding: '18px', flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center' }}>
                <span style={{ fontSize: '0.74rem', fontWeight: 700, color: '#64748b', textTransform: 'uppercase' }}>
                  Awaiting Response
                </span>
                <div style={{ fontSize: '2rem', fontWeight: 900, color: overview.unreplied_reviews_count > 0 ? '#dc2626' : '#16a34a', marginTop: '4px' }}>
                  {overview.unreplied_reviews_count || 0}
                </div>
                <span style={{ fontSize: '0.76rem', color: '#64748b', marginTop: '4px' }}>
                  {overview.unreplied_reviews_count > 0 ? 'Requires immediate action in Reply Queue' : '100% response rate across all stores'}
                </span>
              </div>
            </div>
          </div>

          {/* Reply Queue Component */}
          <div className="prody-card" style={{ padding: '22px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
              <div>
                <h2 style={{ fontSize: '1.05rem', fontWeight: 800, color: '#0f172a', margin: 0 }}>
                  Unreplied Reviews Reply Queue
                </h2>
                <p style={{ fontSize: '0.8rem', color: '#64748b', margin: '3px 0 0 0' }}>
                  Responding to customer reviews within 24 hours accelerates Google Maps local ranking velocity.
                </p>
              </div>

              <span className={`prody-pill ${overview.unreplied_reviews_count > 0 ? 'coral' : 'green'}`}>
                {overview.unreplied_reviews_count > 0 ? `${overview.unreplied_reviews_count} Reviews Pending` : 'Inbox Zero'}
              </span>
            </div>

            {unrepliedLocations.length > 0 ? (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
                {unrepliedLocations.map((loc) => (
                  <div
                    key={loc.id}
                    onClick={() => {
                      selectLocation(loc.id);
                      setActiveBranchTab('reviews');
                    }}
                    style={{
                      padding: '16px',
                      borderRadius: '24px',
                      backgroundColor: '#fff1f2',
                      border: '1px solid #fecdd3',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'space-between',
                      cursor: 'pointer',
                      transition: 'all 0.15s ease',
                    }}
                  >
                    <div>
                      <div style={{ fontSize: '0.94rem', fontWeight: 800, color: '#9f1239' }}>
                        {loc.name} ({loc.location})
                      </div>
                      <span style={{ fontSize: '0.78rem', color: '#be123c' }}>
                        {loc.unreplied_reviews} pending {loc.unreplied_reviews === 1 ? 'review' : 'reviews'} awaiting response
                      </span>
                    </div>

                    <div style={{ display: 'flex', alignItems: 'center', gap: '6px', color: '#9f1239', fontWeight: 800, fontSize: '0.82rem' }}>
                      <span>Open Reviews Studio</span>
                      <ArrowRight size={14} />
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <div
                style={{
                  padding: '30px',
                  borderRadius: '14px',
                  backgroundColor: '#f0fdf4',
                  border: '1px solid #bbf7d0',
                  textAlign: 'center',
                  display: 'flex',
                  flexDirection: 'column',
                  alignItems: 'center',
                  gap: '8px',
                }}
              >
                <CheckCircle2 size={32} color="#16a34a" />
                <h4 style={{ fontSize: '1rem', fontWeight: 800, color: '#166534', margin: 0 }}>
                  All Reviews Replied!
                </h4>
                <p style={{ fontSize: '0.82rem', color: '#15803d', margin: 0 }}>
                  Every customer review across all franchise branches has been answered.
                </p>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
};
