// ==================================================
// OptigoAI Enterprise — Prody Light Branch Settings
// ==================================================

import React, { useState } from 'react';
import { useLocation } from '../../context/LocationContext';
import {
  Settings,
  MapPin,
  Globe,
  CheckCircle2,
  Save,
} from 'lucide-react';

export const BranchSettingsView: React.FC = () => {
  const { activeLocation } = useLocation();

  const [defaultTone, setDefaultTone] = useState('Professional');
  const [alertEmail, setAlertEmail] = useState('alerts@optigoai.com');
  const [savedSuccess, setSavedSuccess] = useState(false);

  if (!activeLocation) return null;

  const handleSave = (e: React.FormEvent) => {
    e.preventDefault();
    setSavedSuccess(true);
    setTimeout(() => setSavedSuccess(false), 3000);
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
      {/* 1. Entity Header */}
      <div className="entity-header-card">
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <div className="entity-icon-badge">
            <Settings size={26} />
          </div>
          <div>
            <h1 style={{ fontSize: '1.45rem', fontWeight: 800, color: '#111827', lineHeight: 1.2 }}>
              Branch Settings & Integrations
            </h1>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginTop: '6px' }}>
              <span className="prody-pill blue">{activeLocation.name}</span>
              <span className="prody-pill green">Google APIs Active</span>
            </div>
          </div>
        </div>
      </div>

      {savedSuccess && (
        <div style={{ padding: '10px 14px', backgroundColor: '#DCFCE7', border: '1px solid #BBF7D0', borderRadius: 'var(--radius-sm)', color: '#15803D', fontSize: '0.82rem', fontWeight: 600 }}>
          Branch settings and preferences saved successfully.
        </div>
      )}

      {/* 2. Connected Integrations */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: '16px' }}>
        <div className="prody-card" style={{ display: 'flex', flexDirection: 'column', justifyContent: 'space-between', gap: '12px' }}>
          <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
              <h3 style={{ fontSize: '1rem', fontWeight: 700, color: '#111827' }}>Google Business Profile</h3>
              <span className="prody-pill green">Connected</span>
            </div>
            <p style={{ fontSize: '0.82rem', color: '#6B7280', lineHeight: 1.4 }}>
              Active live sync with Google Search & Maps API.
            </p>
          </div>
          <span style={{ fontSize: '0.75rem', color: '#9CA3AF' }}>Status: Active Live</span>
        </div>

        <div className="prody-card" style={{ display: 'flex', flexDirection: 'column', justifyContent: 'space-between', gap: '12px' }}>
          <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
              <h3 style={{ fontSize: '1rem', fontWeight: 700, color: '#111827' }}>Google Search Console</h3>
              <span className="prody-pill green">Connected</span>
            </div>
            <p style={{ fontSize: '0.82rem', color: '#6B7280', lineHeight: 1.4 }}>
              Organic search discovery and local keyword verification.
            </p>
          </div>
          <span style={{ fontSize: '0.75rem', color: '#9CA3AF' }}>Status: Active Live</span>
        </div>
      </div>

      {/* 3. Preferences Form */}
      <div className="prody-card">
        <h3 style={{ fontSize: '1.05rem', fontWeight: 800, color: '#111827', marginBottom: '14px' }}>
          Response & Notification Preferences
        </h3>

        <form onSubmit={handleSave} style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px' }}>
            <div className="input-group">
              <label className="input-label">Default Response Tone</label>
              <select className="optigo-input" value={defaultTone} onChange={(e) => setDefaultTone(e.target.value)}>
                <option value="Professional">Professional (Corporate & Courteous)</option>
                <option value="Warm & Friendly">Warm & Friendly (Welcoming & Personal)</option>
                <option value="Empathetic">Empathetic (Customer Resolution Focused)</option>
              </select>
            </div>

            <div className="input-group">
              <label className="input-label">Alert Notification Email</label>
              <input
                type="email"
                className="optigo-input"
                value={alertEmail}
                onChange={(e) => setAlertEmail(e.target.value)}
              />
            </div>
          </div>

          <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: '10px' }}>
            <button type="submit" className="btn btn-primary" style={{ gap: '8px', padding: '11px 24px', fontSize: '0.9rem', borderRadius: '10px' }}>
              <Save size={16} />
              <span>Save Preferences</span>
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
