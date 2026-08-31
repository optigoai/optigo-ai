// ==================================================
// OptigoAI Enterprise — Real Business & Onboarding API Service
// ==================================================

import { apiRequest } from './api';
import { BusinessLocation } from '../types';

export interface BusinessCreatePayload {
  name: string;
  category?: string;
  location?: string;
  website?: string;
  phone?: string;
  description?: string;
  services?: string;
  target_customers?: string;
  business_goals?: string;
  marketing_channels?: string;
}

export interface BusinessOnboardingPayload {
  target_customers?: string;
  services?: string;
  business_goals?: string;
  marketing_channels?: string;
}

export const businessService = {
  async listBusinesses(): Promise<BusinessLocation[]> {
    try {
      const res = await apiRequest<BusinessLocation[]>('/businesses');
      return res || [];
    } catch {
      return [];
    }
  },

  async getBusiness(id: string): Promise<BusinessLocation> {
    return await apiRequest<BusinessLocation>(`/businesses/${id}`);
  },

  async createBusiness(data: BusinessCreatePayload): Promise<BusinessLocation> {
    return await apiRequest<BusinessLocation>('/businesses', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  },

  async submitOnboarding(id: string, data: BusinessOnboardingPayload): Promise<BusinessLocation> {
    return await apiRequest<BusinessLocation>(`/businesses/${id}/onboarding`, {
      method: 'POST',
      body: JSON.stringify(data),
    });
  },

  async updateBusiness(id: string, data: Partial<BusinessLocation>): Promise<BusinessLocation> {
    return await apiRequest<BusinessLocation>(`/businesses/${id}`, {
      method: 'PATCH',
      body: JSON.stringify(data),
    });
  },

  async syncGBP(id: string): Promise<any> {
    return await apiRequest(`/businesses/${id}/sync-gbp`, {
      method: 'POST',
    });
  },

  async getROIAnalytics(businessId: string): Promise<any> {
    try {
      return await apiRequest(`/analytics/roi?business_id=${businessId}`);
    } catch {
      return null;
    }
  },

  async getDashboardSummary(businessId: string): Promise<any> {
    try {
      return await apiRequest(`/analytics/dashboard-summary?business_id=${businessId}`);
    } catch {
      return null;
    }
  },
};
