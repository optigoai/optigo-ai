// ==================================================
// OptigoAI Enterprise — Content Engine API Service
// ==================================================

import { apiRequest } from './api';

export interface GeneratedPostItem {
  channel: string;
  title?: string;
  body: string;
  hashtags?: string;
  call_to_action?: string;
  media_prompt?: string;
}

export interface ContentGenerateResponse {
  business_id: string;
  campaign_theme: string;
  posts: GeneratedPostItem[];
  calendar_suggestions?: Array<{
    day: string;
    channel: string;
    post_type: string;
    theme: string;
  }>;
}

export interface ContentItem {
  id: string;
  business_id: string;
  content_type: string;
  title?: string;
  body: string;
  hashtags?: string;
  status: 'draft' | 'scheduled' | 'published' | 'failed';
  scheduled_for?: string;
  published_at?: string;
  call_to_action?: string;
  metrics?: Record<string, any>;
  created_at: string;
}

export const contentService = {
  async generatePosts(params: {
    businessId: string;
    channels: string[];
    topic: string;
    tone?: string;
    goal?: string;
    offerDetails?: string;
  }): Promise<ContentGenerateResponse> {
    return await apiRequest<ContentGenerateResponse>('/contents/generate', {
      method: 'POST',
      body: JSON.stringify({
        business_id: params.businessId,
        channels: params.channels,
        topic: params.topic,
        tone: params.tone || 'Engaging & Friendly',
        goal: params.goal || 'foot_traffic',
        offer_details: params.offerDetails,
      }),
    });
  },

  async createPost(params: {
    businessId: string;
    contentType: string;
    title?: string;
    body: string;
    hashtags?: string;
    status?: string;
    scheduledFor?: string;
    callToAction?: string;
  }): Promise<ContentItem> {
    return await apiRequest<ContentItem>('/contents', {
      method: 'POST',
      body: JSON.stringify({
        business_id: params.businessId,
        content_type: params.contentType,
        title: params.title,
        body: params.body,
        hashtags: params.hashtags,
        status: params.status || 'draft',
        scheduled_for: params.scheduledFor,
        call_to_action: params.callToAction,
      }),
    });
  },

  async listPosts(businessId: string, contentType?: string, status?: string): Promise<ContentItem[]> {
    let url = `/contents?business_id=${encodeURIComponent(businessId)}`;
    if (contentType) url += `&content_type=${encodeURIComponent(contentType)}`;
    if (status) url += `&status=${encodeURIComponent(status)}`;
    try {
      return await apiRequest<ContentItem[]>(url);
    } catch {
      return [];
    }
  },
};
