// ==================================================
// OptigoAI Enterprise — Lead & Onboarding Service
// ==================================================

import { apiRequest } from './api';

export interface PlaceSearchResult {
  place_id: string;
  name: string;
  address?: string;
  category?: string;
  rating?: number;
  review_count?: number;
  phone?: string;
  website?: string;
  photo_url?: string;
  latitude?: number;
  longitude?: number;
}

export interface LeadCreatePayload {
  business_name: string;
  place_id?: string;
  phone: string;
  country_code?: string;
  address?: string;
  category?: string;
  rating?: number;
  review_count?: number;
  website?: string;
  photo_url?: string;
  latitude?: number;
  longitude?: number;
  raw_places_data?: any;
}

export interface LeadResponse {
  id: string;
  business_name: string;
  phone: string;
  country_code?: string;
  place_id?: string;
  address?: string;
  category?: string;
  rating?: number;
  review_count?: number;
  website?: string;
  photo_url?: string;
  status: string;
  priority: string;
  report_data?: any;
  report_score?: number;
  report_generated_at?: string;
  report_viewed_at?: string;
  selected_plan?: string;
  payment_status?: string;
  created_at?: string;
  last_activity_at?: string;
}

export interface CompetitorData {
  rank: number;
  name: string;
  initials?: string;
  rating: number;
  review_count: number;
  distance?: string;
  advantage: string;
  address?: string;
  photo_url?: string;
  lat?: number;
  lng?: number;
  estimated_monthly_calls?: number;
  call_share_pct?: number;
}

export interface CompetitorsSummaryData {
  title: string;
  subtitle: string;
  what_this_means: string;
}

export interface AuditIssue {
  id: string;
  title: string;
  description?: string;
  summary?: string;
  impact?: string;
  severity: 'critical' | 'warning' | 'info';
  icon_type?: string;
  color?: string;
  action?: string;
}

export interface AuditRecommendation {
  id: string;
  title: string;
  description: string;
  impact: string;
  impact_level: 'high' | 'medium' | 'low';
  icon_type: string;
  cta_label: string;
  solution_pillar?: string;
}

export interface HealthScoreBreakdownItem {
  label: string;
  score: number;
}

export interface HealthScoreData {
  score: number;
  verdict: string;
  breakdown: {
    profile_completeness?: HealthScoreBreakdownItem;
    reviews_engagement?: HealthScoreBreakdownItem;
    search_visibility?: HealthScoreBreakdownItem;
    website_seo?: HealthScoreBreakdownItem;
    photos_content?: HealthScoreBreakdownItem;
    [key: string]: HealthScoreBreakdownItem | undefined;
  };
}

export interface QuickStatsData {
  monthly_searches: string;
  searches_trend: string;
  searches_trend_label: string;
  unanswered_reviews: number;
  unanswered_pct: string;
  unanswered_label: string;
  competitors_ahead_count: number;
  competitors_label: string;
}

export interface LosingCustomersAlert {
  title: string;
  description: string;
}

export interface OpportunityData {
  title: string;
  description: string;
}

export interface RevenueBreakdown {
  search_volume_est: number;
  local_pack_ctr: number;
  total_pack_calls: number;
  rank1_share: number;
  rank1_calls: number;
  business_rank: number;
  business_share: number;
  business_calls: number;
  missed_calls: number;
  conversion_rate: number;
  lost_customers_monthly: number;
  price_source: string;
  google_price_range?: {
    start_price?: number;
    end_price?: number;
    currency?: string;
  };
  google_price_level?: string;
  currency: string;
  avg_ticket_low: number;
  avg_ticket_high: number;
  monthly_loss_low: number;
  monthly_loss_high: number;
  annual_loss_low: number;
  annual_loss_high: number;
}

export interface BusinessImpactData {
  top_competitor_name: string;
  competitor_rank_advantage: string;
  estimated_missed_calls_monthly: number;
  estimated_lost_walkins_monthly: number;
  estimated_revenue_loss_monthly_low?: number;
  estimated_revenue_loss_monthly_high?: number;
  estimated_revenue_loss_annual_low?: number;
  estimated_revenue_loss_annual_high?: number;
  revenue_breakdown?: RevenueBreakdown;
  visibility_verdict: string;
  urgency_headline: string;
}

export interface SolutionBlueprint {
  pillar: string;
  headline: string;
  benefit: string;
}

