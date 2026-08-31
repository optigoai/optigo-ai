// ==================================================
// OptigoAI Enterprise — Prody Light Minimalist TopBar
// ==================================================

import React, { useState } from 'react';
import { useLocation } from '../../context/LocationContext';
import { useFranchise, DateRange } from '../../context/FranchiseContext';
import {
  Folder,
  ChevronRight,
  ArrowLeft,
  Share2,
  SlidersHorizontal,
  RefreshCw,
  MessageSquare,
  Building2,
  MoreHorizontal,
} from 'lucide-react';
import { CmoAssistantDrawer } from './CmoAssistantDrawer';
import { LocationSwitcherModal } from './LocationSwitcherModal';

export const TopBar: React.FC = () => {
  const { scope, activeLocation, activeFranchiseTab, activeBranchTab, switchToFranchiseView, setIsLocationSwitcherOpen } = useLocation();
  const { triggerBulkSync, isSyncing } = useFranchise();

  const [isCmoDrawerOpen, setIsCmoDrawerOpen] = useState(false);

  const tabTitle =
    scope === 'franchise'
      ? (activeFranchiseTab.charAt(0).toUpperCase() + activeFranchiseTab.slice(1))
      : (activeBranchTab.charAt(0).toUpperCase() + activeBranchTab.slice(1));

  return (
    <>
      <header className="app-topbar">
        {/* Left: Breadcrumbs (Reference Style: ← 📁 Projects > 📁 Construction > 🏢 House Spectrum) */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '0.84rem' }}>
          {scope === 'branch' ? (
            <button
              onClick={switchToFranchiseView}
              style={{
                background: 'transparent',
                border: 'none',
                color: '#6B7280',
                cursor: 'pointer',
                display: 'flex',
                alignItems: 'center',
                padding: '2px',
              }}
              title="Back to Franchise Overview"
            >
              <ArrowLeft size={15} />
            </button>
          ) : null}

          <div style={{ display: 'flex', alignItems: 'center', gap: '6px', color: '#6B7280' }}>
            <Folder size={14} color="#9CA3AF" />
            <span>Network</span>
          </div>

          <ChevronRight size={13} color="#D1D5DB" />

          {scope === 'branch' && activeLocation ? (
            <>
              <button
                onClick={() => setIsLocationSwitcherOpen(true)}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '4px',
                  background: 'transparent',
                  border: 'none',
                  color: '#111827',
                  fontWeight: 600,
                  cursor: 'pointer',
                  fontSize: '0.84rem',
                }}
              >
                <Building2 size={14} color="#6B7280" />
                <span>{activeLocation.name}</span>
              </button>
              <ChevronRight size={13} color="#D1D5DB" />
            </>
          ) : null}

          <span style={{ color: '#111827', fontWeight: 700 }}>{tabTitle}</span>
        </div>

        {/* Right: Actions (Reference Style: Manage, Share, Action buttons) */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          <button
            onClick={() => setIsLocationSwitcherOpen(true)}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              background: 'transparent',
              border: 'none',
              color: '#4B5563',
              fontSize: '0.82rem',
              fontWeight: 600,
              cursor: 'pointer',
              padding: '6px 8px',
            }}
          >
            <SlidersHorizontal size={14} />
            <span>Manage</span>
          </button>

          <button
            onClick={triggerBulkSync}
            disabled={isSyncing}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              background: 'transparent',
              border: 'none',
              color: '#4B5563',
              fontSize: '0.82rem',
              fontWeight: 600,
              cursor: 'pointer',
              padding: '6px 8px',
            }}
          >
            <RefreshCw size={14} className={isSyncing ? 'spin-anim' : ''} />
            <span>{isSyncing ? 'Syncing...' : 'Sync'}</span>
          </button>

          <button
            onClick={() => setIsCmoDrawerOpen(true)}
            className="btn btn-secondary btn-sm"
            style={{ gap: '6px' }}
          >
            <MessageSquare size={14} />
            <span>Advisor</span>
          </button>

          <button
            onClick={() => {}}
            style={{
              background: 'transparent',
              border: 'none',
              color: '#9CA3AF',
              cursor: 'pointer',
              padding: '4px',
            }}
          >
            <MoreHorizontal size={16} />
          </button>
        </div>
      </header>

      {/* Slide-out Marketing Advisor Drawer */}
      <CmoAssistantDrawer isOpen={isCmoDrawerOpen} onClose={() => setIsCmoDrawerOpen(false)} />

      {/* Location Switcher Modal */}
      <LocationSwitcherModal />
    </>
  );
};
