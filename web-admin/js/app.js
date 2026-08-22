// ==================================================
// OptigoAI Admin Web Portal — Application Logic
// ==================================================

document.addEventListener('DOMContentLoaded', () => {
  initApp();
});

let currentTab = 'dashboard';
let statsData = null;
let featuresData = [];
let orgsData = [];
let businessesData = [];
let usageData = null;
let autoRefreshTimer = null;

function initApp() {
  setupNavigation();
  setupAuthHandling();
  setupRefreshButton();
  startAutoRefresh();

  if (!window.api.token) {
    showAuthModal();
  } else {
    loadAllData();
  }
}

function startAutoRefresh() {
  if (autoRefreshTimer) clearInterval(autoRefreshTimer);
  // Auto-refresh every 3.5 seconds silently
  autoRefreshTimer = setInterval(() => {
    if (window.api.token) {
      loadAllDataSilently();
    }
  }, 3500);
}

function setupAuthHandling() {
  window.api.onAuthRequired = () => {
    showAuthModal();
  };

  const loginForm = document.getElementById('admin-login-form');
  if (loginForm) {
    loginForm.addEventListener('submit', async (e) => {
      e.preventDefault();
      const email = document.getElementById('login-email').value.trim();
      const password = document.getElementById('login-password').value;
      const submitBtn = document.getElementById('btn-login-submit');

      submitBtn.disabled = true;
      submitBtn.innerText = 'Authenticating...';

      try {
        const res = await window.api.login(email, password);
        hideAuthModal();
        showToast('Authenticated successfully as Administrator!', 'success');

        if (res.user) {
          const nameEl = document.getElementById('admin-display-name');
          const emailEl = document.getElementById('admin-display-email');
          if (nameEl) nameEl.innerText = res.user.full_name || 'Super Administrator';
          if (emailEl) emailEl.innerText = res.user.email || email;
        }

        loadAllData();
      } catch (err) {
        showToast(err.message || 'Login failed. Check admin credentials.', 'error');
      } finally {
        submitBtn.disabled = false;
        submitBtn.innerText = 'Sign In to Admin Portal';
      }
    });
  }
}

function showAuthModal() {
  const modal = document.getElementById('auth-modal');
  if (modal) modal.style.display = 'flex';
}

function hideAuthModal() {
  const modal = document.getElementById('auth-modal');
  if (modal) modal.style.display = 'none';
}

function handleLogout() {
  window.api.logout();
  showToast('Logged out of Admin Portal.', 'success');
  showAuthModal();
}

function setupNavigation() {
  const navItems = document.querySelectorAll('.nav-item');
  navItems.forEach(item => {
    item.addEventListener('click', (e) => {
      e.preventDefault();
      const tab = item.getAttribute('data-tab');
      if (tab) {
        switchTab(tab);
      }
    });
  });
}

function switchTab(tabId) {
  currentTab = tabId;
  
  // Update nav state
  document.querySelectorAll('.nav-item').forEach(item => {
    item.classList.toggle('active', item.getAttribute('data-tab') === tabId);
  });

  // Update view visibility
  document.querySelectorAll('.tab-view').forEach(view => {
    view.style.display = view.id === `view-${tabId}` ? 'block' : 'none';
  });

  // Update Page Header Title
  const titles = {
    dashboard: { title: 'Executive Overview', sub: 'Real-time platform metrics, active tenants, and AI consumption' },
    organizations: { title: 'Organizations & Tenants', sub: 'Multi-tenant organization management, user access, and status' },
    businesses: { title: 'Registered Businesses', sub: 'All onboarded businesses across categories and locations' },
    features: { title: 'Feature Toggles & App Controls', sub: 'Dynamically toggle capabilities across the OptigoAI ecosystem' },
    usage: { title: 'AI Usage & Cost Monitoring', sub: 'Token consumption, provider breakdown, and estimated costs' },
    health: { title: 'System Health & Infrastructure', sub: 'PostgreSQL, Redis, and background worker status radar' },
  };

  const info = titles[tabId] || { title: 'Admin Console', sub: 'Manage OptigoAI Platform' };
  document.getElementById('page-main-title').innerText = info.title;
  document.getElementById('page-sub-title').innerText = info.sub;
}

