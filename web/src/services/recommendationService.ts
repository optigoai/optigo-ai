// ==================================================
// OptigoAI Enterprise — Real Recommendations & Growth Service
// ==================================================

import { apiRequest } from './api';
import { RecommendationItem } from '../types';

export const recommendationService = {
  async getRecommendations(
    businessId: string,
    priority?: string,
    status?: string,
    includeDismissed: boolean = false
  ): Promise<RecommendationItem[]> {
    try {
      let url = `/recommendations?business_id=${businessId}`;
      if (priority && priority !== 'all') url += `&priority=${priority}`;
      if (status && status !== 'all') url += `&status=${status}`;
      if (includeDismissed) url += `&include_dismissed=true`;

      const res = await apiRequest<RecommendationItem[]>(url);
      return Array.isArray(res) ? res : [];
    } catch {
      return [];
    }
  },

  async generateRecommendations(businessId: string): Promise<RecommendationItem[]> {
    const res = await apiRequest<{ business_id: string; cmo_note: string; recommendations: RecommendationItem[] }>(
      `/recommendations/generate?business_id=${businessId}`,
      { method: 'POST' }
    );
    return res.recommendations || [];
  },

  async updateStatus(
    recId: string,
    businessId: string,
    newStatus: 'pending' | 'in_progress' | 'completed' | 'dismissed'
  ): Promise<RecommendationItem> {
    return await apiRequest<RecommendationItem>(
      `/recommendations/${recId}/status?business_id=${businessId}`,
      {
        method: 'PATCH',
        body: JSON.stringify({ status: newStatus }),
      }
    );
  },
};
