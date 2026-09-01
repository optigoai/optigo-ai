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
  public_website_slug?: string;
  public_website_status?: 'published' | 'draft' | 'unpublished';
  public_website_url?: string;
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
  response_rate_pct?: number;
  discovery_searches_pct?: number;
  direct_searches_pct?: number;
  search_views_breakdown?: {
    direct_searches: number;
    discovery_searches: number;
    maps_views: number;
  };
  customer_actions_breakdown?: {
    phone_calls: number;
    direction_requests: number;
    website_clicks: number;
  };
  top_keywords_pulse?: {
    keyword: string;
    search_volume: number;
    rank: number;
    change: number;
  }[];
  urgent_actions?: {
    title: string;
    category: string;
    impact: string;
    action_tab: string;
  }[];
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
  key_themes?: string;
}

export interface ReviewManagementAnalytics {
  total_reviews: number;
  replied_count: number;
  not_replied_count: number;
  replied_percentage: number;
  not_replied_percentage: number;
  average_rating: number;
  trending_keywords_7d: { keyword: string; count: number }[];
  positive_keywords: { keyword: string; count: number; sentiment: string }[];
  negative_keywords: { keyword: string; count: number; sentiment: string }[];
  keyword_sentiment: {
    positive_count: number;
    negative_count: number;
    positive_pct: number;
    negative_pct: number;
  };
  monthly_rating_analysis: {
    month: string;
    reviews_count: number;
    rating: number;
  }[];
  monthly_sentiment_trend: {
    month: string;
    positive: number;
    negative: number;
  }[];
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

export interface WebsiteHero {
  headline: string;
  subheadline: string;
  badge?: string;
  primary_cta_text?: string;
  primary_cta_action?: string;
  secondary_cta_text?: string;
  secondary_cta_action?: string;
  hero_image_url?: string;
}

export interface WebsiteAbout {
  title: string;
  story: string;
  highlights: string[];
  image_url?: string;
}

export interface WebsiteService {
  name: string;
  description: string;
  price_range?: string;
  badge?: string;
  icon?: string;
}

export interface WebsiteWhyChooseUs {
  title: string;
  description: string;
  icon?: string;
}

export interface WebsiteReviewItem {
  author_name: string;
  rating: number;
  text: string;
  review_date?: string;
}

export interface WebsiteReviewsSection {
  title: string;
  average_rating: number;
  total_reviews: number;
  featured_reviews: WebsiteReviewItem[];
}

export interface WebsiteHoursLocation {
  address: string;
  city: string;
  phone?: string;
  email?: string;
  maps_query?: string;
  opening_hours: string[];
}

export interface WebsiteFAQ {
  question: string;
  answer: string;
}

export interface WebsiteCTABanner {
  title: string;
  description: string;
  button_text: string;
  button_action: string;
}

export interface WebsiteContent {
  theme_config?: {
    accent_color: string;
    font_family: string;
    dark_mode: boolean;
  };
  hero: WebsiteHero;
  about: WebsiteAbout;
  services: WebsiteService[];
  why_choose_us: WebsiteWhyChooseUs[];
  reviews: WebsiteReviewsSection;
  gallery: string[];
  hours_location: WebsiteHoursLocation;
  faqs: WebsiteFAQ[];
  cta_banner: WebsiteCTABanner;
}

export interface BusinessWebsiteItem {
  id: string;
  business_id: string;
  organization_id: string;
  slug: string;
  status: 'draft' | 'published' | 'unpublished';
  seo_title?: string;
  seo_description?: string;
  content_json: WebsiteContent;
  custom_html?: string;
  custom_css?: string;
  custom_js?: string;
  view_count: number;
  published_at?: string;
  created_at?: string;
  updated_at?: string;
}

export interface PublicWebsiteData {
  id: string;
  business_name: string;
  category: string;
  location: string;
  phone?: string;
  website_url?: string;
  slug: string;
  seo_title: string;
  seo_description: string;
  content: WebsiteContent;
  custom_html?: string;
  custom_css?: string;
  custom_js?: string;
  published_at?: string;
  canonical_url: string;
  schema_org_json: Record<string, any>;
}
