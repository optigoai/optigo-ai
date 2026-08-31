// ==================================================
// OptigoAI Enterprise — TypeScript Type Definitions
// ==================================================

export interface User {
  id: string;
  email: string;
  full_name: string;
  role: string;
  organization_id?: string;
  created_at?: string;
}

export interface Organization {
  id: string;
  name: string;
  slug?: string;
  created_at?: string;
  settings?: Record<string, any>;
}

export interface BusinessLocation {
  id: string;
  organization_id?: string;
  name: string;
  category: string;
  location: string;
  phone?: string;
  website?: string;
  description?: string;
  services?: string;
  target_customers?: string;
  business_goals?: string;
  marketing_channels?: string;
  health_score: number;
  completeness_score: number;
  total_reviews: number;
  average_rating: number;
  unreplied_reviews: number;
  google_maps_rank: number;
  region?: string;
  status: 'Optimal' | 'Good' | 'Action Required';
  missing_fields: string[];
  monthly_searches: number;
  monthly_actions: number;
  last_synced?: string;
  created_at?: string;
}

export interface FranchiseOverview {
  organization_id: string;
  total_locations: number;
  active_locations: number;
  aggregate_health_score: number;
  total_searches: number;
  total_maps_views: number;
  total_customer_actions: number;
  total_calls: number;
  total_website_clicks: number;
  total_direction_requests: number;
  total_reviews: number;
  franchise_avg_rating: number;
  positive_sentiment_pct: number;
  unreplied_reviews_count: number;
  top_performing_location?: {
    id: string;
    name: string;
    location: string;
    health_score: number;
  } | null;
  attention_needed_location?: {
    id: string;
    name: string;
    location: string;
    health_score: number;
  } | null;
  growth_mom_pct: number;
  health_distribution: {
    excellent: number;
    good: number;
    needs_attention: number;
  };
}

export interface FranchiseBenchmarkItem {
  id: string;
  rank: number;
  name: string;
  region: string;
  health_score: number;
  health_delta_vs_avg: number;
  average_rating: number;
  rating_delta_vs_avg: number;
  total_reviews: number;
  monthly_actions: number;
  google_maps_rank: number;
  tier: string;
}

export interface FranchiseBenchmarks {
  franchise_averages: {
    health_score: number;
    rating: number;
    reviews_per_location: number;
    completeness_score: number;
    monthly_actions: number;
  };
  rankings: FranchiseBenchmarkItem[];
  top_performer: string;
  opportunity_performer: string;
}

export interface RegionSummary {
  region_name: string;
  location_count: number;
  average_health_score: number;
  average_rating: number;
  total_reviews: number;
  total_monthly_actions: number;
  total_monthly_searches: number;
  locations: { id: string; name: string; health_score: number }[];
  regional_manager: string;
}

export interface ProfileAuditData {
  total_locations: number;
  fully_optimized_count: number;
  attention_required_count: number;
  average_completeness_pct: number;
  issues_by_type: {
    unreplied_reviews: number;
    missing_phone: number;
    missing_website: number;
    missing_description: number;
    low_health_score: number;
  };
  locations_requiring_fixes: {
    id: string;
    name: string;
    location: string;
    health_score: number;
    issues: string[];
    urgency: 'High' | 'Medium';
  }[];
}

export interface ReviewItem {
  id: string;
  business_id: string;
  reviewer_name?: string;
  author_name?: string;
  rating: number;
  text?: string;
  comment?: string;
  sentiment?: 'positive' | 'neutral' | 'negative';
  review_date?: string;
  is_replied: boolean;
  reply_text?: string;
  reply_date?: string;
}

export interface SEOKeywordItem {
  id: string;
  business_id?: string;
  keyword: string;
  target_location?: string;
  search_volume?: number;
  current_rank?: number;
  previous_rank?: number;
  rank_change?: number;
  difficulty?: string;
  intent?: string;
}

export interface RecommendationItem {
  id: string;
  business_id: string;
  title: string;
  explanation: string;
  reason?: string;
  priority: 'urgent' | 'important' | 'opportunity';
  impact: string;
  effort: string;
  suggested_action: string;
  related_feature?: string;
  status: 'pending' | 'in_progress' | 'completed' | 'dismissed';
  sort_order?: number;
  created_at?: string;
  updated_at?: string;
}

export interface TeamMember {
  id: string;
  name: string;
  email: string;
  role: 'Franchise Owner' | 'Regional Director' | 'Store Manager' | 'Analyst';
  assigned_regions: string[];
  assigned_locations: string[];
  status: 'Active' | 'Invited' | 'Suspended';
}
