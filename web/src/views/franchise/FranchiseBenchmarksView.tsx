// ==================================================
// OptigoAI Enterprise — Prody Light Benchmarks View
// ==================================================

import React from 'react';
import { useFranchise } from '../../context/FranchiseContext';
import { useLocation } from '../../context/LocationContext';
import {
  BarChart3,
  TrendingUp,
  TrendingDown,
  Star,
} from 'lucide-react';

export const FranchiseBenchmarksView: React.FC = () => {
  const { benchmarks, locations } = useFranchise();
  const { selectLocation } = useLocation();

  const averages = benchmarks.franchise_averages || {
    health_score: 85,
    rating: 4.6,
    reviews_per_location: 45,
    completeness_score: 90,
    monthly_actions: 520,
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
      {/* 1. Entity Header */}
      <div className="entity-header-card">
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <div className="entity-icon-badge">
            <BarChart3 size={26} />
          </div>
          <div>
            <h1 style={{ fontSize: '1.45rem', fontWeight: 800, color: '#111827', lineHeight: 1.2 }}>
              Cross-Branch Benchmark Leaderboard
            </h1>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginTop: '6px' }}>
              <span className="prody-pill blue">{locations.length} Locations Benchmarked</span>
              <span className="prody-pill green">Network Baseline: {averages.health_score}/100</span>
            </div>
          </div>
        </div>
      </div>

      {/* 2. 4 Quick Stat Boxes */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '16px' }}>
        <div className="prody-card">
          <span style={{ fontSize: '0.75rem', fontWeight: 700, color: '#6B7280', textTransform: 'uppercase' }}>
            Avg Health Score
          </span>
          <div style={{ fontSize: '1.8rem', fontWeight: 800, color: '#059669', marginTop: '4px' }}>
            {averages.health_score}/100
          </div>
          <span style={{ fontSize: '0.75rem', color: '#6B7280' }}>Franchise benchmark</span>
        </div>

        <div className="prody-card">
          <span style={{ fontSize: '0.75rem', fontWeight: 700, color: '#6B7280', textTransform: 'uppercase' }}>
            Avg Google Rating
          </span>
          <div style={{ fontSize: '1.8rem', fontWeight: 800, color: '#111827', marginTop: '4px' }}>
            {averages.rating}★
          </div>
          <span style={{ fontSize: '0.75rem', color: '#6B7280' }}>Across all branches</span>
        </div>

        <div className="prody-card">
          <span style={{ fontSize: '0.75rem', fontWeight: 700, color: '#6B7280', textTransform: 'uppercase' }}>
            Avg Reviews / Branch
          </span>
          <div style={{ fontSize: '1.8rem', fontWeight: 800, color: '#0284C7', marginTop: '4px' }}>
            {averages.reviews_per_location}
          </div>
          <span style={{ fontSize: '0.75rem', color: '#6B7280' }}>Verified feedback</span>
        </div>

        <div className="prody-card">
          <span style={{ fontSize: '0.75rem', fontWeight: 700, color: '#6B7280', textTransform: 'uppercase' }}>
            Avg Customer Actions
          </span>
          <div style={{ fontSize: '1.8rem', fontWeight: 800, color: '#E11D48', marginTop: '4px' }}>
            {averages.monthly_actions}
          </div>
          <span style={{ fontSize: '0.75rem', color: '#6B7280' }}>Calls, clicks, directions</span>
        </div>
      </div>

      {/* 3. Table */}
      <div className="prody-card" style={{ padding: 0, overflow: 'hidden' }}>
        <div className="prody-table-wrapper" style={{ border: 'none', borderRadius: 0 }}>
          <table className="prody-table">
            <thead>
              <tr>
                <th style={{ width: '40px' }}>Rank</th>
                <th>Branch Location</th>
                <th>Health Score</th>
                <th>Delta vs Avg</th>
                <th>Average Rating</th>
                <th>Total Reviews</th>
                <th>Map Rank</th>
                <th style={{ textAlign: 'right' }}>Action</th>
              </tr>
            </thead>
            <tbody>
              {locations.map((loc, idx) => {
                const rank = idx + 1;
                const delta = loc.health_score - averages.health_score;

                return (
                  <tr key={loc.id} style={{ cursor: 'pointer' }} onClick={() => selectLocation(loc.id)}>
                    <td style={{ color: '#9CA3AF', fontWeight: 700, fontSize: '0.8rem' }}>
                      {String(rank).padStart(2, '0')}
                    </td>
                    <td>
                      <div style={{ fontWeight: 700, color: '#111827' }}>{loc.name}</div>
                      <div style={{ fontSize: '0.78rem', color: '#6B7280' }}>{loc.location}</div>
                    </td>
                    <td>
                      <strong style={{ color: loc.health_score >= 80 ? '#059669' : '#D97706' }}>
                        {loc.health_score}/100
                      </strong>
                    </td>
                    <td>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '4px', color: delta >= 0 ? '#059669' : '#DC2626', fontWeight: 600, fontSize: '0.82rem' }}>
                        {delta >= 0 ? <TrendingUp size={13} /> : <TrendingDown size={13} />}
                        <span>{delta >= 0 ? `+${delta}` : delta} pts</span>
                      </div>
                    </td>
                    <td>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                        <Star size={13} fill="#F59E0B" color="#F59E0B" />
                        <strong style={{ color: '#111827' }}>{loc.average_rating > 0 ? loc.average_rating : '—'}</strong>
                      </div>
                    </td>
                    <td><span style={{ color: '#4B5563', fontSize: '0.84rem' }}>{loc.total_reviews} reviews</span></td>
                    <td><span className="prody-pill purple">#{loc.google_maps_rank}</span></td>
                    <td style={{ textAlign: 'right' }}>
                      <button className="btn btn-secondary btn-sm">Drill Down</button>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
