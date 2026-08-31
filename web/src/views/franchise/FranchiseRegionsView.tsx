// ==================================================
// OptigoAI Enterprise — Prody Light Regions View
// ==================================================

import React from 'react';
import { useFranchise } from '../../context/FranchiseContext';
import { useLocation } from '../../context/LocationContext';
import {
  Compass,
  Map,
  Users,
  Star,
  Building2,
  ArrowRight,
} from 'lucide-react';

export const FranchiseRegionsView: React.FC = () => {
  const { regions } = useFranchise();
  const { selectLocation } = useLocation();

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
      {/* 1. Entity Header */}
      <div className="entity-header-card">
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <div className="entity-icon-badge">
            <Compass size={26} />
          </div>
          <div>
            <h1 style={{ fontSize: '1.45rem', fontWeight: 800, color: '#111827', lineHeight: 1.2 }}>
              Regional Performance & Clusters
            </h1>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginTop: '6px' }}>
              <span className="prody-pill blue">{regions.length} Operational Regions</span>
              <span className="prody-pill green">Territory Directors Assigned</span>
            </div>
          </div>
        </div>
      </div>

      {/* 2. Regions Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))', gap: '16px' }}>
        {regions.map((reg) => (
          <div key={reg.region_name} className="prody-card" style={{ display: 'flex', flexDirection: 'column', justifyContent: 'space-between', gap: '14px' }}>
            <div>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
                <span className="prody-pill blue">{reg.location_count} Locations</span>
                <strong style={{ color: reg.average_health_score >= 80 ? '#059669' : '#D97706', fontSize: '0.92rem' }}>
                  {reg.average_health_score}/100 Health
                </strong>
              </div>

              <h3 style={{ fontSize: '1.15rem', fontWeight: 700, color: '#111827', marginBottom: '2px' }}>
                {reg.region_name}
              </h3>
              <span style={{ fontSize: '0.78rem', color: '#6B7280' }}>
                Manager: <strong style={{ color: '#111827' }}>{reg.regional_manager}</strong>
              </span>
            </div>

            {/* Quick Metrics */}
            <div
              style={{
                display: 'grid',
                gridTemplateColumns: '1fr 1fr 1fr',
                gap: '6px',
                padding: '10px',
                backgroundColor: '#F9FAFB',
                borderRadius: 'var(--radius-sm)',
                border: '1px solid var(--border-subtle)',
                fontSize: '0.78rem',
              }}
            >
              <div>
                <span style={{ color: '#9CA3AF', fontSize: '0.68rem', fontWeight: 600 }}>Searches</span>
                <div style={{ fontWeight: 800, color: '#0284C7' }}>{reg.total_monthly_searches.toLocaleString()}</div>
              </div>
              <div>
                <span style={{ color: '#9CA3AF', fontSize: '0.68rem', fontWeight: 600 }}>Actions</span>
                <div style={{ fontWeight: 800, color: '#E11D48' }}>{reg.total_monthly_actions.toLocaleString()}</div>
              </div>
              <div>
                <span style={{ color: '#9CA3AF', fontSize: '0.68rem', fontWeight: 600 }}>Rating</span>
                <div style={{ fontWeight: 800, color: '#111827' }}>{reg.average_rating}★</div>
              </div>
            </div>

            {/* Branch Links */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
              {reg.locations.map((loc) => (
                <div
                  key={loc.id}
                  onClick={() => selectLocation(loc.id)}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    padding: '6px 10px',
                    borderRadius: '4px',
                    backgroundColor: '#FFFFFF',
                    border: '1px solid var(--border-subtle)',
                    cursor: 'pointer',
                    fontSize: '0.8rem',
                  }}
                >
                  <span style={{ fontWeight: 600, color: '#111827' }}>{loc.name}</span>
                  <ArrowRight size={12} color="#9CA3AF" />
                </div>
              ))}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};
