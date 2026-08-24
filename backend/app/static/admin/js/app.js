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

  tbody.innerHTML = orgs.map(o => {
    const firstBiz = o.businesses && o.businesses.length > 0 ? o.businesses[0] : null;
    return `
      <tr>
        <td><strong>${escapeHtml(o.name)}</strong></td>
        <td><code>${escapeHtml(o.slug)}</code></td>
        <td>
          ${firstBiz 
            ? `<button class="badge badge-pill" style="cursor:pointer; background:rgba(59,130,246,0.18); color:#60A5FA; border:1px solid rgba(59,130,246,0.35); font-weight:700;" onclick="openBusinessDetail('${firstBiz.id}')">${o.businesses_count} Business${o.businesses_count > 1 ? 'es' : ''} (Inspect ↗)</button>` 
            : `<span class="badge badge-pill">0 Businesses</span>`}
        </td>
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
    `;
  }).join('');
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
    <tr class="clickable-row" onclick="openBusinessDetail('${b.id}')" title="Click to view full DB profile and edit details">
      <td>
        <div style="display:flex; align-items:center; justify-content:space-between;">
          <strong>${escapeHtml(b.name)}</strong>
          <span style="font-size:0.72rem; color:#60A5FA; background:rgba(59, 130, 246, 0.15); padding:2px 8px; border-radius:6px;">View & Edit ↗</span>
        </div>
      </td>
      <td><span class="badge badge-pill">${escapeHtml(b.category || 'General')}</span></td>
      <td>${escapeHtml(b.location || 'Not Specified')}</td>
      <td>
        ${b.website 
          ? `<a href="${escapeHtml(b.website)}" target="_blank" onclick="event.stopPropagation();" style="color:#60A5FA; text-decoration:none;">${escapeHtml(b.website)}</a>` 
          : '<span style="color:var(--text-muted);">N/A</span>'}
      </td>
      <td>
        <span class="badge ${b.onboarding_completed ? 'badge-active' : 'badge-suspended'}">
          ${b.onboarding_completed ? 'Onboarded' : 'Pending'}
        </span>
      </td>
    </tr>
  `).join('');
}

// Global modal state
let activeBusinessDetailId = null;
let activeBusinessDetailData = null;

async function openBusinessDetail(businessId) {
  activeBusinessDetailId = businessId;
  const modal = document.getElementById('business-detail-modal');
  if (!modal) return;

  // Reset tab to profile
  switchModalTab('profile');
  modal.style.display = 'flex';

  // Set loading state in modal
  document.getElementById('modal-biz-title').innerText = 'Loading Business Data...';
  document.getElementById('modal-biz-id').innerText = businessId;
  document.getElementById('modal-biz-org-name').innerText = '...';

  try {
    const data = await window.api.getBusinessDetail(businessId);
    activeBusinessDetailData = data;

    // Header & Meta
    document.getElementById('modal-biz-title').innerText = data.name || 'Untitled Business';
    document.getElementById('modal-biz-id').innerText = data.id;
    document.getElementById('modal-biz-org-name').innerText = data.organization_name || 'N/A';
    document.getElementById('userstab-org-slug').innerText = data.organization_name || 'N/A';

    const onboardBadge = document.getElementById('modal-biz-onboard-badge');
    if (onboardBadge) {
      onboardBadge.className = `badge ${data.onboarding_completed ? 'badge-active' : 'badge-suspended'}`;
      onboardBadge.innerText = data.onboarding_completed ? 'Onboarded' : 'Onboarding Pending';
    }

    // Tab 1: Profile & Storefront
    document.getElementById('edit-biz-name').value = data.name || '';
    document.getElementById('edit-biz-category').value = data.category || '';
    document.getElementById('edit-biz-location').value = data.location || '';
    document.getElementById('edit-biz-website').value = data.website || '';
    document.getElementById('edit-biz-phone').value = data.phone || '';
    document.getElementById('edit-biz-onboard-status').value = data.onboarding_completed ? 'true' : 'false';
    document.getElementById('edit-biz-gbp-acc').value = data.gbp_account_id || '';
    document.getElementById('edit-biz-gbp-loc').value = data.gbp_location_id || '';
    document.getElementById('edit-biz-description').value = data.description || '';

    // Tab 2: Onboarding & Strategy
    document.getElementById('edit-biz-target-customers').value = data.target_customers || '';
    document.getElementById('edit-biz-services').value = Array.isArray(data.services) ? data.services.join(', ') : (data.services || '');
    document.getElementById('edit-biz-goals').value = Array.isArray(data.business_goals) ? data.business_goals.join(', ') : (data.business_goals || '');
    document.getElementById('edit-biz-channels').value = Array.isArray(data.marketing_channels) ? data.marketing_channels.join(', ') : (data.marketing_channels || '');
    document.getElementById('edit-biz-ai-profile').value = data.ai_business_profile ? JSON.stringify(data.ai_business_profile, null, 2) : '';

    // Tab 3: Users
    renderModalUsers(data.users || []);

    // Tab 4: Database & Marketing Stats
    const stats = data.stats || {};
    document.getElementById('stat-biz-reviews').innerText = `${stats.reviews_count || 0} (${stats.average_rating || 0.0}★ Avg)`;
    document.getElementById('stat-biz-keywords').innerText = `${stats.keywords_count || 0} (${stats.top3_keywords_count || 0} in Top 3)`;
    
    if (stats.latest_audit && stats.latest_audit.overall_score) {
      document.getElementById('stat-biz-crawl').innerText = `${stats.latest_audit.overall_score}% (${stats.latest_audit.findings_count} Findings)`;
    } else {
      document.getElementById('stat-biz-crawl').innerText = 'Not Audited Yet';
    }
    document.getElementById('stat-biz-recs').innerText = `${stats.recommendations_count || 0} Action Items`;

    document.getElementById('meta-biz-created').innerText = data.created_at ? new Date(data.created_at).toLocaleString() : 'N/A';
    document.getElementById('meta-biz-updated').innerText = data.updated_at ? new Date(data.updated_at).toLocaleString() : 'N/A';
    document.getElementById('meta-biz-org-id').innerText = data.organization_id || 'N/A';

  } catch (err) {
    showToast(`Failed to load business details: ${err.message}`, 'error');
  }
}

function renderModalUsers(users) {
  const container = document.getElementById('modal-users-list-container');
  if (!container) return;

  if (users.length === 0) {
    container.innerHTML = `<div style="text-align:center; padding:20px; color:var(--text-muted);">No users associated with this organization.</div>`;
    return;
  }

  container.innerHTML = users.map(u => `
    <div class="user-editor-card" id="user-card-${u.id}">
      <div style="display:flex; justify-content:space-between; align-items:center;">
        <div>
          <strong style="font-size:0.95rem; color:var(--text-primary);">${escapeHtml(u.full_name || 'Unnamed User')}</strong>
          <span style="font-size:0.75rem; color:var(--text-muted); margin-left:8px;">ID: <code>${u.id}</code></span>
        </div>
        <span class="badge ${u.is_active ? 'badge-active' : 'badge-suspended'}">${u.is_active ? 'Active User' : 'Suspended'}</span>
      </div>

      <div class="form-grid-3" style="margin-top:8px;">
        <div class="form-group">
          <label>Full Name</label>
          <input type="text" id="user-name-${u.id}" class="form-input" value="${escapeHtml(u.full_name || '')}">
        </div>
        <div class="form-group">
          <label>Email Address</label>
          <input type="email" id="user-email-${u.id}" class="form-input" value="${escapeHtml(u.email || '')}">
        </div>
        <div class="form-group">
          <label>Role</label>
          <select id="user-role-${u.id}" class="form-select">
            <option value="business_owner" ${u.role === 'business_owner' ? 'selected' : ''}>Business Owner</option>
            <option value="marketing_manager" ${u.role === 'marketing_manager' ? 'selected' : ''}>Marketing Manager</option>
            <option value="admin" ${u.role === 'admin' ? 'selected' : ''}>Super Administrator</option>
          </select>
        </div>
      </div>

      <div style="display:flex; justify-content:space-between; align-items:center; margin-top:8px; padding-top:8px; border-top:1px solid rgba(255,255,255,0.05);">
        <label style="display:flex; align-items:center; gap:8px; font-size:0.8rem; cursor:pointer;">
          <input type="checkbox" id="user-active-${u.id}" ${u.is_active ? 'checked' : ''}>
          <span>Account Active</span>
        </label>
        <button type="button" class="btn btn-secondary" style="padding:4px 12px; font-size:0.78rem;" onclick="handleSaveUserModal('${u.id}')">
          Save User
        </button>
      </div>
    </div>
  `).join('');
}

function closeBusinessDetailModal() {
  const modal = document.getElementById('business-detail-modal');
  if (modal) modal.style.display = 'none';
  activeBusinessDetailId = null;
  activeBusinessDetailData = null;
}

function switchModalTab(tabKey) {
  document.querySelectorAll('.modal-tab-btn').forEach(btn => {
    btn.classList.toggle('active', btn.getAttribute('data-modaltab') === tabKey);
  });
  document.querySelectorAll('.modal-tab-pane').forEach(pane => {
    pane.style.display = pane.id === `modaltab-${tabKey}` ? 'block' : 'none';
  });
}

async function handleSaveBusinessModal() {
  if (!activeBusinessDetailId) return;

  const saveBtn = document.getElementById('btn-save-biz-modal');
  if (saveBtn) {
    saveBtn.innerText = 'Saving...';
    saveBtn.disabled = true;
  }

  try {
    // Parse fields
    let services = document.getElementById('edit-biz-services').value.trim();
    if (services.includes(',')) {
      services = services.split(',').map(s => s.trim()).filter(Boolean);
    }

    let goals = document.getElementById('edit-biz-goals').value.trim();
    if (goals.includes(',')) {
      goals = goals.split(',').map(s => s.trim()).filter(Boolean);
    }

    let channels = document.getElementById('edit-biz-channels').value.trim();
    if (channels.includes(',')) {
      channels = channels.split(',').map(s => s.trim()).filter(Boolean);
    }

    let aiProfile = null;
    const aiProfileRaw = document.getElementById('edit-biz-ai-profile').value.trim();
    if (aiProfileRaw) {
      try {
        aiProfile = JSON.parse(aiProfileRaw);
      } catch (e) {
        showToast('Warning: Invalid JSON in AI Business Profile. Saving as raw or ignoring parse error.', 'error');
      }
    }

    const payload = {
      name: document.getElementById('edit-biz-name').value.trim(),
      category: document.getElementById('edit-biz-category').value.trim(),
      location: document.getElementById('edit-biz-location').value.trim(),
      website: document.getElementById('edit-biz-website').value.trim() || null,
      phone: document.getElementById('edit-biz-phone').value.trim() || null,
      description: document.getElementById('edit-biz-description').value.trim() || null,
      onboarding_completed: document.getElementById('edit-biz-onboard-status').value === 'true',
      gbp_account_id: document.getElementById('edit-biz-gbp-acc').value.trim() || null,
      gbp_location_id: document.getElementById('edit-biz-gbp-loc').value.trim() || null,
      target_customers: document.getElementById('edit-biz-target-customers').value.trim() || null,
      services: services || null,
      business_goals: goals || null,
      marketing_channels: channels || null,
    };

    if (aiProfile) {
      payload.ai_business_profile = aiProfile;
    }

    await window.api.updateBusiness(activeBusinessDetailId, payload);
    showToast(`✓ Business '${payload.name}' updated successfully in the database!`, 'success');

    // Refresh modal header & table
    document.getElementById('modal-biz-title').innerText = payload.name;
    const onboardBadge = document.getElementById('modal-biz-onboard-badge');
    if (onboardBadge) {
      onboardBadge.className = `badge ${payload.onboarding_completed ? 'badge-active' : 'badge-suspended'}`;
      onboardBadge.innerText = payload.onboarding_completed ? 'Onboarded' : 'Onboarding Pending';
    }

    loadBusinesses();
    loadOrganizations();
  } catch (err) {
    showToast(`Failed to update business: ${err.message}`, 'error');
  } finally {
    if (saveBtn) {
      saveBtn.innerText = 'Save Changes';
      saveBtn.disabled = false;
    }
  }
}

async function handleSaveUserModal(userId) {
  const name = document.getElementById(`user-name-${userId}`)?.value.trim();
  const email = document.getElementById(`user-email-${userId}`)?.value.trim();
  const role = document.getElementById(`user-role-${userId}`)?.value;
  const isActive = document.getElementById(`user-active-${userId}`)?.checked;

  try {
    await window.api.updateUser(userId, {
      full_name: name,
      email: email,
      role: role,
      is_active: isActive,
    });
    showToast(`✓ User '${name}' updated successfully!`, 'success');
  } catch (err) {
    showToast(`Failed to update user: ${err.message}`, 'error');
  }
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
                <div class="user-avatar-initials">${initials}</div>
                <div>
                  <div style="font-weight:700;">${escapeHtml(u.user_name || 'Unknown')}</div>
                  <div style="font-size:0.75rem; color:var(--text-muted);">${escapeHtml(u.user_email || 'N/A')}</div>
                </div>
              </div>
            </td>
            <td><strong>${escapeHtml(u.business_name || 'N/A')}</strong></td>
            <td><span class="badge badge-pill">${escapeHtml(u.organization_name || 'N/A')}</span></td>
            <td><code>${escapeHtml(u.preferred_model || 'gpt-4o-mini')}</code></td>
            <td><strong>${(u.total_tokens || 0).toLocaleString()}</strong></td>
            <td>${u.request_count || 0}</td>
            <td style="color:#10B981; font-weight:700;">$${(u.estimated_cost_usd || 0).toFixed(4)}</td>
            <td style="font-size:0.75rem; color:var(--text-muted);">${lastActiveFormatted}</td>
          </tr>
        `;
      }).join('');
    }
  }

  // 2. Render By-Feature Usage
  const featureTbody = document.getElementById('usage-feature-tbody');
  if (featureTbody && data.by_feature) {
    if (data.by_feature.length === 0) {
      featureTbody.innerHTML = `<tr><td colspan="3" style="text-align:center; padding:20px; color:var(--text-muted);">No feature logs available.</td></tr>`;
    } else {
      featureTbody.innerHTML = data.by_feature.map(f => `
        <tr>
          <td><span class="badge badge-pill">${escapeHtml(f.feature_name)}</span></td>
          <td>${(f.total_tokens || 0).toLocaleString()}</td>
          <td style="color:#10B981; font-weight:700;">$${(f.estimated_cost_usd || 0).toFixed(4)}</td>
        </tr>
      `).join('');
    }
  }

  // 3. Render By-Model Latency
  const modelTbody = document.getElementById('usage-model-tbody');
  if (modelTbody && data.by_model) {
    if (data.by_model.length === 0) {
      modelTbody.innerHTML = `<tr><td colspan="4" style="text-align:center; padding:20px; color:var(--text-muted);">No model logs available.</td></tr>`;
    } else {
      modelTbody.innerHTML = data.by_model.map(m => `
        <tr>
          <td>${escapeHtml(m.provider)}</td>
          <td><code>${escapeHtml(m.model)}</code></td>
          <td>${m.request_count || 0}</td>
          <td>${(m.avg_latency_ms || 0).toFixed(0)} ms</td>
        </tr>
      `).join('');
    }
  }
}

async function loadHealth() {
  try {
    healthData = await window.api.getSystemHealth();
    renderHealth(healthData);
  } catch (err) {
    renderHealth({ components: { postgres: 'error', redis: 'error', celery: 'error', openai: 'error', gemini: 'error' } });
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
window.openBusinessDetail = openBusinessDetail;
window.closeBusinessDetailModal = closeBusinessDetailModal;
window.switchModalTab = switchModalTab;
window.handleSaveBusinessModal = handleSaveBusinessModal;
window.handleSaveUserModal = handleSaveUserModal;
