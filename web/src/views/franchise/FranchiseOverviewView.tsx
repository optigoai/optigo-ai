// ==================================================
// OptigoAI Enterprise — Prody Light Executive Dashboard
// ==================================================

import React, { useState } from 'react';
import { useFranchise, DateRange } from '../../context/FranchiseContext';
import { useLocation } from '../../context/LocationContext';
import { useAuth } from '../../context/AuthContext';
import {
  Building2,
  TrendingUp,
  MapPin,
  Star,
  ShieldCheck,
  Plus,
  ArrowRight,
  Filter,
  ArrowUpDown,
  Search,
  Download,
  MoreHorizontal,
  RefreshCw,
  Award,
  CheckCircle2,
  Calendar,
} from 'lucide-react';

export const FranchiseOverviewView: React.FC = () => {
  const { overview, locations, isSyncing, triggerBulkSync, selectedDateRange, setSelectedDateRange } = useFranchise();
  const { selectLocation, setIsOnboardingOpen } = useLocation();
  const { organization, user } = useAuth();

  const [tableSearch, setTableSearch] = useState('');

  const filtered = locations.filter(
    (l) =>
      l.name.toLowerCase().includes(tableSearch.toLowerCase()) ||
      l.location.toLowerCase().includes(tableSearch.toLowerCase())
  );

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
      {/* 1. Entity Profile Header Card (Reference Top Hero) */}
      <div className="entity-header-card">
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          {/* Entity Icon Badge */}
          <div className="entity-icon-badge">
            <Building2 size={26} />
          </div>

          <div>
            <h1 style={{ fontSize: '1.45rem', fontWeight: 800, color: '#111827', lineHeight: 1.2 }}>
              {organization?.name || 'Casaraza Franchise Group'}
            </h1>

            {/* Metadata Tags Row */}
            <div style={{ display: 'flex', alignItems: 'center', flexWrap: 'wrap', gap: '10px', marginTop: '6px' }}>
              <span className="prody-pill blue" style={{ gap: '5px' }}>
                <Award size={12} /> Google Verified Network
              </span>

              <div style={{ display: 'flex', alignItems: 'center', gap: '5px', fontSize: '0.78rem', color: '#4B5563' }}>
                <div
                  style={{
                    width: '18px',
                    height: '18px',
                    borderRadius: '50%',
                    backgroundColor: '#FDE68A',
                    color: '#B45309',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    fontWeight: 800,
                    fontSize: '0.62rem',
                  }}
                >
                  {(user?.full_name || 'Ahmed').substring(0, 1).toUpperCase()}
                </div>
                <span>{user?.full_name || 'Ahmed Yazeen'}</span>
              </div>

              <span style={{ fontSize: '0.78rem', color: '#9CA3AF' }}>•</span>
              <span style={{ fontSize: '0.78rem', color: '#6B7280' }}>
                Synced with Google API 12 mins ago
              </span>
            </div>
          </div>
        </div>

        {/* Top-Right Quick Metric Gauges (Reference Top-Right 3 Gauges) */}
        <div className="metric-meter-box">
          <div className="meter-item">
            <div className="meter-label">
              <span style={{ width: '6px', height: '6px', borderRadius: '50%', backgroundColor: '#0284C7' }} />
              <span>Health</span>
            </div>
            <div className="meter-value">
              {overview.aggregate_health_score}<span style={{ fontSize: '0.75rem', color: '#9CA3AF', fontWeight: 600 }}>/100</span>
            </div>
          </div>

          <div style={{ width: '1px', height: '24px', backgroundColor: '#E5E7EB' }} />

          <div className="meter-item">
            <div className="meter-label">
              <span style={{ width: '6px', height: '6px', borderRadius: '50%', backgroundColor: '#E11D48' }} />
              <span>Rating</span>
            </div>
            <div className="meter-value">
              {overview.franchise_avg_rating > 0 ? overview.franchise_avg_rating : '—'}<span style={{ fontSize: '0.75rem', color: '#9CA3AF', fontWeight: 600 }}>★</span>
            </div>
          </div>

          <div style={{ width: '1px', height: '24px', backgroundColor: '#E5E7EB' }} />

          <div className="meter-item">
            <div className="meter-label">
              <span style={{ width: '6px', height: '6px', borderRadius: '50%', backgroundColor: '#10B981' }} />
              <span>Reviews</span>
            </div>
            <div className="meter-value">{overview.total_reviews}</div>
          </div>
        </div>
      </div>

      {/* 2. Main Performance Trends Box (Reference Consolidated Chart Box) */}
      <div className="prody-card">
        {/* Header Row */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '12px', marginBottom: '16px' }}>
          <div>
            <h3 style={{ fontSize: '1.05rem', fontWeight: 800, color: '#111827' }}>
              Consolidated Performance & Discovery
            </h3>
            <div style={{ display: 'flex', alignItems: 'center', gap: '14px', marginTop: '4px', fontSize: '0.78rem' }}>
              <span style={{ color: '#0284C7', fontWeight: 700 }}>— Search & Maps Impressions</span>
              <span style={{ color: '#E11D48', fontWeight: 700 }}>— Customer Inquiries & Actions</span>
            </div>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <button
              onClick={triggerBulkSync}
              disabled={isSyncing}
              style={{ background: 'transparent', border: 'none', color: '#6B7280', cursor: 'pointer', padding: '4px' }}
              title="Refresh Analytics"
            >
              <RefreshCw size={14} className={isSyncing ? 'spin-anim' : ''} />
            </button>

            {/* Date Range Selector Pills (Reference Style: D M Y All Custom) */}
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
                    padding: '3px 8px',
                    borderRadius: '4px',
                    border: 'none',
                    backgroundColor: selectedDateRange === r ? '#FFFFFF' : 'transparent',
                    color: selectedDateRange === r ? '#111827' : '#6B7280',
                    fontWeight: selectedDateRange === r ? 700 : 500,
                    fontSize: '0.72rem',
                    cursor: 'pointer',
                    textTransform: 'uppercase',
                    boxShadow: selectedDateRange === r ? 'var(--shadow-xs)' : 'none',
                  }}
                >
                  {r}
                </button>
              ))}
            </div>

            <span style={{ fontSize: '0.75rem', color: '#6B7280', fontWeight: 600 }}>↑ 0 - 50,000</span>
          </div>
        </div>

        {/* SVG Multi-Line Chart Canvas with Floating Tooltip (Reference Style) */}
        <div style={{ position: 'relative', width: '100%', height: '150px', margin: '14px 0 10px' }}>
          <svg viewBox="0 0 900 150" style={{ width: '100%', height: '100%', overflow: 'visible' }}>
            <defs>
              <linearGradient id="blueGradient" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor="#0284C7" stopOpacity="0.15" />
                <stop offset="100%" stopColor="#0284C7" stopOpacity="0.0" />
              </linearGradient>
              <linearGradient id="redGradient" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor="#E11D48" stopOpacity="0.15" />
                <stop offset="100%" stopColor="#E11D48" stopOpacity="0.0" />
              </linearGradient>
            </defs>

            {/* Grid Lines */}
            <line x1="0" y1="35" x2="900" y2="35" stroke="#F3F4F6" strokeDasharray="3 3" />
            <line x1="0" y1="75" x2="900" y2="75" stroke="#F3F4F6" strokeDasharray="3 3" />
            <line x1="0" y1="115" x2="900" y2="115" stroke="#F3F4F6" strokeDasharray="3 3" />

            {/* Blue Line (Impressions) */}
            <path
              d="M 0,90 Q 75,50 150,70 T 300,40 T 450,55 T 600,25 T 750,45 T 900,30"
              fill="none"
              stroke="#0284C7"
              strokeWidth="2.5"
            />

            {/* Red/Coral Line (Inquiries) */}
            <path
              d="M 0,130 Q 75,110 150,120 T 300,95 T 450,110 T 600,80 T 750,90 T 900,85"
              fill="none"
              stroke="#E11D48"
              strokeWidth="2.5"
            />

            {/* Active Marker Dot */}
            <circle cx="450" cy="110" r="4.5" fill="#E11D48" stroke="#FFFFFF" strokeWidth="2" />
            <circle cx="450" cy="55" r="4.5" fill="#0284C7" stroke="#FFFFFF" strokeWidth="2" />
          </svg>

          {/* Reference Style Floating Tooltip */}
          <div
            style={{
              position: 'absolute',
              top: '15px',
              left: '48%',
              transform: 'translateX(-50%)',
              backgroundColor: '#FFFFFF',
              border: '1px solid var(--border-subtle)',
              borderRadius: '8px',
              padding: '8px 12px',
              boxShadow: 'var(--shadow-card)',
              fontSize: '0.75rem',
              display: 'flex',
              flexDirection: 'column',
              gap: '4px',
              pointerEvents: 'none',
            }}
          >
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: '8px', color: '#6B7280', fontWeight: 600 }}>
              <span>Jan 17, 26</span>
              <span style={{ color: '#059669', backgroundColor: '#DCFCE7', padding: '1px 4px', borderRadius: '3px', fontWeight: 700 }}>
                +24.8%
              </span>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', gap: '10px' }}>
              <span style={{ color: '#0284C7', fontWeight: 700 }}>{(overview.total_maps_views + overview.total_searches).toLocaleString()} Views</span>
              <span style={{ color: '#059669', fontWeight: 600 }}>+12%</span>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', gap: '10px' }}>
              <span style={{ color: '#E11D48', fontWeight: 700 }}>{overview.total_customer_actions.toLocaleString()} Actions</span>
              <span style={{ color: '#E11D48', fontWeight: 600 }}>+3.4%</span>
            </div>
          </div>
        </div>

        {/* Timeline Baseline */}
        <div style={{ display: 'flex', justifyContent: 'space-between', borderTop: '1px solid #F3F4F6', paddingTop: '10px', fontSize: '0.72rem', color: '#9CA3AF' }}>
          <span>2 May, 25</span>
          <span style={{ color: '#111827', fontWeight: 700 }}>Jan 17, 26</span>
          <span style={{ color: '#059669', fontWeight: 700 }}>Active Peak</span>
          <span>Today</span>
        </div>
      </div>

      {/* 3. Branch Directory & Performance Table (Reference Data Table) */}
      <div className="prody-card" style={{ padding: 0, overflow: 'hidden' }}>
        {/* Controls Header Row */}
        <div
          style={{
            padding: '14px 18px',
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            flexWrap: 'wrap',
            gap: '12px',
            borderBottom: '1px solid var(--border-subtle)',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <span style={{ fontWeight: 800, fontSize: '0.96rem', color: '#111827' }}>All Branch Locations</span>
            <span className="prody-pill grey">{locations.length}</span>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <div style={{ position: 'relative' }}>
              <input
                type="text"
                placeholder="Search branch..."
                value={tableSearch}
                onChange={(e) => setTableSearch(e.target.value)}
                style={{
                  padding: '6px 10px 6px 28px',
                  borderRadius: 'var(--radius-sm)',
                  border: '1px solid var(--border-subtle)',
                  fontSize: '0.78rem',
                  outline: 'none',
                  backgroundColor: '#F9FAFB',
                }}
              />
              <Search size={13} color="#9CA3AF" style={{ position: 'absolute', left: '9px', top: '8px' }} />
            </div>

            <button onClick={() => setIsOnboardingOpen(true)} className="btn btn-coral btn-sm">
              <Plus size={14} />
              <span>Add Location</span>
            </button>
          </div>
        </div>

        {/* Table */}
        <div className="prody-table-wrapper" style={{ border: 'none', borderRadius: 0 }}>
          <table className="prody-table">
            <thead>
              <tr>
                <th style={{ width: '40px' }}>#</th>
                <th>Branch Location</th>
                <th>Category</th>
                <th>City / Area</th>
                <th>Health Score</th>
                <th>Rating & Reviews</th>
                <th>Channel Status</th>
                <th style={{ textAlign: 'right' }}>Action</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((loc, idx) => (
                <tr key={loc.id} style={{ cursor: 'pointer' }} onClick={() => selectLocation(loc.id)}>
                  <td style={{ color: '#9CA3AF', fontWeight: 600, fontSize: '0.78rem' }}>
                    {String(idx + 1).padStart(2, '0')}
                  </td>
                  <td>
                    <div style={{ fontWeight: 700, color: '#111827', fontSize: '0.88rem' }}>{loc.name}</div>
                  </td>
                  <td>
                    <span className="prody-pill blue">{loc.category}</span>
                  </td>
                  <td>
                    <span style={{ fontSize: '0.82rem', color: '#6B7280' }}>{loc.location}</span>
                  </td>
                  <td>
                    <strong style={{ color: loc.health_score >= 80 ? '#059669' : '#D97706', fontSize: '0.9rem' }}>
                      {loc.health_score}/100
                    </strong>
                  </td>
                  <td>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                      <Star size={13} fill="#F59E0B" color="#F59E0B" />
                      <strong style={{ color: '#111827' }}>{loc.average_rating > 0 ? loc.average_rating : '—'}</strong>
                      <span style={{ fontSize: '0.75rem', color: '#9CA3AF' }}>({loc.total_reviews})</span>
                    </div>
                  </td>
                  <td>
                    <span className={`prody-pill ${loc.status === 'Optimal' ? 'green' : (loc.status === 'Good' ? 'peach' : 'red')}`}>
                      {loc.status === 'Optimal' ? 'Google Live' : 'Needs Sync'}
                    </span>
                  </td>
                  <td style={{ textAlign: 'right' }}>
                    <button
                      className="btn btn-secondary btn-sm"
                      onClick={(e) => {
                        e.stopPropagation();
                        selectLocation(loc.id);
                      }}
                    >
                      Manage
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
