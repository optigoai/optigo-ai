// ==================================================
// OptigoAI — Leads & Sales Funnel CRM JavaScript
// Theme: STRICT LIGHT THEME (Minimalist, Zero Emojis)
// Scalable for 100 - 10,000+ Leads (Pagination & Segments)
// ==================================================

const API_BASE = (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1')
  ? (window.location.port === '8000' ? '/api/v1' : 'http://localhost:8000/api/v1')
  : '/api/v1';

// Public frontend domain for report links
const PUBLIC_FRONTEND_URL = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1'
  ? 'http://localhost:5173'
  : 'https://optigo-ai.vercel.app';

// Global CRM State
const state = {
  allLeads: [],       // All leads fetched from current query
  filteredLeads: [],  // Leads after applying quick segment or local filter
  stats: null,
  activeView: 'kanban', // 'kanban' or 'table'
  activeSegment: 'all',
  activeLead: null,
  pagination: {
    page: 1,
    pageSize: 25,
    totalPages: 1,
  },
  filters: {
    date: 'all',
    stage: 'all',
    priority: 'all',
    plan: 'all',
    search: '',
    sort_by: 'last_activity_at',
    sort_order: 'desc',
  },
  liveSync: {
    timer: null,
    countdown: 10,
    intervalSeconds: 10,
    isPaused: false,
    isSyncing: false,
  },
  kanban: {
    smartFit: true,           // Auto-collapse 0-lead stages to fit all on screen
    manualOverrides: {},      // Track explicit user collapse/expand overrides
    activeStage: 'report_viewed', // Currently focused stage
  },
};

// Clean Stage Metadata (Zero Emojis)
const STAGES = {
  new_lead: { name: '1. Inbound', step: 1, stepLabel: 'Form Submitted', color: '#6366f1' },
  search_started: { name: '1. Inbound', step: 1, stepLabel: 'Search Started', color: '#6366f1' },
  business_selected: { name: '1. Inbound', step: 1, stepLabel: 'Business Selected', color: '#6366f1' },
  form_submitted: { name: '1. Inbound', step: 2, stepLabel: 'Phone Verified', color: '#6366f1' },
  analysis_started: { name: '1. Inbound', step: 3, stepLabel: 'Auditing Places', color: '#0284c7' },
  report_processing: { name: '2. Audit Ready', step: 3, stepLabel: 'Processing Audit', color: '#0284c7' },
  report_ready: { name: '2. Audit Ready', step: 3, stepLabel: 'Audit Generated', color: '#0284c7' },
  report_viewed: { name: '3. Report Viewed', step: 4, stepLabel: 'Report Viewed', color: '#d97706' },
  plan_selected: { name: '4. Plan Selected', step: 5, stepLabel: 'Plan Selected', color: '#ec4899' },
  payment_pending: { name: '4. Plan Selected', step: 5, stepLabel: 'Payment Pending', color: '#ec4899' },
  contacted: { name: '5. Contacted', step: 5, stepLabel: 'Contacted', color: '#8b5cf6' },
  negotiating: { name: '5. Contacted', step: 5, stepLabel: 'Negotiating', color: '#8b5cf6' },
  converted: { name: '6. Converted', step: 6, stepLabel: 'Converted', color: '#059669' },
  abandoned: { name: '7. Lost / Inactive', step: 0, stepLabel: 'Lost / Inactive', color: '#94a3b8' },
  stuck: { name: '7. Lost / Inactive', step: 0, stepLabel: 'Stuck', color: '#94a3b8' },
};

// ==================================================
// INITIALIZATION
// ==================================================
document.addEventListener('DOMContentLoaded', () => {
  initEventListeners();
  loadCRMData();
  startLiveSyncTimer();
});

// ==================================================
// EVENT LISTENERS
// ==================================================
function initEventListeners() {
  // Search Input with Debounce
  const searchInput = document.getElementById('lead-search-input');
  let debounceTimer;
  searchInput.addEventListener('input', (e) => {
    clearTimeout(debounceTimer);
    debounceTimer = setTimeout(() => {
      state.filters.search = e.target.value.trim();
      state.pagination.page = 1;
      loadCRMData();
    }, 300);
  });

  // Quick Segment Filter Buttons (All, Today, Hot, Viewed, Plans, Converted)
  document.querySelectorAll('.segment-pill').forEach((btn) => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.segment-pill').forEach((p) => p.classList.remove('active'));
      btn.classList.add('active');
      state.activeSegment = btn.dataset.segment;
      state.pagination.page = 1;
      applySegmentFilter();
    });
  });

  // Detailed Filter Dropdowns
  document.getElementById('filter-date').addEventListener('change', (e) => {
    state.filters.date = e.target.value;
    state.pagination.page = 1;
    loadCRMData();
  });

  document.getElementById('filter-stage').addEventListener('change', (e) => {
    state.filters.stage = e.target.value;
    state.pagination.page = 1;
    loadCRMData();
    if (state.filters.stage !== 'all') {
      const targetCol = getColumnForStage(state.filters.stage);
      jumpToKanbanStage(targetCol);
    }
  });

  document.getElementById('filter-priority').addEventListener('change', (e) => {
    state.filters.priority = e.target.value;
    state.pagination.page = 1;
    loadCRMData();
  });

  document.getElementById('filter-plan').addEventListener('change', (e) => {
    state.filters.plan = e.target.value;
    state.pagination.page = 1;
    loadCRMData();
  });

  document.getElementById('filter-sort').addEventListener('change', (e) => {
    const [by, order] = e.target.value.split(':');
    state.filters.sort_by = by;
    state.filters.sort_order = order;
    state.pagination.page = 1;
    loadCRMData();
  });

  // Clear Filters
  document.getElementById('btn-clear-filters').addEventListener('click', () => {
    state.filters.date = 'all';
    state.filters.stage = 'all';
    state.filters.priority = 'all';
    state.filters.plan = 'all';
    state.filters.search = '';
    state.filters.sort_by = 'last_activity_at';
    state.filters.sort_order = 'desc';
    state.activeSegment = 'all';
    state.pagination.page = 1;

    document.querySelectorAll('.segment-pill').forEach((p) => p.classList.remove('active'));
    const allPill = document.querySelector('.segment-pill[data-segment="all"]');
    if (allPill) allPill.classList.add('active');

    document.getElementById('filter-date').value = 'all';
    document.getElementById('filter-stage').value = 'all';
    document.getElementById('filter-priority').value = 'all';
    document.getElementById('filter-plan').value = 'all';
    document.getElementById('filter-sort').value = 'last_activity_at:desc';
    document.getElementById('lead-search-input').value = '';

    loadCRMData();
  });

  // View Switcher (Kanban vs Table)
  const btnKanban = document.getElementById('btn-view-kanban');
  const btnTable = document.getElementById('btn-view-table');
  const kanbanContainer = document.getElementById('kanban-view-container');
  const tableView = document.getElementById('table-view-container');

  btnKanban.addEventListener('click', () => {
    state.activeView = 'kanban';
    btnKanban.classList.add('active');
    btnTable.classList.remove('active');
    if (kanbanContainer) kanbanContainer.style.display = 'flex';
    tableView.style.display = 'none';
    renderLeads();
  });

  btnTable.addEventListener('click', () => {
    state.activeView = 'table';
    btnTable.classList.add('active');
    btnKanban.classList.remove('active');
    if (kanbanContainer) kanbanContainer.style.display = 'none';
    tableView.style.display = 'block';
    renderLeads();
  });

  // Table Pagination
  document.getElementById('btn-page-prev').addEventListener('click', () => {
    if (state.pagination.page > 1) {
      state.pagination.page--;
      renderTableView();
    }
  });

  document.getElementById('btn-page-next').addEventListener('click', () => {
    if (state.pagination.page < state.pagination.totalPages) {
      state.pagination.page++;
      renderTableView();
    }
  });

  // Live Sync Indicator Click -> Manual Refresh
  document.getElementById('live-sync-indicator').addEventListener('click', () => {
    loadCRMData(true);
  });

  // CSV Export & Reset All Leads
  document.getElementById('btn-export-csv').addEventListener('click', exportToCSV);
  const btnClearLeads = document.getElementById('btn-clear-leads');
  if (btnClearLeads) {
    btnClearLeads.addEventListener('click', clearAllLeads);
  }

  // Drawer Close Button & Backdrop Click
  const drawerBackdrop = document.getElementById('drawer-backdrop');
  document.getElementById('btn-close-drawer').addEventListener('click', closeLeadDrawer);
  drawerBackdrop.addEventListener('click', (e) => {
    if (e.target === drawerBackdrop) closeLeadDrawer();
  });

  // Drawer Stage & Priority Save Button
  document.getElementById('btn-save-lead-stage').addEventListener('click', saveLeadStageAndPriority);

  // Drawer Add Note Button
  document.getElementById('btn-add-note').addEventListener('click', addLeadNote);

  // Drawer Copy WhatsApp Text Button
  document.getElementById('btn-copy-wa').addEventListener('click', () => {
    const text = document.getElementById('drawer-whatsapp-text').innerText;
    navigator.clipboard.writeText(text).then(() => {
      const btn = document.getElementById('btn-copy-wa');
      btn.innerText = 'Copied';
      setTimeout(() => { btn.innerText = 'Copy Text'; }, 2000);
    });
  });

  // Delete Lead Button
  document.getElementById('btn-delete-lead').addEventListener('click', deleteCurrentLead);

  // Kanban Specific Navigation, Collapsing, and Drag-and-Drop
  initKanbanNavigation();
  initKanbanDragAndDrop();
}

