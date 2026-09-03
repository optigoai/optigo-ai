// ==================================================
// OptigoAI Enterprise — Location Scope & Active Branch Context
// ==================================================

import React, { createContext, useContext, useState, useEffect } from 'react';
import { BusinessLocation } from '../types';
import { useFranchise } from './FranchiseContext';

export type ViewScope = 'franchise' | 'branch';

interface LocationContextType {
  scope: ViewScope;
  activeLocation: BusinessLocation | null;
  activeBranchTab: string;
  activeFranchiseTab: string;
  isLocationSwitcherOpen: boolean;
  isOnboardingOpen: boolean;
  isSidebarCollapsed: boolean;
  setScope: (scope: ViewScope) => void;
  selectLocation: (locationId: string) => void;
  switchToFranchiseView: () => void;
  setActiveBranchTab: (tab: string) => void;
  setActiveFranchiseTab: (tab: string) => void;
  setIsLocationSwitcherOpen: (isOpen: boolean) => void;
  setIsOnboardingOpen: (isOpen: boolean) => void;
  setIsSidebarCollapsed: (collapsed: boolean) => void;
  toggleSidebar: () => void;
}

const LocationContext = createContext<LocationContextType | undefined>(undefined);

export const LocationProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { locations } = useFranchise();
  const [scope, setScope] = useState<ViewScope>('franchise');
  const [activeLocationId, setActiveLocationId] = useState<string | null>(null);
  const [activeFranchiseTab, setActiveFranchiseTab] = useState<string>('overview');
  const [activeBranchTab, setActiveBranchTab] = useState<string>('dashboard');
  const [isLocationSwitcherOpen, setIsLocationSwitcherOpen] = useState<boolean>(false);
  const [isOnboardingOpen, setIsOnboardingOpen] = useState<boolean>(false);
  const [isSidebarCollapsed, setIsSidebarCollapsed] = useState<boolean>(() => {
    try {
      return localStorage.getItem('optigo_sidebar_collapsed') === 'true';
    } catch {
      return false;
    }
  });

  const toggleSidebar = () => {
    setIsSidebarCollapsed((prev) => {
      const next = !prev;
      try {
        localStorage.setItem('optigo_sidebar_collapsed', String(next));
      } catch {}
      return next;
    });
  };

  // Set active location if available
  useEffect(() => {
    if (!activeLocationId && locations.length > 0) {
      setActiveLocationId(locations[0].id);
    }
  }, [locations, activeLocationId]);

  const activeLocation = locations.find((l) => l.id === activeLocationId) || (locations.length > 0 ? locations[0] : null);

  const selectLocation = (locationId: string) => {
    setActiveLocationId(locationId);
    setScope('branch');
    setIsLocationSwitcherOpen(false);
  };

  const switchToFranchiseView = () => {
    setScope('franchise');
    setIsLocationSwitcherOpen(false);
  };

  return (
    <LocationContext.Provider
      value={{
        scope,
        activeLocation,
        activeBranchTab,
        activeFranchiseTab,
        isLocationSwitcherOpen,
        isOnboardingOpen,
        isSidebarCollapsed,
        setScope,
        selectLocation,
        switchToFranchiseView,
        setActiveBranchTab,
        setActiveFranchiseTab,
        setIsLocationSwitcherOpen,
        setIsOnboardingOpen,
        setIsSidebarCollapsed,
        toggleSidebar,
      }}
    >
      {children}
    </LocationContext.Provider>
  );
};

export const useLocation = () => {
  const context = useContext(LocationContext);
  if (!context) {
    throw new Error('useLocation must be used within a LocationProvider');
  }
  return context;
};