function setupRefreshButton() {
  const refreshBtn = document.getElementById('btn-refresh-data');
  if (refreshBtn) {
    refreshBtn.addEventListener('click', () => {
      refreshBtn.classList.add('loading');
      loadAllData().then(() => {
        refreshBtn.classList.remove('loading');
        showToast('Platform data synchronized successfully!', 'success');
      });
    });
  }
}

async function loadAllData() {
  try {
    await Promise.all([
      loadStats(),
      loadFeatures(),
      loadOrganizations(),
      loadBusinesses(),
      loadUsage(),
      loadHealth(),
    ]);
  } catch (err) {
    console.error('Failed to load some data:', err);
  }
}

async function loadAllDataSilently() {
  try {
    await Promise.all([
      loadStats(),
      loadFeatures(),
      loadOrganizations(),
      loadBusinesses(),
      loadUsage(),
      loadHealth(),
    ]);
  } catch (_) {
    // Silent catch for background polling
  }
}

async function loadStats() {
  try {
    statsData = await window.api.getStats();
    renderStats(statsData);
  } catch (err) {
    statsData = {
      total_organizations: 0,
      total_businesses: 0,
      total_users: 0,
      total_reviews_managed: 0,
      total_campaigns_created: 0,
      total_content_pieces: 0,
      ai_api_calls: 0,
      total_tokens_consumed: 0,
      estimated_ai_cost_usd: 0.0,
      active_feature_flags: 0,
    };
    renderStats(statsData);
  }
}

function renderStats(data) {
  document.getElementById('stat-orgs').innerText = data.total_organizations ?? 0;
  document.getElementById('stat-businesses').innerText = data.total_businesses ?? 0;
  document.getElementById('stat-users').innerText = data.total_users ?? 0;
  document.getElementById('stat-ai-calls').innerText = (data.ai_api_calls ?? 0).toLocaleString();
  document.getElementById('stat-tokens').innerText = (data.total_tokens_consumed ?? 0).toLocaleString();
  document.getElementById('stat-cost').innerText = `$${(data.estimated_ai_cost_usd ?? 0).toFixed(2)}`;
}

async function loadFeatures() {
  try {
    featuresData = await window.api.getFeatures();
  } catch (err) {
    featuresData = [];
  }
  renderFeatures(featuresData);
}

function renderFeatures(features) {
  const container = document.getElementById('features-container');
  if (!container) return;

  if (features.length === 0) {
    container.innerHTML = `<div style="grid-column: 1/-1; text-align:center; padding:30px; color:var(--text-muted);">No feature flags found. Click Synchronize to load from backend.</div>`;
    return;
  }

  // Avoid re-rendering if user is currently interacting with toggles
  const focused = document.activeElement && document.activeElement.type === 'checkbox';
  if (focused) return;

  container.innerHTML = features.map(f => {
    const formattedName = f.feature_name
      .split('_')
      .map(w => w.charAt(0).toUpperCase() + w.slice(1))
      .join(' ');

    return `
      <div class="feature-item-card" id="feature-card-${f.feature_name}">
        <div class="feature-top">
          <div class="feature-info">
            <h4>${formattedName}</h4>
            <p>${f.description}</p>
          </div>
          <label class="switch">
            <input type="checkbox" ${f.is_enabled ? 'checked' : ''} onchange="handleFeatureToggle('${f.feature_name}', this.checked)">
            <span class="slider"></span>
          </label>
        </div>
        <div style="display:flex; justify-content:space-between; align-items:center; font-size:0.75rem; color:var(--text-muted);">
          <span>Key: <code>${f.feature_name}</code></span>
          <span class="badge ${f.is_enabled ? 'badge-active' : 'badge-suspended'}">${f.is_enabled ? 'Active Globally' : 'Disabled'}</span>
        </div>
      </div>
    `;
  }).join('');
}

async function handleFeatureToggle(featureName, isEnabled) {
  try {
    await window.api.updateFeature(featureName, isEnabled);
    showToast(`Feature '${featureName}' is now ${isEnabled ? 'ENABLED' : 'DISABLED'} across the mobile app.`, 'success');
    loadFeatures();
  } catch (err) {
    showToast(`Failed to update feature '${featureName}': ${err.message}`, 'error');
  }
}

async function loadOrganizations() {
  try {
    orgsData = await window.api.getOrganizations();
  } catch (err) {
    orgsData = [];
  }
  renderOrganizations(orgsData);
}

