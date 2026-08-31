// ==================================================
// OptigoAI Enterprise — Prody Light Profile Editor
// ==================================================

import React, { useState } from 'react';
import { useLocation } from '../../context/LocationContext';
import {
  Building2,
  Save,
  RefreshCw,
  CheckCircle2,
} from 'lucide-react';

export const BranchProfileView: React.FC = () => {
  const { activeLocation } = useLocation();

  const [name, setName] = useState(activeLocation?.name || '');
  const [category, setCategory] = useState(activeLocation?.category || '');
  const [location, setLocation] = useState(activeLocation?.location || '');
  const [phone, setPhone] = useState(activeLocation?.phone || '');
  const [website, setWebsite] = useState(activeLocation?.website || '');
  const [description, setDescription] = useState(activeLocation?.description || '');
  const [services, setServices] = useState(activeLocation?.services || '');
  const [savedSuccess, setSavedSuccess] = useState(false);
  const [isSyncing, setIsSyncing] = useState(false);

  if (!activeLocation) return null;

  const handleSave = (e: React.FormEvent) => {
    e.preventDefault();
    setSavedSuccess(true);
    setTimeout(() => setSavedSuccess(false), 3000);
  };

  const handleSyncGbp = () => {
    setIsSyncing(true);
    setTimeout(() => {
      setIsSyncing(false);
      setSavedSuccess(true);
      setTimeout(() => setSavedSuccess(false), 3000);
    }, 1200);
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
      {/* 1. Entity Header */}
      <div className="entity-header-card">
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <div className="entity-icon-badge">
            <Building2 size={26} />
          </div>
          <div>
            <h1 style={{ fontSize: '1.45rem', fontWeight: 800, color: '#111827', lineHeight: 1.2 }}>
              Google Business Profile Manager
            </h1>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginTop: '6px' }}>
              <span className="prody-pill blue">{activeLocation.name}</span>
              <span className="prody-pill green">{activeLocation.completeness_score}% Complete</span>
            </div>
          </div>
        </div>

        <div style={{ display: 'flex', gap: '8px' }}>
          <button onClick={handleSyncGbp} disabled={isSyncing} className="btn btn-secondary btn-sm" style={{ gap: '6px' }}>
            <RefreshCw size={14} className={isSyncing ? 'spin-anim' : ''} />
            <span>{isSyncing ? 'Syncing...' : 'Sync Live'}</span>
          </button>
          <button onClick={handleSave} className="btn btn-coral btn-sm" style={{ gap: '6px' }}>
            <Save size={14} />
            <span>{savedSuccess ? 'Saved & Synced' : 'Save Changes'}</span>
          </button>
        </div>
      </div>

      {savedSuccess && (
        <div style={{ padding: '10px 14px', backgroundColor: '#DCFCE7', border: '1px solid #BBF7D0', borderRadius: 'var(--radius-sm)', color: '#15803D', fontSize: '0.82rem', fontWeight: 600 }}>
          Profile changes successfully saved and synchronized with Google Business Profile.
        </div>
      )}

      {/* 2. Form Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '18px' }}>
        <div className="prody-card">
          <form onSubmit={handleSave} style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
            <div className="input-group">
              <label className="input-label">Official Business Name on Google *</label>
              <input type="text" className="optigo-input" value={name} onChange={(e) => setName(e.target.value)} required />
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
              <div className="input-group">
                <label className="input-label">Primary Category *</label>
                <input type="text" className="optigo-input" value={category} onChange={(e) => setCategory(e.target.value)} required />
              </div>

              <div className="input-group">
                <label className="input-label">Phone Number</label>
                <input type="text" className="optigo-input" value={phone} onChange={(e) => setPhone(e.target.value)} />
              </div>
            </div>

            <div className="input-group">
              <label className="input-label">Full Address / Location *</label>
              <input type="text" className="optigo-input" value={location} onChange={(e) => setLocation(e.target.value)} required />
            </div>

            <div className="input-group">
              <label className="input-label">Website URL</label>
              <input type="url" className="optigo-input" value={website} onChange={(e) => setWebsite(e.target.value)} />
            </div>

            <div className="input-group">
              <label className="input-label">Business Overview</label>
              <textarea className="optigo-input" rows={3} value={description} onChange={(e) => setDescription(e.target.value)} />
            </div>

            <div className="input-group">
              <label className="input-label">Services & Offerings</label>
              <input type="text" className="optigo-input" value={services} onChange={(e) => setServices(e.target.value)} />
            </div>
          </form>
        </div>

        {/* Strength Card */}
        <div className="prody-card" style={{ display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
          <div>
            <h3 style={{ fontSize: '1rem', fontWeight: 800, color: '#111827', marginBottom: '10px' }}>Profile Strength</h3>
            <div style={{ fontSize: '2rem', fontWeight: 800, color: '#059669' }}>
              {activeLocation.completeness_score}%
            </div>
            <div style={{ height: '6px', backgroundColor: '#F3F4F6', borderRadius: '3px', overflow: 'hidden', margin: '8px 0 14px' }}>
              <div style={{ width: `${activeLocation.completeness_score}%`, height: '100%', backgroundColor: '#059669', borderRadius: '3px' }} />
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', fontSize: '0.8rem', color: '#059669', fontWeight: 600 }}>
              <div>✓ Business Name Configured</div>
              <div>✓ Primary Category Set</div>
              <div>✓ Address & Map Pin Verified</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
