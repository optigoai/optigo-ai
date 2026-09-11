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
  setupLeadsControls();
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
    leads: { title: 'Leads & Onboarding Funnel', sub: 'Single-page business audit leads, progression timeline, and conversions' },
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
      loadLeadsStats(),
      loadLeads(),
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
      loadLeadsStats(),
      loadLeads(),
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
            ? `<button class="badge badge-pill" style="cursor:pointer; background:var(--primary-light); color:var(--primary); border:1px solid rgba(37,99,235,0.3); font-weight:700;" onclick="openBusinessDetail('${firstBiz.id}')">${o.businesses_count} Business${o.businesses_count > 1 ? 'es' : ''} (Inspect)</button>` 
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
    tbody.innerHTML = `<tr><td colspan="6" style="text-align:center; padding:30px; color:var(--text-muted);">No businesses registered yet.</td></tr>`;
    return;
  }

  tbody.innerHTML = businesses.map(b => `
    <tr class="clickable-row" onclick="openBusinessDetail('${b.id}')" title="Click to view full DB profile and edit details">
      <td>
        <div style="font-weight:700; color:var(--text-primary);">
          ${escapeHtml(b.name)}
        </div>
      </td>
      <td><span class="badge badge-pill">${escapeHtml(b.category || 'General')}</span></td>
      <td>${escapeHtml(b.location || 'Not Specified')}</td>
      <td>
        ${b.website 
          ? `<a href="${escapeHtml(b.website)}" target="_blank" onclick="event.stopPropagation();" style="color:var(--primary); font-weight:600; text-decoration:none;">${escapeHtml(b.website)}</a>` 
          : '<span style="color:var(--text-muted);">N/A</span>'}
      </td>
      <td>
        <span class="badge ${b.onboarding_completed ? 'badge-active' : 'badge-suspended'}">
          ${b.onboarding_completed ? 'Onboarded' : 'Pending'}
        </span>
      </td>
      <td>
        <button type="button" class="btn btn-secondary" style="padding:5px 12px; font-size:0.75rem; font-weight:700; color:var(--primary); border-color:rgba(37,99,235,0.3); background:var(--primary-light);" onclick="event.stopPropagation(); openBusinessDetail('${b.id}')">
          Inspect & Edit
        </button>
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
  document.getElementById('modal-biz-title').innerText = 'Loading Complete Business Data...';
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
    document.getElementById('edit-biz-health-score').value = data.health_score !== null && data.health_score !== undefined ? data.health_score : '';
    document.getElementById('edit-biz-gbp-acc').value = data.gbp_account_id || '';
    document.getElementById('edit-biz-gbp-loc').value = data.gbp_location_id || '';
    document.getElementById('edit-biz-uuid-readonly').value = data.id || '';
    document.getElementById('edit-biz-description').value = data.description || '';

    // Tab 2: Onboarding & Strategy
    document.getElementById('edit-biz-target-customers').value = data.target_customers || '';
    document.getElementById('edit-biz-services').value = Array.isArray(data.services) ? data.services.join(', ') : (data.services || '');
    document.getElementById('edit-biz-goals').value = Array.isArray(data.business_goals) ? data.business_goals.join(', ') : (data.business_goals || '');
    document.getElementById('edit-biz-channels').value = Array.isArray(data.marketing_channels) ? data.marketing_channels.join(', ') : (data.marketing_channels || '');
    document.getElementById('edit-biz-ai-profile').value = data.ai_business_profile ? JSON.stringify(data.ai_business_profile, null, 2) : '';
    document.getElementById('edit-biz-health-analysis').value = data.health_analysis ? JSON.stringify(data.health_analysis, null, 2) : '';

    // Tab 3: Tenant & Organization
    const org = data.organization || {};
    document.getElementById('edit-org-name').value = org.name || data.organization_name || '';
    document.getElementById('edit-org-slug').value = org.slug || '';
    document.getElementById('edit-org-id').value = org.id || data.organization_id || '';
    document.getElementById('edit-org-status').value = (org.is_active !== false && data.organization_is_active !== false) ? 'true' : 'false';
    const orgBadge = document.getElementById('org-tab-badge');
    if (orgBadge) {
      const isOrgActive = (org.is_active !== false && data.organization_is_active !== false);
      orgBadge.className = `badge ${isOrgActive ? 'badge-active' : 'badge-suspended'}`;
      orgBadge.innerText = isOrgActive ? 'Active Tenant' : 'Suspended Tenant';
    }
    document.getElementById('org-meta-dates').innerText = `Created: ${org.created_at ? new Date(org.created_at).toLocaleString() : 'N/A'} • Updated: ${org.updated_at ? new Date(org.updated_at).toLocaleString() : 'N/A'}`;

    // Tab 4: Users
    renderModalUsers(data.users || []);

    // Tab 5: Reviews
    renderModalReviews(data.reviews || [], data.stats || {});

    // Tab 6: SEO, Keywords & Crawl
    renderModalSEO(data);

    // Tab 7: Marketing, Campaigns & Competitors
    renderModalMarketing(data);

    // Tab 8: Raw JSON
    renderModalRawJson(data);

  } catch (err) {
    showToast(`Failed to load business details: ${err.message}`, 'error');
  }
}

function renderModalUsers(users) {
  const container = document.getElementById('modal-users-list-container');
  if (!container) return;

  if (users.length === 0) {
    container.innerHTML = `<div style="text-align:center; padding:24px; color:var(--text-muted); background:#F8FAFC; border-radius:var(--radius-md); border:1px dashed var(--border-color);">No users associated with this organization in the database.</div>`;
    return;
  }

  container.innerHTML = users.map(u => {
    const roleVal = (u.role || 'user').toLowerCase();
    return `
    <div class="user-editor-card" id="user-card-${u.id}" style="background:#F8FAFC; border:1px solid var(--border-color); border-radius:var(--radius-md); padding:14px; margin-bottom:12px;">
      <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:10px;">
        <div>
          <strong style="font-size:0.95rem; color:var(--text-primary);">${escapeHtml(u.full_name || 'Unnamed User')}</strong>
          <span style="font-size:0.75rem; color:var(--text-muted); margin-left:8px;">UUID: <code style="font-family:monospace;">${u.id}</code></span>
        </div>
        <span class="badge ${u.is_active ? 'badge-active' : 'badge-suspended'}">${u.is_active ? 'Active User' : 'Suspended'}</span>
      </div>

      <div class="form-grid-3">
        <div class="form-group">
          <label>Full Name</label>
          <input type="text" id="user-name-${u.id}" class="form-input" value="${escapeHtml(u.full_name || '')}">
        </div>
        <div class="form-group">
          <label>Email Address</label>
          <input type="email" id="user-email-${u.id}" class="form-input" value="${escapeHtml(u.email || '')}">
        </div>
        <div class="form-group">
          <label>Role in Organization</label>
          <select id="user-role-${u.id}" class="form-select">
            <option value="owner" ${roleVal === 'owner' || roleVal === 'business_owner' ? 'selected' : ''}>Organization Owner</option>
            <option value="manager" ${roleVal === 'manager' || roleVal === 'marketing_manager' ? 'selected' : ''}>Marketing Manager</option>
            <option value="user" ${roleVal === 'user' ? 'selected' : ''}>Standard User</option>
            <option value="admin" ${roleVal === 'admin' ? 'selected' : ''}>Super Administrator</option>
          </select>
        </div>
      </div>

      <div style="display:flex; justify-content:space-between; align-items:center; margin-top:12px; padding-top:10px; border-top:1px solid var(--border-color);">
        <label style="display:flex; align-items:center; gap:8px; font-size:0.82rem; cursor:pointer; color:var(--text-primary); font-weight:600;">
          <input type="checkbox" id="user-active-${u.id}" ${u.is_active ? 'checked' : ''}>
          <span>Account Active & Enabled</span>
        </label>
        <div style="display:flex; align-items:center; gap:10px;">
          <span style="font-size:0.75rem; color:var(--text-muted);">Joined: ${u.created_at ? new Date(u.created_at).toLocaleDateString() : 'N/A'}</span>
          <button type="button" class="btn btn-secondary" style="padding:4px 12px; font-size:0.78rem;" onclick="handleSaveUserModal('${u.id}')">
            Save User
          </button>
        </div>
      </div>
    </div>
  `;
  }).join('');
}

function renderModalReviews(reviews, stats) {
  const tbody = document.getElementById('modal-reviews-tbody');
  const title = document.getElementById('reviews-tab-title');
  const avgText = document.getElementById('reviews-tab-avg');
  if (!tbody) return;

  if (title) title.innerText = `Customer Reviews in Database (${reviews.length})`;
  if (avgText) avgText.innerText = `Average Rating: ${stats.average_rating || 0.0} / 5.0 ⭐`;

  if (reviews.length === 0) {
    tbody.innerHTML = `<tr><td colspan="5" style="text-align:center; padding:24px; color:var(--text-muted);">No customer reviews recorded in the database yet.</td></tr>`;
    return;
  }

  tbody.innerHTML = reviews.map(r => {
    const stars = '★'.repeat(Math.round(r.rating || 5)) + '☆'.repeat(5 - Math.round(r.rating || 5));
    const sentiment = (r.sentiment || 'NEUTRAL').toUpperCase();
    let sentBadge = 'badge-active';
    if (sentiment === 'NEGATIVE') sentBadge = 'badge-suspended';
    else if (sentiment === 'NEUTRAL') sentBadge = 'badge-draft';

    return `
      <tr>
        <td style="color:#F59E0B; font-weight:800; white-space:nowrap;">${stars} (${r.rating})</td>
        <td><strong>${escapeHtml(r.author_name || 'Anonymous')}</strong></td>
        <td style="max-width:300px;">
          <div>${escapeHtml(r.review_text || '')}</div>
          ${r.response_text ? `<div style="font-size:0.75rem; color:var(--primary-color); margin-top:4px; background:#EFF6FF; padding:4px 8px; border-radius:6px;"><strong>Owner Reply:</strong> ${escapeHtml(r.response_text)}</div>` : ''}
        </td>
        <td><span class="badge ${sentBadge}">${sentiment}</span></td>
        <td style="white-space:nowrap; color:var(--text-muted); font-size:0.75rem;">${r.review_date ? new Date(r.review_date).toLocaleDateString() : (r.created_at ? new Date(r.created_at).toLocaleDateString() : '-')}</td>
      </tr>
    `;
  }).join('');
}

function renderModalSEO(data) {
  const audit = data.seo_audit || {};
  const webAudit = data.website_audit || {};
  const gsc = data.gsc_connection || {};
  const keywords = data.seo_keywords || [];

  // Metrics
  const mapScore = document.getElementById('seo-tab-map-score');
  if (mapScore) mapScore.innerText = audit.map_pack_score ? `${audit.map_pack_score}% (Visibility)` : 'Not Audited';

  const crawlScore = document.getElementById('seo-tab-crawl-score');
  if (crawlScore) crawlScore.innerText = webAudit.overall_score ? `${webAudit.overall_score}/100 Score` : 'Not Audited';

  const gscStatus = document.getElementById('seo-tab-gsc-status');
  if (gscStatus) {
    gscStatus.innerText = gsc.is_connected ? 'Connected' : 'Disconnected';
    gscStatus.style.color = gsc.is_connected ? 'var(--emerald-text)' : 'var(--text-muted)';
  }

  // Keywords Table
  const kwTbody = document.getElementById('modal-keywords-tbody');
  if (kwTbody) {
    if (keywords.length === 0) {
      kwTbody.innerHTML = `<tr><td colspan="6" style="text-align:center; padding:20px; color:var(--text-muted);">No keywords tracked in database.</td></tr>`;
    } else {
      kwTbody.innerHTML = keywords.map(kw => `
        <tr>
          <td><strong>${escapeHtml(kw.keyword)}</strong></td>
          <td><span class="badge ${kw.current_rank && kw.current_rank <= 3 ? 'badge-active' : 'badge-draft'}">${kw.current_rank ? '#' + kw.current_rank : '—'}</span></td>
          <td style="color:var(--text-muted);">${kw.best_rank ? '#' + kw.best_rank : '—'}</td>
          <td>${escapeHtml(kw.search_volume || 'N/A')}</td>
          <td><span class="badge badge-active">${escapeHtml(kw.difficulty || 'Medium')}</span></td>
          <td style="color:var(--text-secondary);">${escapeHtml(kw.target_location || 'Global/Local')}</td>
        </tr>
      `).join('');
    }
  }

  // Crawl Findings
  const findingsContainer = document.getElementById('modal-crawl-findings-list');
  if (findingsContainer) {
    const findings = webAudit.findings || [];
    if (findings.length === 0) {
      findingsContainer.innerHTML = `<div style="text-align:center; padding:16px; color:var(--text-muted); background:#F8FAFC; border-radius:var(--radius-md);">No technical crawl findings recorded for this website.</div>`;
    } else {
      findingsContainer.innerHTML = findings.map(f => {
        const isPass = f.status === 'pass';
        return `
          <div style="background:${isPass ? '#F0FDF4' : '#FEF2F2'}; border:1px solid ${isPass ? '#BBF7D0' : '#FECACA'}; border-radius:var(--radius-md); padding:10px 14px;">
            <div style="display:flex; justify-content:space-between; align-items:center;">
              <strong style="font-size:0.85rem; color:${isPass ? '#15803D' : '#991B1B'};">${escapeHtml(f.title || '')}</strong>
              <span class="badge ${isPass ? 'badge-active' : 'badge-suspended'}">${isPass ? 'PASSED' : (f.impact || 'WARNING').toUpperCase()}</span>
            </div>
            ${f.fix ? `<div style="font-size:0.78rem; color:#475569; margin-top:4px;"><strong>Fix:</strong> ${escapeHtml(f.fix)}</div>` : ''}
          </div>
        `;
      }).join('');
    }
  }
}

function renderModalMarketing(data) {
  const campaigns = data.campaigns || [];
  const contents = data.contents || [];
  const competitors = data.competitors || [];

  // Campaigns
  const campTbody = document.getElementById('modal-campaigns-tbody');
  if (campTbody) {
    if (campaigns.length === 0) {
      campTbody.innerHTML = `<tr><td colspan="5" style="text-align:center; padding:16px; color:var(--text-muted);">No campaigns in database.</td></tr>`;
    } else {
      campTbody.innerHTML = campaigns.map(c => `
        <tr>
          <td><strong>${escapeHtml(c.name)}</strong></td>
          <td style="color:var(--text-secondary);">${escapeHtml(c.objective || '')}</td>
          <td style="color:var(--text-secondary);">${escapeHtml(c.audience || '')}</td>
          <td><span class="badge badge-active">${escapeHtml(c.status || 'DRAFT')}</span></td>
          <td style="color:var(--text-muted); font-size:0.75rem;">${c.created_at ? new Date(c.created_at).toLocaleDateString() : '-'}</td>
        </tr>
      `).join('');
    }
  }

  // Contents
  const contentTbody = document.getElementById('modal-contents-tbody');
  if (contentTbody) {
    if (contents.length === 0) {
      contentTbody.innerHTML = `<tr><td colspan="5" style="text-align:center; padding:16px; color:var(--text-muted);">No generated content in database.</td></tr>`;
    } else {
      contentTbody.innerHTML = contents.map(ct => `
        <tr>
          <td><span class="badge badge-active">${escapeHtml(ct.content_type || 'POST')}</span></td>
          <td><strong>${escapeHtml(ct.title || 'Untitled')}</strong></td>
          <td style="color:var(--text-secondary); font-size:0.75rem; max-width:250px;">${escapeHtml(ct.body || '')}</td>
          <td><span class="badge badge-draft">${escapeHtml(ct.status || 'DRAFT')}</span></td>
          <td style="color:var(--text-muted); font-size:0.75rem;">${ct.created_at ? new Date(ct.created_at).toLocaleDateString() : '-'}</td>
        </tr>
      `).join('');
    }
  }

  // Competitors
  const compTbody = document.getElementById('modal-competitors-tbody');
  if (compTbody) {
    if (competitors.length === 0) {
      compTbody.innerHTML = `<tr><td colspan="5" style="text-align:center; padding:16px; color:var(--text-muted);">No tracked competitors in database.</td></tr>`;
    } else {
      compTbody.innerHTML = competitors.map(cp => `
        <tr>
          <td><strong>${escapeHtml(cp.name)}</strong></td>
          <td style="color:var(--text-secondary);">${escapeHtml(cp.category || '')}</td>
          <td style="color:var(--text-secondary);">${escapeHtml(cp.location || '')}</td>
          <td style="color:#F59E0B; font-weight:700;">★ ${cp.rating || 0.0}</td>
          <td style="color:var(--text-muted);">${cp.reviews_count || 0} reviews</td>
        </tr>
      `).join('');
    }
  }
}

function renderModalRawJson(data) {
  const viewer = document.getElementById('modal-raw-json-viewer');
  if (viewer) {
    viewer.innerText = JSON.stringify(data, null, 2);
  }
}

function copyRawBusinessJson() {
  if (!activeBusinessDetailData) return;
  const jsonStr = JSON.stringify(activeBusinessDetailData, null, 2);
  navigator.clipboard.writeText(jsonStr).then(() => {
    showToast('✨ Complete database document copied to clipboard!', 'success');
  }).catch(() => {
    showToast('Failed to copy to clipboard', 'error');
  });
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

async function handleSaveOrganizationModal() {
  if (!activeBusinessDetailData) return;
  const orgId = activeBusinessDetailData.organization_id || (activeBusinessDetailData.organization && activeBusinessDetailData.organization.id);
  if (!orgId) {
    showToast('Organization ID not found', 'error');
    return;
  }

  const name = document.getElementById('edit-org-name').value.trim();
  const slug = document.getElementById('edit-org-slug').value.trim();
  const isActive = document.getElementById('edit-org-status').value === 'true';

  try {
    await window.api.updateOrganization(orgId, { name, slug, is_active: isActive });
    showToast(`Organization '${name}' updated successfully!`, 'success');
    loadOrganizations();
    loadBusinesses();
  } catch (err) {
    showToast(`Failed to update organization: ${err.message}`, 'error');
  }
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
        showToast('Warning: Invalid JSON in AI Business Profile.', 'error');
      }
    }

    let healthAnalysis = null;
    const healthAnalysisRaw = document.getElementById('edit-biz-health-analysis').value.trim();
    if (healthAnalysisRaw) {
      try {
        healthAnalysis = JSON.parse(healthAnalysisRaw);
      } catch (e) {
        showToast('Warning: Invalid JSON in AI Health Analysis.', 'error');
      }
    }

    const healthScoreRaw = document.getElementById('edit-biz-health-score').value.trim();
    const healthScore = healthScoreRaw ? parseInt(healthScoreRaw, 10) : null;

    const payload = {
      name: document.getElementById('edit-biz-name').value.trim(),
      category: document.getElementById('edit-biz-category').value.trim(),
      location: document.getElementById('edit-biz-location').value.trim(),
      website: document.getElementById('edit-biz-website').value.trim() || null,
      phone: document.getElementById('edit-biz-phone').value.trim() || null,
      description: document.getElementById('edit-biz-description').value.trim() || null,
      onboarding_completed: document.getElementById('edit-biz-onboard-status').value === 'true',
      health_score: healthScore,
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
    if (healthAnalysis) {
      payload.health_analysis = healthAnalysis;
    }

    await window.api.updateBusiness(activeBusinessDetailId, payload);
    showToast(`Business '${payload.name}' updated successfully in the database!`, 'success');

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
    showToast(`User '${name}' updated successfully!`, 'success');
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
        const tokens = u.tokens !== undefined ? u.tokens : (u.total_tokens || 0);
        const calls = u.calls !== undefined ? u.calls : (u.request_count || 0);
        const cost = u.cost_usd !== undefined ? u.cost_usd : (u.estimated_cost_usd || 0);
        const model = u.preferred_model || u.model || 'gemini-2.0-flash';
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
            <td><code>${escapeHtml(model)}</code></td>
            <td><strong>${tokens.toLocaleString()}</strong></td>
            <td>${calls.toLocaleString()}</td>
            <td style="color:#10B981; font-weight:700;">$${cost.toFixed(4)}</td>
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
      featureTbody.innerHTML = data.by_feature.map(f => {
        const featureName = f.feature || f.feature_name || 'AI Module';
        const tokens = f.tokens !== undefined ? f.tokens : (f.total_tokens || 0);
        const cost = f.cost_usd !== undefined ? f.cost_usd : (f.estimated_cost_usd || 0);
        return `
          <tr>
            <td><span class="badge badge-pill">${escapeHtml(featureName)}</span></td>
            <td>${tokens.toLocaleString()}</td>
            <td style="color:#10B981; font-weight:700;">$${cost.toFixed(4)}</td>
          </tr>
        `;
      }).join('');
    }
  }

  // 3. Render By-Model Latency
  const modelTbody = document.getElementById('usage-model-tbody');
  if (modelTbody && data.by_model) {
    if (data.by_model.length === 0) {
      modelTbody.innerHTML = `<tr><td colspan="4" style="text-align:center; padding:20px; color:var(--text-muted);">No model logs available.</td></tr>`;
    } else {
      modelTbody.innerHTML = data.by_model.map(m => {
        const calls = m.calls !== undefined ? m.calls : (m.request_count || 0);
        const latency = m.avg_latency_ms !== undefined ? m.avg_latency_ms : 0;
        return `
          <tr>
            <td>${escapeHtml(m.provider)}</td>
            <td><code>${escapeHtml(m.model)}</code></td>
            <td>${calls.toLocaleString()}</td>
            <td>${latency.toFixed(0)} ms</td>
          </tr>
        `;
      }).join('');
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

  const iconSvg = type === 'success'
    ? `<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"></polyline></svg>`
    : `<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="8" x2="12" y2="12"></line><line x1="12" y1="16" x2="12.01" y2="16"></line></svg>`;

  const toast = document.createElement('div');
  toast.className = `toast toast-${type}`;
  toast.innerHTML = `<span style="display:flex; align-items:center;">${iconSvg}</span> <span>${escapeHtml(message)}</span>`;
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

// ==================================================
// Leads & Onboarding Funnel Management
// ==================================================

let leadsData = [];
let leadsStatsData = null;
let activeLeadDetailId = null;
let leadsSearchTimeout = null;

function setupLeadsControls() {
  const searchInput = document.getElementById('leads-search-input');
  if (searchInput) {
    searchInput.addEventListener('input', () => {
      if (leadsSearchTimeout) clearTimeout(leadsSearchTimeout);
      leadsSearchTimeout = setTimeout(() => {
        loadLeads();
      }, 300);
    });
  }

  const statusFilter = document.getElementById('leads-filter-status');
  if (statusFilter) {
    statusFilter.addEventListener('change', () => loadLeads());
  }

  const priorityFilter = document.getElementById('leads-filter-priority');
  if (priorityFilter) {
    priorityFilter.addEventListener('change', () => loadLeads());
  }

  const refreshBtn = document.getElementById('btn-refresh-leads');
  if (refreshBtn) {
    refreshBtn.addEventListener('click', () => {
      loadLeadsStats();
      loadLeads();
      showToast('Leads data refreshed', 'success');
    });
  }
}

async function loadLeadsStats() {
  try {
    const stats = await window.api.getLeadsStats();
    leadsStatsData = stats;
    renderLeadsStats(stats);
  } catch (err) {
    console.error('Failed to load lead stats:', err);
  }
}

function renderLeadsStats(stats) {
  if (!stats) return;
  const setEl = (id, val) => {
    const el = document.getElementById(id);
    if (el) el.innerText = val;
  };
  setEl('stat-leads-total', stats.total_leads || 0);
  setEl('stat-leads-new', stats.new_leads || 0);
  setEl('stat-leads-active', stats.active_onboarding || 0);
  setEl('stat-leads-ready', stats.report_ready || 0);
  setEl('stat-leads-converted', stats.converted_leads || 0);
  setEl('stat-leads-rate', `${stats.conversion_rate || 0}%`);
  setEl('stat-leads-stuck', stats.stuck_abandoned || 0);
}

async function loadLeads() {
  try {
    const status = document.getElementById('leads-filter-status')?.value || null;
    const priority = document.getElementById('leads-filter-priority')?.value || null;
    const search = document.getElementById('leads-search-input')?.value?.trim() || null;

    const res = await window.api.getLeads(status, priority, search);
    leadsData = res.leads || [];
    renderLeadsTable(leadsData);
  } catch (err) {
    console.error('Failed to load leads:', err);
    leadsData = [];
    renderLeadsTable([]);
  }
}

function getStageBadge(stage) {
  const stageMap = {
    new_lead: { label: 'New Lead', cls: 'badge-pill' },
    search_started: { label: 'Search Started', cls: 'badge-pill' },
    business_selected: { label: 'Business Selected', cls: 'badge-pill' },
    form_submitted: { label: 'Audit Requested', cls: 'badge-active' },
    analysis_started: { label: 'Analyzing', cls: 'badge-active' },
    report_processing: { label: 'Generating Report', cls: 'badge-active' },
    report_ready: { label: 'Report Ready', cls: 'badge-active' },
    report_viewed: { label: 'Report Viewed', cls: 'badge-active' },
    plan_selected: { label: 'Plan Selected', cls: 'badge-active' },
    payment_pending: { label: 'Payment Pending', cls: 'badge-active' },
    converted: { label: 'Converted Customer', cls: 'badge-active' },
    abandoned: { label: 'Abandoned', cls: 'badge-suspended' },
    stuck: { label: 'Stuck / Intervention', cls: 'badge-suspended' },
  };

  const info = stageMap[stage] || { label: (stage || '').replace('_', ' ').toUpperCase(), cls: 'badge-pill' };
  return `<span class="badge ${info.cls}">${info.label}</span>`;
}

function getPriorityBadge(priority) {
  // Clean badges without hardcoded emojis
  if (priority === 'hot') {
    return `<span class="badge" style="background:rgba(239, 68, 68, 0.15); color:#F87171; border:1px solid rgba(239, 68, 68, 0.3); font-weight:700;">Hot</span>`;
  }
  if (priority === 'warm') {
    return `<span class="badge" style="background:rgba(245, 158, 11, 0.15); color:#FBBF24; border:1px solid rgba(245, 158, 11, 0.3); font-weight:700;">Warm</span>`;
  }
  return `<span class="badge" style="background:rgba(100, 116, 139, 0.15); color:#94A3B8; border:1px solid rgba(100, 116, 139, 0.3); font-weight:700;">Cold</span>`;
}

function renderLeadsTable(leads) {
  const tbody = document.getElementById('leads-tbody');
  if (!tbody) return;

  if (!leads || leads.length === 0) {
    tbody.innerHTML = `<tr><td colspan="8" style="text-align:center; padding:32px; color:var(--text-muted);">No onboarding leads found matching filters.</td></tr>`;
    return;
  }

  tbody.innerHTML = leads.map(l => {
    const formattedPhone = `${l.country_code || ''} ${l.phone || ''}`.trim();
    const cleanDigits = (l.phone || '').replace(/[^0-9]/g, '');
    const lastActive = l.last_activity_at ? new Date(l.last_activity_at).toLocaleDateString(undefined, { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' }) : 'Recently';

    return `
      <tr class="clickable-row" onclick="openLeadDetail('${l.id}')">
        <td>
          <div style="font-weight:700; color:var(--text-primary); font-size:0.95rem;">
            ${escapeHtml(l.business_name)}
          </div>
          <div style="font-size:0.75rem; color:var(--text-secondary); margin-top:2px;">
            ${escapeHtml(l.category || 'Local Business')} • ${escapeHtml(l.address || 'Address unlisted')}
          </div>
        </td>
        <td>
          <div style="font-weight:600; color:var(--text-primary);">${escapeHtml(formattedPhone)}</div>
          <div style="display:flex; gap:8px; margin-top:4px;">
            <a href="tel:${cleanDigits}" onclick="event.stopPropagation();" style="font-size:0.75rem; color:var(--primary); text-decoration:none; font-weight:600;">Call</a>
          </div>
        </td>
        <td>${getStageBadge(l.status)}</td>
        <td>${getPriorityBadge(l.priority)}</td>
        <td>
          <span style="font-weight:700; color:#60A5FA;">
            ${l.report_score !== null && l.report_score !== undefined ? `${l.report_score}/100` : '--'}
          </span>
        </td>
        <td>
          <div style="font-size:0.85rem; font-weight:600; text-transform:capitalize; color:var(--text-primary);">
            ${l.selected_plan || 'None'}
          </div>
          <span class="badge ${l.payment_status === 'paid' ? 'badge-active' : 'badge-suspended'}" style="font-size:0.7rem; padding:1px 6px;">
            ${l.payment_status || 'unpaid'}
          </span>
        </td>
        <td style="font-size:0.8rem; color:var(--text-secondary);">${lastActive}</td>
        <td>
          <div style="display:flex; gap:8px;">
            <button type="button" class="btn btn-secondary" style="padding:4px 10px; font-size:0.75rem; font-weight:700; color:var(--primary); background:var(--primary-light);" onclick="event.stopPropagation(); openLeadDetail('${l.id}')">
              Inspect
            </button>
            <a href="/report/${l.id}" target="_blank" onclick="event.stopPropagation();" class="btn btn-secondary" style="padding:4px 8px; font-size:0.75rem; text-decoration:none;" title="Open Public Report">
              ↗
            </a>
          </div>
        </td>
      </tr>
    `;
  }).join('');
}

async function openLeadDetail(leadId) {
  activeLeadDetailId = leadId;
  const modal = document.getElementById('lead-detail-modal');
  if (!modal) return;

  switchLeadModalTab('overview');
  modal.style.display = 'flex';

  try {
    const lead = await window.api.getLeadDetail(leadId);

    // Header
    document.getElementById('lead-modal-biz-name').innerText = lead.business_name || 'Lead';
    document.getElementById('lead-modal-stage-badge').innerHTML = getStageBadge(lead.status);
    document.getElementById('lead-modal-priority-badge').innerHTML = getPriorityBadge(lead.priority);
    document.getElementById('lead-modal-phone').innerText = `${lead.country_code || ''} ${lead.phone || ''}`.trim();
    document.getElementById('lead-modal-category').innerText = lead.category || 'Local Business';

    const publicLink = document.getElementById('lead-modal-public-link');
    if (publicLink) publicLink.href = `/report/${lead.id}`;

    // Overview Stats
    document.getElementById('lead-detail-score').innerText = lead.report_score !== null && lead.report_score !== undefined ? `${lead.report_score}/100` : '--';
    document.getElementById('lead-detail-plan').innerText = lead.selected_plan || 'None';
    document.getElementById('lead-detail-payment-status').innerText = `Payment: ${lead.payment_status || 'unpaid'}`;

    const reportData = lead.report_data || {};
    const impact = reportData.business_impact || {};
    document.getElementById('lead-detail-missed-calls').innerText = impact.estimated_missed_calls_monthly ? `~${impact.estimated_missed_calls_monthly}` : '--';

    // Issues List
    const issuesListEl = document.getElementById('lead-detail-issues-list');
    if (issuesListEl) {
      const issues = reportData.issues || [];
      if (issues.length === 0) {
        issuesListEl.innerHTML = `<div style="color:var(--text-muted); font-size:0.85rem;">No critical issues logged in report.</div>`;
      } else {
        issuesListEl.innerHTML = issues.map(iss => `
          <div style="background:var(--bg-card); border:1px solid var(--border-color); border-radius:8px; padding:12px 14px;">
            <div style="display:flex; align-items:center; justify-content:space-between; margin-bottom:4px;">
              <strong style="color:var(--text-primary); font-size:0.9rem;">${escapeHtml(iss.title)}</strong>
              <span class="badge ${iss.severity === 'critical' ? 'badge-suspended' : 'badge-pill'}" style="font-size:0.7rem; text-transform:uppercase;">${iss.severity}</span>
            </div>
            <p style="font-size:0.82rem; color:var(--text-secondary); margin:0 0 6px 0;">${escapeHtml(iss.summary)}</p>
            <div style="font-size:0.8rem; color:#60A5FA;"><strong>Required Fix:</strong> ${escapeHtml(iss.action)}</div>
          </div>
        `).join('');
      }
    }

    // Competitors Table
    const compTbody = document.getElementById('lead-detail-competitors-tbody');
    if (compTbody) {
      const comps = reportData.competitors || [];
      if (comps.length === 0) {
        compTbody.innerHTML = `<tr><td colspan="4" style="text-align:center; padding:14px; color:var(--text-muted);">No competitors analyzed yet.</td></tr>`;
      } else {
        compTbody.innerHTML = comps.map(c => `
          <tr>
            <td style="font-weight:600; color:var(--text-primary);">${escapeHtml(c.name)}</td>
            <td style="color:#10B981; font-weight:700;">Rank #${c.rank}</td>
            <td>${c.rating} (${c.review_count})</td>
            <td style="color:var(--text-secondary);">${escapeHtml(c.advantage)}</td>
          </tr>
        `).join('');
      }
    }

    // Timeline
    const timelineEl = document.getElementById('lead-detail-timeline-container');
    if (timelineEl) {
      const timeline = lead.timeline || [];
      if (timeline.length === 0) {
        timelineEl.innerHTML = `<div style="color:var(--text-muted); font-size:0.85rem;">No timeline events recorded.</div>`;
      } else {
        timelineEl.innerHTML = timeline.map(evt => `
          <div style="display:flex; gap:12px; align-items:flex-start;">
            <div style="width:10px; height:10px; border-radius:50%; background:#3B82F6; margin-top:5px; flex-shrink:0;"></div>
            <div>
              <div style="font-weight:700; color:var(--text-primary); font-size:0.88rem;">${escapeHtml(evt.title || evt.label || evt.stage)}</div>
              <div style="font-size:0.8rem; color:var(--text-secondary);">${escapeHtml(evt.description || '')}</div>
              <div style="font-size:0.75rem; color:var(--text-muted); margin-top:2px;">${evt.timestamp ? new Date(evt.timestamp).toLocaleString() : ''}</div>
            </div>
          </div>
        `).join('');
      }
    }

    // Status Actions
    const statusSelect = document.getElementById('lead-action-status');
    if (statusSelect) statusSelect.value = lead.status;

    const prioritySelect = document.getElementById('lead-action-priority');
    if (prioritySelect) prioritySelect.value = lead.priority;

    const notesDisplay = document.getElementById('lead-notes-display');
    if (notesDisplay) {
      notesDisplay.innerText = lead.notes || 'No admin notes recorded yet.';
    }
  } catch (err) {
    showToast(`Failed to load lead: ${err.message}`, 'error');
  }
}

function closeLeadDetailModal() {
  const modal = document.getElementById('lead-detail-modal');
  if (modal) modal.style.display = 'none';
  activeLeadDetailId = null;
}

function switchLeadModalTab(tabId) {
  ['overview', 'timeline', 'actions'].forEach(t => {
    const pane = document.getElementById(`leadmodaltab-${t}`);
    const btn = document.getElementById(`btn-leadtab-${t}`);
    if (pane) pane.style.display = t === tabId ? 'block' : 'none';
    if (btn) btn.classList.toggle('active', t === tabId);
  });
}

async function handleUpdateLeadStatus() {
  if (!activeLeadDetailId) return;
  const status = document.getElementById('lead-action-status')?.value;
  const priority = document.getElementById('lead-action-priority')?.value;

  try {
    await window.api.updateLead(activeLeadDetailId, { status, priority });
    showToast('Lead status updated successfully', 'success');
    loadLeads();
    loadLeadsStats();
    openLeadDetail(activeLeadDetailId);
  } catch (err) {
    showToast(`Failed to update lead: ${err.message}`, 'error');
  }
}

async function handleAddLeadNote() {
  if (!activeLeadDetailId) return;
  const input = document.getElementById('lead-new-note-input');
  if (!input || !input.value.trim()) return;

  const noteText = input.value.trim();
  try {
    await window.api.addLeadNote(activeLeadDetailId, noteText);
    input.value = '';
    showToast('Note appended to lead history', 'success');
    openLeadDetail(activeLeadDetailId);
  } catch (err) {
    showToast(`Failed to add note: ${err.message}`, 'error');
  }
}

window.openLeadDetail = openLeadDetail;
window.closeLeadDetailModal = closeLeadDetailModal;
window.switchLeadModalTab = switchLeadModalTab;
window.handleUpdateLeadStatus = handleUpdateLeadStatus;
window.handleAddLeadNote = handleAddLeadNote;