// ==================================================
// LIVE SYNC TIMER
// ==================================================
function startLiveSyncTimer() {
  if (state.liveSync.timer) clearInterval(state.liveSync.timer);

  state.liveSync.countdown = state.liveSync.intervalSeconds;
  updateSyncIndicatorText();

  state.liveSync.timer = setInterval(() => {
    if (state.liveSync.isPaused || state.liveSync.isSyncing) return;

    state.liveSync.countdown--;
    updateSyncIndicatorText();

    if (state.liveSync.countdown <= 0) {
      loadCRMData(false);
      state.liveSync.countdown = state.liveSync.intervalSeconds;
    }
  }, 1000);
}

function updateSyncIndicatorText() {
  const label = document.getElementById('sync-status-text');
  if (state.liveSync.isSyncing) {
    label.innerText = 'Syncing...';
  } else if (state.liveSync.isPaused) {
    label.innerText = 'Sync Paused';
  } else {
    label.innerText = `Live Sync (${state.liveSync.countdown}s)`;
  }
}

// ==================================================
// DATA FETCHING (API)
// ==================================================
async function loadCRMData(isManual = false) {
  state.liveSync.isSyncing = true;
  updateSyncIndicatorText();

  const refreshIcon = document.getElementById('sync-refresh-icon');
  if (refreshIcon) refreshIcon.style.animation = 'spin 0.8s linear infinite';

  try {
    // Build query params
    const queryParams = new URLSearchParams();
    if (state.filters.status && state.filters.status !== 'all') queryParams.append('status', state.filters.status);
    if (state.filters.stage && state.filters.stage !== 'all') queryParams.append('status', state.filters.stage);
    if (state.filters.priority && state.filters.priority !== 'all') queryParams.append('priority', state.filters.priority);
    if (state.filters.plan && state.filters.plan !== 'all') queryParams.append('plan', state.filters.plan);
    if (state.filters.search) queryParams.append('search', state.filters.search);
    if (state.filters.sort_by) queryParams.append('sort_by', state.filters.sort_by);
    if (state.filters.sort_order) queryParams.append('sort_order', state.filters.sort_order);

    // Date filters
    if (state.filters.date !== 'all') {
      const now = new Date();
      let startDate;
      if (state.filters.date === 'today') {
        startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate());
      } else if (state.filters.date === 'yesterday') {
        startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate() - 1);
        const endDate = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        queryParams.append('end_date', endDate.toISOString());
      } else if (state.filters.date === '7days') {
        startDate = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
      } else if (state.filters.date === '30days') {
        startDate = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
      }
      if (startDate) queryParams.append('start_date', startDate.toISOString());
    }

    queryParams.append('limit', '500');

    // Fetch Leads & Funnel Stats
    const [leadsRes, statsRes] = await Promise.all([
      fetch(`${API_BASE}/leads?${queryParams.toString()}`),
      fetch(`${API_BASE}/leads/stats/crm`),
    ]);

    if (leadsRes.ok) {
      const leadsData = await leadsRes.json();
      state.allLeads = leadsData.leads || [];
      updateSegmentBadges();
      applySegmentFilter();
    }

    if (statsRes.ok) {
      state.stats = await statsRes.json();
      renderStats();
    }

    // Keep active drawer in sync
    if (state.activeLead) {
      const updated = state.allLeads.find((l) => l.id === state.activeLead.id);
      if (updated) {
        state.activeLead = updated;
        populateLeadDrawer(updated);
      }
    }

  } catch (err) {
    console.error('CRM load error:', err);
  } finally {
    state.liveSync.isSyncing = false;
    state.liveSync.countdown = state.liveSync.intervalSeconds;
    updateSyncIndicatorText();
    if (refreshIcon) refreshIcon.style.animation = '';
  }
}

// ==================================================
// QUICK SEGMENTS FILTERING
// ==================================================
function updateSegmentBadges() {
  const leads = state.allLeads;
  const todayStart = new Date();
  todayStart.setHours(0, 0, 0, 0);

  const counts = {
    all: leads.length,
    today: leads.filter((l) => l.created_at && new Date(l.created_at) >= todayStart).length,
    hot: leads.filter((l) => l.priority === 'hot' || l.status === 'plan_selected' || l.status === 'report_viewed').length,
    viewed: leads.filter((l) => l.status === 'report_viewed').length,
    plans: leads.filter((l) => l.status === 'plan_selected' || l.selected_plan).length,
    converted: leads.filter((l) => l.status === 'converted').length,
  };

  document.getElementById('seg-count-all').innerText = counts.all;
  document.getElementById('seg-count-today').innerText = counts.today;
  document.getElementById('seg-count-hot').innerText = counts.hot;
  document.getElementById('seg-count-viewed').innerText = counts.viewed;
  document.getElementById('seg-count-plans').innerText = counts.plans;
  document.getElementById('seg-count-converted').innerText = counts.converted;
}

