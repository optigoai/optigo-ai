// ==================================================
// OptigoAI Enterprise — Prody Light Minimalist AppShell
// ==================================================

import React from 'react';
import { useLocation } from '../../context/LocationContext';
import { Sidebar } from './Sidebar';
import { TopBar } from './TopBar';

// Franchise Views
import { FranchiseOverviewView } from '../../views/franchise/FranchiseOverviewView';
import { FranchiseLocationsView } from '../../views/franchise/FranchiseLocationsView';
import { FranchiseBenchmarksView } from '../../views/franchise/FranchiseBenchmarksView';
import { FranchiseRegionsView } from '../../views/franchise/FranchiseRegionsView';
import { FranchiseAuditView } from '../../views/franchise/FranchiseAuditView';
import { FranchiseAnalyticsView } from '../../views/franchise/FranchiseAnalyticsView';
import { FranchiseTeamView } from '../../views/franchise/FranchiseTeamView';
import { FranchiseReportsView } from '../../views/franchise/FranchiseReportsView';

// Branch Views
import { BranchDashboardView } from '../../views/branch/BranchDashboardView';
import { BranchProfileView } from '../../views/branch/BranchProfileView';
import { BranchSeoView } from '../../views/branch/BranchSeoView';
import { BranchReviewsView } from '../../views/branch/BranchReviewsView';
import { BranchContentView } from '../../views/branch/BranchContentView';
import { BranchRecommendationsView } from '../../views/branch/BranchRecommendationsView';
import { BranchCmoChatView } from '../../views/branch/BranchCmoChatView';
import { BranchSettingsView } from '../../views/branch/BranchSettingsView';
import { BranchWebsiteBuilderView } from '../../views/branch/BranchWebsiteBuilderView';

interface AppShellProps {
  children?: React.ReactNode;
}

export const AppShell: React.FC<AppShellProps> = ({ children }) => {
  const { scope, activeFranchiseTab, activeBranchTab } = useLocation();

  const renderFranchiseContent = () => {
    switch (activeFranchiseTab) {
      case 'overview': return <FranchiseOverviewView />;
      case 'locations': return <FranchiseLocationsView />;
      case 'benchmarks': return <FranchiseBenchmarksView />;
      case 'regions': return <FranchiseRegionsView />;
      case 'audit': return <FranchiseAuditView />;
      case 'analytics': return <FranchiseAnalyticsView />;
      case 'team': return <FranchiseTeamView />;
      case 'reports': return <FranchiseReportsView />;
      default: return <FranchiseOverviewView />;
    }
  };

  const renderBranchContent = () => {
    switch (activeBranchTab) {
      case 'dashboard': return <BranchDashboardView />;
      case 'profile': return <BranchProfileView />;
      case 'website': return <BranchWebsiteBuilderView />;
      case 'seo': return <BranchSeoView />;
      case 'reviews': return <BranchReviewsView />;
      case 'content': return <BranchContentView />;
      case 'recommendations': return <BranchRecommendationsView />;
      case 'cmo': return <BranchCmoChatView />;
      case 'settings': return <BranchSettingsView />;
      default: return <BranchDashboardView />;
    }
  };

  return (
    <div className="app-layout-frame">
      {/* Light Clean Minimalist Sidebar */}
      <Sidebar />

      {/* Main Content Viewport */}
      <div className="app-main-viewport">
        <TopBar />
        <main className="app-content-body">
          {children || (scope === 'franchise' ? renderFranchiseContent() : renderBranchContent())}
        </main>
      </div>
    </div>
  );
};
