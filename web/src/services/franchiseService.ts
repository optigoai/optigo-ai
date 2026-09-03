// ==================================================
// OptigoAI Enterprise — Real Franchise API Service
// ==================================================

import { apiRequest } from './api';
import {
  FranchiseOverview,
  BusinessLocation,
  FranchiseBenchmarks,
  RegionSummary,
  ProfileAuditData,
  TeamMember,
} from '../types';

export const franchiseService = {
  async getOverview(): Promise<FranchiseOverview> {
    try {
      return await apiRequest<FranchiseOverview>('/franchise/overview');
    } catch {
      return {
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
    }
  },

  async getLocations(): Promise<BusinessLocation[]> {
    try {
      const res = await apiRequest<BusinessLocation[]>('/franchise/locations');
      return res || [];
    } catch {
      return [];
    }
  },

  async getBenchmarks(): Promise<FranchiseBenchmarks> {
    try {
      const res = await apiRequest<FranchiseBenchmarks>('/franchise/benchmarks');
      return res || {
        franchise_averages: { health_score: 0, rating: 0, reviews_per_location: 0, completeness_score: 0, monthly_actions: 0 },
        rankings: [],
        top_performer: '',
        opportunity_performer: '',
      };
    } catch {
      return {
        franchise_averages: { health_score: 0, rating: 0, reviews_per_location: 0, completeness_score: 0, monthly_actions: 0 },
        rankings: [],
        top_performer: '',
        opportunity_performer: '',
      };
    }
  },

  async getRegions(): Promise<RegionSummary[]> {
    try {
      const res = await apiRequest<RegionSummary[]>('/franchise/regions');
      return res || [];
    } catch {
      return [];
    }
  },

  async getAudit(): Promise<ProfileAuditData> {
    try {
      const res = await apiRequest<ProfileAuditData>('/franchise/audit');
      return res || {
        total_locations: 0,
        fully_optimized_count: 0,
        attention_required_count: 0,
        average_completeness_pct: 0,
        issues_by_type: { unreplied_reviews: 0, missing_phone: 0, missing_website: 0, missing_description: 0, low_health_score: 0 },
        locations_requiring_fixes: [],
      };
    } catch {
      return {
        total_locations: 0,
        fully_optimized_count: 0,
        attention_required_count: 0,
        average_completeness_pct: 0,
        issues_by_type: { unreplied_reviews: 0, missing_phone: 0, missing_website: 0, missing_description: 0, low_health_score: 0 },
        locations_requiring_fixes: [],
      };
    }
  },

  async getTeam(): Promise<TeamMember[]> {
    try {
      const res = await apiRequest<TeamMember[]>('/franchise/team');
      return res || [];
    } catch {
      return [];
    }
  },

  async triggerBulkSync(): Promise<{ status: string; message: string }> {
    return await apiRequest('/franchise/bulk-sync', { method: 'POST' });
  },
};
