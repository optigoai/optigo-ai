// ==================================================
// OptigoAI Enterprise — Light Location Switcher Modal
// ==================================================

import React, { useState } from 'react';
import { useLocation } from '../../context/LocationContext';
import { useFranchise } from '../../context/FranchiseContext';
import {
  Building2,
  Search,
  X,
  MapPin,
  Star,
  ShieldCheck,
  Check,
  Plus,
} from 'lucide-react';

export const LocationSwitcherModal: React.FC = () => {
  const {
    scope,
    activeLocation,
    isLocationSwitcherOpen,
    setIsLocationSwitcherOpen,
    selectLocation,
    switchToFranchiseView,
    setIsOnboardingOpen,
  } = useLocation();

  const { locations } = useFranchise();
  const [search, setSearch] = useState('');

  if (!isLocationSwitcherOpen) return null;

  const filtered = locations.filter(
    (loc) =>
      loc.name.toLowerCase().includes(search.toLowerCase()) ||
      loc.location.toLowerCase().includes(search.toLowerCase()) ||
      loc.category.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div className="modal-overlay" onClick={() => setIsLocationSwitcherOpen(false)}>
      <div className="modal-container" onClick={(e) => e.stopPropagation()}>
        {/* Header */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '18px' }}>
          <div>
            <h3 style={{ fontSize: '1.2rem', fontWeight: 800, color: 'var(--text-primary)' }}>
              Switch Workspace Location
            </h3>
            <p style={{ fontSize: '0.82rem', color: 'var(--text-muted)' }}>
              Select a single branch to manage operations or view the entire franchise network
            </p>
          </div>
          <button
            onClick={() => setIsLocationSwitcherOpen(false)}
            style={{ background: 'transparent', border: 'none', color: '#94A3B8', cursor: 'pointer' }}
          >
            <X size={20} />
          </button>
        </div>

        {/* Search */}
        <div className="search-box" style={{ marginBottom: '16px' }}>
          <Search size={16} color="#94A3B8" />
          <input
            type="text"
            className="optigo-input"
            placeholder="Search branches by name, city, or category..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            autoFocus
          />
        </div>

        {/* Option 1: Franchise Roll-Up */}
        <div
          onClick={switchToFranchiseView}
          style={{
            padding: '14px 16px',
            borderRadius: 'var(--radius-md)',
            backgroundColor: scope === 'franchise' ? 'var(--primary-50)' : 'var(--bg-surface-subtle)',
            border: scope === 'franchise' ? '1px solid var(--primary-200)' : '1px solid var(--border-subtle)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            cursor: 'pointer',
            marginBottom: '12px',
            transition: 'all 0.15s ease',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            <div
              style={{
                width: '36px',
                height: '36px',
                borderRadius: '8px',
                backgroundColor: '#2563EB',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: '#FFFFFF',
              }}
            >
              <Building2 size={18} />
            </div>
            <div>
              <div style={{ fontWeight: 700, fontSize: '0.9rem', color: 'var(--text-primary)' }}>
                All Franchise Locations (Overview)
              </div>
              <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                Consolidated performance metrics & regional benchmarks
              </div>
            </div>
          </div>
          {scope === 'franchise' && <Check size={18} color="var(--primary-600)" />}
        </div>

        {/* Branches Header */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', margin: '14px 0 8px' }}>
          <span style={{ fontSize: '0.72rem', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
            Branch Locations ({filtered.length})
          </span>
          <button
            onClick={() => {
              setIsLocationSwitcherOpen(false);
              setIsOnboardingOpen(true);
            }}
            style={{
              background: 'transparent',
              border: 'none',
              color: 'var(--primary-600)',
              fontSize: '0.75rem',
              fontWeight: 600,
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: '4px',
            }}
          >
            <Plus size={14} />
            <span>Add Branch</span>
          </button>
        </div>

        {/* Branches List */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', maxHeight: '300px', overflowY: 'auto' }}>
          {filtered.map((loc) => {
            const isSelected = scope === 'branch' && activeLocation?.id === loc.id;
            return (
              <div
                key={loc.id}
                onClick={() => selectLocation(loc.id)}
                style={{
                  padding: '12px 16px',
                  borderRadius: 'var(--radius-md)',
                  backgroundColor: isSelected ? 'var(--primary-50)' : '#FFFFFF',
                  border: isSelected ? '1px solid var(--primary-200)' : '1px solid var(--border-subtle)',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  cursor: 'pointer',
                  transition: 'all 0.15s ease',
                }}
                onMouseEnter={(e) => {
                  if (!isSelected) (e.currentTarget as HTMLElement).style.backgroundColor = '#F8FAFC';
                }}
                onMouseLeave={(e) => {
                  if (!isSelected) (e.currentTarget as HTMLElement).style.backgroundColor = '#FFFFFF';
                }}
              >
                <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                  <div
                    style={{
                      width: '36px',
                      height: '36px',
                      borderRadius: '8px',
                      backgroundColor: 'var(--bg-surface-subtle)',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      color: 'var(--primary-600)',
                    }}
                  >
                    <MapPin size={18} />
                  </div>
                  <div>
                    <div style={{ fontWeight: 700, fontSize: '0.88rem', color: 'var(--text-primary)' }}>
                      {loc.name}
                    </div>
                    <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                      {loc.location} • Health: <strong style={{ color: loc.health_score >= 80 ? '#047857' : '#B45309' }}>{loc.health_score}/100</strong>
                    </div>
                  </div>
                </div>

                {isSelected && <Check size={18} color="var(--primary-600)" />}
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
};
