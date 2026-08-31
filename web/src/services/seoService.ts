// ==================================================
// OptigoAI Enterprise — Real SEO & Keywords API Service
// ==================================================

import { apiRequest } from './api';
import { SEOKeywordItem } from '../types';

export const seoService = {
  async getKeywords(businessId: string): Promise<SEOKeywordItem[]> {
    try {
      const res = await apiRequest<any[]>(`/seo/keywords?business_id=${businessId}`);
      if (Array.isArray(res)) {
        return res.map((k) => ({
          id: k.id,
          business_id: k.business_id,
          keyword: k.keyword,
          target_location: k.target_location,
          current_rank: k.current_rank || 1,
          previous_rank: k.previous_rank,
          rank_change: (k.previous_rank && k.current_rank) ? (k.previous_rank - k.current_rank) : 0,
          search_volume: typeof k.search_volume === 'number' ? k.search_volume : parseInt(k.search_volume) || 1200,
          difficulty: k.difficulty || 'Medium',
          intent: k.intent || 'Commercial Intent',
        }));
      }
      return [];
    } catch {
      return [];
    }
  },

  async addKeyword(businessId: string, keyword: string, targetLocation?: string): Promise<SEOKeywordItem> {
    const res = await apiRequest<any>(`/seo/keywords?business_id=${businessId}`, {
      method: 'POST',
      body: JSON.stringify({
        keyword,
        target_location: targetLocation,
      }),
    });
    return {
      id: res.id,
      business_id: res.business_id,
      keyword: res.keyword,
      target_location: res.target_location,
      current_rank: res.current_rank || 1,
      previous_rank: res.previous_rank,
      rank_change: 0,
      search_volume: typeof res.search_volume === 'number' ? res.search_volume : 1200,
      difficulty: res.difficulty || 'Medium',
      intent: res.intent || 'Commercial Intent',
    };
  },

  async deleteKeyword(businessId: string, keywordId: string): Promise<void> {
    await apiRequest(`/seo/keywords/${keywordId}?business_id=${businessId}`, {
      method: 'DELETE',
    });
  },

  async discoverKeywords(businessId: string): Promise<any[]> {
    return await apiRequest(`/seo/discover-keywords?business_id=${businessId}`, {
      method: 'POST',
      body: JSON.stringify({}),
    });
  },

  async getSeoAudit(businessId: string): Promise<any> {
    try {
      return await apiRequest(`/seo/audit?business_id=${businessId}`, {
        method: 'POST',
      });
    } catch {
      return null;
    }
  },
};