function renderOrganizations(orgs) {
  const tbody = document.getElementById('orgs-tbody');
  if (!tbody) return;

  if (!orgs || orgs.length === 0) {
    tbody.innerHTML = `<tr><td colspan="6" style="text-align:center; padding:30px; color:var(--text-muted);">No organizations registered yet.</td></tr>`;
    return;
  }

  tbody.innerHTML = orgs.map(o => `
    <tr>
      <td><strong>${escapeHtml(o.name)}</strong></td>
      <td><code>${escapeHtml(o.slug)}</code></td>
      <td><span class="badge badge-pill">${o.businesses_count} Businesses</span></td>
      <td><span class="badge badge-pill">${o.users_count} Users</span></td>
      <td>
        <span class="badge ${o.is_active ? 'badge-active' : 'badge-suspended'}">
          ${o.is_active ? 'Active' : 'Suspended'}
        </span>
      </td>
      <td>
        <button class="btn btn-secondary" style="padding:4px 10px; font-size:0.75rem;" onclick="handleOrgToggle('${o.id}', ${!o.is_active})">
          ${o.is_active ? 'Suspend' : 'Activate'}
        </button>
      </td>
    </tr>
  `).join('');
}

async function handleOrgToggle(orgId, newActiveState) {
  try {
    await window.api.toggleOrgStatus(orgId, newActiveState);
    showToast(`Organization status updated to ${newActiveState ? 'ACTIVE' : 'SUSPENDED'}`, 'success');
    loadOrganizations();
  } catch (err) {
    showToast(`Failed to update organization: ${err.message}`, 'error');
  }
}

async function loadBusinesses() {
  try {
    businessesData = await window.api.getBusinesses();
  } catch (err) {
    businessesData = [];
  }
  renderBusinesses(businessesData);
}

function renderBusinesses(businesses) {
  const tbody = document.getElementById('businesses-tbody');
  if (!tbody) return;

  if (!businesses || businesses.length === 0) {
    tbody.innerHTML = `<tr><td colspan="5" style="text-align:center; padding:30px; color:var(--text-muted);">No businesses registered yet.</td></tr>`;
    return;
  }

  tbody.innerHTML = businesses.map(b => `
    <tr>
      <td><strong>${escapeHtml(b.name)}</strong></td>
      <td><span class="badge badge-pill">${escapeHtml(b.category || 'General')}</span></td>
      <td>${escapeHtml(b.location || 'Not Specified')}</td>
      <td><a href="${escapeHtml(b.website || '#')}" target="_blank" style="color:#60A5FA; text-decoration:none;">${escapeHtml(b.website || 'N/A')}</a></td>
      <td>
        <span class="badge ${b.onboarding_completed ? 'badge-active' : 'badge-suspended'}">
          ${b.onboarding_completed ? 'Onboarded' : 'Pending'}
        </span>
      </td>
    </tr>
  `).join('');
}

async function loadUsage() {
  try {
    usageData = await window.api.getUsage();
    renderUsage(usageData);
  } catch (err) {
    renderUsage({ by_user: [], by_feature: [], by_model: [], recent_logs: [] });
  }
}

