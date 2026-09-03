// ==================================================
// OptigoAI Enterprise — Prody Light Profile Audit
// ==================================================

import React from 'react';
import { useFranchise } from '../../context/FranchiseContext';
import { useLocation } from '../../context/LocationContext';
import {
  ShieldAlert,
  ShieldCheck,
  AlertTriangle,
  CheckCircle2,
  ArrowRight,
  RefreshCw,
} from 'lucide-react';

export const FranchiseAuditView: React.FC = () => {
  const { audit, isSyncing, triggerBulkSync } = useFranchise();
  const { selectLocation } = useLocation();

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
      {/* 1. Entity Header */}
      <div className="entity-header-card">
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <div className="entity-icon-badge">
            <ShieldAlert size={26} />
          </div>
          <div>
            <h1 style={{ fontSize: '1.45rem', fontWeight: 800, color: '#111827', lineHeight: 1.2 }}>
              Profile Strength & Completeness Audit
            </h1>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginTop: '6px' }}>
              <span className="prody-pill blue">{audit.average_completeness_pct}% Network Average</span>
              <span className="prody-pill red">{audit.attention_required_count} Branches Flagged</span>
            </div>
          </div>
        </div>

        <button onClick={triggerBulkSync} disabled={isSyncing} className="btn btn-secondary btn-sm" style={{ gap: '6px' }}>
          <RefreshCw size={14} className={isSyncing ? 'spin-anim' : ''} />
          <span>{isSyncing ? 'Running Audit...' : 'Re-Scan Profiles'}</span>
        </button>
      </div>

      {/* 2. 4 Quick Stat Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '16px' }}>
        <div className="prody-card">
          <span style={{ fontSize: '0.75rem', fontWeight: 700, color: '#6B7280', textTransform: 'uppercase' }}>
            Avg Completeness
          </span>
          <div style={{ fontSize: '1.8rem', fontWeight: 800, color: '#059669', marginTop: '4px' }}>
            {audit.average_completeness_pct || 0}%
          </div>
          <span style={{ fontSize: '0.75rem', color: '#6B7280' }}>Across all profiles</span>
        </div>

        <div className="prody-card">
          <span style={{ fontSize: '0.75rem', fontWeight: 700, color: '#6B7280', textTransform: 'uppercase' }}>
            Locations Requiring Fixes
          </span>
          <div style={{ fontSize: '1.8rem', fontWeight: 800, color: '#E11D48', marginTop: '4px' }}>
            {audit.attention_required_count}
          </div>
          <span style={{ fontSize: '0.75rem', color: '#6B7280' }}>Action items pending</span>
        </div>

        <div className="prody-card">
          <span style={{ fontSize: '0.75rem', fontWeight: 700, color: '#6B7280', textTransform: 'uppercase' }}>
            Unanswered Reviews
          </span>
          <div style={{ fontSize: '1.8rem', fontWeight: 800, color: '#D97706', marginTop: '4px' }}>
            {audit.issues_by_type.unreplied_reviews || 0}
          </div>
          <span style={{ fontSize: '0.75rem', color: '#6B7280' }}>Awaiting responses</span>
        </div>

        <div className="prody-card">
          <span style={{ fontSize: '0.75rem', fontWeight: 700, color: '#6B7280', textTransform: 'uppercase' }}>
            Missing Info / Attributes
          </span>
          <div style={{ fontSize: '1.8rem', fontWeight: 800, color: '#0284C7', marginTop: '4px' }}>
            {(audit.issues_by_type.missing_phone || 0) + (audit.issues_by_type.missing_description || 0)}
          </div>
          <span style={{ fontSize: '0.75rem', color: '#6B7280' }}>Phone / description gaps</span>
        </div>
      </div>

      {/* 3. Action Items List */}
      <div className="prody-card" style={{ padding: 0, overflow: 'hidden' }}>
        <div style={{ padding: '12px 18px', borderBottom: '1px solid var(--border-subtle)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <span style={{ fontWeight: 700, fontSize: '0.92rem', color: '#111827' }}>Action Items by Branch</span>
          <span className="prody-pill peach">{audit.locations_requiring_fixes.length} Locations</span>
        </div>

        <div>
          {audit.locations_requiring_fixes.map((item) => (
            <div
              key={item.id}
              style={{
                padding: '14px 18px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                borderBottom: '1px solid var(--border-subtle)',
              }}
            >
              <div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <strong style={{ color: '#111827', fontSize: '0.9rem' }}>{item.name}</strong>
                  <span className={`prody-pill ${item.urgency === 'High' ? 'red' : 'peach'}`}>
                    {item.urgency} Priority
                  </span>
                </div>
                <div style={{ fontSize: '0.78rem', color: '#6B7280', marginTop: '2px' }}>
                  {item.location} • Health: <strong>{item.health_score}/100</strong>
                </div>
                <div style={{ display: 'flex', flexWrap: 'wrap', gap: '4px', marginTop: '6px' }}>
                  {item.issues.map((iss, i) => (
                    <span key={i} className="prody-pill grey">• {iss}</span>
                  ))}
                </div>
              </div>

              <button onClick={() => selectLocation(item.id)} className="btn btn-secondary btn-sm" style={{ gap: '4px' }}>
                <span>Resolve</span>
                <ArrowRight size={13} />
              </button>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};
