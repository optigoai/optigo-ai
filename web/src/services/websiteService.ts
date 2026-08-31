// ==================================================
// OptigoAI Enterprise — Business Website API Service
// ==================================================

import { apiRequest } from './api';
import { BusinessWebsiteItem, PublicWebsiteData } from '../types';

export const websiteService = {
  async getWebsite(businessId: string): Promise<BusinessWebsiteItem> {
    return await apiRequest<BusinessWebsiteItem>(`/businesses/${businessId}/website`);
  },

  async generateWebsite(businessId: string): Promise<BusinessWebsiteItem> {
    return await apiRequest<BusinessWebsiteItem>(`/businesses/${businessId}/website/generate`, {
      method: 'POST',
    });
  },

  async updateWebsite(
    businessId: string,
    data: Partial<{
      slug: string;
      seo_title: string;
      seo_description: string;
      content_json: any;
      custom_html: string;
      custom_css: string;
      custom_js: string;
    }>
  ): Promise<BusinessWebsiteItem> {
    return await apiRequest<BusinessWebsiteItem>(`/businesses/${businessId}/website`, {
      method: 'PUT',
      body: JSON.stringify(data),
    });
  },

  async updateStatus(
    businessId: string,
    status: 'draft' | 'published' | 'unpublished'
  ): Promise<BusinessWebsiteItem> {
    return await apiRequest<BusinessWebsiteItem>(`/businesses/${businessId}/website/status`, {
      method: 'PATCH',
      body: JSON.stringify({ status }),
    });
  },

  async deleteWebsite(businessId: string): Promise<void> {
    await apiRequest(`/businesses/${businessId}/website`, {
      method: 'DELETE',
    });
  },

  async getPublicWebsite(slug: string): Promise<PublicWebsiteData> {
    return await apiRequest<PublicWebsiteData>(`/public/sites/${slug}`);
  },

  async checkSlugAvailability(slug: string): Promise<{ slug: string; available: boolean }> {
    return await apiRequest<{ slug: string; available: boolean }>(`/public/sites/check-slug?slug=${encodeURIComponent(slug)}`);
  },
};