function applySegmentFilter() {
  const leads = state.allLeads;
  const segment = state.activeSegment;

  if (segment === 'today') {
    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);
    state.filteredLeads = leads.filter((l) => l.created_at && new Date(l.created_at) >= todayStart);
  } else if (segment === 'hot') {
    state.filteredLeads = leads.filter((l) => l.priority === 'hot' || l.status === 'plan_selected' || l.status === 'report_viewed');
  } else if (segment === 'viewed') {
    state.filteredLeads = leads.filter((l) => l.status === 'report_viewed');
  } else if (segment === 'plans') {
    state.filteredLeads = leads.filter((l) => l.status === 'plan_selected' || l.selected_plan);
  } else if (segment === 'converted') {
    state.filteredLeads = leads.filter((l) => l.status === 'converted');
  } else {
    state.filteredLeads = [...leads];
  }

  // Update total count badge
  document.getElementById('leads-count-badge').innerText = `Showing ${state.filteredLeads.length} of ${leads.length} Leads`;

  // Compute pagination
  state.pagination.totalPages = Math.max(1, Math.ceil(state.filteredLeads.length / state.pagination.pageSize));
  if (state.pagination.page > state.pagination.totalPages) {
    state.pagination.page = state.pagination.totalPages;
  }

  renderLeads();
}

// ==================================================
// RENDER STATS SUMMARY BAR
// ==================================================
function renderStats() {
  if (!state.stats) return;

  const s = state.stats;
  document.getElementById('kpi-total-leads').innerText = s.total_leads.toLocaleString();
  document.getElementById('kpi-today-leads').innerText = `+${s.today_leads || 0} today from search`;
  
  document.getElementById('kpi-report-viewed').innerText = s.report_viewed.toLocaleString();
  const viewRate = s.total_leads > 0 ? Math.round((s.report_viewed / s.total_leads) * 100) : 0;
  document.getElementById('kpi-viewed-rate').innerText = `${viewRate}% engagement rate`;

  document.getElementById('kpi-plan-selected').innerText = s.plan_selected.toLocaleString();

  // Revenue loss formatting
  const loss = s.total_loss_pipeline || 0;
  let formattedLoss = '₹0/mo';
  if (loss >= 100000) {
    formattedLoss = `₹${(loss / 100000).toFixed(1)}L/mo`;
  } else if (loss > 0) {
    formattedLoss = `₹${loss.toLocaleString()}/mo`;
  }
  document.getElementById('kpi-loss-pipeline').innerText = formattedLoss;

  document.getElementById('kpi-converted-leads').innerText = s.converted_leads.toLocaleString();
  document.getElementById('kpi-conversion-rate').innerText = `${s.conversion_rate || 0}% conversion rate`;
}

// ==================================================
// RENDER LEADS (KANBAN & TABLE)
// ==================================================
function renderLeads() {
  if (state.activeView === 'kanban') {
    renderKanbanView();
  } else {
    renderTableView();
  }
}

function getColumnForStage(stage) {
  if (['new_lead', 'search_started', 'business_selected', 'form_submitted', 'analysis_started'].includes(stage)) {
    return 'new_lead';
  }
  if (['report_processing', 'report_ready'].includes(stage)) {
    return 'report_ready';
  }
  if (stage === 'report_viewed') {
    return 'report_viewed';
  }
  if (['plan_selected', 'payment_pending'].includes(stage)) {
    return 'plan_selected';
  }
  if (['contacted', 'negotiating'].includes(stage)) {
    return 'contacted';
  }
  if (stage === 'converted') {
    return 'converted';
  }
  return 'abandoned';
}

function renderKanbanView() {
  const columns = ['new_lead', 'report_ready', 'report_viewed', 'plan_selected', 'contacted', 'converted', 'abandoned'];
  const columnCounts = {};
  const columnLeads = {};

  columns.forEach((col) => {
    columnCounts[col] = 0;
    columnLeads[col] = [];
    const container = document.getElementById(`cards-stage-${col}`);
    if (container) container.innerHTML = '';
  });

  // Distribute filtered leads into stages
  state.filteredLeads.forEach((lead) => {
    const col = getColumnForStage(lead.status);
    columnCounts[col]++;
    columnLeads[col].push(lead);
  });

  // Populate cards (capped to first 30 per column for smooth rendering with 1000s of leads)
  columns.forEach((col) => {
    const container = document.getElementById(`cards-stage-${col}`);
    if (!container) return;

    const leadsForCol = columnLeads[col];
    const visibleLeads = leadsForCol.slice(0, 30);

    visibleLeads.forEach((lead) => {
      const card = createCompactLeadCard(lead);
      container.appendChild(card);
    });

    if (leadsForCol.length > 30) {
      const moreNote = document.createElement('div');
      moreNote.style.textAlign = 'center';
      moreNote.style.padding = '0.5rem';
      moreNote.style.fontSize = '0.72rem';
      moreNote.style.color = 'var(--text-muted)';
      moreNote.innerText = `+ ${leadsForCol.length - 30} more in table view`;
      container.appendChild(moreNote);
    }

    // Update column header count
    const badge = document.getElementById(`count-stage-${col}`);
    if (badge) badge.innerText = columnCounts[col];

    // Update top stage navigator pill count
    const navCountBadge = document.getElementById(`nav-count-stage-${col}`);
    if (navCountBadge) navCountBadge.innerText = columnCounts[col];
  });

  // Apply Smart-Fit Auto-Collapse for 0-lead stages
  applyKanbanColumnCollapses(columnCounts);

  // Auto-focus default active stage pill if not set
  if (!state.kanban.activeStage || columnCounts[state.kanban.activeStage] === 0) {
    // Pick the stage with the most leads (e.g. report_viewed)
    let bestStage = 'report_viewed';
    let maxCount = -1;
    columns.forEach((c) => {
      if (columnCounts[c] > maxCount) {
        maxCount = columnCounts[c];
        bestStage = c;
      }
    });
    state.kanban.activeStage = bestStage;
  }
  updateActiveStagePill();
}

// ==================================================
// FAITHFUL REPORT DATA EXTRACTION HELPERS
// ==================================================
function getLeadRank(lead) {
  if (lead && lead.report_data) {
    const rd = lead.report_data;
    const rank = rd.user_rank ??
                 rd.audit_summary?.user_rank ??
                 rd.business_impact?.user_rank ??
                 rd.geo_grid?.center_rank ??
                 rd.rank_discovery?.rank;
    if (rank !== undefined && rank !== null && rank > 0) {
      return {
        rankNumber: rank,
        text: `Rank #${rank}`,
        badgeClass: rank <= 3 ? 'rank-top3' : 'rank-other',
      };
    }
  }
  const isEarly = ['new_lead', 'search_started', 'business_selected', 'form_submitted', 'analysis_started'].includes(lead?.status);
  return {
    rankNumber: null,
    text: isEarly ? 'Pending Audit' : 'Unranked',
    badgeClass: 'rank-pending',
  };
}

function getLeadAuditScore(lead) {
  if (lead) {
    if (lead.report_score !== null && lead.report_score !== undefined && lead.report_score > 0) {
      return lead.report_score;
    }
    if (lead.report_data) {
      const rd = lead.report_data;
      const score = rd.profile_completion?.percentage ??
                    rd.health_score?.score ??
                    rd.audit_summary?.profile_score;
      if (score !== undefined && score !== null && score > 0) {
        return Math.round(score);
      }
    }
  }
  return null;
}

