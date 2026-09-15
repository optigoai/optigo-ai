// ==================================================
// OptigoAI Admin Web Portal — API Client
// ==================================================

const API_BASE = (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1')
  ? (window.location.port === '8000' ? '/api/v1' : 'http://localhost:8000/api/v1')
  : '/api/v1';

class AdminAPI {
  constructor() {
    this.token = localStorage.getItem('optigo_admin_token') || null;
    this.onAuthRequired = null;
  }

  setToken(token) {
    this.token = token;
    if (token) {
      localStorage.setItem('optigo_admin_token', token);
    } else {
      localStorage.removeItem('optigo_admin_token');
    }
  }

  getHeaders() {
    const headers = {
      'Content-Type': 'application/json',
    };
    if (this.token) {
      headers['Authorization'] = `Bearer ${this.token}`;
    }
    return headers;
  }

  async request(endpoint, options = {}) {
    const url = `${API_BASE}${endpoint}`;
    const config = {
      ...options,
      headers: {
        ...this.getHeaders(),
        ...options.headers,
      },
    };

    try {
      const res = await fetch(url, config);
      if (res.status === 401 || res.status === 403) {
        console.warn(`Admin authentication required for ${endpoint}.`);
        if (this.onAuthRequired) {
          this.onAuthRequired();
        }
      }
      if (!res.ok) {
        const errData = await res.json().catch(() => ({}));
        throw new Error(errData.detail || `HTTP ${res.status}: ${res.statusText}`);
      }
      return await res.json();
    } catch (err) {
      throw err;
    }
  }

  // --- Admin API Methods ---
  async getStats() {
    return await this.request('/admin/stats');
  }

  async getOrganizations(limit = 50, offset = 0) {
    return await this.request(`/admin/organizations?limit=${limit}&offset=${offset}`);
  }

  async toggleOrgStatus(orgId, isActive) {
    return await this.request(`/admin/organizations/${orgId}/status`, {
      method: 'PATCH',
      body: JSON.stringify({ is_active: isActive }),
    });
  }

  async updateOrganization(orgId, data) {
    return await this.request(`/admin/organizations/${orgId}`, {
      method: 'PUT',
      body: JSON.stringify(data),
    });
  }

  async getBusinesses(limit = 100) {
    return await this.request(`/admin/businesses?limit=${limit}`);
  }

  async getBusinessDetail(businessId) {
    return await this.request(`/admin/businesses/${businessId}`);
  }

  async updateBusiness(businessId, data) {
    return await this.request(`/admin/businesses/${businessId}`, {
      method: 'PUT',
      body: JSON.stringify(data),
    });
  }

  async updateUser(userId, data) {
    return await this.request(`/admin/users/${userId}`, {
      method: 'PATCH',
      body: JSON.stringify(data),
    });
  }

  async getFeatures() {
    return await this.request('/admin/features');
  }

  async updateFeature(featureName, isEnabled, description = null) {
    return await this.request(`/admin/features/${featureName}`, {
      method: 'PUT',
      body: JSON.stringify({ is_enabled: isEnabled, description }),
    });
  }

  async getUsage() {
    return await this.request('/admin/usage');
  }

  async getSystemHealth() {
    return await this.request('/admin/system-health');
  }

  // --- Leads API Methods ---
  async getLeadsStats() {
    return await this.request('/admin/leads/stats');
  }

  async getLeads(status = null, priority = null, search = null, limit = 50, offset = 0) {
    const params = new URLSearchParams();
    if (status) params.append('status', status);
    if (priority) params.append('priority', priority);
    if (search) params.append('search', search);
    params.append('limit', limit);
    params.append('offset', offset);
    return await this.request(`/admin/leads?${params.toString()}`);
  }

  async getLeadDetail(leadId) {
    return await this.request(`/admin/leads/${leadId}`);
  }

  async updateLead(leadId, data) {
    return await this.request(`/admin/leads/${leadId}`, {
      method: 'PATCH',
      body: JSON.stringify(data),
    });
  }

  async addLeadNote(leadId, note) {
    return await this.request(`/admin/leads/${leadId}/notes`, {
      method: 'POST',
      body: JSON.stringify({ note }),
    });
  }

  // --- Admin Auth ---
  async login(email, password) {
    const res = await this.request('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, password }),
    });
    if (res.tokens && res.tokens.access_token) {
      this.setToken(res.tokens.access_token);
      return res;
    } else if (res.access_token) {
      this.setToken(res.access_token);
      return res;
    }
    return res;
  }

  logout() {
    this.setToken(null);
    if (this.onAuthRequired) {
      this.onAuthRequired();
    }
  }
}

window.api = new AdminAPI();