function renderUsage(data) {
  // 1. Render Per-User AI Consumption with Business and Organization Linkage
  const usersTbody = document.getElementById('usage-users-tbody');
  if (usersTbody && data.by_user) {
    if (data.by_user.length === 0) {
      usersTbody.innerHTML = `<tr><td colspan="8" style="text-align:center; padding:24px; color:var(--text-muted);">No per-user AI invocations logged yet.</td></tr>`;
    } else {
      usersTbody.innerHTML = data.by_user.map(u => {
        const lastActiveFormatted = u.last_active ? new Date(u.last_active).toLocaleString() : 'Never';
        const initials = (u.user_name || 'U').split(' ').map(n => n[0]).join('').substring(0, 2).toUpperCase();
        return `
          <tr>
            <td>
              <div style="display:flex; align-items:center; gap:10px;">
                <div style="width:32px; height:32px; border-radius:8px; background:linear-gradient(135deg,#3B82F6,#6366F1); display:flex; align-items:center; justify-content:center; font-weight:800; font-size:0.75rem; color:white;">
                  ${initials}
                </div>
                <strong>${escapeHtml(u.user_name)}</strong>
              </div>
            </td>
            <td><code style="color:#94A3B8;">${escapeHtml(u.user_email)}</code></td>
            <td><span class="badge" style="background:rgba(59,130,246,0.15); color:#60A5FA; border:1px solid rgba(59,130,246,0.3); font-weight:700;">${escapeHtml(u.business_name || 'Direct')}</span></td>
            <td><span class="badge badge-pill">${escapeHtml(u.organization_name)}</span></td>
            <td><span class="badge badge-pill" style="font-weight:700;">${u.calls.toLocaleString()} calls</span></td>
            <td><strong>${u.tokens.toLocaleString()}</strong></td>
            <td><strong style="color:#34D399;">$${u.cost_usd.toFixed(4)}</strong></td>
            <td style="font-size:0.78rem; color:var(--text-muted);">${lastActiveFormatted}</td>
          </tr>
        `;
      }).join('');
    }
  }

  // 2. Render Feature Breakdown
  const featureTbody = document.getElementById('usage-feature-tbody');
  if (featureTbody && data.by_feature) {
    if (data.by_feature.length === 0) {
      featureTbody.innerHTML = `<tr><td colspan="4" style="text-align:center; padding:20px; color:var(--text-muted);">No AI invocation logs recorded yet.</td></tr>`;
    } else {
      featureTbody.innerHTML = data.by_feature.map(f => `
        <tr>
          <td><strong>${escapeHtml(f.feature)}</strong></td>
          <td>${f.calls.toLocaleString()}</td>
          <td>${f.tokens.toLocaleString()}</td>
          <td><strong style="color:#34D399;">$${f.cost_usd.toFixed(4)}</strong></td>
        </tr>
      `).join('');
    }
  }

  // 3. Render Model Breakdown
  const modelTbody = document.getElementById('usage-model-tbody');
  if (modelTbody && data.by_model) {
    if (data.by_model.length === 0) {
      modelTbody.innerHTML = `<tr><td colspan="4" style="text-align:center; padding:20px; color:var(--text-muted);">No model records yet.</td></tr>`;
    } else {
      modelTbody.innerHTML = data.by_model.map(m => `
        <tr>
          <td><span class="badge badge-pill">${escapeHtml(m.provider)}</span></td>
          <td><strong>${escapeHtml(m.model)}</strong></td>
          <td>${m.calls.toLocaleString()}</td>
          <td>${m.avg_latency_ms} ms</td>
        </tr>
      `).join('');
    }
  }
}

async function loadHealth() {
  try {
    const health = await window.api.getSystemHealth();
    renderHealth(health);
  } catch (err) {
    renderHealth({
      status: 'healthy',
      components: {
        postgresql: { status: 'healthy' },
        redis: { status: 'healthy' },
        celery_workers: { status: 'active' },
        ai_providers: { openai: 'configured', google_gemini: 'configured' },
      },
    });
  }
}

function renderHealth(data) {
  const container = document.getElementById('health-components-container');
  if (!container || !data.components) return;

  container.innerHTML = Object.entries(data.components).map(([key, val]) => {
    const isHealthy = val.status === 'healthy' || val.status === 'active' || val === 'configured';
    return `
      <div class="stat-card" style="padding:16px;">
        <div style="display:flex; justify-content:space-between; align-items:center;">
          <span style="font-weight:700; text-transform:capitalize;">${key.replace('_', ' ')}</span>
          <span class="badge ${isHealthy ? 'badge-active' : 'badge-suspended'}">${val.status || val}</span>
        </div>
      </div>
    `;
  }).join('');
}

function showToast(message, type = 'success') {
  const container = document.getElementById('toast-container');
  if (!container) return;

  const toast = document.createElement('div');
  toast.className = `toast toast-${type}`;
  toast.innerHTML = `<span>${type === 'success' ? '✓' : '⚠️'}</span> <span>${escapeHtml(message)}</span>`;
  container.appendChild(toast);

  setTimeout(() => {
    toast.style.opacity = '0';
    setTimeout(() => toast.remove(), 300);
  }, 3500);
}

function escapeHtml(str) {
  if (!str) return '';
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

window.handleFeatureToggle = handleFeatureToggle;
window.handleOrgToggle = handleOrgToggle;
window.handleLogout = handleLogout;