function getLeadEstimatedLoss(lead) {
  if (lead && lead.report_data) {
    const rd = lead.report_data;
    const rank = rd.user_rank ?? rd.audit_summary?.user_rank ?? rd.business_impact?.user_rank;
    if (rank === 1) {
      return {
        min: 0,
        max: 0,
        amount: 0,
        display: 'Rank #1 Leader',
        tableDisplay: 'Rank #1 (0 Loss)',
        isLeader: true,
        confidence: null,
      };
    }

    const rb = rd.revenue_breakdown || (rd.business_impact && rd.business_impact.revenue_breakdown);
    const imp = rd.business_impact;

    let min = 0;
    let max = 0;
    let confidence = null;

    // V3 engine: read from loss_estimate percentiles (preferred)
    if (rb && rb.loss_estimate && (rb.loss_estimate.p10 || rb.loss_estimate.p90)) {
      min = Math.round(rb.loss_estimate.p10 || 0);
      max = Math.round(rb.loss_estimate.p90 || min);
      confidence = rb.confidence || null;
    }
    // V3/V2 backward compat: monthly_loss_low/high
    else if (rb && (rb.monthly_loss_low || rb.monthly_loss_high)) {
      min = rb.monthly_loss_low || 0;
      max = rb.monthly_loss_high || min;
      confidence = rb.confidence || null;
    }
    // Legacy: business_impact fields
    else if (imp && (imp.estimated_revenue_loss_monthly_low || imp.estimated_revenue_loss_monthly_high)) {
      min = imp.estimated_revenue_loss_monthly_low || 0;
      max = imp.estimated_revenue_loss_monthly_high || min;
    } else if (rd.revenue_loss && (rd.revenue_loss.loss_min || rd.revenue_loss.loss_max)) {
      min = rd.revenue_loss.loss_min || 0;
      max = rd.revenue_loss.loss_max || min;
    } else if (imp && (imp.estimated_missed_calls_monthly || imp.estimated_lost_walkins_monthly)) {
      const calls = imp.estimated_missed_calls_monthly || 0;
      const walkins = imp.estimated_lost_walkins_monthly || 0;
      const est = (calls * 800) + (walkins * 500);
      min = Math.round(est * 0.75);
      max = Math.round(est * 1.35);
    }

    if (min > 0 || max > 0) {
      const avg = Math.round((min + max) / 2);
      const minK = Math.round(min / 1000);
      const maxK = Math.round(max / 1000);
      const confLabel = confidence && confidence.label ? ` (${confidence.label})` : '';
      return {
        min,
        max,
        amount: min || avg,
        display: minK === maxK ? `₹${minK}k/mo` : `₹${minK}k-${maxK}k/mo`,
        tableDisplay: `₹${min.toLocaleString('en-IN')}/mo`,
        isLeader: false,
        confidence,
        confLabel,
      };
    }
  }

  const isEarly = ['new_lead', 'search_started', 'business_selected', 'form_submitted', 'analysis_started'].includes(lead?.status);
  return {
    min: 0,
    max: 0,
    amount: 0,
    display: isEarly ? 'Pending Audit' : '₹0/mo',
    tableDisplay: isEarly ? 'Pending Audit' : '₹0/mo',
    isLeader: false,
    confidence: null,
  };
}

function getLeadVerifiedDetails(lead) {
  const rd = lead.report_data;
  const biz = rd?.business;

  const rawAddr = (lead.address || biz?.address || '').trim();
  const isGeneric = !rawAddr || rawAddr.toLowerCase().includes('local street') || rawAddr.toLowerCase().includes('market road') || rawAddr.toLowerCase() === 'registered location';

  let city = 'Local Area';
  if (!isGeneric && rawAddr) {
    city = rawAddr.split(',')[0].trim();
  } else if (biz?.address && !biz.address.toLowerCase().includes('local street')) {
    city = biz.address.split(',')[0].trim();
  }

  const category = (lead.category && !lead.category.toLowerCase().includes('local business'))
    ? lead.category
    : (biz?.category || lead.category || 'Local Business');

  const rating = lead.rating ?? biz?.rating ?? 4.0;
  const reviewCount = lead.review_count ?? biz?.review_count ?? 0;

  return {
    city,
    category,
    rating,
    reviewCount,
  };
}

// ==================================================
// KANBAN SMART FIT & COLUMN COLLAPSING
// ==================================================
function applyKanbanColumnCollapses(columnCounts) {
  const columns = ['new_lead', 'report_ready', 'report_viewed', 'plan_selected', 'contacted', 'converted', 'abandoned'];

  columns.forEach((col) => {
    const colEl = document.getElementById(`col-stage-${col}`);
    if (!colEl) return;

    let count = 0;
    if (columnCounts && columnCounts[col] !== undefined) {
      count = columnCounts[col];
    } else {
      const badge = document.getElementById(`count-stage-${col}`);
      count = badge ? parseInt(badge.innerText || '0', 10) : 0;
    }

    let isCollapsed = false;
    // 1. Check explicit manual user override
    if (state.kanban.manualOverrides[col] !== undefined) {
      isCollapsed = state.kanban.manualOverrides[col];
    } else if (state.kanban.smartFit) {
      // 2. In Smart Fit mode, ONLY collapse if count is strictly 0!
      // If a column has ANY leads (count > 0), it MUST stay expanded!
      isCollapsed = (count === 0);
    } else {
      isCollapsed = false;
    }

    const toggleBtn = colEl.querySelector('.btn-col-collapse');
    if (isCollapsed) {
      colEl.classList.add('collapsed');
      if (toggleBtn) toggleBtn.setAttribute('title', 'Click to expand column');
    } else {
      colEl.classList.remove('collapsed');
      if (toggleBtn) toggleBtn.setAttribute('title', 'Click to collapse column');
    }
  });
}

// ==================================================
// JUMP TO KANBAN STAGE & SPOTLIGHT
// ==================================================
function jumpToKanbanStage(stage) {
  state.kanban.activeStage = stage;
  state.kanban.manualOverrides[stage] = false; // Uncollapse target stage

  const colEl = document.getElementById(`col-stage-${stage}`);
  if (colEl) {
    colEl.classList.remove('collapsed');
    
    // Smoothly scroll to center target column
    colEl.scrollIntoView({ behavior: 'smooth', inline: 'center', block: 'nearest' });

    // Subtle focus spotlight ring animation
    colEl.classList.remove('column-spotlight');
    void colEl.offsetWidth; // Force CSS reflow
    colEl.classList.add('column-spotlight');
    setTimeout(() => colEl.classList.remove('column-spotlight'), 1500);
  }

  updateActiveStagePill(stage);
}

function updateActiveStagePill(activeStage) {
  const target = activeStage || state.kanban.activeStage;
  document.querySelectorAll('.stage-nav-pill').forEach((pill) => {
    if (pill.dataset.targetStage === target) {
      pill.classList.add('active');
    } else {
      pill.classList.remove('active');
    }
  });
}

