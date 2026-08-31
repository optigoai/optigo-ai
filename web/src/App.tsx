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
import { FranchiseBenchmarksView } from './views/franchise/FranchiseBenchmarksView';
import { FranchiseRegionsView } from './views/franchise/FranchiseRegionsView';
import { FranchiseAuditView } from './views/franchise/FranchiseAuditView';
import { FranchiseAnalyticsView } from './views/franchise/FranchiseAnalyticsView';
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

const MainRouter: React.FC = () => {
  const { isAuthenticated, isLoading: isAuthLoading } = useAuth();
  const { locations, isLoading: isFranchiseLoading } = useFranchise();
  const { scope, activeFranchiseTab, activeBranchTab, isOnboardingOpen, setIsOnboardingOpen } = useLocation();
  const [authMode, setAuthMode] = useState<'login' | 'signup'>('login');

  if (isAuthLoading) {
    return (
      <div style={{ width: '100vw', height: '100vh', background: '#0B0F19', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#60A5FA', fontSize: '0.95rem' }}>
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
          {activeFranchiseTab === 'benchmarks' && <FranchiseBenchmarksView />}
          {activeFranchiseTab === 'regions' && <FranchiseRegionsView />}
          {activeFranchiseTab === 'audit' && <FranchiseAuditView />}
          {activeFranchiseTab === 'analytics' && <FranchiseAnalyticsView />}
          {activeFranchiseTab === 'team' && <FranchiseTeamView />}
          {activeFranchiseTab === 'reports' && <FranchiseReportsView />}
        </>
      ) : (
        <>
          {activeBranchTab === 'dashboard' && <BranchDashboardView />}
          {activeBranchTab === 'profile' && <BranchProfileView />}
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
