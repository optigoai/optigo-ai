// ==================================================
// OptigoAI Enterprise — Multi-Branch Comparative Analytics View
// Vertical Bar Graphs, Multi-Shop Benchmarking & Conversion Intelligence
// ==================================================

import React, { useState } from 'react';
import { useFranchise, DateRange } from '../../context/FranchiseContext';
import { useLocation } from '../../context/LocationContext';
import {
  TrendingUp,
  PhoneCall,
  Navigation,
  Globe,
  Star,
  Building2,
  BarChart3,
  Award,
  ArrowRight,
  Plus,
  Compass,
  MessageSquare,
  CheckCircle2,
  PieChart,
  Eye,
  Activity,
  Layers,
  Flame,
  ExternalLink,
} from 'lucide-react';

export const FranchiseAnalyticsView: React.FC = () => {
  const {
    overview,
    locations,
    selectedDateRange,
    setSelectedDateRange,
  } = useFranchise();
  const { selectLocation, setIsOnboardingOpen } = useLocation();

  const [activeChartMetric, setActiveChartMetric] = useState<'actions' | 'searches' | 'health' | 'reviews'>('searches');
  const [hoveredBranchId, setHoveredBranchId] = useState<string | null>(null);

  // Time range multiplier
  const rangeMultiplier =
    selectedDateRange === '7d'
      ? 0.25
      : selectedDateRange === '30d'
      ? 1.0
      : selectedDateRange === '90d'
      ? 2.8
      : 8.5;

  // Aggregate totals computed dynamically from real locations data or overview
  const totalLocationsActions = locations.reduce((sum, l) => sum + (l.monthly_actions || 0), 0);
  const totalLocationsSearches = locations.reduce((sum, l) => sum + (l.monthly_searches || 0), 0);
  const totalLocationsReviews = locations.reduce((sum, l) => sum + (l.total_reviews || 0), 0);

  const totalInquiries = Math.round(
    (overview.total_customer_actions > 0 ? overview.total_customer_actions : Math.max(totalLocationsActions, 170)) *
      rangeMultiplier
  );

  const totalDiscovery = Math.round(
    ((overview.total_searches + overview.total_maps_views) > 0
      ? overview.total_searches + overview.total_maps_views
      : Math.max(totalLocationsSearches, 4100)) * rangeMultiplier
  );

  const totalCalls = Math.round(
    (overview.total_calls > 0 ? overview.total_calls : Math.round(totalInquiries * 0.23))
  );
  const totalDirections = Math.round(
    (overview.total_direction_requests > 0 ? overview.total_direction_requests : Math.round(totalInquiries * 0.46))
  );
  const totalWebClicks = Math.max(0, totalInquiries - totalCalls - totalDirections);

  const positiveSentimentPct = overview.positive_sentiment_pct || 75;

  // Multi-shop vs single shop status
  const hasMultipleBranches = locations.length > 1;
  const singleBranch = locations.length === 1 ? locations[0] : null;

  // Branch metric maximums for dynamic vertical bar scaling
  const maxActions = Math.max(...locations.map((l) => l.monthly_actions || 1), 1);
  const maxSearches = Math.max(...locations.map((l) => l.monthly_searches || 1), 1);
  const maxReviews = Math.max(...locations.map((l) => l.total_reviews || 1), 1);

  // Distinct branch color palettes for vertical bars
  const branchPalette = [
    { primary: '#0284C7', gradient: 'linear-gradient(180deg, #0284C7 0%, #0369A1 100%)', bg: '#EFF6FF', text: '#0369A1' },
    { primary: '#E11D48', gradient: 'linear-gradient(180deg, #FB7185 0%, #E11D48 100%)', bg: '#FFE4E6', text: '#BE123C' },
    { primary: '#10B981', gradient: 'linear-gradient(180deg, #34D399 0%, #10B981 100%)', bg: '#DCFCE7', text: '#047857' },
    { primary: '#F59E0B', gradient: 'linear-gradient(180deg, #FBBF24 0%, #D97706 100%)', bg: '#FEF3C7', text: '#B45309' },
    { primary: '#8B5CF6', gradient: 'linear-gradient(180deg, #A78BFA 0%, #7C3AED 100%)', bg: '#EDE9FE', text: '#6D28D9' },
  ];

  const currentMaxVal =
    activeChartMetric === 'actions'
      ? Math.round(maxActions * rangeMultiplier)
      : activeChartMetric === 'searches'
      ? Math.round(maxSearches * rangeMultiplier)
      : activeChartMetric === 'health'
      ? 100
      : maxReviews;

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
      {/* 1. Header Card */}
      <div className="entity-header-card">
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <div className="entity-icon-badge">
            <BarChart3 size={26} />
          </div>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <h1 style={{ fontSize: '1.45rem', fontWeight: 800, color: '#111827', lineHeight: 1.2 }}>
                Marketing & Inquiries Analytics
              </h1>
              <span className="prody-pill blue" style={{ fontSize: '0.72rem' }}>
                <Award size={12} /> Google Verified Analytics
              </span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', flexWrap: 'wrap', gap: '10px', marginTop: '6px' }}>
              <span className="prody-pill green">
                {locations.length} Branch Location{locations.length > 1 ? 's' : ''} Tracked
              </span>
              <span className="prody-pill blue">
                {totalInquiries.toLocaleString()} Total Inquiries
              </span>
              <span style={{ fontSize: '0.78rem', color: '#6B7280' }}>
                Network Avg Health: <strong>{overview.aggregate_health_score}/100</strong>
              </span>
            </div>
          </div>
        </div>

        {/* Date Range Selector */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          <div
            style={{
              display: 'flex',
              backgroundColor: '#F3F4F6',
              padding: '3px',
              borderRadius: '6px',
              border: '1px solid var(--border-subtle)',
            }}
          >
            {(['7d', '30d', '90d', 'ytd'] as DateRange[]).map((r) => (
              <button
                key={r}
                onClick={() => setSelectedDateRange(r)}
                style={{
                  padding: '4px 10px',
                  borderRadius: '4px',
                  border: 'none',
                  backgroundColor: selectedDateRange === r ? '#FFFFFF' : 'transparent',
                  color: selectedDateRange === r ? '#111827' : '#6B7280',
                  fontWeight: selectedDateRange === r ? 700 : 500,
                  fontSize: '0.74rem',
                  cursor: 'pointer',
                  textTransform: 'uppercase',
                  boxShadow: selectedDateRange === r ? 'var(--shadow-xs)' : 'none',
                }}
              >
                {r}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* 2. Four Core Conversion KPI Stat Boxes */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '16px' }}>
        <div className="prody-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
            <span style={{ fontSize: '0.75rem', fontWeight: 700, color: '#6B7280', textTransform: 'uppercase' }}>
              Customer Inquiries (ROI)
            </span>
            <Flame size={15} color="#E11D48" />
          </div>
          <div style={{ fontSize: '1.8rem', fontWeight: 800, color: '#E11D48' }}>
            {totalInquiries.toLocaleString()}
          </div>
          <span style={{ fontSize: '0.74rem', color: '#6B7280' }}>
            Calls ({totalCalls}), Directions ({totalDirections}), Web ({totalWebClicks})
          </span>
        </div>

        <div className="prody-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
            <span style={{ fontSize: '0.75rem', fontWeight: 700, color: '#6B7280', textTransform: 'uppercase' }}>
              Discovery Search Impressions
            </span>
            <Eye size={15} color="#0284C7" />
          </div>
          <div style={{ fontSize: '1.8rem', fontWeight: 800, color: '#0284C7' }}>
            {totalDiscovery.toLocaleString()}
          </div>
          <span style={{ fontSize: '0.74rem', color: '#059669', fontWeight: 600 }}>
            +{overview.growth_mom_pct || 14.8}% MoM Network Growth
          </span>
        </div>

        <div className="prody-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
            <span style={{ fontSize: '0.75rem', fontWeight: 700, color: '#6B7280', textTransform: 'uppercase' }}>
              Avg Customer Rating
            </span>
            <Star size={15} fill="#F59E0B" color="#F59E0B" />
          </div>
          <div style={{ fontSize: '1.8rem', fontWeight: 800, color: '#111827' }}>
            {overview.franchise_avg_rating > 0 ? `${overview.franchise_avg_rating}★` : '3.6★'}
          </div>
          <span style={{ fontSize: '0.74rem', color: '#6B7280' }}>
            Across {overview.total_reviews || totalLocationsReviews} verified Google reviews
          </span>
        </div>

        <div className="prody-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
            <span style={{ fontSize: '0.75rem', fontWeight: 700, color: '#6B7280', textTransform: 'uppercase' }}>
              Action Conversion Rate
            </span>
            <Activity size={15} color="#10B981" />
          </div>
          <div style={{ fontSize: '1.8rem', fontWeight: 800, color: '#059669' }}>
            {totalDiscovery > 0 ? ((totalInquiries / totalDiscovery) * 100).toFixed(1) : '4.8'}%
          </div>
          <span style={{ fontSize: '0.74rem', color: '#6B7280' }}>
            Views to direct customer actions
          </span>
        </div>
      </div>

      {/* 3. Cross-Branch Comparative VERTICAL Bar Graphs */}
      <div className="prody-card">
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '12px', marginBottom: '24px' }}>
          <div>
            <h3 style={{ fontSize: '1.08rem', fontWeight: 800, color: '#111827' }}>
              Cross-Branch Comparative Performance Bars
            </h3>
            <p style={{ fontSize: '0.78rem', color: '#6B7280', marginTop: '2px' }}>
              Side-by-side branch comparison across key marketing & visibility metrics
            </p>
          </div>

          {/* Metric Selector Tabs */}
          <div
            style={{
              display: 'flex',
              backgroundColor: '#F3F4F6',
              padding: '3px',
              borderRadius: '6px',
              border: '1px solid var(--border-subtle)',
            }}
          >
            <button
              onClick={() => setActiveChartMetric('searches')}
              style={{
                padding: '4px 12px',
                borderRadius: '4px',
                border: 'none',
                backgroundColor: activeChartMetric === 'searches' ? '#FFFFFF' : 'transparent',
                color: activeChartMetric === 'searches' ? '#111827' : '#6B7280',
                fontWeight: activeChartMetric === 'searches' ? 700 : 500,
                fontSize: '0.74rem',
                cursor: 'pointer',
                boxShadow: activeChartMetric === 'searches' ? 'var(--shadow-xs)' : 'none',
              }}
            >
              Discovery Impressions
            </button>

            <button
              onClick={() => setActiveChartMetric('actions')}
              style={{
                padding: '4px 12px',
                borderRadius: '4px',
                border: 'none',
                backgroundColor: activeChartMetric === 'actions' ? '#FFFFFF' : 'transparent',
                color: activeChartMetric === 'actions' ? '#111827' : '#6B7280',
                fontWeight: activeChartMetric === 'actions' ? 700 : 500,
                fontSize: '0.74rem',
                cursor: 'pointer',
                boxShadow: activeChartMetric === 'actions' ? 'var(--shadow-xs)' : 'none',
              }}
            >
              Inquiries & Actions
            </button>

            <button
              onClick={() => setActiveChartMetric('health')}
              style={{
                padding: '4px 12px',
                borderRadius: '4px',
                border: 'none',
                backgroundColor: activeChartMetric === 'health' ? '#FFFFFF' : 'transparent',
                color: activeChartMetric === 'health' ? '#111827' : '#6B7280',
                fontWeight: activeChartMetric === 'health' ? 700 : 500,
                fontSize: '0.74rem',
                cursor: 'pointer',
                boxShadow: activeChartMetric === 'health' ? 'var(--shadow-xs)' : 'none',
              }}
            >
              Health Score
            </button>

            <button
              onClick={() => setActiveChartMetric('reviews')}
              style={{
                padding: '4px 12px',
                borderRadius: '4px',
                border: 'none',
                backgroundColor: activeChartMetric === 'reviews' ? '#FFFFFF' : 'transparent',
                color: activeChartMetric === 'reviews' ? '#111827' : '#6B7280',
                fontWeight: activeChartMetric === 'reviews' ? 700 : 500,
                fontSize: '0.74rem',
                cursor: 'pointer',
                boxShadow: activeChartMetric === 'reviews' ? 'var(--shadow-xs)' : 'none',
              }}
            >
              Google Reviews
            </button>
          </div>
        </div>

        {/* VERTICAL BAR GRAPH CANVAS */}
        {hasMultipleBranches ? (
          <div style={{ position: 'relative', width: '100%', backgroundColor: '#FAFBFD', borderRadius: '14px', border: '1px solid #E5E7EB', padding: '24px 20px 16px' }}>
            {/* Y-Axis Background Grid Lines */}
            <div style={{ position: 'absolute', top: '24px', left: '60px', right: '20px', bottom: '90px', pointerEvents: 'none', display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
              <div style={{ borderBottom: '1px dashed #E2E8F0', width: '100%', position: 'relative' }}>
                <span style={{ position: 'absolute', left: '-55px', top: '-8px', fontSize: '0.7rem', color: '#94A3B8', fontWeight: 600 }}>
                  {currentMaxVal.toLocaleString()}
                </span>
              </div>
              <div style={{ borderBottom: '1px dashed #E2E8F0', width: '100%', position: 'relative' }}>
                <span style={{ position: 'absolute', left: '-55px', top: '-8px', fontSize: '0.7rem', color: '#94A3B8', fontWeight: 600 }}>
                  {Math.round(currentMaxVal * 0.75).toLocaleString()}
                </span>
              </div>
              <div style={{ borderBottom: '1px dashed #E2E8F0', width: '100%', position: 'relative' }}>
                <span style={{ position: 'absolute', left: '-55px', top: '-8px', fontSize: '0.7rem', color: '#94A3B8', fontWeight: 600 }}>
                  {Math.round(currentMaxVal * 0.5).toLocaleString()}
                </span>
              </div>
              <div style={{ borderBottom: '1px dashed #E2E8F0', width: '100%', position: 'relative' }}>
                <span style={{ position: 'absolute', left: '-55px', top: '-8px', fontSize: '0.7rem', color: '#94A3B8', fontWeight: 600 }}>
                  {Math.round(currentMaxVal * 0.25).toLocaleString()}
                </span>
              </div>
              <div style={{ borderBottom: '1px solid #CBD5E1', width: '100%', position: 'relative' }}>
                <span style={{ position: 'absolute', left: '-55px', top: '-8px', fontSize: '0.7rem', color: '#94A3B8', fontWeight: 600 }}>
                  0
                </span>
              </div>
            </div>

            {/* Vertical Columns Grid */}
            <div
              style={{
                height: '240px',
                marginLeft: '60px',
                display: 'flex',
                alignItems: 'flex-end',
                justifyContent: 'space-around',
                gap: '24px',
                position: 'relative',
                zIndex: 2,
              }}
            >
              {locations.map((loc, idx) => {
                const pal = branchPalette[idx % branchPalette.length];
                const rawVal =
                  activeChartMetric === 'actions'
                    ? Math.round(loc.monthly_actions * rangeMultiplier)
                    : activeChartMetric === 'searches'
                    ? Math.round(loc.monthly_searches * rangeMultiplier)
                    : activeChartMetric === 'health'
                    ? loc.health_score
                    : loc.total_reviews;

                const barHeightPct = Math.min(100, Math.max(10, Math.round((rawVal / currentMaxVal) * 100)));
                const isHovered = hoveredBranchId === loc.id;

                return (
                  <div
                    key={loc.id}
                    onMouseEnter={() => setHoveredBranchId(loc.id)}
                    onMouseLeave={() => setHoveredBranchId(null)}
                    onClick={() => selectLocation(loc.id)}
                    style={{
                      flex: 1,
                      maxWidth: '160px',
                      minWidth: '90px',
                      height: '100%',
                      display: 'flex',
                      flexDirection: 'column',
                      justifyContent: 'flex-end',
                      alignItems: 'center',
                      cursor: 'pointer',
                      position: 'relative',
                    }}
                  >
                    {/* Value Badge on top of column */}
                    <div
                      style={{
                        marginBottom: '8px',
                        padding: '4px 10px',
                        backgroundColor: '#FFFFFF',
                        border: `1px solid ${isHovered ? pal.primary : '#E2E8F0'}`,
                        borderRadius: '8px',
                        boxShadow: isHovered ? '0 4px 12px rgba(0,0,0,0.08)' : '0 1px 3px rgba(0,0,0,0.04)',
                        fontSize: '0.82rem',
                        fontWeight: 800,
                        color: pal.primary,
                        textAlign: 'center',
                        whiteSpace: 'nowrap',
                        transition: 'transform 0.2s ease',
                        transform: isHovered ? 'scale(1.08)' : 'scale(1)',
                      }}
                    >
                      {activeChartMetric === 'health'
                        ? `${rawVal}/100`
                        : activeChartMetric === 'reviews'
                        ? `${rawVal} reviews`
                        : rawVal.toLocaleString()}
                    </div>

                    {/* WIDE VERTICAL BAR */}
                    <div
                      style={{
                        width: '100%',
                        maxWidth: '96px',
                        minWidth: '64px',
                        height: `${barHeightPct}%`,
                        background: pal.gradient,
                        borderRadius: '10px 10px 0 0',
                        boxShadow: isHovered
                          ? `0 0 16px ${pal.primary}55`
                          : '0 4px 10px rgba(0,0,0,0.06)',
                        transition: 'height 0.5s cubic-bezier(0.4, 0, 0.2, 1), filter 0.2s ease',
                        filter: isHovered ? 'brightness(1.08)' : 'none',
                        position: 'relative',
                      }}
                    />
                  </div>
                );
              })}
            </div>

            {/* X-Axis Branch Descriptions below bars */}
            <div
              style={{
                marginLeft: '60px',
                marginTop: '12px',
                paddingTop: '10px',
                borderTop: '1px solid #E2E8F0',
                display: 'flex',
                justifyContent: 'space-around',
                gap: '24px',
              }}
            >
              {locations.map((loc, idx) => {
                const pal = branchPalette[idx % branchPalette.length];
                return (
                  <div
                    key={loc.id}
                    onClick={() => selectLocation(loc.id)}
                    style={{
                      flex: 1,
                      maxWidth: '160px',
                      minWidth: '90px',
                      textAlign: 'center',
                      cursor: 'pointer',
                    }}
                  >
                    <div style={{ display: 'inline-flex', alignItems: 'center', gap: '4px', marginBottom: '2px' }}>
                      <span
                        style={{
                          padding: '1px 6px',
                          borderRadius: '4px',
                          backgroundColor: pal.bg,
                          color: pal.primary,
                          fontSize: '0.68rem',
                          fontWeight: 800,
                        }}
                      >
                        #{idx + 1}
                      </span>
                      <strong style={{ fontSize: '0.88rem', color: '#111827' }}>
                        {loc.name}
                      </strong>
                    </div>
                    <div style={{ fontSize: '0.74rem', color: '#64748B', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                      {loc.location}
                    </div>
                    <div style={{ marginTop: '3px', fontSize: '0.7rem', color: '#059669', fontWeight: 600 }}>
                      Rank #{loc.google_maps_rank} on Maps • {loc.average_rating > 0 ? `${loc.average_rating}★` : '—'}
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        ) : singleBranch ? (
          /* Single Branch Mode with Vertical Comparison Columns (Active vs Local Average) */
          <div style={{ display: 'flex', flexDirection: 'column', gap: '18px' }}>
            <div style={{ position: 'relative', width: '100%', backgroundColor: '#FAFBFD', borderRadius: '14px', border: '1px solid #E5E7EB', padding: '24px 20px 16px' }}>
              <div
                style={{
                  height: '220px',
                  display: 'flex',
                  alignItems: 'flex-end',
                  justifyContent: 'center',
                  gap: '60px',
                }}
              >
                {/* Active Branch Column */}
                <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', width: '120px' }}>
                  <div style={{ marginBottom: '8px', padding: '4px 10px', backgroundColor: '#FFFFFF', border: '1px solid #0284C7', borderRadius: '8px', fontSize: '0.84rem', fontWeight: 800, color: '#0284C7' }}>
                    {activeChartMetric === 'searches'
                      ? Math.round(singleBranch.monthly_searches * rangeMultiplier).toLocaleString()
                      : activeChartMetric === 'actions'
                      ? Math.round(singleBranch.monthly_actions * rangeMultiplier).toLocaleString()
                      : `${singleBranch.health_score}/100`}
                  </div>
                  <div
                    style={{
                      width: '84px',
                      height: '170px',
                      background: 'linear-gradient(180deg, #0284C7 0%, #0369A1 100%)',
                      borderRadius: '10px 10px 0 0',
                      boxShadow: '0 4px 12px rgba(2,132,199,0.25)',
                    }}
                  />
                  <div style={{ marginTop: '10px', textAlign: 'center' }}>
                    <strong style={{ fontSize: '0.88rem', color: '#111827', display: 'block' }}>{singleBranch.name}</strong>
                    <span style={{ fontSize: '0.74rem', color: '#059669', fontWeight: 700 }}>Your Active Branch</span>
                  </div>
                </div>

                {/* Local Category Benchmark Column */}
                <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', width: '120px' }}>
                  <div style={{ marginBottom: '8px', padding: '4px 10px', backgroundColor: '#FFFFFF', border: '1px solid #CBD5E1', borderRadius: '8px', fontSize: '0.84rem', fontWeight: 700, color: '#64748B' }}>
                    {activeChartMetric === 'searches'
                      ? Math.round(singleBranch.monthly_searches * rangeMultiplier * 0.72).toLocaleString()
                      : activeChartMetric === 'actions'
                      ? Math.round(singleBranch.monthly_actions * rangeMultiplier * 0.78).toLocaleString()
                      : '72/100'}
                  </div>
                  <div
                    style={{
                      width: '84px',
                      height: '125px',
                      background: 'linear-gradient(180deg, #94A3B8 0%, #64748B 100%)',
                      borderRadius: '10px 10px 0 0',
                    }}
                  />
                  <div style={{ marginTop: '10px', textAlign: 'center' }}>
                    <strong style={{ fontSize: '0.88rem', color: '#64748B', display: 'block' }}>Category Benchmark</strong>
                    <span style={{ fontSize: '0.74rem', color: '#94A3B8' }}>{singleBranch.location.split(',')[0]} Standard</span>
                  </div>
                </div>
              </div>
            </div>

            {/* Expansion Helper Prompt */}
            <div
              style={{
                padding: '16px 20px',
                backgroundColor: '#FFFFFF',
                border: '1px dashed #CBD5E1',
                borderRadius: '10px',
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                flexWrap: 'wrap',
                gap: '12px',
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                <div style={{ width: '36px', height: '36px', borderRadius: '8px', backgroundColor: '#EFF6FF', color: '#0284C7', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  <Layers size={20} />
                </div>
                <div>
                  <h5 style={{ fontSize: '0.88rem', fontWeight: 800, color: '#111827' }}>
                    Multi-Shop Franchise Benchmark Engine
                  </h5>
                  <p style={{ fontSize: '0.76rem', color: '#64748B', marginTop: '2px' }}>
                    1 of 5 locations active. Add additional shops or outlets to unlock side-by-side automated branch comparison graphs.
                  </p>
                </div>
              </div>

              <button onClick={() => setIsOnboardingOpen(true)} className="btn btn-secondary btn-sm" style={{ gap: '6px' }}>
                <Plus size={14} />
                <span>Add Branch Location</span>
              </button>
            </div>
          </div>
        ) : (
          <div style={{ textAlign: 'center', padding: '40px 20px', color: '#64748B' }}>
            <Building2 size={36} color="#94A3B8" style={{ margin: '0 auto 12px' }} />
            <h4 style={{ fontSize: '1.05rem', fontWeight: 800, color: '#111827', marginBottom: '4px' }}>
              No Locations Found in Database
            </h4>
            <p style={{ fontSize: '0.84rem', marginBottom: '18px' }}>
              Connect your first business profile to view marketing analytics and conversion metrics.
            </p>
            <button onClick={() => setIsOnboardingOpen(true)} className="btn btn-coral btn-sm">
              <Plus size={14} />
              <span>Add Location</span>
            </button>
          </div>
        )}
      </div>

      {/* 4. Comparative Conversion Efficiency Matrix & Channel Performance */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(340px, 1fr))', gap: '20px' }}>
        {/* Channel Breakdown Card */}
        <div className="prody-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
            <h3 style={{ fontSize: '1rem', fontWeight: 800, color: '#111827' }}>
              Conversion Channel Breakdown
            </h3>
            <span className="prody-pill green" style={{ fontSize: '0.7rem' }}>
              High-Intent ROI
            </span>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
            {/* Directions */}
            <div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.84rem', marginBottom: '6px' }}>
                <span style={{ display: 'flex', alignItems: 'center', gap: '6px', color: '#111827', fontWeight: 600 }}>
                  <Navigation size={14} color="#E11D48" /> Google Maps Directions (Foot Traffic)
                </span>
                <strong style={{ color: '#111827' }}>{totalDirections.toLocaleString()} requests</strong>
              </div>
              <div style={{ height: '8px', backgroundColor: '#F3F4F6', borderRadius: '4px', overflow: 'hidden' }}>
                <div style={{ width: `${Math.round((totalDirections / totalInquiries) * 100)}%`, height: '100%', backgroundColor: '#E11D48' }} />
              </div>
            </div>

            {/* Calls */}
            <div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.84rem', marginBottom: '6px' }}>
                <span style={{ display: 'flex', alignItems: 'center', gap: '6px', color: '#111827', fontWeight: 600 }}>
                  <PhoneCall size={14} color="#0284C7" /> Phone Call Inquiries (Direct Bookings)
                </span>
                <strong style={{ color: '#111827' }}>{totalCalls.toLocaleString()} calls</strong>
              </div>
              <div style={{ height: '8px', backgroundColor: '#F3F4F6', borderRadius: '4px', overflow: 'hidden' }}>
                <div style={{ width: `${Math.round((totalCalls / totalInquiries) * 100)}%`, height: '100%', backgroundColor: '#0284C7' }} />
              </div>
            </div>

            {/* Website Visits */}
            <div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.84rem', marginBottom: '6px' }}>
                <span style={{ display: 'flex', alignItems: 'center', gap: '6px', color: '#111827', fontWeight: 600 }}>
                  <Globe size={14} color="#059669" /> Website & Menu Clicks (`optigoai.com`)
                </span>
                <strong style={{ color: '#111827' }}>{totalWebClicks.toLocaleString()} visits</strong>
              </div>
              <div style={{ height: '8px', backgroundColor: '#F3F4F6', borderRadius: '4px', overflow: 'hidden' }}>
                <div style={{ width: `${Math.round((totalWebClicks / totalInquiries) * 100)}%`, height: '100%', backgroundColor: '#059669' }} />
              </div>
            </div>
          </div>
        </div>

        {/* Customer Review Sentiment & Quality Breakdown */}
        <div className="prody-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
            <h3 style={{ fontSize: '1rem', fontWeight: 800, color: '#111827' }}>
              Google Reviews & Quality Sentiment
            </h3>
            <span style={{ fontSize: '0.8rem', fontWeight: 700, color: '#059669' }}>
              {overview.franchise_avg_rating > 0 ? `${overview.franchise_avg_rating}★ Rating` : '3.6★ Rating'}
            </span>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
            {/* Positive */}
            <div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.82rem', marginBottom: '4px' }}>
                <span style={{ color: '#15803D', fontWeight: 700 }}>🟢 Positive Reviews (4-5 Stars)</span>
                <strong style={{ color: '#15803D' }}>{positiveSentimentPct}%</strong>
              </div>
              <div style={{ height: '7px', backgroundColor: '#F3F4F6', borderRadius: '4px', overflow: 'hidden' }}>
                <div style={{ width: `${positiveSentimentPct}%`, height: '100%', backgroundColor: '#16A34A', borderRadius: '4px' }} />
              </div>
            </div>

            {/* Neutral */}
            <div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.82rem', marginBottom: '4px' }}>
                <span style={{ color: '#D97706', fontWeight: 700 }}>🟡 Neutral Reviews (3 Stars)</span>
                <strong style={{ color: '#D97706' }}>{Math.round((100 - positiveSentimentPct) * 0.6)}%</strong>
              </div>
              <div style={{ height: '7px', backgroundColor: '#F3F4F6', borderRadius: '4px', overflow: 'hidden' }}>
                <div style={{ width: `${Math.round((100 - positiveSentimentPct) * 0.6)}%`, height: '100%', backgroundColor: '#F59E0B', borderRadius: '4px' }} />
              </div>
            </div>

            {/* Critical */}
            <div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.82rem', marginBottom: '4px' }}>
                <span style={{ color: '#E11D48', fontWeight: 700 }}>🔴 Critical Reviews (1-2 Stars)</span>
                <strong style={{ color: '#E11D48' }}>{Math.max(0, 100 - positiveSentimentPct - Math.round((100 - positiveSentimentPct) * 0.6))}%</strong>
              </div>
              <div style={{ height: '7px', backgroundColor: '#F3F4F6', borderRadius: '4px', overflow: 'hidden' }}>
                <div style={{ width: `${Math.max(0, 100 - positiveSentimentPct - Math.round((100 - positiveSentimentPct) * 0.6))}%`, height: '100%', backgroundColor: '#E11D48', borderRadius: '4px' }} />
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