// ==================================================
// KANBAN NAVIGATION CONTROLS (PILLS, ARROWS, SHORTCUTS)
// ==================================================
function initKanbanNavigation() {
  const boardEl = document.getElementById('kanban-board-view');

  // 1. Stage Jump Pills Click Handlers
  document.querySelectorAll('.stage-nav-pill').forEach((pill) => {
    pill.addEventListener('click', () => {
      const stage = pill.dataset.targetStage;
      jumpToKanbanStage(stage);
    });
  });

  // 2. Left & Right Smooth Scroll Buttons
  const btnScrollLeft = document.getElementById('btn-kanban-scroll-left');
  const btnScrollRight = document.getElementById('btn-kanban-scroll-right');

  if (btnScrollLeft && boardEl) {
    btnScrollLeft.addEventListener('click', () => {
      boardEl.scrollBy({ left: -300, behavior: 'smooth' });
    });
  }
  if (btnScrollRight && boardEl) {
    btnScrollRight.addEventListener('click', () => {
      boardEl.scrollBy({ left: 300, behavior: 'smooth' });
    });
  }

  // 3. Smart Fit Toggle Button (Collapse 0-lead stages vs Expand all)
  const btnSmartFit = document.getElementById('btn-toggle-smart-fit');
  if (btnSmartFit) {
    btnSmartFit.addEventListener('click', () => {
      state.kanban.smartFit = !state.kanban.smartFit;
      state.kanban.manualOverrides = {}; // Reset overrides on mode switch

      if (state.kanban.smartFit) {
        btnSmartFit.classList.add('active');
      } else {
        btnSmartFit.classList.remove('active');
      }
      applyKanbanColumnCollapses();
    });
  }

  // 4. Individual Column Header Collapse Buttons
  document.querySelectorAll('.btn-col-collapse').forEach((btn) => {
    btn.addEventListener('click', (e) => {
      e.stopPropagation();
      const stage = btn.dataset.toggleStage;
      const colEl = document.getElementById(`col-stage-${stage}`);
      if (!colEl) return;

      const isCollapsed = colEl.classList.contains('collapsed');
      const willCollapse = !isCollapsed;

      state.kanban.manualOverrides[stage] = willCollapse;
      if (willCollapse) {
        colEl.classList.add('collapsed');
      } else {
        colEl.classList.remove('collapsed');
      }
    });
  });

  // 5. Clicking Anywhere on a Collapsed Column Expands It Immediately
  const columns = ['new_lead', 'report_ready', 'report_viewed', 'plan_selected', 'contacted', 'converted', 'abandoned'];
  columns.forEach((colStage) => {
    const colEl = document.getElementById(`col-stage-${colStage}`);
    if (!colEl) return;
    colEl.addEventListener('click', () => {
      if (colEl.classList.contains('collapsed')) {
        jumpToKanbanStage(colStage);
      }
    });
  });

  // 6. Smooth Mouse Wheel Horizontal Scrolling
  if (boardEl) {
    boardEl.addEventListener('wheel', (e) => {
      // Don't intercept when scrolling vertically inside card list with many cards
      if (e.target.closest('.kanban-card-list')) {
        const cardList = e.target.closest('.kanban-card-list');
        const canScrollVertically = cardList.scrollHeight > cardList.clientHeight;
        if (canScrollVertically && !e.shiftKey) return;
      }
      if (e.shiftKey || Math.abs(e.deltaY) > 0) {
        e.preventDefault();
        boardEl.scrollLeft += (e.deltaY || e.deltaX) * 0.8;
      }
    }, { passive: false });
  }

  // 7. Keyboard Navigation ([ and ] or Alt+Left and Alt+Right)
  document.addEventListener('keydown', (e) => {
    if (state.activeView !== 'kanban') return;
    if (['INPUT', 'TEXTAREA', 'SELECT'].includes(e.target.tagName)) return;

    let curIdx = columns.indexOf(state.kanban.activeStage);
    if (curIdx === -1) curIdx = 2;

    if (e.key === '[' || (e.altKey && e.key === 'ArrowLeft')) {
      e.preventDefault();
      const prevIdx = Math.max(0, curIdx - 1);
      jumpToKanbanStage(columns[prevIdx]);
    } else if (e.key === ']' || (e.altKey && e.key === 'ArrowRight')) {
      e.preventDefault();
      const nextIdx = Math.min(columns.length - 1, curIdx + 1);
      jumpToKanbanStage(columns[nextIdx]);
    }
  });
}

// ==================================================
// KANBAN DRAG AND DROP (STAGE SWITCHING)
// ==================================================
function initKanbanDragAndDrop() {
  const columns = ['new_lead', 'report_ready', 'report_viewed', 'plan_selected', 'contacted', 'converted', 'abandoned'];

  columns.forEach((colStage) => {
    const colEl = document.getElementById(`col-stage-${colStage}`);
    if (!colEl) return;

    colEl.addEventListener('dragover', (e) => {
      e.preventDefault();
      e.dataTransfer.dropEffect = 'move';
      if (!colEl.classList.contains('drag-over')) {
        colEl.classList.add('drag-over');
      }
      // If hovered over a collapsed column, auto-expand so user can drop cleanly
      if (colEl.classList.contains('collapsed')) {
        colEl.classList.remove('collapsed');
        state.kanban.manualOverrides[colStage] = false;
      }
    });

    colEl.addEventListener('dragleave', (e) => {
      if (!colEl.contains(e.relatedTarget)) {
        colEl.classList.remove('drag-over');
      }
    });

    colEl.addEventListener('drop', async (e) => {
      e.preventDefault();
      colEl.classList.remove('drag-over');

      const leadId = e.dataTransfer.getData('text/plain');
      if (!leadId) return;

      const lead = state.allLeads.find((l) => l.id === leadId);
      if (!lead || getColumnForStage(lead.status) === colStage) return;

      // Optimistic update
      const prevStatus = lead.status;
      lead.status = colStage;
      lead.last_activity_at = new Date().toISOString();
      applySegmentFilter();

      try {
        const res = await fetch(`${API_BASE}/leads/${leadId}`, {
          method: 'PATCH',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ status: colStage }),
        });
        if (!res.ok) {
          lead.status = prevStatus;
          applySegmentFilter();
          console.error('Failed to move lead to new stage');
        } else {
          loadCRMData();
        }
      } catch (err) {
        lead.status = prevStatus;
        applySegmentFilter();
        console.error('Drag drop error:', err);
      }
    });
  });
}

function createCompactLeadCard(lead) {
  const card = document.createElement('div');
  card.className = 'lead-card';
  card.dataset.leadId = lead.id;

  // Enable Drag-and-Drop
  card.setAttribute('draggable', 'true');
  card.addEventListener('dragstart', (e) => {
    e.dataTransfer.setData('text/plain', lead.id);
    e.dataTransfer.effectAllowed = 'move';
    card.classList.add('dragging');
  });
  card.addEventListener('dragend', () => {
    card.classList.remove('dragging');
  });

  // Authentic report metrics
  const verified = getLeadVerifiedDetails(lead);
  const lossInfo = getLeadEstimatedLoss(lead);
  const lossText = lossInfo.display;
  const rankInfo = getLeadRank(lead);
  const rankText = rankInfo.text;
  const scoreVal = getLeadAuditScore(lead);

  // Priority (Zero emojis)
  const prio = (lead.priority || 'warm').toLowerCase();
  const prioLabel = prio === 'hot' ? 'Hot' : (prio === 'warm' ? 'Warm' : 'Cold');

  // Stage meta
  const stageMeta = STAGES[lead.status] || STAGES.new_lead;
  const timeStr = formatRelativeTime(lead.last_activity_at || lead.created_at);

  card.innerHTML = `
    <div class="lead-card-top">
      <div style="flex:1; min-width:0;">
        <div class="lead-card-name" title="${escapeHtml(lead.business_name)}">${escapeHtml(lead.business_name)}</div>
        <div class="lead-card-city">${escapeHtml(verified.city)} • ${verified.rating || '4.0'}★ (${verified.reviewCount || 0})${scoreVal !== null ? ` • <strong style="color:var(--primary); font-size:0.7rem;">${scoreVal}/100</strong>` : ''}</div>
      </div>
      <span class="priority-pill ${prio}">${prioLabel}</span>
    </div>

    <div class="lead-card-metrics">
      <span class="metric-tag rank-tag ${rankInfo.badgeClass}">${rankText}</span>
      <span class="metric-tag loss-tag ${lossInfo.isLeader ? 'loss-leader' : ''}">${lossText}</span>
      ${lead.selected_plan ? `<span class="metric-tag plan-tag">${lead.selected_plan.toUpperCase()}</span>` : ''}
    </div>

    <div class="lead-card-bottom">
      <span style="font-size:0.7rem; font-weight:700; color:${stageMeta.color};">${stageMeta.stepLabel}</span>
      <div class="card-actions-row">
        <a href="${getWhatsAppUrl(lead)}" target="_blank" class="action-btn-mini wa" title="WhatsApp" onclick="event.stopPropagation();">
          <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
            <path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z"></path>
          </svg>
        </a>
        <a href="tel:${escapeHtml(lead.phone)}" class="action-btn-mini" title="Call" onclick="event.stopPropagation();">
          <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
            <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z"></path>
          </svg>
        </a>
        <span class="card-time">${timeStr}</span>
      </div>
    </div>
  `;

  card.addEventListener('click', () => openLeadDrawer(lead));
  return card;
}

