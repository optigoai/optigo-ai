// ==================================================
// OptigoAI Enterprise — Enterprise Blue Sidebar
// Rich Royal Blue Theme without any glowing effects
// Supports Expanded & Collapsible Icon-Only mode with smooth transitions
// Completely hidden, seamless scrollbar (no cheap scrollbar visible)
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
  HelpCircle,
  Bell,
  PanelLeftClose,
  PanelLeftOpen,
  Plus,
  LogOut,
  Sparkles,
  Globe,
  ChevronRight,
  ArrowLeft,
} from 'lucide-react';
import optigoLogo from '../../assets/optigoai-logo.png';

export const Sidebar: React.FC = () => {
  const {
    scope,
    activeLocation,
    activeFranchiseTab,
    activeBranchTab,
    isSidebarCollapsed,
    toggleSidebar,
    setActiveFranchiseTab,
    setActiveBranchTab,
    switchToFranchiseView,
    setIsOnboardingOpen,
    setIsLocationSwitcherOpen,
  } = useLocation();

  const { logout, user } = useAuth();
  const { locations, audit, regions, team } = useFranchise();
  const [searchTerm, setSearchTerm] = useState('');

  // Primary Navigation (Home, Locations, Insights, AI Analysis, Reports)
  const franchisePrimary = [
    { id: 'overview', label: 'Home', icon: LayoutDashboard },
    { id: 'locations', label: 'Locations', icon: Building2, count: locations.length.toString() },
    { id: 'insights', label: 'Insights', icon: TrendingUp },
    { id: 'ai-analysis', label: 'AI Analysis', icon: Sparkles, tag: 'AI' },
    { id: 'reports', label: 'Reports', icon: FileText },
  ];

  // Real counts derived from database records
  const realRegionsCount = (
    regions.length > 0 
      ? regions.length 
      : new Set(locations.map((l) => l.region).filter(Boolean)).size || (locations.length > 0 ? 1 : 0)
  ).toString();

  const realTeamCount = (team.length > 0 ? team.length : 1).toString();

  // Secondary Group Navigation (Governance)
  const franchiseSecondary = [
    { id: 'regions', label: 'Regions', icon: Compass, count: realRegionsCount },
    { id: 'team', label: 'People', icon: Users, count: realTeamCount },
    {
      id: 'audit',
      label: 'Profile Audit',
      icon: ShieldCheck,
      count: audit.attention_required_count > 0 ? audit.attention_required_count.toString() : undefined,
      tag: audit.attention_required_count > 0 ? '!' : undefined,
    },
  ];

  // Branch Mode Navigation
  const branchPrimary = [
    { id: 'dashboard', label: 'Dashboard', icon: LayoutDashboard },
    { id: 'profile', label: 'Google Profile', icon: Building2 },
    { id: 'seo', label: 'Local SEO', icon: Compass },
    { id: 'reviews', label: 'Reviews', icon: Star, count: activeLocation?.total_reviews ? `${activeLocation.total_reviews}` : '0' },
  ];

  const branchSecondary = [
    { id: 'website', label: 'Website Builder', icon: Globe, tag: 'Public' },
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

    // Render a single animated button for both collapsed and expanded states
    return (
      <button
        key={item.id}
        className="sidebar-nav-item"
        onClick={() => setTab(item.id)}
        title={isSidebarCollapsed ? item.label : undefined}
        style={{
          position: 'relative',
          display: 'flex',
          alignItems: 'center',
          justifyContent: isSidebarCollapsed ? 'center' : 'flex-start',
          gap: isSidebarCollapsed ? '0px' : '12px',
          width: isSidebarCollapsed ? '46px' : '100%',
          height: isSidebarCollapsed ? '46px' : 'auto',
          margin: '0 auto',
          padding: isSidebarCollapsed ? '0' : '11px 14px',
          borderRadius: '11px',
          border: isActive ? '1px solid #ffffff' : '1px solid transparent',
          backgroundColor: isActive ? '#ffffff' : 'transparent',
          color: isActive ? '#1255E6' : 'rgba(255, 255, 255, 0.88)',
          fontWeight: isActive ? 800 : 600,
          fontSize: '0.92rem',
          cursor: 'pointer',
          textAlign: 'left',
          transition: 'all 0.2s ease',
          whiteSpace: 'nowrap',
          overflow: 'hidden',
          boxShadow: isActive ? '0 2px 8px rgba(0, 0, 0, 0.12)' : 'none',
        }}
        onMouseEnter={(e) => {
          if (!isActive) {
            (e.currentTarget as HTMLElement).style.backgroundColor = 'rgba(255, 255, 255, 0.15)';
            (e.currentTarget as HTMLElement).style.color = '#ffffff';
          }
        }}
        onMouseLeave={(e) => {
          if (!isActive) {
            (e.currentTarget as HTMLElement).style.backgroundColor = 'transparent';
            (e.currentTarget as HTMLElement).style.color = 'rgba(255, 255, 255, 0.88)';
          }
        }}
      >
        <div
          style={{
            width: '24px',
            height: '24px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            color: isActive ? '#1255E6' : '#ffffff',
            transition: 'color 0.15s ease',
            flexShrink: 0,
          }}
        >
          <Icon size={isSidebarCollapsed ? 20 : 19} />
        </div>

        {/* Text and badges container, hidden when collapsed */}
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
            opacity: isSidebarCollapsed ? 0 : 1,
            width: isSidebarCollapsed ? 0 : '100%',
            transition: 'opacity 0.2s ease, width 0.3s ease',
            overflow: 'hidden',
          }}
        >
          <span style={{ flex: 1, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
            {item.label}
          </span>

          {item.count && (
            <span
              style={{
                fontSize: '0.76rem',
                color: isActive ? '#1255E6' : '#ffffff',
                backgroundColor: isActive ? '#EEF4FE' : 'rgba(255, 255, 255, 0.22)',
                padding: '2px 8px',
                borderRadius: '8px',
                fontWeight: 800,
              }}
            >
              {item.count}
            </span>
          )}

          {item.tag && (
            <span
              style={{
                padding: '2px 8px',
                borderRadius: '8px',
                backgroundColor:
                  item.tag === '!'
                    ? 'rgba(239, 68, 68, 0.3)'
                    : item.tag === 'AI'
                    ? 'rgba(192, 132, 252, 0.25)'
                    : 'rgba(52, 211, 153, 0.25)',
                color:
                  item.tag === '!'
                    ? '#fecaca'
                    : item.tag === 'AI'
                    ? '#f3e8ff'
                    : '#d1fae5',
                border:
                  item.tag === '!'
                    ? '1px solid rgba(239, 68, 68, 0.6)'
                    : item.tag === 'AI'
                    ? '1px solid rgba(192, 132, 252, 0.6)'
                    : '1px solid rgba(52, 211, 153, 0.6)',
                fontSize: '0.7rem',
                fontWeight: 900,
                letterSpacing: '0.3px',
              }}
            >
              {item.tag}
            </span>
          )}
        </div>

        {/* Collapsed Badge Dot (Clean solid color, zero glow) */}
        {isSidebarCollapsed && item.tag === '!' && (
          <span
            style={{
              position: 'absolute',
              top: '7px',
              right: '7px',
              width: '8px',
              height: '8px',
              borderRadius: '50%',
              backgroundColor: '#ef4444',
            }}
          />
        )}
        {isSidebarCollapsed && item.tag === 'AI' && (
          <span
            style={{
              position: 'absolute',
              top: '7px',
              right: '7px',
              width: '7px',
              height: '7px',
              borderRadius: '50%',
              backgroundColor: '#c084fc',
            }}
          />
        )}
      </button>
    );
  };

  return (
    <aside className={`app-sidebar ${isSidebarCollapsed ? 'collapsed' : ''}`}>
      {/* Top Header & Navigation */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
        {/* Brand Row with Logo & Collapse/Expand Toggle (Vertical stack when collapsed to prevent edge clipping) */}
        <div
          style={{
            display: 'flex',
            flexDirection: isSidebarCollapsed ? 'column' : 'row',
            alignItems: 'center',
            justifyContent: isSidebarCollapsed ? 'center' : 'space-between',
            padding: isSidebarCollapsed ? '2px 0 6px' : '2px 4px 6px',
            gap: isSidebarCollapsed ? '12px' : '8px',
          }}
        >
          <div
            onClick={isSidebarCollapsed ? toggleSidebar : undefined}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '10px',
              cursor: isSidebarCollapsed ? 'pointer' : 'default',
            }}
            title={isSidebarCollapsed ? 'Click to expand sidebar' : undefined}
          >
            {/* Crisp white logo emblem without glow */}
            <div
              style={{
                width: '38px',
                height: '38px',
                borderRadius: '11px',
                backgroundColor: '#ffffff',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                flexShrink: 0,
                padding: '4px',
                overflow: 'hidden',
                border: '1px solid rgba(255, 255, 255, 0.25)',
              }}
            >
              <img
                src={optigoLogo}
                alt="OptigoAI Logo"
                style={{
                  width: '100%',
                  height: '100%',
                  objectFit: 'contain',
                }}
              />
            </div>

            <div
              style={{
                opacity: isSidebarCollapsed ? 0 : 1,
                width: isSidebarCollapsed ? 0 : 'auto',
                transition: 'opacity 0.2s ease, width 0.3s ease',
                overflow: 'hidden',
                whiteSpace: 'nowrap',
              }}
            >
              <span
                style={{
                  fontWeight: 900,
                  fontSize: '1.14rem',
                  color: '#ffffff',
                  letterSpacing: '-0.03em',
                  display: 'block',
                  lineHeight: 1.1,
                }}
              >
                OptigoAI
              </span>
              <span
                style={{
                  fontSize: '0.68rem',
                  color: '#bfdbfe',
                  fontWeight: 800,
                  textTransform: 'uppercase',
                  letterSpacing: '0.08em',
                }}
              >
                Enterprise
              </span>
            </div>
          </div>

          {/* Sidebar Size Toggle Button (Large <-> Small icon mode) */}
          <button
            onClick={toggleSidebar}
            style={{
              background: 'rgba(255, 255, 255, 0.18)',
              border: '1px solid rgba(255, 255, 255, 0.25)',
              borderRadius: '8px',
              color: '#ffffff',
              cursor: 'pointer',
              padding: '7px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              transition: 'all 0.15s ease',
            }}
            title={isSidebarCollapsed ? 'Expand Sidebar (Large Mode)' : 'Collapse Sidebar (Small Icon Mode)'}
            onMouseEnter={(e) => {
              (e.currentTarget as HTMLElement).style.backgroundColor = 'rgba(255, 255, 255, 0.28)';
            }}
            onMouseLeave={(e) => {
              (e.currentTarget as HTMLElement).style.backgroundColor = 'rgba(255, 255, 255, 0.18)';
            }}
          >
            {isSidebarCollapsed ? <PanelLeftOpen size={17} /> : <PanelLeftClose size={17} />}
          </button>
        </div>

        {/* Search Bar / Icon */}
        <div
          onClick={isSidebarCollapsed ? toggleSidebar : undefined}
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: isSidebarCollapsed ? '0px' : '10px',
            backgroundColor: 'rgba(255, 255, 255, 0.14)',
            border: '1px solid rgba(255, 255, 255, 0.22)',
            borderRadius: '10px',
            padding: isSidebarCollapsed ? '0' : '9px 14px',
            width: isSidebarCollapsed ? '46px' : '100%',
            height: isSidebarCollapsed ? '40px' : 'auto',
            margin: '0 auto',
            justifyContent: isSidebarCollapsed ? 'center' : 'flex-start',
            cursor: isSidebarCollapsed ? 'pointer' : 'text',
            transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
            overflow: 'hidden',
          }}
          title={isSidebarCollapsed ? "Search network (Click to expand)" : undefined}
        >
          <div style={{
            display: 'flex',
            alignItems: 'center',
            flex: 1,
            opacity: isSidebarCollapsed ? 0 : 1,
            width: isSidebarCollapsed ? 0 : '100%',
            transition: 'opacity 0.2s ease, width 0.3s ease',
            overflow: 'hidden',
          }}>
            <input
              type="text"
              placeholder="Search network..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              style={{
                border: 'none',
                background: 'transparent',
                outline: 'none',
                fontSize: '0.84rem',
                color: '#ffffff',
                width: '100%',
                fontWeight: 500,
              }}
            />
            <span
              style={{
                fontSize: '0.7rem',
                color: '#dbeafe',
                fontWeight: 700,
                border: '1px solid rgba(255, 255, 255, 0.25)',
                padding: '1px 5px',
                borderRadius: '5px',
                backgroundColor: 'rgba(255, 255, 255, 0.14)',
                flexShrink: 0,
              }}
            >
              ⌘K
            </span>
          </div>
        </div>

        {/* Active Branch Scope Indicator (when in branch mode) */}
        {scope === 'branch' && activeLocation && (
          <div
            style={{
              padding: isSidebarCollapsed ? '0' : '10px 14px',
              backgroundColor: 'rgba(255, 255, 255, 0.14)',
              border: '1px solid rgba(255, 255, 255, 0.22)',
              borderRadius: isSidebarCollapsed ? '10px' : '12px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: isSidebarCollapsed ? 'center' : 'space-between',
              width: isSidebarCollapsed ? '46px' : '100%',
              height: isSidebarCollapsed ? '40px' : 'auto',
              margin: '0 auto',
              transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
              overflow: 'hidden',
              cursor: isSidebarCollapsed ? 'pointer' : 'default',
            }}
            onClick={isSidebarCollapsed ? switchToFranchiseView : undefined}
            title={isSidebarCollapsed ? `Active: ${activeLocation.name} (Click to view Network)` : undefined}
          >
            {/* Expanded Content (Fades out when collapsed) */}
            <div style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              width: isSidebarCollapsed ? '0px' : '100%',
              opacity: isSidebarCollapsed ? 0 : 1,
              transition: 'opacity 0.2s ease, width 0.3s ease',
              overflow: 'hidden',
            }}>
              <div style={{ minWidth: 0, paddingRight: '6px', whiteSpace: 'nowrap' }}>
                <div style={{ fontSize: '0.68rem', color: '#bfdbfe', fontWeight: 800, textTransform: 'uppercase', letterSpacing: '0.4px' }}>
                  Active Branch
                </div>
                <div style={{ fontSize: '0.88rem', fontWeight: 800, color: '#ffffff', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                  {activeLocation.name}
                </div>
              </div>
              <button
                onClick={switchToFranchiseView}
                style={{
                  background: '#FFFFFF',
                  border: 'none',
                  borderRadius: '6px',
                  padding: '4px 8px',
                  fontSize: '0.74rem',
                  fontWeight: 800,
                  color: '#1255E6',
                  cursor: 'pointer',
                  flexShrink: 0,
                }}
              >
                Network
              </button>
            </div>

            {/* Collapsed Icon (Fades in when collapsed) */}
            <div style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              width: isSidebarCollapsed ? '100%' : '0px',
              opacity: isSidebarCollapsed ? 1 : 0,
              transition: 'opacity 0.2s ease, width 0.3s ease',
              overflow: 'hidden',
              color: '#ffffff',
            }}>
              <Building2 size={18} />
            </div>
          </div>
        )}

        {/* Primary Nav List */}
        <nav style={{ display: 'flex', flexDirection: 'column', gap: '5px' }}>
          {(scope === 'franchise' ? franchisePrimary : branchPrimary).map(renderNavRow)}
        </nav>

        {/* Secondary Group Header & List */}
        <div
          style={{
            marginTop: '8px',
            paddingTop: '12px',
            borderTop: '1px solid rgba(255, 255, 255, 0.16)',
          }}
        >
          {!isSidebarCollapsed && (
            <div
              style={{
                fontSize: '0.72rem',
                fontWeight: 800,
                color: 'rgba(255, 255, 255, 0.65)',
                textTransform: 'uppercase',
                letterSpacing: '0.08em',
                padding: '0 10px 8px',
              }}
            >
              {scope === 'franchise' ? 'Governance' : 'Intelligence'}
            </div>
          )}
          <nav style={{ display: 'flex', flexDirection: 'column', gap: '5px' }}>
            {(scope === 'franchise' ? franchiseSecondary : branchSecondary).map(renderNavRow)}
          </nav>
        </div>
      </div>

      {/* Bottom Footer Section */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: '12px', marginTop: '20px' }}>
        {/* Help & Notifications */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
          <button
            onClick={() => {}}
            style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: isSidebarCollapsed ? 'center' : 'flex-start',
              gap: '10px',
              padding: isSidebarCollapsed ? '10px 0' : '8px 12px',
              borderRadius: '10px',
              border: 'none',
              backgroundColor: 'transparent',
              color: 'rgba(255, 255, 255, 0.88)',
              fontSize: '0.84rem',
              fontWeight: 600,
              cursor: 'pointer',
              textAlign: 'left',
              transition: 'background-color 0.15s ease',
            }}
            title="Help Center & Docs"
            onMouseEnter={(e) => ((e.currentTarget as HTMLElement).style.backgroundColor = 'rgba(255, 255, 255, 0.15)')}
            onMouseLeave={(e) => ((e.currentTarget as HTMLElement).style.backgroundColor = 'transparent')}
          >
            <HelpCircle size={18} color="#ffffff" />
            {!isSidebarCollapsed && <span>Help Center</span>}
          </button>

          <button
            onClick={() => {}}
            style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: isSidebarCollapsed ? 'center' : 'flex-start',
              gap: '10px',
              padding: isSidebarCollapsed ? '10px 0' : '8px 12px',
              borderRadius: '10px',
              border: 'none',
              backgroundColor: 'transparent',
              color: 'rgba(255, 255, 255, 0.88)',
              fontSize: '0.84rem',
              fontWeight: 600,
              cursor: 'pointer',
              textAlign: 'left',
              position: 'relative',
              transition: 'background-color 0.15s ease',
            }}
            title="Notifications (3 unread)"
            onMouseEnter={(e) => ((e.currentTarget as HTMLElement).style.backgroundColor = 'rgba(255, 255, 255, 0.15)')}
            onMouseLeave={(e) => ((e.currentTarget as HTMLElement).style.backgroundColor = 'transparent')}
          >
            <Bell size={18} color="#ffffff" />
            {!isSidebarCollapsed && <span style={{ flex: 1 }}>Notifications</span>}
            <span
              style={{
                width: isSidebarCollapsed ? '8px' : '20px',
                height: isSidebarCollapsed ? '8px' : '20px',
                borderRadius: '50%',
                backgroundColor: '#ef4444',
                color: '#ffffff',
                fontSize: '0.72rem',
                fontWeight: 800,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                position: isSidebarCollapsed ? 'absolute' : 'static',
                top: isSidebarCollapsed ? '6px' : 'auto',
                right: isSidebarCollapsed ? '10px' : 'auto',
              }}
            >
              {!isSidebarCollapsed && '3'}
            </span>
          </button>
        </div>

        {/* User Card */}
        <div
          style={{
            padding: isSidebarCollapsed ? '8px 0' : '10px 14px',
            backgroundColor: 'rgba(255, 255, 255, 0.14)',
            borderRadius: '12px',
            border: '1px solid rgba(255, 255, 255, 0.22)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: isSidebarCollapsed ? 'center' : 'space-between',
          }}
        >
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '10px',
              minWidth: 0,
              justifyContent: isSidebarCollapsed ? 'center' : 'flex-start',
            }}
          >
            <div
              style={{
                width: '36px',
                height: '36px',
                borderRadius: '50%',
                background: '#f59e0b',
                color: '#ffffff',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontWeight: 900,
                fontSize: '0.84rem',
                flexShrink: 0,
              }}
              title={isSidebarCollapsed ? (user?.full_name || 'Ahmed Yazeen') : undefined}
            >
              {(user?.full_name || 'Ahmed').substring(0, 2).toUpperCase()}
            </div>

            {!isSidebarCollapsed && (
              <div style={{ minWidth: 0 }}>
                <div
                  style={{
                    fontWeight: 800,
                    fontSize: '0.86rem',
                    color: '#ffffff',
                    whiteSpace: 'nowrap',
                    overflow: 'hidden',
                    textOverflow: 'ellipsis',
                  }}
                >
                  {user?.full_name || 'Ahmed Yazeen'}
                </div>
                <div style={{ fontSize: '0.72rem', color: '#bfdbfe', fontWeight: 600 }}>
                  Enterprise Admin
                </div>
              </div>
            )}
          </div>

          {!isSidebarCollapsed && (
            <button
              onClick={logout}
              style={{
                background: 'rgba(255, 255, 255, 0.18)',
                border: '1px solid rgba(255, 255, 255, 0.25)',
                borderRadius: '8px',
                color: '#ffffff',
                cursor: 'pointer',
                padding: '6px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                transition: 'all 0.15s ease',
              }}
              title="Sign out"
              onMouseEnter={(e) => {
                (e.currentTarget as HTMLElement).style.color = '#ffffff';
                (e.currentTarget as HTMLElement).style.borderColor = 'rgba(239, 68, 68, 0.6)';
                (e.currentTarget as HTMLElement).style.backgroundColor = 'rgba(239, 68, 68, 0.4)';
              }}
              onMouseLeave={(e) => {
                (e.currentTarget as HTMLElement).style.color = '#ffffff';
                (e.currentTarget as HTMLElement).style.borderColor = 'rgba(255, 255, 255, 0.25)';
                (e.currentTarget as HTMLElement).style.backgroundColor = 'rgba(255, 255, 255, 0.18)';
              }}
            >
              <LogOut size={15} />
            </button>
          )}
        </div>

        {/* Add Location Action */}
        {!isSidebarCollapsed ? (
          <div
            style={{
              padding: '12px 14px',
              backgroundColor: 'rgba(255, 255, 255, 0.14)',
              borderRadius: '14px',
              border: '1px solid rgba(255, 255, 255, 0.22)',
              display: 'flex',
              flexDirection: 'column',
              gap: '10px',
            }}
          >
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span style={{ fontSize: '0.78rem', fontWeight: 800, color: '#ffffff' }}>
                Network Locations
              </span>
              <span style={{ fontSize: '0.74rem', fontWeight: 800, color: '#bfdbfe' }}>
                {locations.length}/5 Active
              </span>
            </div>

            <button
              onClick={() => setIsOnboardingOpen(true)}
              style={{
                width: '100%',
                padding: '10px 14px',
                fontSize: '0.84rem',
                fontWeight: 800,
                gap: '8px',
                borderRadius: '10px',
                backgroundColor: '#ffffff',
                color: '#1255E6',
                border: 'none',
                cursor: 'pointer',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                transition: 'all 0.15s ease',
              }}
              onMouseEnter={(e) => {
                (e.currentTarget as HTMLElement).style.backgroundColor = '#EEF4FE';
                (e.currentTarget as HTMLElement).style.transform = 'translateY(-1px)';
              }}
              onMouseLeave={(e) => {
                (e.currentTarget as HTMLElement).style.backgroundColor = '#ffffff';
                (e.currentTarget as HTMLElement).style.transform = 'translateY(0)';
              }}
            >
              <Plus size={16} />
              <span>Add New Location</span>
            </button>
          </div>
        ) : (
          <button
            onClick={() => setIsOnboardingOpen(true)}
            style={{
              width: '46px',
              height: '44px',
              margin: '0 auto',
              borderRadius: '11px',
              backgroundColor: '#ffffff',
              color: '#1255E6',
              border: 'none',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              transition: 'all 0.15s ease',
            }}
            title="Add New Location"
            onMouseEnter={(e) => {
              (e.currentTarget as HTMLElement).style.backgroundColor = '#EEF4FE';
            }}
            onMouseLeave={(e) => {
              (e.currentTarget as HTMLElement).style.backgroundColor = '#ffffff';
            }}
          >
            <Plus size={20} />
          </button>
        )}
      </div>
    </aside>
  );
};
