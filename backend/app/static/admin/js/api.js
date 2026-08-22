// ==================================================
// OptigoAI Admin Web Portal — API Client
// ==================================================

const API_BASE = window.location.origin.includes(':8000') 
  ? '/api/v1' 
  : 'http://localhost:8000/api/v1';

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

  async getBusinesses(limit = 100) {
    return await this.request(`/admin/businesses?limit=${limit}`);
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