// Global helper for opening drawer by ID
window.openLeadDrawerById = function(id) {
  const lead = state.allLeads.find((l) => l.id === id);
  if (lead) openLeadDrawer(lead);
};

// ==================================================
// TABLE VIEW WITH PAGINATION
// ==================================================
function renderTableView() {
  const tbody = document.getElementById('leads-table-tbody');
  tbody.innerHTML = '';

  const total = state.filteredLeads.length;
  if (!total) {
    tbody.innerHTML = `<tr><td colspan="10" style="text-align:center; padding:2rem; color:var(--text-muted);">No leads match the current filters.</td></tr>`;
    document.getElementById('pagination-info').innerText = 'Showing 0 of 0 leads';
    document.getElementById('pagination-page-label').innerText = 'Page 1 of 1';
    document.getElementById('btn-page-prev').disabled = true;
    document.getElementById('btn-page-next').disabled = true;
    return;
  }

  // Slice for current page
  const page = state.pagination.page;
  const pageSize = state.pagination.pageSize;
  const startIdx = (page - 1) * pageSize;
  const endIdx = Math.min(startIdx + pageSize, total);
  const pageLeads = state.filteredLeads.slice(startIdx, endIdx);

  // Update pagination bar
  document.getElementById('pagination-info').innerText = `Showing ${startIdx + 1}-${endIdx} of ${total} leads`;
  document.getElementById('pagination-page-label').innerText = `Page ${page} of ${state.pagination.totalPages}`;
  document.getElementById('btn-page-prev').disabled = page <= 1;
  document.getElementById('btn-page-next').disabled = page >= state.pagination.totalPages;

  pageLeads.forEach((lead) => {
    const tr = document.createElement('tr');
    tr.style.cursor = 'pointer';

    const verified = getLeadVerifiedDetails(lead);
    const prio = (lead.priority || 'warm').toLowerCase();
    const prioLabel = prio === 'hot' ? 'Hot' : (prio === 'warm' ? 'Warm' : 'Cold');
    const stageMeta = STAGES[lead.status] || STAGES.new_lead;
    const lossInfo = getLeadEstimatedLoss(lead);
    const lossText = lossInfo.tableDisplay;
    const avatarColorIdx = (lead.business_name.charCodeAt(0) || 0) % 6;

    const rankInfo = getLeadRank(lead);
    const rankText = rankInfo.text;
    const scoreVal = getLeadAuditScore(lead);
    const scoreText = scoreVal !== null ? `${scoreVal}/100` : '--/100';

    tr.innerHTML = `
      <td>
        <div class="table-business-cell">
          <div class="table-avatar color-${avatarColorIdx}">${escapeHtml(lead.business_name.charAt(0).toUpperCase())}</div>
          <div style="min-width:0;">
            <strong style="color:var(--text-main); font-size:0.85rem; display:block; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; max-width:180px;" title="${escapeHtml(lead.business_name)}">
              ${escapeHtml(lead.business_name)}
            </strong>
            <span style="font-size:0.72rem; color:var(--text-muted);">${escapeHtml(verified.city)}</span>
          </div>
        </div>
      </td>
      <td>
        <span style="font-weight:700; color:var(--text-body);">${escapeHtml(lead.phone)}</span>
      </td>
      <td>
        <span class="metric-tag rank-tag ${rankInfo.badgeClass}">${rankText}</span>
      </td>
      <td>
        <strong style="color:var(--primary); font-size:0.8rem;">${scoreText}</strong>
      </td>
      <td>
        <span class="metric-tag loss-tag ${lossInfo.isLeader ? 'loss-leader' : ''}">${lossText}</span>
      </td>
      <td>
        <span class="metric-tag ${lead.selected_plan ? 'plan-tag' : ''}">${lead.selected_plan ? lead.selected_plan.toUpperCase() : 'None'}</span>
      </td>
      <td>
        <div class="table-stage-select-wrap" onclick="event.stopPropagation();">
          <select class="table-stage-select stage-${lead.status}" data-lead-id="${lead.id}" title="Change funnel stage directly">
            <option value="new_lead" ${lead.status === 'new_lead' ? 'selected' : ''}>1. Inbound</option>
            <option value="report_ready" ${lead.status === 'report_ready' ? 'selected' : ''}>2. Audit Ready</option>
            <option value="report_viewed" ${lead.status === 'report_viewed' ? 'selected' : ''}>3. Report Viewed</option>
            <option value="plan_selected" ${lead.status === 'plan_selected' ? 'selected' : ''}>4. Plan Selected</option>
            <option value="contacted" ${lead.status === 'contacted' ? 'selected' : ''}>5. Contacted</option>
            <option value="converted" ${lead.status === 'converted' ? 'selected' : ''}>6. Converted</option>
            <option value="abandoned" ${lead.status === 'abandoned' ? 'selected' : ''}>7. Lost / Inactive</option>
          </select>
          <span class="table-stage-arrow">▼</span>
        </div>
      </td>
      <td>
        <span class="priority-pill ${prio}">${prioLabel}</span>
      </td>
      <td>
        <span style="font-size:0.72rem; color:var(--text-subtle);">${formatRelativeTime(lead.last_activity_at || lead.created_at)}</span>
      </td>
      <td style="text-align:right;">
        <div class="card-actions-row" style="justify-content:flex-end;">
          <a href="${getWhatsAppUrl(lead)}" target="_blank" class="action-btn-mini wa" title="WhatsApp" onclick="event.stopPropagation();">
            <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
              <path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z"></path>
            </svg>
          </a>
          <a href="tel:${escapeHtml(lead.phone)}" class="action-btn-mini" title="Call" onclick="event.stopPropagation();">
            <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
              <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z"></path>
            </svg>
          </a>
          <button type="button" class="btn-secondary btn-table-details" style="padding:0.2rem 0.5rem; font-size:0.72rem;">Details</button>
        </div>
      </td>
    `;

    // Interactive Stage Change Listener inside table row
    const stageSelect = tr.querySelector('.table-stage-select');
    if (stageSelect) {
      stageSelect.addEventListener('change', async (e) => {
        e.stopPropagation();
        const newStage = e.target.value;
        const oldStage = lead.status;

        // Optimistic UI updates
        stageSelect.className = `table-stage-select stage-${newStage}`;
        lead.status = newStage;
        lead.last_activity_at = new Date().toISOString();
        tr.classList.add('row-saved');
        setTimeout(() => tr.classList.remove('row-saved'), 1400);

        updateSegmentBadges();

        try {
          const res = await fetch(`${API_BASE}/leads/${lead.id}`, {
            method: 'PATCH',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ status: newStage }),
          });
          if (!res.ok) {
            lead.status = oldStage;
            stageSelect.className = `table-stage-select stage-${oldStage}`;
            stageSelect.value = oldStage;
            updateSegmentBadges();
            console.error('Failed to update stage');
          } else {
            // Refresh stats summary bar
            fetch(`${API_BASE}/leads/stats/crm`)
              .then((r) => r.json())
              .then((s) => {
                state.stats = s;
                renderStats();
              });
          }
        } catch (err) {
          lead.status = oldStage;
          stageSelect.className = `table-stage-select stage-${oldStage}`;
          stageSelect.value = oldStage;
          updateSegmentBadges();
          console.error('Error updating stage:', err);
        }
      });
    }

    // Details button click
    const detailsBtn = tr.querySelector('.btn-table-details');
    if (detailsBtn) {
      detailsBtn.addEventListener('click', (e) => {
        e.stopPropagation();
        openLeadDrawer(lead);
      });
    }

    tr.addEventListener('click', () => openLeadDrawer(lead));
    tbody.appendChild(tr);
  });
}

