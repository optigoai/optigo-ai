// ==================================================
// OptigoAI Enterprise — Real Reviews API Service
// ==================================================

import { apiRequest } from './api';
import { ReviewItem } from '../types';

export const reviewsService = {
  async getReviews(businessId: string, sentiment?: string, unansweredOnly?: boolean): Promise<ReviewItem[]> {
    try {
      let query = `/reviews?business_id=${businessId}`;
      if (sentiment && sentiment !== 'all') query += `&sentiment=${sentiment}`;
      if (unansweredOnly) query += `&unanswered_only=true`;
      const res = await apiRequest<any[]>(query);
      if (Array.isArray(res)) {
        return res.map((r) => {
          const name = r.reviewer_name || r.author_name || 'Verified Customer';
          const body = r.text || r.comment || '';
          return {
            id: r.id,
            business_id: r.business_id,
            reviewer_name: name,
            author_name: name,
            rating: typeof r.rating === 'number' ? r.rating : 5,
            text: body,
            comment: body,
            sentiment: (r.sentiment?.toLowerCase() as any) || (r.rating >= 4 ? 'positive' : (r.rating === 3 ? 'neutral' : 'negative')),
            review_date: r.review_date || 'Recent',
            is_replied: Boolean(r.is_replied),
            reply_text: r.reply_text,
            reply_date: r.updated_at ? new Date(r.updated_at).toLocaleDateString() : 'Recent',
          };
        });
      }
      return [];
    } catch {
      return [];
    }
  },

  async syncGbpReviews(businessId: string): Promise<any> {
    return await apiRequest(`/businesses/${businessId}/sync-gbp`, {
      method: 'POST',
    });
  },

  async generateAiReply(reviewId: string, tone: string = 'Professional', businessId?: string): Promise<string> {
    try {
      let url = `/reviews/${reviewId}/generate-reply?tone=${encodeURIComponent(tone)}`;
      if (businessId) url += `&business_id=${businessId}`;
      const res = await apiRequest<{ suggested_reply?: string; reply_text?: string }>(url, {
        method: 'POST',
        body: JSON.stringify({ tone }),
      });
      return res.suggested_reply || res.reply_text || 'Thank you for your valuable feedback!';
    } catch {
      return 'Thank you for taking the time to share your feedback! We appreciate your support and look forward to serving you again.';
    }
  },

  async postReply(reviewId: string, replyText: string, businessId?: string): Promise<any> {
    let url = `/reviews/${reviewId}/reply`;
    if (businessId) url += `?business_id=${businessId}`;
    return await apiRequest(url, {
      method: 'POST',
      body: JSON.stringify({ reply_text: replyText }),
    });
  },

  async getManagementAnalytics(businessId: string): Promise<any> {
    try {
      return await apiRequest(`/reviews/management-analytics?business_id=${businessId}`);
    } catch {
      return null;
    }
  },
};
