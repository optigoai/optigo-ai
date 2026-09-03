// ==================================================
// OptigoAI Enterprise — Clean Global Filter Bar Component
// Single branch selector + 7D/30D/90D/YTD date range selector
// No duplicate breadcrumbs or duplicate sync buttons
// ==================================================

import React from 'react';
import { useFranchise, DateRange } from '../../context/FranchiseContext';
import { useLocation } from '../../context/LocationContext';
import {
  Building2,
  Calendar,
  Layers,
} from 'lucide-react';

interface GlobalFilterBarProps {
  pageTitle: string;
  showDateFilter?: boolean;
  showBranchSelector?: boolean;
}

export const GlobalFilterBar: React.FC<GlobalFilterBarProps> = ({
  pageTitle,
  showDateFilter = true,
  showBranchSelector = true,
}) => {
  const { locations, selectedDateRange, setSelectedDateRange } = useFranchise();
  const { scope, activeLocation, selectLocation, switchToFranchiseView } = useLocation();

  const dateRanges: { id: DateRange; label: string }[] = [
    { id: '7d', label: '7D' },
    { id: '30d', label: '30D' },
    { id: '90d', label: '90D' },
    { id: 'ytd', label: 'YTD' },
  ];

  return (
    <div
      style={{
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        flexWrap: 'wrap',
        gap: '12px',
        padding: '10px 18px',
        backgroundColor: '#ffffff',
        borderRadius: '12px',
        border: '1px solid #e2e8f0',
        boxShadow: '0 1px 2px rgba(0, 0, 0, 0.02)',
      }}
    >
      {/* Left: Active Scope / Page Context Badge */}
      <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
          <Layers size={14} color="#2563eb" />
          <span style={{ fontSize: '0.84rem', fontWeight: 800, color: '#0f172a' }}>
            {pageTitle}
          </span>
        </div>

        <span style={{ color: '#cbd5e1', fontSize: '0.8rem' }}>•</span>

        <span style={{ fontSize: '0.76rem', color: '#64748b', fontWeight: 500 }}>
          {scope === 'branch' && activeLocation
            ? `Filtered to ${activeLocation.name}`
            : `Network-wide across all ${locations.length} locations`}
        </span>
      </div>

      {/* Right: Controls & Global Filters */}
      <div style={{ display: 'flex', alignItems: 'center', gap: '12px', flexWrap: 'wrap' }}>
        {/* Branch Filter Selector */}
        {showBranchSelector && (
          <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
            <Building2 size={13} color="#64748b" />
            <select
              value={scope === 'branch' && activeLocation ? activeLocation.id : 'all'}
              onChange={(e) => {
                if (e.target.value === 'all') {
                  switchToFranchiseView();
                } else {
                  selectLocation(e.target.value);
                }
              }}
              style={{
                padding: '5px 10px',
                borderRadius: '8px',
                border: '1px solid #cbd5e1',
                backgroundColor: '#f8fafc',
                fontSize: '0.78rem',
                fontWeight: 700,
                color: '#0f172a',
                outline: 'none',
                cursor: 'pointer',
              }}
            >
              <option value="all">All Branches ({locations.length})</option>
              {locations.map((loc) => (
                <option key={loc.id} value={loc.id}>
                  {loc.name} ({loc.location})
                </option>
              ))}
            </select>
          </div>
        )}

        {/* Date Range Selector Pills */}
        {showDateFilter && (
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              backgroundColor: '#f1f5f9',
              padding: '2px',
              borderRadius: '8px',
              border: '1px solid #e2e8f0',
            }}
          >
            {dateRanges.map((r) => (
              <button
                key={r.id}
                onClick={() => setSelectedDateRange(r.id)}
                style={{
                  padding: '4px 9px',
                  borderRadius: '6px',
                  border: 'none',
                  backgroundColor: selectedDateRange === r.id ? '#ffffff' : 'transparent',
                  color: selectedDateRange === r.id ? '#0f172a' : '#64748b',
                  fontWeight: selectedDateRange === r.id ? 800 : 600,
                  fontSize: '0.74rem',
                  cursor: 'pointer',
                  boxShadow: selectedDateRange === r.id ? '0 1px 2px rgba(0, 0, 0, 0.05)' : 'none',
                  transition: 'all 0.15s ease',
                }}
              >
                {r.label}
              </button>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};
