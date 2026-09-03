// ==================================================
// OptigoAI Enterprise — Enhanced Modern SaaS TopBar
// Clean hierarchy, unified location switcher, zero crowding,
// responsive spacing, and polished design system controls
// ==================================================

import React, { useState, useRef, useEffect } from 'react';
import { useLocation } from '../../context/LocationContext';
import { useFranchise, DateRange } from '../../context/FranchiseContext';
import {
  ChevronRight,
  ArrowLeft,
  RefreshCw,
  Building2,
  Sparkles,
  Globe,
  ChevronsUpDown,
  Search,
  Check,
  SlidersHorizontal,
  Plus,
} from 'lucide-react';
import { CmoAssistantDrawer } from './CmoAssistantDrawer';
import { LocationSwitcherModal } from './LocationSwitcherModal';

export const TopBar: React.FC = () => {
  const {
    scope,
    activeLocation,
    activeFranchiseTab,
    activeBranchTab,
    selectLocation,
    switchToFranchiseView,
    setActiveFranchiseTab,
    setIsLocationSwitcherOpen,
    setIsOnboardingOpen,
  } = useLocation();

  const {
    locations,
    selectedDateRange,
    setSelectedDateRange,
    triggerBulkSync,
    isSyncing,
  } = useFranchise();

  const [isCmoDrawerOpen, setIsCmoDrawerOpen] = useState(false);
  const [isLocationDropdownOpen, setIsLocationDropdownOpen] = useState(false);
  const [locationSearch, setLocationSearch] = useState('');
  const dropdownRef = useRef<HTMLDivElement>(null);

  // Close dropdown on outside click
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setIsLocationDropdownOpen(false);
      }
    };
    if (isLocationDropdownOpen) {
      document.addEventListener('mousedown', handleClickOutside);
    }
    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, [isLocationDropdownOpen]);

  const dateRanges: { id: DateRange; label: string }[] = [
    { id: '7d', label: '7D' },
    { id: '30d', label: '30D' },
    { id: '90d', label: '90D' },
    { id: 'ytd', label: 'YTD' },
  ];

  const getTabTitle = () => {
    if (scope === 'franchise') {
      switch (activeFranchiseTab) {
        case 'overview': return 'Home';
        case 'locations': return 'Locations';
        case 'insights': return 'Insights';
        case 'ai-analysis':
        case 'advisor': return 'AI Analysis';
        case 'reports': return 'Reports';
        case 'regions': return 'Regions';
        case 'team': return 'People';
        case 'audit': return 'Profile Audit';
        default: return activeFranchiseTab.charAt(0).toUpperCase() + activeFranchiseTab.slice(1);
      }
    } else {
      switch (activeBranchTab) {
        case 'dashboard': return 'Dashboard';
        case 'profile': return 'Google Profile';
        case 'seo': return 'Local SEO';
        case 'reviews': return 'Reviews';
        case 'content': return 'Marketing Studio';
        case 'recommendations': return 'Directives';
        case 'website': return 'Website Builder';
        case 'cmo': return 'AI Advisor';
        case 'settings': return 'Settings';
        default: return activeBranchTab.charAt(0).toUpperCase() + activeBranchTab.slice(1);
      }
    }
  };

  const tabTitle = getTabTitle();

  const filteredLocations = locations.filter(
    (loc) =>
      loc.name.toLowerCase().includes(locationSearch.toLowerCase()) ||
      loc.location.toLowerCase().includes(locationSearch.toLowerCase())
  );

  const handleSelectBranch = (locId: string) => {
    selectLocation(locId);
    setIsLocationDropdownOpen(false);
    setLocationSearch('');
  };

  const handleSwitchToNetwork = () => {
    switchToFranchiseView();
    setIsLocationDropdownOpen(false);
    setLocationSearch('');
  };

  return (
    <>
      <header
        className="app-topbar"
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          padding: '0 28px',
          height: '68px',
          borderBottom: '1px solid #e2e8f0',
          backgroundColor: '#ffffff',
          position: 'sticky',
          top: 0,
          zIndex: 40,
          flexShrink: 0,
          gap: '16px',
          boxShadow: '0 1px 3px rgba(15, 23, 42, 0.03)',
        }}
      >
        {/* Left: Breadcrumb Navigation with Integrated Workspace Switcher */}
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
            minWidth: 0,
            overflow: 'hidden',
          }}
        >
          {/* Back button (when in branch view to quickly jump back to franchise network) */}
          {scope === 'branch' && (
            <button
              onClick={switchToFranchiseView}
              style={{
                background: '#f8fafc',
                border: '1px solid #e2e8f0',
                color: '#475569',
                cursor: 'pointer',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                width: '32px',
                height: '32px',
                borderRadius: '8px',
                transition: 'all 0.15s ease',
                flexShrink: 0,
              }}
              title="Return to Network Overview"
              onMouseEnter={(e) => {
                (e.currentTarget as HTMLElement).style.backgroundColor = '#eff6ff';
                (e.currentTarget as HTMLElement).style.color = '#2563eb';
                (e.currentTarget as HTMLElement).style.borderColor = '#bfdbfe';
              }}
              onMouseLeave={(e) => {
                (e.currentTarget as HTMLElement).style.backgroundColor = '#f8fafc';
                (e.currentTarget as HTMLElement).style.color = '#475569';
                (e.currentTarget as HTMLElement).style.borderColor = '#e2e8f0';
              }}
            >
              <ArrowLeft size={16} />
            </button>
          )}

          {/* Root Network Link */}
          <button
            onClick={switchToFranchiseView}
            style={{
              background: 'transparent',
              border: 'none',
              cursor: 'pointer',
              color: scope === 'franchise' ? '#0f172a' : '#64748b',
              fontWeight: 700,
              fontSize: '0.88rem',
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              padding: '4px 6px',
              borderRadius: '6px',
              transition: 'all 0.15s ease',
              flexShrink: 0,
            }}
            onMouseEnter={(e) => {
              (e.currentTarget as HTMLElement).style.backgroundColor = '#f1f5f9';
              (e.currentTarget as HTMLElement).style.color = '#0f172a';
            }}
            onMouseLeave={(e) => {
              (e.currentTarget as HTMLElement).style.backgroundColor = 'transparent';
              (e.currentTarget as HTMLElement).style.color = scope === 'franchise' ? '#0f172a' : '#64748b';
            }}
          >
            <span>Network</span>
          </button>

          <ChevronRight size={14} color="#cbd5e1" style={{ flexShrink: 0 }} />

          {/* Workspace / Location Switcher Badge Button */}
          <div style={{ position: 'relative', flexShrink: 0 }} ref={dropdownRef}>
            <button
              onClick={() => setIsLocationDropdownOpen(!isLocationDropdownOpen)}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '6px',
                background: scope === 'branch' ? '#eff6ff' : '#f0fdf4',
                border: scope === 'branch' ? '1px solid #bfdbfe' : '1px solid #bbf7d0',
                color: scope === 'branch' ? '#1d4ed8' : '#15803d',
                fontWeight: 700,
                cursor: 'pointer',
                fontSize: '0.84rem',
                padding: '5px 10px',
                borderRadius: '8px',
                transition: 'all 0.15s ease',
              }}
              title="Click to switch workspace branch"
            >
              {scope === 'branch' && activeLocation ? (
                <>
                  <Building2 size={14} color="#2563eb" />
                  <span style={{ maxWidth: '170px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                    {activeLocation.name}
                  </span>
                </>
              ) : (
                <>
                  <Globe size={14} color="#16a34a" />
                  <span>All Locations ({locations.length})</span>
                </>
              )}
              <ChevronsUpDown size={13} color={scope === 'branch' ? '#3b82f6' : '#22c55e'} />
            </button>

            {/* Fast Floating Dropdown Popover */}
            {isLocationDropdownOpen && (
              <div
                style={{
                  position: 'absolute',
                  top: 'calc(100% + 8px)',
                  left: 0,
                  width: '290px',
                  backgroundColor: '#ffffff',
                  border: '1px solid #e2e8f0',
                  borderRadius: '14px',
                  boxShadow: '0 10px 30px -4px rgba(15, 23, 42, 0.12), 0 4px 12px -2px rgba(15, 23, 42, 0.06)',
                  padding: '6px',
                  zIndex: 100,
                  display: 'flex',
                  flexDirection: 'column',
                  gap: '4px',
                }}
              >
                {/* Search Input (when network has multiple locations) */}
                {locations.length > 3 && (
                  <div style={{ padding: '4px 6px 6px' }}>
                    <div
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: '8px',
                        background: '#f8fafc',
                        border: '1px solid #e2e8f0',
                        borderRadius: '8px',
                        padding: '6px 10px',
                      }}
                    >
                      <Search size={14} color="#94a3b8" />
                      <input
                        type="text"
                        placeholder="Search locations..."
                        value={locationSearch}
                        onChange={(e) => setLocationSearch(e.target.value)}
                        style={{
                          border: 'none',
                          background: 'transparent',
                          outline: 'none',
                          fontSize: '0.82rem',
                          width: '100%',
                          color: '#0f172a',
                        }}
                        autoFocus
                      />
                    </div>
                  </div>
                )}

                {/* Option 1: Franchise Roll-Up */}
                <button
                  onClick={handleSwitchToNetwork}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    padding: '8px 10px',
                    borderRadius: '8px',
                    border: 'none',
                    background: scope === 'franchise' ? '#eff6ff' : 'transparent',
                    color: scope === 'franchise' ? '#1d4ed8' : '#334155',
                    fontWeight: scope === 'franchise' ? 700 : 600,
                    fontSize: '0.84rem',
                    cursor: 'pointer',
                    textAlign: 'left',
                    width: '100%',
                    transition: 'all 0.1s ease',
                  }}
                  onMouseEnter={(e) => {
                    if (scope !== 'franchise') (e.currentTarget as HTMLElement).style.backgroundColor = '#f8fafc';
                  }}
                  onMouseLeave={(e) => {
                    if (scope !== 'franchise') (e.currentTarget as HTMLElement).style.backgroundColor = 'transparent';
                  }}
                >
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                    <Globe size={15} color={scope === 'franchise' ? '#2563eb' : '#64748b'} />
                    <span>All Locations (Network View)</span>
                  </div>
                  {scope === 'franchise' && <Check size={14} color="#2563eb" />}
                </button>

                {/* Section Divider */}
                <div style={{ height: '1px', backgroundColor: '#f1f5f9', margin: '2px 0' }} />

                {/* Section: Branches List */}
                <div
                  style={{
                    maxHeight: '210px',
                    overflowY: 'auto',
                    display: 'flex',
                    flexDirection: 'column',
                    gap: '2px',
                  }}
                >
                  {filteredLocations.map((loc) => {
                    const isSelected = scope === 'branch' && activeLocation?.id === loc.id;
                    return (
                      <button
                        key={loc.id}
                        onClick={() => handleSelectBranch(loc.id)}
                        style={{
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'space-between',
                          padding: '7px 10px',
                          borderRadius: '8px',
                          border: 'none',
                          background: isSelected ? '#eff6ff' : 'transparent',
                          color: isSelected ? '#1d4ed8' : '#334155',
                          fontWeight: isSelected ? 700 : 500,
                          fontSize: '0.84rem',
                          cursor: 'pointer',
                          textAlign: 'left',
                          width: '100%',
                          transition: 'all 0.1s ease',
                        }}
                        onMouseEnter={(e) => {
                          if (!isSelected) (e.currentTarget as HTMLElement).style.backgroundColor = '#f8fafc';
                        }}
                        onMouseLeave={(e) => {
                          if (!isSelected) (e.currentTarget as HTMLElement).style.backgroundColor = 'transparent';
                        }}
                      >
                        <div style={{ minWidth: 0, paddingRight: '8px' }}>
                          <div style={{ whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', fontWeight: isSelected ? 700 : 600 }}>
                            {loc.name}
                          </div>
                          <div style={{ fontSize: '0.72rem', color: '#64748b', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                            {loc.location}
                          </div>
                        </div>
                        {isSelected && <Check size={14} color="#2563eb" style={{ flexShrink: 0 }} />}
                      </button>
                    );
                  })}
                </div>

                {/* Section Footer: Directory and Add Branch */}
                <div
                  style={{
                    borderTop: '1px solid #f1f5f9',
                    paddingTop: '6px',
                    marginTop: '2px',
                    display: 'flex',
                    justifyContent: 'space-between',
                    alignItems: 'center',
                    padding: '6px 8px 2px',
                  }}
                >
                  <button
                    onClick={() => {
                      setIsLocationDropdownOpen(false);
                      setIsLocationSwitcherOpen(true);
                    }}
                    style={{
                      background: 'transparent',
                      border: 'none',
                      color: '#1255E6',
                      fontSize: '0.76rem',
                      fontWeight: 700,
                      cursor: 'pointer',
                      display: 'flex',
                      alignItems: 'center',
                      gap: '4px',
                      padding: '3px 6px',
                      borderRadius: '6px',
                    }}
                  >
                    <SlidersHorizontal size={12} />
                    <span>Directory View</span>
                  </button>

                  <button
                    onClick={() => {
                      setIsLocationDropdownOpen(false);
                      setIsOnboardingOpen(true);
                    }}
                    style={{
                      background: 'transparent',
                      border: 'none',
                      color: '#1255E6',
                      fontSize: '0.76rem',
                      fontWeight: 700,
                      cursor: 'pointer',
                      display: 'flex',
                      alignItems: 'center',
                      gap: '4px',
                      padding: '3px 6px',
                      borderRadius: '6px',
                    }}
                  >
                    <Plus size={12} />
                    <span>Add Branch</span>
                  </button>
                </div>
              </div>
            )}
          </div>

          <ChevronRight size={14} color="#cbd5e1" style={{ flexShrink: 0 }} />

          {/* Active Page / Tab Title */}
          <span
            style={{
              color: '#0f172a',
              fontWeight: 800,
              fontSize: '0.96rem',
              letterSpacing: '-0.2px',
              whiteSpace: 'nowrap',
              flexShrink: 0,
            }}
          >
            {tabTitle}
          </span>

          {/* Subtitle / Scope Pill (hides gracefully on narrower displays) */}
          <span
            className="topbar-scope-tag"
            style={{
              fontSize: '0.74rem',
              color: '#64748b',
              backgroundColor: '#f8fafc',
              border: '1px solid #e2e8f0',
              padding: '2px 8px',
              borderRadius: '6px',
              fontWeight: 600,
              whiteSpace: 'nowrap',
              marginLeft: '4px',
              flexShrink: 0,
            }}
          >
            {scope === 'branch' && activeLocation
              ? activeLocation.location
              : `${locations.length} Locations`}
          </span>
        </div>

        {/* Right: Unified, Compact Controls (Date Range + Sync + AI Advisor) */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px', flexShrink: 0 }}>
          {/* Segmented Date Range Selector */}
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              backgroundColor: '#f1f5f9',
              padding: '3px',
              borderRadius: '10px',
              border: '1px solid #e2e8f0',
              height: '36px',
            }}
          >
            {dateRanges.map((r) => (
              <button
                key={r.id}
                onClick={() => setSelectedDateRange(r.id)}
                style={{
                  height: '28px',
                  padding: '0 10px',
                  borderRadius: '7px',
                  border: 'none',
                  backgroundColor: selectedDateRange === r.id ? '#ffffff' : 'transparent',
                  color: selectedDateRange === r.id ? '#0f172a' : '#64748b',
                  fontWeight: selectedDateRange === r.id ? 800 : 600,
                  fontSize: '0.78rem',
                  cursor: 'pointer',
                  boxShadow: selectedDateRange === r.id ? '0 1px 2px rgba(15, 23, 42, 0.08)' : 'none',
                  transition: 'all 0.15s ease',
                }}
              >
                {r.label}
              </button>
            ))}
          </div>

          {/* Live Sync Action Button */}
          <button
            onClick={triggerBulkSync}
            disabled={isSyncing}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              background: '#ffffff',
              border: '1px solid #e2e8f0',
              borderRadius: '10px',
              color: '#334155',
              fontSize: '0.82rem',
              fontWeight: 700,
              cursor: 'pointer',
              padding: '0 14px',
              height: '36px',
              boxShadow: '0 1px 2px rgba(15, 23, 42, 0.04)',
              transition: 'all 0.15s ease',
            }}
            title="Synchronize Google Business Profiles & Network Data"
            onMouseEnter={(e) => {
              (e.currentTarget as HTMLElement).style.backgroundColor = '#f8fafc';
              (e.currentTarget as HTMLElement).style.borderColor = '#cbd5e1';
            }}
            onMouseLeave={(e) => {
              (e.currentTarget as HTMLElement).style.backgroundColor = '#ffffff';
              (e.currentTarget as HTMLElement).style.borderColor = '#e2e8f0';
            }}
          >
            <RefreshCw size={14} className={isSyncing ? 'spin-anim' : ''} color="#1255E6" />
            <span>{isSyncing ? 'Syncing...' : 'Sync Live'}</span>
          </button>

          {/* AI Advisor Button with Premium Brand Gradient */}
          <button
            onClick={() => {
              if (scope === 'franchise') {
                setActiveFranchiseTab('ai-analysis');
              } else {
                setIsCmoDrawerOpen(true);
              }
            }}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              fontSize: '0.82rem',
              fontWeight: 700,
              padding: '0 15px',
              height: '36px',
              borderRadius: '10px',
              background: 'linear-gradient(135deg, #1255E6 0%, #1A64F5 100%)',
              border: '1px solid #0F46CB',
              color: '#ffffff',
              cursor: 'pointer',
              boxShadow: '0 2px 8px rgba(18, 85, 230, 0.25)',
              transition: 'all 0.15s ease',
            }}
            onMouseEnter={(e) => {
              (e.currentTarget as HTMLElement).style.opacity = '0.92';
              (e.currentTarget as HTMLElement).style.transform = 'translateY(-1px)';
            }}
            onMouseLeave={(e) => {
              (e.currentTarget as HTMLElement).style.opacity = '1';
              (e.currentTarget as HTMLElement).style.transform = 'translateY(0)';
            }}
          >
            <Sparkles size={14} color="#ffffff" />
            <span>AI Advisor</span>
          </button>
        </div>
      </header>

      {/* Slide-out Marketing Advisor Drawer */}
      <CmoAssistantDrawer isOpen={isCmoDrawerOpen} onClose={() => setIsCmoDrawerOpen(false)} />

      {/* Comprehensive Location Switcher Directory Modal */}
      <LocationSwitcherModal />
    </>
  );
};