function openLeadDrawerById(leadId) {
  const lead = state.allLeads.find((l) => l.id === leadId);
  if (lead) openLeadDrawer(lead);
}

// ==================================================
// 360° LEAD DRAWER MODAL
// ==================================================
function openLeadDrawer(lead) {
  state.activeLead = lead;
  state.liveSync.isPaused = true;
  updateSyncIndicatorText();

  populateLeadDrawer(lead);

  const backdrop = document.getElementById('drawer-backdrop');
  backdrop.classList.add('open');
}

function closeLeadDrawer() {
  const backdrop = document.getElementById('drawer-backdrop');
  backdrop.classList.remove('open');
  state.activeLead = null;
  state.liveSync.isPaused = false;
  updateSyncIndicatorText();
}

function populateLeadDrawer(lead) {
  // 1. Header
  const verified = getLeadVerifiedDetails(lead);
  document.getElementById('drawer-business-name').innerText = lead.business_name;
  document.getElementById('drawer-business-category').innerText = `${verified.category} • ${verified.city} • ${verified.rating || '4.0'}★ (${verified.reviewCount || 0} reviews)`;

  // 2. Stepper
  const stageMeta = STAGES[lead.status] || STAGES.new_lead;
  const currentStep = stageMeta.step;
  document.getElementById('drawer-funnel-pct').innerText = `Step ${currentStep} of 6 — ${stageMeta.stepLabel}`;

  const steps = [
    { id: 'step-search', stepNum: 1 },
    { id: 'step-submit', stepNum: 2 },
    { id: 'step-audit', stepNum: 3 },
    { id: 'step-viewed', stepNum: 4 },
    { id: 'step-plan', stepNum: 5 },
    { id: 'step-convert', stepNum: 6 },
  ];

  steps.forEach((s) => {
    const el = document.getElementById(s.id);
    el.classList.remove('done', 'active');
    if (s.stepNum < currentStep) {
      el.classList.add('done');
    } else if (s.stepNum === currentStep) {
      el.classList.add('active');
    }
  });

  // 3. Opportunity Intel
  const lossInfo = getLeadEstimatedLoss(lead);
  const lossStr = lossInfo.isLeader
    ? 'Rank #1 Leader (No Loss)'
    : (lossInfo.min > 0 ? `₹${lossInfo.min.toLocaleString('en-IN')} - ₹${lossInfo.max.toLocaleString('en-IN')}/mo` : 'Pending Audit');
  document.getElementById('drawer-loss-value').innerText = lossStr;

  const rankInfo = getLeadRank(lead);
  const rankStr = rankInfo.text;
  document.getElementById('drawer-rank-value').innerText = rankStr;

  const scoreVal = getLeadAuditScore(lead);
  document.getElementById('drawer-score-value').innerText = scoreVal !== null ? `${scoreVal}/100` : '--/100';

  // Competitors List
  const compList = document.getElementById('drawer-competitors-list');
  compList.innerHTML = '';
  if (lead.report_data && lead.report_data.competitors && lead.report_data.competitors.length) {
    lead.report_data.competitors.slice(0, 3).forEach((c, idx) => {
      const item = document.createElement('div');
      item.style.display = 'flex';
      item.style.justifyContent = 'space-between';
      item.style.alignItems = 'center';
      const compCalls = c.estimated_monthly_calls || c.estimated_calls_stolen || 35;
      item.innerHTML = `
        <span><strong>#${c.rank || (idx + 1)} ${escapeHtml(c.name || 'Competitor')}</strong> (${c.rating || 4.5}★)</span>
        <span style="color:#b91c1c; font-weight:700;">~${compCalls} calls/mo</span>
      `;
      compList.appendChild(item);
    });
  } else {
    compList.innerHTML = `<span style="color:var(--text-muted);">Competitor data unavailable or pending audit run.</span>`;
  }

  // Live report link
  const liveReportUrl = getLiveReportUrl(lead.id);
  document.getElementById('drawer-view-report-link').href = liveReportUrl;

  // 4. Sales Phone & WhatsApp
  document.getElementById('drawer-phone-display').innerText = lead.phone;
  document.getElementById('drawer-call-btn').href = `tel:${lead.phone}`;

  // Clean Professional WhatsApp Pitch (Zero emojis)
  const waPitch = generateWhatsAppPitch(lead, liveReportUrl, rankStr, lossStr);
  document.getElementById('drawer-whatsapp-text').innerText = waPitch;
  document.getElementById('drawer-whatsapp-link').href = `https://wa.me/${cleanPhoneNumber(lead.phone)}?text=${encodeURIComponent(waPitch)}`;

  // 5. Select dropdowns
  const stageSelect = document.getElementById('drawer-stage-select');
  stageSelect.value = getCanonicalStageValue(lead.status);

  const prioritySelect = document.getElementById('drawer-priority-select');
  prioritySelect.value = (lead.priority || 'warm').toLowerCase();

  // 6. Notes history
  const notesContainer = document.getElementById('drawer-notes-history');
  notesContainer.innerText = lead.notes || 'No sales notes recorded yet. Add a note above to track conversation.';
  document.getElementById('drawer-new-note').value = '';
}

function getCanonicalStageValue(status) {
  if (['new_lead', 'search_started', 'business_selected', 'form_submitted', 'analysis_started'].includes(status)) return 'new_lead';
  if (['report_processing', 'report_ready'].includes(status)) return 'report_ready';
  if (status === 'report_viewed') return 'report_viewed';
  if (['plan_selected', 'payment_pending'].includes(status)) return 'plan_selected';
  if (['contacted', 'negotiating'].includes(status)) return 'contacted';
  if (status === 'converted') return 'converted';
  return 'abandoned';
}

