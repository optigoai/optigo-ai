// ==================================================
// OptigoAI Enterprise — Reusable BranchCompareList Component
// Standard ranked list with uniform health-score color coding
// Green (≥70) | Amber (50-69) | Red (<50)
// ==================================================

import React from 'react';
import { useLocation } from '../../context/LocationContext';
import { BusinessLocation } from '../../types';
import {
  Star,
  ArrowRight,
  AlertTriangle,
  ChevronRight,
} from 'lucide-react';

interface BranchCompareListProps {
  locations: BusinessLocation[];
  onSelectBranch?: (id: string) => void;
  showMetrics?: boolean;
  maxRows?: number;
  onViewAll?: () => void;
}

export const getHealthBadgeStyle = (score: number) => {
  if (score >= 70) {
    return {
      bg: '#dcfce7',
      text: '#15803d',
      barColor: '#16a34a',
      label: 'Healthy (≥70)',
      borderColor: '#86efac',
      dotColor: '#16a34a',
    };
  }
  if (score >= 50) {
    return {
      bg: '#fef3c7',
      text: '#b45309',
      barColor: '#f59e0b',
      label: 'Attention (50–69)',
      borderColor: '#fde68a',
      dotColor: '#f59e0b',
    };
  }
  return {
    bg: '#fee2e2',
    text: '#b91c1c',
    barColor: '#dc2626',
    label: 'Urgent (<50)',
    borderColor: '#fca5a5',
    dotColor: '#dc2626',
  };
};

export const BranchCompareList: React.FC<BranchCompareListProps> = ({
  locations,
  onSelectBranch,
  showMetrics = true,
  maxRows,
  onViewAll,
}) => {
  const { selectLocation, setActiveFranchiseTab } = useLocation();

  const handleSelect = (id: string) => {
    if (onSelectBranch) {
      onSelectBranch(id);
    } else {
      selectLocation(id);
    }
  };

  const sortedLocations = [...locations].sort((a, b) => (b.health_score || 0) - (a.health_score || 0));
  const displayedLocations = maxRows ? sortedLocations.slice(0, maxRows) : sortedLocations;

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
      {/* Branch List Rows */}
      {displayedLocations.map((loc, idx) => {
        const rank = idx + 1;
        const score = loc.health_score || 0;
        const healthStyle = getHealthBadgeStyle(score);

        // One-line reason if below 70
        let reason = '';
        if (score < 70) {
          if (loc.unreplied_reviews && loc.unreplied_reviews > 0) {
            reason = `${loc.unreplied_reviews} unreplied ${loc.unreplied_reviews === 1 ? 'review' : 'reviews'}`;
          } else if ((loc.completeness_score || 0) < 90) {
            reason = 'Missing profile attributes & photos';
          } else {
            reason = 'Search discovery momentum below benchmark';
          }
        }

        return (
          <div
            key={loc.id}
            onClick={() => handleSelect(loc.id)}
            style={{
              padding: '12px 16px',
              borderRadius: '10px',
              backgroundColor: '#ffffff',
              border: '1px solid #e2e8f0',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              cursor: 'pointer',
              transition: 'all 0.15s ease',
              boxShadow: '0 1px 2px rgba(0, 0, 0, 0.02)',
              gap: '12px',
              flexWrap: 'wrap',
            }}
            onMouseEnter={(e) => {
              e.currentTarget.style.borderColor = '#2563eb';
              e.currentTarget.style.boxShadow = '0 3px 10px rgba(37,99,235,0.06)';
            }}
            onMouseLeave={(e) => {
              e.currentTarget.style.borderColor = '#e2e8f0';
              e.currentTarget.style.boxShadow = '0 1px 2px rgba(0, 0, 0, 0.02)';
            }}
          >
            {/* Left: Rank Badge + Name + Location & Reason */}
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px', minWidth: '200px', flex: 1 }}>
              <span
                style={{
                  width: '26px',
                  height: '26px',
                  borderRadius: '50%',
                  backgroundColor: rank === 1 ? '#fef3c7' : '#f1f5f9',
                  color: rank === 1 ? '#b45309' : '#475569',
                  fontWeight: 800,
                  fontSize: '0.78rem',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  flexShrink: 0,
                }}
              >
                #{rank}
              </span>

              <div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                  <h4 style={{ fontSize: '0.9rem', fontWeight: 800, color: '#0f172a', margin: 0 }}>
                    {loc.name}
                  </h4>
                  <span style={{ fontSize: '0.74rem', color: '#64748b' }}>
                    ({loc.location})
                  </span>
                </div>

                {reason ? (
                  <div style={{ display: 'flex', alignItems: 'center', gap: '4px', marginTop: '2px', color: '#b45309', fontSize: '0.72rem', fontWeight: 600 }}>
                    <AlertTriangle size={11} color="#d97706" />
                    <span>{reason}</span>
                  </div>
                ) : (
                  <span style={{ fontSize: '0.72rem', color: '#64748b' }}>
                    {loc.category || 'Restaurant & Bakery'}
                  </span>
                )}
              </div>
            </div>

            {/* Middle: Health Score with Strict Green/Amber/Red Threshold */}
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <span
                style={{
                  padding: '3px 9px',
                  borderRadius: '7px',
                  fontSize: '0.78rem',
                  fontWeight: 800,
                  backgroundColor: healthStyle.bg,
                  color: healthStyle.text,
                  border: `1px solid ${healthStyle.borderColor}`,
                }}
              >
                {score}/100 Health
              </span>
            </div>

            {/* Right: Reviews & Drilldown Action */}
            {showMetrics && (
              <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '3px', fontSize: '0.8rem' }}>
                  <Star size={13} fill="#f59e0b" color="#f59e0b" />
                  <strong style={{ color: '#0f172a' }}>{loc.average_rating || '—'}</strong>
                  <span style={{ color: '#64748b', fontSize: '0.74rem' }}>({loc.total_reviews || 0})</span>
                </div>

                <div style={{ display: 'flex', alignItems: 'center', gap: '3px', color: '#2563eb', fontWeight: 700, fontSize: '0.78rem' }}>
                  <span>Manage</span>
                  <ArrowRight size={12} />
                </div>
              </div>
            )}
          </div>
        );
      })}

      {/* View All Locations Footer Link if capped */}
      {maxRows && locations.length > maxRows && (
        <div style={{ display: 'flex', justifyContent: 'flex-end', paddingTop: '4px' }}>
          <button
            onClick={() => {
              if (onViewAll) {
                onViewAll();
              } else {
                setActiveFranchiseTab('locations');
              }
            }}
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
              padding: '4px 0',
            }}
          >
            <span>View all {locations.length} locations</span>
            <ChevronRight size={13} />
          </button>
        </div>
      )}
    </div>
  );
};
