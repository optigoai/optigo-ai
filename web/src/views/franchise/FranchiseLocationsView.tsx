// ==================================================
// OptigoAI Enterprise — Prody Light Locations View
// ==================================================

import React, { useState } from 'react';
import { useFranchise } from '../../context/FranchiseContext';
import { useLocation } from '../../context/LocationContext';
import {
  Building2,
  MapPin,
  Star,
  Search,
  Plus,
  ArrowRight,
  ShieldCheck,
  LayoutGrid,
  List,
} from 'lucide-react';

export const FranchiseLocationsView: React.FC = () => {
  const { filteredLocations, searchQuery, setSearchQuery } = useFranchise();
  const { selectLocation, setIsOnboardingOpen } = useLocation();
  const [viewMode, setViewMode] = useState<'grid' | 'table'>('table');

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
      {/* 1. Entity Header */}
      <div className="entity-header-card">
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <div className="entity-icon-badge">
            <Building2 size={26} />
          </div>
          <div>
            <h1 style={{ fontSize: '1.45rem', fontWeight: 800, color: '#111827', lineHeight: 1.2 }}>
              Franchise Locations Directory
            </h1>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginTop: '6px' }}>
              <span className="prody-pill blue">{filteredLocations.length} Locations Managed</span>
              <span className="prody-pill green">Google Business Profiles Live</span>
            </div>
          </div>
        </div>

        <button onClick={() => setIsOnboardingOpen(true)} className="btn btn-coral btn-sm" style={{ gap: '6px' }}>
          <Plus size={14} />
          <span>Add Location</span>
        </button>
      </div>

      {/* 2. Control Bar */}
      <div
        className="prody-card"
        style={{
          padding: '12px 18px',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          flexWrap: 'wrap',
          gap: '12px',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px', flex: 1, maxWidth: '400px' }}>
          <div style={{ position: 'relative', width: '100%' }}>
            <input
              type="text"
              placeholder="Search branch name, category, or city..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              style={{
                width: '100%',
                padding: '7px 12px 7px 30px',
                borderRadius: 'var(--radius-sm)',
                border: '1px solid var(--border-subtle)',
                fontSize: '0.82rem',
                outline: 'none',
                backgroundColor: '#F9FAFB',
              }}
            />
            <Search size={14} color="#9CA3AF" style={{ position: 'absolute', left: '10px', top: '9px' }} />
          </div>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
          <button
            onClick={() => setViewMode('table')}
            className={`btn btn-sm ${viewMode === 'table' ? 'btn-primary' : 'btn-secondary'}`}
          >
            <List size={14} />
          </button>
          <button
            onClick={() => setViewMode('grid')}
            className={`btn btn-sm ${viewMode === 'grid' ? 'btn-primary' : 'btn-secondary'}`}
          >
            <LayoutGrid size={14} />
          </button>
        </div>
      </div>

      {/* 3. Table or Grid */}
      {viewMode === 'table' ? (
        <div className="prody-card" style={{ padding: 0, overflow: 'hidden' }}>
          <div className="prody-table-wrapper" style={{ border: 'none', borderRadius: 0 }}>
            <table className="prody-table">
              <thead>
                <tr>
                  <th style={{ width: '40px' }}>#</th>
                  <th>Branch Location</th>
                  <th>Category</th>
                  <th>City / Area</th>
                  <th>Health Score</th>
                  <th>Rating</th>
                  <th>Map Rank</th>
                  <th>Status</th>
                  <th style={{ textAlign: 'right' }}>Action</th>
                </tr>
              </thead>
              <tbody>
                {filteredLocations.map((loc, idx) => (
                  <tr key={loc.id} style={{ cursor: 'pointer' }} onClick={() => selectLocation(loc.id)}>
                    <td style={{ color: '#9CA3AF', fontWeight: 600, fontSize: '0.78rem' }}>
                      {String(idx + 1).padStart(2, '0')}
                    </td>
                    <td>
                      <div style={{ fontWeight: 700, color: '#111827' }}>{loc.name}</div>
                    </td>
                    <td><span className="prody-pill blue">{loc.category}</span></td>
                    <td><span style={{ fontSize: '0.82rem', color: '#6B7280' }}>{loc.location}</span></td>
                    <td>
                      <strong style={{ color: loc.health_score >= 80 ? '#059669' : '#D97706' }}>
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
                    <td><span className="prody-pill purple">#{loc.google_maps_rank}</span></td>
                    <td>
                      <span className={`prody-pill ${loc.status === 'Optimal' ? 'green' : 'peach'}`}>
                        {loc.status}
                      </span>
                    </td>
                    <td style={{ textAlign: 'right' }}>
                      <button className="btn btn-secondary btn-sm">Manage</button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', gap: '16px' }}>
          {filteredLocations.map((loc) => (
            <div key={loc.id} className="prody-card clickable" onClick={() => selectLocation(loc.id)}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '8px' }}>
                <span className="prody-pill blue">{loc.category}</span>
                <span className={`prody-pill ${loc.status === 'Optimal' ? 'green' : 'peach'}`}>{loc.status}</span>
              </div>
              <h3 style={{ fontSize: '1.05rem', fontWeight: 700, color: '#111827', marginBottom: '2px' }}>{loc.name}</h3>
              <p style={{ fontSize: '0.8rem', color: '#6B7280', marginBottom: '12px' }}>{loc.location}</p>

              <div style={{ display: 'flex', justifyContent: 'space-between', borderTop: '1px solid var(--border-subtle)', paddingTop: '10px', fontSize: '0.82rem' }}>
                <span>Health: <strong style={{ color: loc.health_score >= 80 ? '#059669' : '#D97706' }}>{loc.health_score}/100</strong></span>
                <span style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                  <Star size={12} fill="#F59E0B" color="#F59E0B" /> {loc.average_rating > 0 ? loc.average_rating : '—'}
                </span>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};
