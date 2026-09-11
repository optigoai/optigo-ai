// ==================================================
// OptigoAI Enterprise — Real Application Root
// ==================================================

import React, { useState } from 'react';
import { AuthProvider, useAuth } from './context/AuthContext';
import { FranchiseProvider, useFranchise } from './context/FranchiseContext';
import { LocationProvider, useLocation } from './context/LocationContext';
import { AppShell } from './components/layout/AppShell';

// Auth & Onboarding Views
import { LoginView } from './views/auth/LoginView';
import { SignupView } from './views/auth/SignupView';
import { BusinessOnboardingView } from './views/onboarding/BusinessOnboardingView';

// Franchise Multi-Location Views
import { FranchiseOverviewView } from './views/franchise/FranchiseOverviewView';
import { FranchiseLocationsView } from './views/franchise/FranchiseLocationsView';
import { FranchiseInsightsView } from './views/franchise/FranchiseInsightsView';
import { FranchiseAiAnalysisView } from './views/franchise/FranchiseAiAnalysisView';
import { FranchiseRegionsView } from './views/franchise/FranchiseRegionsView';
import { FranchiseAuditView } from './views/franchise/FranchiseAuditView';
import { FranchiseTeamView } from './views/franchise/FranchiseTeamView';
import { FranchiseReportsView } from './views/franchise/FranchiseReportsView';

// Single-Branch Drill-Down Views
import { BranchDashboardView } from './views/branch/BranchDashboardView';
import { BranchProfileView } from './views/branch/BranchProfileView';
import { BranchSeoView } from './views/branch/BranchSeoView';
import { BranchReviewsView } from './views/branch/BranchReviewsView';
import { BranchContentView } from './views/branch/BranchContentView';
import { BranchRecommendationsView } from './views/branch/BranchRecommendationsView';
import { BranchCmoChatView } from './views/branch/BranchCmoChatView';
import { BranchSettingsView } from './views/branch/BranchSettingsView';
import { BranchWebsiteBuilderView } from './views/branch/BranchWebsiteBuilderView';
import { PublicBusinessPageView } from './views/public/PublicBusinessPageView';
import { SinglePageOnboardingView } from './views/lead-gen/SinglePageOnboardingView';
import { AiBusinessReportView } from './views/lead-gen/AiBusinessReportView';

const MainRouter: React.FC = () => {
  const { isAuthenticated, isLoading: isAuthLoading } = useAuth();
  const { locations, isLoading: isFranchiseLoading } = useFranchise();
  const { scope, activeFranchiseTab, activeBranchTab, isOnboardingOpen, setIsOnboardingOpen } = useLocation();
  const [authMode, setAuthMode] = useState<'login' | 'signup'>('login');

  // Check URL path
  const cleanPath = window.location.pathname.replace(/^\/+|\/+$/g, '');
  const internalReserved = ['', 'login', 'signup', 'onboarding', 'audit', 'onboard', 'report', 'app', 'admin', 'dashboard'];

  // Public Lead-Gen Single-Page Onboarding (/audit or /onboard)
  if (cleanPath === 'audit' || cleanPath === 'onboard') {
    return (
      <SinglePageOnboardingView
        onReportReady={(leadId) => {
          window.location.href = `/report/${leadId}`;
        }}
      />
    );
  }

  // Public AI Business Audit Report (/report/:leadId)
  if (cleanPath.startsWith('report/')) {
    const leadId = cleanPath.replace(/^report\//, '');
    return <AiBusinessReportView leadId={leadId} />;
  }

  // Check if current URL path is a public business site (e.g. optigoai.com/casaraza-restaurant)
  const isPublicBusinessSlug = cleanPath.length > 0 && !internalReserved.includes(cleanPath.toLowerCase().split('/')[0]);

  if (isPublicBusinessSlug) {
    return <PublicBusinessPageView slug={cleanPath.replace(/^site\//, '')} />;
  }

  if (isAuthLoading) {
    return (
      <div style={{ width: '100vw', height: '100vh', background: '#F0F4F9', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#1255E6', fontSize: '0.95rem' }}>
        <span>Loading OptigoAI Enterprise...</span>
      </div>
    );
  }

  // If not signed in, show clean real Login / Signup screens
  if (!isAuthenticated) {
    return authMode === 'login' ? (
      <LoginView onNavigateSignup={() => setAuthMode('signup')} />
    ) : (
      <SignupView onNavigateLogin={() => setAuthMode('login')} />
    );
  }

  // If user has 0 businesses or explicitly opened Onboarding Modal, display Onboarding Flow
  if (locations.length === 0 || isOnboardingOpen) {
    return <BusinessOnboardingView onComplete={() => setIsOnboardingOpen(false)} />;
  }

  return (
    <AppShell>
      {scope === 'franchise' ? (
        <>
          {activeFranchiseTab === 'overview' && <FranchiseOverviewView />}
          {activeFranchiseTab === 'locations' && <FranchiseLocationsView />}
          {(activeFranchiseTab === 'insights' || activeFranchiseTab === 'benchmarks' || activeFranchiseTab === 'analytics') && <FranchiseInsightsView />}
          {(activeFranchiseTab === 'ai-analysis' || activeFranchiseTab === 'advisor') && <FranchiseAiAnalysisView />}
          {activeFranchiseTab === 'regions' && <FranchiseRegionsView />}
          {activeFranchiseTab === 'audit' && <FranchiseAuditView />}
          {activeFranchiseTab === 'team' && <FranchiseTeamView />}
          {activeFranchiseTab === 'reports' && <FranchiseReportsView />}
        </>
      ) : (
        <>
          {activeBranchTab === 'dashboard' && <BranchDashboardView />}
          {activeBranchTab === 'profile' && <BranchProfileView />}
          {activeBranchTab === 'website' && <BranchWebsiteBuilderView />}
          {activeBranchTab === 'seo' && <BranchSeoView />}
          {activeBranchTab === 'reviews' && <BranchReviewsView />}
          {activeBranchTab === 'content' && <BranchContentView />}
          {activeBranchTab === 'recommendations' && <BranchRecommendationsView />}
          {activeBranchTab === 'cmo' && <BranchCmoChatView />}
          {activeBranchTab === 'settings' && <BranchSettingsView />}
        </>
      )}
    </AppShell>
  );
};

export const App: React.FC = () => {
  return (
    <AuthProvider>
      <FranchiseProvider>
        <LocationProvider>
          <MainRouter />
        </LocationProvider>
      </FranchiseProvider>
    </AuthProvider>
  );
};

export default App;