export interface PlanData {
  id?: string;
  name: string;
  slug?: string;
  price_monthly?: number;
  monthly_price?: number;
  price_annual?: number;
  annual_price?: number;
  description: string;
  features: string[];
  highlighted?: boolean;
  recommended?: boolean;
  badge?: string;
  currency?: string;
}

export interface RealSearchQuery {
  query: string;
  rank_status: string;
  rank_number?: number;
  is_critical?: boolean;
}

export interface GrowthOpportunity {
  id: string;
  title: string;
  benefit: string;
  icon_type: string;
  impact: string;
}

export interface InactionConsequence {
  icon_type: 'down_trend' | 'lost_customers' | 'time_lag' | string;
  text: string;
}

export interface BusinessReportData {
  business: {
    name: string;
    category?: string;
    address?: string;
    rating?: number;
    review_count?: number;
    website?: string;
    phone?: string;
    photo_url?: string;
    is_verified?: boolean;
    open_now?: boolean;
    weekday_descriptions?: string[];
    business_status?: string;
    price_level?: string;
    price_range?: {
      start_price?: number;
      end_price?: number;
      currency?: string;
    };
    editorial_summary?: string;
    place_id?: string;
  };
  health_score?: HealthScoreData;
  quick_stats?: QuickStatsData;
  losing_customers_alert?: LosingCustomersAlert;
  opportunity?: OpportunityData;
  audit_summary: {
    profile_score: number;
    total_issues_found: number;
    critical_issues_count: number;
    competitors_ahead_count?: number;
    user_rank?: number;
    status_label: string;
  };
  profile_completion?: {
    percentage: number;
    items: Array<{ name: string; status: 'complete' | 'missing' }>;
  };
  geo_grid?: any;
  cost_comparison?: any;
  competitors: CompetitorData[];
  competitors_summary?: CompetitorsSummaryData;
  issues: AuditIssue[];
  recommendations?: AuditRecommendation[];
  real_searches?: RealSearchQuery[];
  growth_opportunities?: GrowthOpportunity[];
  inaction_consequences?: InactionConsequence[];
  searches_analyzed_count?: number;
  competitors_ahead_count?: number;
  user_rank?: number;
  user_estimated_calls?: number;
  user_call_share_pct?: number;
  total_local_calls_monthly?: number;
  is_in_top_3?: boolean;
  estimated_missed_calls?: number;
  business_impact: BusinessImpactData & {
    user_rank?: number;
    competitors_ahead_count?: number;
  };
  revenue_breakdown?: RevenueBreakdown;
  solutions: SolutionBlueprint[];
  plans: PlanData[];
  generated_at: string;
}

export const leadService = {
  async searchPlaces(query: string, location?: string): Promise<PlaceSearchResult[]> {
    if (!query || query.trim().length < 2) return [];
    const params = new URLSearchParams({ query: query.trim() });
    if (location) params.append('location', location.trim());
    return await apiRequest<PlaceSearchResult[]>(`/leads/places/search?${params.toString()}`);
  },

  async createLead(payload: LeadCreatePayload): Promise<LeadResponse> {
    return await apiRequest<LeadResponse>('/leads', {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  },

  async analyzeLead(leadId: string): Promise<any> {
    return await apiRequest(`/leads/${leadId}/analyze`, {
      method: 'POST',
    });
  },

  async getLead(leadId: string): Promise<LeadResponse> {
    return await apiRequest<LeadResponse>(`/leads/${leadId}`);
  },

  async recordLeadViewed(leadId: string): Promise<void> {
    try {
      await apiRequest(`/leads/${leadId}/viewed`, { method: 'POST' });
    } catch {
      // Non-critical tracking call
    }
  },

  async selectPlan(leadId: string, plan: string, duration: string = 'monthly'): Promise<LeadResponse> {
    return await apiRequest<LeadResponse>(`/leads/${leadId}/select-plan`, {
      method: 'POST',
      body: JSON.stringify({ plan, duration }),
    });
  },

  async createPaymentOrder(leadId: string, plan: string, duration: string = 'monthly'): Promise<any> {
    return await apiRequest(`/leads/${leadId}/create-order`, {
      method: 'POST',
      body: JSON.stringify({ plan, duration }),
    });
  },

  async verifyPayment(
    leadId: string,
    paymentDetails: {
      order_id: string;
      payment_id: string;
      signature?: string;
      create_account?: boolean;
      password?: string;
    }
  ): Promise<any> {
    return await apiRequest(`/leads/${leadId}/verify-payment`, {
      method: 'POST',
      body: JSON.stringify(paymentDetails),
    });
  },
};
