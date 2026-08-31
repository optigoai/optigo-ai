// ==================================================
// OptigoAI Enterprise — Clean Light Minimalist Sidebar
// Inspired by "Prody" Light SaaS UI
// ==================================================

import React, { useState } from 'react';
import { useLocation } from '../../context/LocationContext';
import { useAuth } from '../../context/AuthContext';
import { useFranchise } from '../../context/FranchiseContext';
import {
  LayoutDashboard,
  Building2,
  TrendingUp,
  BarChart3,
  Compass,
  ShieldCheck,
  Users,
  FileText,
  Star,
  Zap,
  MessageSquare,
  Settings,
  Search,
  HelpCircle,
  Bell,
  PanelLeftClose,
  Layers,
  ChevronDown,
  Plus,
  LogOut,
  Sparkles,
} from 'lucide-react';

export const Sidebar: React.FC = () => {
  const {
    scope,
    activeLocation,
    activeFranchiseTab,
    activeBranchTab,
    setActiveFranchiseTab,
    setActiveBranchTab,
    switchToFranchiseView,
    setIsOnboardingOpen,
    setIsLocationSwitcherOpen,
  } = useLocation();

  const { organization, logout, user } = useAuth();
  const { locations, audit } = useFranchise();
  const [searchTerm, setSearchTerm] = useState('');

  // Primary Navigation
  const franchisePrimary = [
    { id: 'overview', label: 'Dashboard', icon: LayoutDashboard },
    { id: 'locations', label: 'Locations', icon: Building2, count: locations.length.toString() },
    { id: 'analytics', label: 'Analytics', icon: TrendingUp },
    { id: 'reports', label: 'Reports', icon: FileText, tag: 'New' },
    { id: 'benchmarks', label: 'Benchmarks', icon: BarChart3 },
  ];

  // Secondary Group Navigation
  const franchiseSecondary = [
    { id: 'regions', label: 'Regions', icon: Compass, count: '3' },
    { id: 'team', label: 'People', icon: Users, count: '6' },
    { id: 'audit', label: 'Profile Audit', icon: ShieldCheck, tag: audit.attention_required_count > 0 ? '!' : undefined },
  ];

  // Branch Mode Navigation
  const branchPrimary = [
    { id: 'dashboard', label: 'Dashboard', icon: LayoutDashboard },
    { id: 'profile', label: 'Google Profile', icon: Building2 },
    { id: 'seo', label: 'Local SEO', icon: Compass },
    { id: 'reviews', label: 'Reviews', icon: Star, count: activeLocation?.total_reviews ? `${activeLocation.total_reviews}` : '0' },
  ];

  const branchSecondary = [
    { id: 'content', label: 'Marketing Studio', icon: FileText },
    { id: 'recommendations', label: 'Growth Directives', icon: Zap, tag: 'Active' },
    { id: 'cmo', label: 'Advisor', icon: MessageSquare },
    { id: 'settings', label: 'Settings', icon: Settings },
  ];

  const activeTab = scope === 'franchise' ? activeFranchiseTab : activeBranchTab;
  const setTab = scope === 'franchise' ? setActiveFranchiseTab : setActiveBranchTab;

  const renderNavRow = (item: {
    id: string;
    label: string;
    icon: any;
    count?: string;
    tag?: string;
  }) => {
    const Icon = item.icon;
    const isActive = activeTab === item.id;

    return (
      <button
        key={item.id}
        onClick={() => setTab(item.id)}
        style={{
          display: 'flex',
          alignItems: 'center',
          gap: '10px',
          width: '100%',
          padding: '8px 10px',
          borderRadius: 'var(--radius-sm)',
          border: isActive ? '1px solid var(--border-subtle)' : '1px solid transparent',
          backgroundColor: isActive ? '#FFFFFF' : 'transparent',
          color: isActive ? '#111827' : '#4B5563',
          fontWeight: isActive ? 700 : 500,
          fontSize: '0.84rem',
          cursor: 'pointer',
          textAlign: 'left',
          boxShadow: isActive ? '0 1px 3px rgba(0,0,0,0.05)' : 'none',
          transition: 'all 0.12s ease',
        }}
        onMouseEnter={(e) => {
          if (!isActive) {
            (e.currentTarget as HTMLElement).style.backgroundColor = '#F3F4F6';
            (e.currentTarget as HTMLElement).style.color = '#111827';
          }
        }}
        onMouseLeave={(e) => {
          if (!isActive) {
            (e.currentTarget as HTMLElement).style.backgroundColor = 'transparent';
            (e.currentTarget as HTMLElement).style.color = '#4B5563';
          }
        }}
      >
        <Icon size={16} color={isActive ? '#111827' : '#6B7280'} />
        <span style={{ flex: 1 }}>{item.label}</span>

        {item.count && (
          <span style={{ fontSize: '0.75rem', color: '#9CA3AF', fontWeight: 600 }}>
            {item.count}
          </span>
        )}

        {item.tag && (
          <span
            style={{
              padding: '1px 6px',
              borderRadius: '4px',
              backgroundColor: item.tag === '!' ? '#FEE2E2' : '#F3F4F6',
              color: item.tag === '!' ? '#DC2626' : '#4B5563',
              fontSize: '0.65rem',
              fontWeight: 700,
            }}
          >
            {item.tag}
          </span>
        )}
      </button>
    );
  };

  return (
    <aside className="app-sidebar">
      {/* Top Header & Navigation */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
        {/* Brand Row (Reference Style) */}
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '2px 4px 4px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <div
              style={{
                width: '26px',
                height: '26px',
                borderRadius: '7px',
                backgroundColor: '#111827',
                color: '#FFFFFF',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontWeight: 800,
                fontSize: '0.88rem',
              }}
            >
              O
            </div>
            <span style={{ fontWeight: 800, fontSize: '0.96rem', color: '#111827', letterSpacing: '-0.02em' }}>
              OptigoAI
            </span>
          </div>

          <button
            onClick={() => setIsLocationSwitcherOpen(true)}
            style={{
              background: 'transparent',
              border: 'none',
              color: '#9CA3AF',
              cursor: 'pointer',
              padding: '2px',
            }}
            title="Switch Location / Scope"
          >
            <PanelLeftClose size={16} />
          </button>
        </div>

        {/* Compact Search Bar (Reference Style) */}
        <div className="sidebar-search-box">
          <Search size={14} color="#9CA3AF" />
          <input
            type="text"
            placeholder="Search..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
          <span style={{ fontSize: '0.68rem', color: '#9CA3AF', fontWeight: 600, border: '1px solid #E5E7EB', padding: '1px 4px', borderRadius: '4px' }}>
            ⌘F
          </span>
        </div>

        {/* Scope Pill */}
        {scope === 'branch' && activeLocation ? (
          <div
            style={{
              padding: '6px 10px',
              backgroundColor: '#FFFFFF',
              border: '1px solid var(--border-subtle)',
              borderRadius: 'var(--radius-sm)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
            }}
          >
            <div style={{ minWidth: 0 }}>
              <div style={{ fontSize: '0.68rem', color: '#6B7280', fontWeight: 600 }}>Active Branch</div>
              <div style={{ fontSize: '0.8rem', fontWeight: 700, color: '#111827', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                {activeLocation.name}
              </div>
            </div>
            <button
              onClick={switchToFranchiseView}
              style={{
                background: '#F3F4F6',
                border: 'none',
                borderRadius: '4px',
                padding: '3px 6px',
                fontSize: '0.7rem',
                fontWeight: 600,
                color: '#4B5563',
                cursor: 'pointer',
              }}
            >
              All
            </button>
          </div>
        ) : null}

        {/* Primary Nav List */}
        <nav style={{ display: 'flex', flexDirection: 'column', gap: '2px' }}>
          {(scope === 'franchise' ? franchisePrimary : branchPrimary).map(renderNavRow)}
        </nav>

        {/* Secondary Group Header & List */}
        <div style={{ marginTop: '6px', paddingTop: '10px', borderTop: '1px solid var(--border-subtle)' }}>
          <div style={{ fontSize: '0.68rem', fontWeight: 700, color: '#9CA3AF', textTransform: 'uppercase', letterSpacing: '0.04em', padding: '0 8px 6px' }}>
            {scope === 'franchise' ? 'Governance' : 'Intelligence'}
          </div>
          <nav style={{ display: 'flex', flexDirection: 'column', gap: '2px' }}>
            {(scope === 'franchise' ? franchiseSecondary : branchSecondary).map(renderNavRow)}
          </nav>
        </div>
      </div>

      {/* Bottom Footer Section (Reference Style) */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: '10px', marginTop: '16px' }}>
        {/* Help & Notifications */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '2px' }}>
          <button
            onClick={() => {}}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '10px',
              padding: '6px 10px',
              borderRadius: 'var(--radius-sm)',
              border: 'none',
              backgroundColor: 'transparent',
              color: '#6B7280',
              fontSize: '0.8rem',
              fontWeight: 500,
              cursor: 'pointer',
              textAlign: 'left',
            }}
          >
            <HelpCircle size={15} color="#9CA3AF" />
            <span>Help center</span>
          </button>

          <button
            onClick={() => {}}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '10px',
              padding: '6px 10px',
              borderRadius: 'var(--radius-sm)',
              border: 'none',
              backgroundColor: 'transparent',
              color: '#6B7280',
              fontSize: '0.8rem',
              fontWeight: 500,
              cursor: 'pointer',
              textAlign: 'left',
            }}
          >
            <Bell size={15} color="#9CA3AF" />
            <span style={{ flex: 1 }}>Notifications</span>
            <span
              style={{
                width: '16px',
                height: '16px',
                borderRadius: '50%',
                backgroundColor: '#E11D48',
                color: '#FFFFFF',
                fontSize: '0.65rem',
                fontWeight: 700,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              3
            </span>
          </button>
        </div>

        {/* User Card */}
        <div
          style={{
            padding: '8px 10px',
            backgroundColor: '#FFFFFF',
            borderRadius: 'var(--radius-sm)',
            border: '1px solid var(--border-subtle)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', minWidth: 0 }}>
            <div
              style={{
                width: '28px',
                height: '28px',
                borderRadius: '50%',
                backgroundColor: '#FDE68A',
                color: '#B45309',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontWeight: 800,
                fontSize: '0.75rem',
                flexShrink: 0,
              }}
            >
              {(user?.full_name || 'Ahmed').substring(0, 2).toUpperCase()}
            </div>
            <div style={{ minWidth: 0 }}>
              <div style={{ fontWeight: 700, fontSize: '0.8rem', color: '#111827', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                {user?.full_name || 'Ahmed Yazeen'}
              </div>
            </div>
          </div>

          <button
            onClick={logout}
            style={{ background: 'transparent', border: 'none', color: '#9CA3AF', cursor: 'pointer', padding: '2px' }}
            title="Sign out"
            onMouseEnter={(e) => ((e.currentTarget as HTMLElement).style.color = '#E11D48')}
            onMouseLeave={(e) => ((e.currentTarget as HTMLElement).style.color = '#9CA3AF')}
          >
            <LogOut size={14} />
          </button>
        </div>

        {/* Starter Overview Card (Reference Style) */}
        <div
          style={{
            padding: '10px',
            backgroundColor: '#FFFFFF',
            borderRadius: 'var(--radius-md)',
            border: '1px solid var(--border-subtle)',
            display: 'flex',
            flexDirection: 'column',
            gap: '8px',
          }}
        >
          <div>
            <div style={{ fontSize: '0.75rem', fontWeight: 700, color: '#111827' }}>Locations Overview</div>
            <div style={{ fontSize: '0.68rem', color: '#6B7280' }}>{locations.length} of 5 locations active</div>
          </div>

          <button
            onClick={() => setIsOnboardingOpen(true)}
            style={{
              width: '100%',
              padding: '6px 10px',
              borderRadius: 'var(--radius-sm)',
              border: '1px solid var(--border-subtle)',
              backgroundColor: '#F9FAFB',
              color: '#111827',
              fontSize: '0.75rem',
              fontWeight: 700,
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: '4px',
            }}
          >
            <Plus size={13} />
            <span>Add Branch</span>
          </button>
        </div>
      </div>
    </aside>
  );
};
