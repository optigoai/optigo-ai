// ==================================================
// OptigoAI Enterprise — Real Franchise Multi-Location Context
// ==================================================

import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';
import {
  FranchiseOverview,
  BusinessLocation,
  FranchiseBenchmarks,
  RegionSummary,
  ProfileAuditData,
} from '../types';
import { franchiseService } from '../services/franchiseService';
import { useAuth } from './AuthContext';

export type DateRange = '7d' | '30d' | '90d' | 'ytd';

interface FranchiseContextType {
  overview: FranchiseOverview;
  locations: BusinessLocation[];
  benchmarks: FranchiseBenchmarks;
  regions: RegionSummary[];
  audit: ProfileAuditData;
  isLoading: boolean;
  isSyncing: boolean;
  selectedDateRange: DateRange;
  selectedRegionFilter: string;
  searchQuery: string;
  setSelectedDateRange: (range: DateRange) => void;
  setSelectedRegionFilter: (region: string) => void;
  setSearchQuery: (query: string) => void;
  refreshFranchiseData: () => Promise<void>;
  triggerBulkSync: () => Promise<void>;
  filteredLocations: BusinessLocation[];
}

const EMPTY_OVERVIEW: FranchiseOverview = {
  organization_id: '',
  total_locations: 0,
  active_locations: 0,
  aggregate_health_score: 0,
  total_searches: 0,
  total_maps_views: 0,
  total_customer_actions: 0,
  total_calls: 0,
  total_website_clicks: 0,
  total_direction_requests: 0,
  total_reviews: 0,
  franchise_avg_rating: 0,
  positive_sentiment_pct: 0,
  unreplied_reviews_count: 0,
  growth_mom_pct: 0,
  health_distribution: { excellent: 0, good: 0, needs_attention: 0 },
};

const EMPTY_BENCHMARKS: FranchiseBenchmarks = {
  franchise_averages: { health_score: 0, rating: 0, reviews_per_location: 0, completeness_score: 0, monthly_actions: 0 },
  rankings: [],
  top_performer: '',
  opportunity_performer: '',
};

const EMPTY_AUDIT: ProfileAuditData = {
  total_locations: 0,
  fully_optimized_count: 0,
  attention_required_count: 0,
  average_completeness_pct: 0,
  issues_by_type: { unreplied_reviews: 0, missing_phone: 0, missing_website: 0, missing_description: 0, low_health_score: 0 },
  locations_requiring_fixes: [],
};

const FranchiseContext = createContext<FranchiseContextType | undefined>(undefined);

export const FranchiseProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { isAuthenticated } = useAuth();
  const [overview, setOverview] = useState<FranchiseOverview>(EMPTY_OVERVIEW);
  const [locations, setLocations] = useState<BusinessLocation[]>([]);
  const [benchmarks, setBenchmarks] = useState<FranchiseBenchmarks>(EMPTY_BENCHMARKS);
  const [regions, setRegions] = useState<RegionSummary[]>([]);
  const [audit, setAudit] = useState<ProfileAuditData>(EMPTY_AUDIT);
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [isSyncing, setIsSyncing] = useState<boolean>(false);
  const [selectedDateRange, setSelectedDateRange] = useState<DateRange>('30d');
  const [selectedRegionFilter, setSelectedRegionFilter] = useState<string>('all');
  const [searchQuery, setSearchQuery] = useState<string>('');

  const loadData = useCallback(async () => {
    if (!isAuthenticated) {
      setOverview(EMPTY_OVERVIEW);
      setLocations([]);
      setBenchmarks(EMPTY_BENCHMARKS);
      setRegions([]);
      setAudit(EMPTY_AUDIT);
      return;
    }

    setIsLoading(true);
    try {
      const [ov, locs, bm, regs, aud] = await Promise.all([
        franchiseService.getOverview(),
        franchiseService.getLocations(),
        franchiseService.getBenchmarks(),
        franchiseService.getRegions(),
        franchiseService.getAudit(),
      ]);

      setOverview(ov);
      setLocations(locs || []);
      setBenchmarks(bm || EMPTY_BENCHMARKS);
      setRegions(regs || []);
      setAudit(aud || EMPTY_AUDIT);
    } catch {
      // Clear on error
    } finally {
      setIsLoading(false);
    }
  }, [isAuthenticated]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  const triggerBulkSync = async () => {
    setIsSyncing(true);
    try {
      await franchiseService.triggerBulkSync();
      await loadData();
    } finally {
      setIsSyncing(false);
    }
  };

  const filteredLocations = locations.filter((loc) => {
    const matchesRegion =
      selectedRegionFilter === 'all' ||
      (loc.region && loc.region.toLowerCase() === selectedRegionFilter.toLowerCase());
    const matchesSearch =
      searchQuery.trim() === '' ||
      loc.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      loc.location.toLowerCase().includes(searchQuery.toLowerCase()) ||
      loc.category.toLowerCase().includes(searchQuery.toLowerCase());
    return matchesRegion && matchesSearch;
  });

  return (
    <FranchiseContext.Provider
      value={{
        overview,
        locations,
        benchmarks,
        regions,
        audit,
        isLoading,
        isSyncing,
        selectedDateRange,
        selectedRegionFilter,
        searchQuery,
        setSelectedDateRange,
        setSelectedRegionFilter,
        setSearchQuery,
        refreshFranchiseData: loadData,
        triggerBulkSync,
        filteredLocations,
      }}
    >
      {children}
    </FranchiseContext.Provider>
  );
};

export const useFranchise = () => {
  const context = useContext(FranchiseContext);
  if (!context) {
    throw new Error('useFranchise must be used within a FranchiseProvider');
  }
  return context;
};