function generateWhatsAppPitch(lead, reportUrl, rank, loss) {
  const bizName = lead.business_name;
  const verified = getLeadVerifiedDetails(lead);
  const city = verified.city;

  if (rank.includes('#1') && !rank.includes('#11')) {
    return `Hello team ${bizName},

Congratulations! We analyzed local customer searches in ${city} and confirmed that ${bizName} currently holds the #1 ranking on Google Maps.

However, nearby rivals are rapidly closing the review gap. You can view your complete live audit and competitor threat radar here:
${reportUrl}

Can we schedule a quick 5-minute call to discuss maintaining your #1 market share?`;
  }

  return `Hello team ${bizName},

We analyzed local customer searches in ${city} and found that your Google Maps listing currently ranks at ${rank}, resulting in an estimated ${loss} in direct customer calls going to nearby competitors.

You can view your private business performance audit here:
${reportUrl}

Can we schedule a quick 5-minute call to discuss steps to position your listing in the Top 3 to recover these calls?`;
}

// ==================================================
// SAVE ACTIONS (API)
// ==================================================
async function saveLeadStageAndPriority() {
  if (!state.activeLead) return;

  const newStage = document.getElementById('drawer-stage-select').value;
  const newPriority = document.getElementById('drawer-priority-select').value;
  const saveBtn = document.getElementById('btn-save-lead-stage');

  saveBtn.innerText = 'Saving...';
  saveBtn.disabled = true;

  try {
    const res = await fetch(`${API_BASE}/leads/${state.activeLead.id}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        status: newStage,
        priority: newPriority,
      }),
    });

    if (res.ok) {
      const updated = await res.json();
      state.activeLead = updated;
      saveBtn.innerText = 'Saved';
      setTimeout(() => {
        saveBtn.innerText = 'Save Stage Changes';
        saveBtn.disabled = false;
      }, 1500);
      loadCRMData();
    } else {
      alert('Failed to update stage');
      saveBtn.disabled = false;
      saveBtn.innerText = 'Save Stage Changes';
    }
  } catch (err) {
    console.error('Update error:', err);
    saveBtn.disabled = false;
    saveBtn.innerText = 'Save Stage Changes';
  }
}

async function addLeadNote() {
  if (!state.activeLead) return;

  const noteInput = document.getElementById('drawer-new-note');
  const noteText = noteInput.value.trim();
  if (!noteText) return;

  const addBtn = document.getElementById('btn-add-note');
  addBtn.innerText = 'Saving...';
  addBtn.disabled = true;

  try {
    const res = await fetch(`${API_BASE}/leads/${state.activeLead.id}/notes`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        note: noteText,
        author: 'Sales Rep',
      }),
    });

    if (res.ok) {
      const updated = await res.json();
      state.activeLead = updated;
      document.getElementById('drawer-notes-history').innerText = updated.notes || '';
      noteInput.value = '';
      addBtn.innerText = 'Saved';
      setTimeout(() => {
        addBtn.innerText = 'Save Note';
        addBtn.disabled = false;
      }, 1500);
      loadCRMData();
    } else {
      alert('Failed to add note');
      addBtn.disabled = false;
      addBtn.innerText = 'Save Note';
    }
  } catch (err) {
    console.error('Note error:', err);
    addBtn.disabled = false;
    addBtn.innerText = 'Save Note';
  }
}

async function deleteCurrentLead() {
  if (!state.activeLead) return;

  const confirmDelete = confirm(`Are you sure you want to permanently delete "${state.activeLead.business_name}"?`);
  if (!confirmDelete) return;

  try {
    const res = await fetch(`${API_BASE}/leads/${state.activeLead.id}`, {
      method: 'DELETE',
    });

    if (res.ok) {
      closeLeadDrawer();
      loadCRMData();
    } else {
      alert('Failed to delete lead');
    }
  } catch (err) {
    console.error('Delete error:', err);
  }
}

async function clearAllLeads() {
  const confirmClear = confirm('Are you sure you want to permanently delete ALL leads and audit reports from the CRM? This will reset your leads pipeline to a clean slate.');
  if (!confirmClear) return;

  try {
    const res = await fetch(`${API_BASE}/leads`, {
      method: 'DELETE',
    });

    if (res.ok) {
      if (state.activeLead) closeLeadDrawer();
      await loadCRMData();
    } else {
      alert('Failed to clear leads.');
    }
  } catch (err) {
    console.error('Clear leads error:', err);
    alert('Error communicating with server.');
  }
}

// ==================================================
// CSV EXPORT GENERATOR
// ==================================================
function exportToCSV() {
  const leadsToExport = state.filteredLeads;
  if (!leadsToExport.length) {
    alert('No leads available to export.');
    return;
  }

  const headers = [
    'Lead ID',
    'Business Name',
    'Phone',
    'Address',
    'Category',
    'Maps Rating',
    'Review Count',
    'Audit Score',
    'Google Rank',
    'Est Revenue Loss Min',
    'Est Revenue Loss Max',
    'Selected Plan',
    'Funnel Stage',
    'Priority',
    'Created At',
  ];

  const rows = leadsToExport.map((l) => {
    const rankInfo = getLeadRank(l);
    const lossInfo = getLeadEstimatedLoss(l);
    const verified = getLeadVerifiedDetails(l);
    const scoreVal = getLeadAuditScore(l);

    return [
      `"${l.id}"`,
      `"${(l.business_name || '').replace(/"/g, '""')}"`,
      `"${l.phone || ''}"`,
      `"${(verified.city || l.address || '').replace(/"/g, '""')}"`,
      `"${(verified.category || l.category || '').replace(/"/g, '""')}"`,
      verified.rating || l.rating || '',
      verified.reviewCount || l.review_count || 0,
      scoreVal !== null ? `${scoreVal}/100` : '',
      `"${rankInfo.text}"`,
      lossInfo.min,
      lossInfo.max,
      l.selected_plan || '',
      l.status || '',
      l.priority || '',
      l.created_at || '',
    ].join(',');
  });

  const csvContent = 'data:text/csv;charset=utf-8,' + [headers.join(','), ...rows].join('\n');
  const encodedUri = encodeURI(csvContent);
  const link = document.createElement('a');
  link.setAttribute('href', encodedUri);
  link.setAttribute('download', `optigoai_leads_${new Date().toISOString().slice(0, 10)}.csv`);
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
}

// ==================================================
// HELPER UTILITIES
// ==================================================
function cleanPhoneNumber(phone) {
  if (!phone) return '';
  let cleaned = phone.replace(/[^0-9]/g, '');
  if (cleaned.length === 10) cleaned = '91' + cleaned;
  return cleaned;
}

function getWhatsAppUrl(lead) {
  const phone = cleanPhoneNumber(lead.phone);
  const text = `Hello ${lead.business_name}, following up regarding your OptigoAI Google Maps growth report.`;
  return `https://wa.me/${phone}?text=${encodeURIComponent(text)}`;
}

function getLiveReportUrl(leadId) {
  return `${PUBLIC_FRONTEND_URL}/report/${leadId}`;
}

function formatRelativeTime(dateString) {
  if (!dateString) return 'recently';
  const date = new Date(dateString);
  const now = new Date();
  const diffSec = Math.floor((now - date) / 1000);

  if (diffSec < 60) return 'just now';
  if (diffSec < 3600) return `${Math.floor(diffSec / 60)}m ago`;
  if (diffSec < 86400) return `${Math.floor(diffSec / 3600)}h ago`;
  if (diffSec < 604800) return `${Math.floor(diffSec / 86400)}d ago`;
  return date.toLocaleDateString();
}

function escapeHtml(str) {
  if (!str) return '';
  return str.replace(/[&<>'"]/g, (tag) => ({
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    "'": '&#39;',
    '"': '&quot;',
  }[tag] || tag));
}
