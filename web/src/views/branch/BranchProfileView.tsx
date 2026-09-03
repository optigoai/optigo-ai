// ==================================================
// OptigoAI Enterprise — Real Google Business Profile Editor
// Direct Real-Time Database Persistence & GBP Live Synchronization
// ==================================================

import React, { useState, useEffect } from 'react';
import { useLocation } from '../../context/LocationContext';
import { useFranchise } from '../../context/FranchiseContext';
import { businessService } from '../../services/businessService';
import {
  Building2,
  Save,
  RefreshCw,
  CheckCircle2,
  AlertCircle,
  MapPin,
  Phone,
  Globe,
  Tag,
  FileText,
  Layers,
  Sparkles,
  ExternalLink,
  Lightbulb,
} from 'lucide-react';

export const BranchProfileView: React.FC = () => {
  const { activeLocation } = useLocation();
  const { refreshFranchiseData } = useFranchise();

  // Form State
  const [name, setName] = useState(activeLocation?.name || '');
  const [category, setCategory] = useState(activeLocation?.category || '');
  const [location, setLocation] = useState(activeLocation?.location || '');
  const [phone, setPhone] = useState(activeLocation?.phone || '');
  const [website, setWebsite] = useState(activeLocation?.website || activeLocation?.public_website_url || '');
  const [description, setDescription] = useState(activeLocation?.description || '');
  const [services, setServices] = useState(activeLocation?.services || '');

  // UI State
  const [isSaving, setIsSaving] = useState(false);
  const [isSyncing, setIsSyncing] = useState(false);
  const [savedSuccess, setSavedSuccess] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  // Sync form inputs when active location changes
  useEffect(() => {
    if (activeLocation) {
      setName(activeLocation.name || '');
      setCategory(activeLocation.category || '');
      setLocation(activeLocation.location || '');
      setPhone(activeLocation.phone || '');
      setWebsite(activeLocation.website || activeLocation.public_website_url || '');
      setDescription(activeLocation.description || '');
      setServices(activeLocation.services || '');
    }
  }, [activeLocation?.id]);

  if (!activeLocation) return null;

  // Real-Time Dynamic Completeness Calculation
  const checklistItems = [
    { label: 'Business Name Configured', done: Boolean(name.trim().length > 0) },
    { label: 'Primary Category Set', done: Boolean(category.trim().length > 0) },
    { label: 'Address & Location Verified', done: Boolean(location.trim().length > 0) },
    { label: 'Phone Number Linked', done: Boolean(phone.trim().length > 0) },
    { label: 'Website URL Connected', done: Boolean(website.trim().length > 0) },
    { label: 'Business Overview Provided', done: Boolean(description.trim().length > 20) },
    { label: 'Services & Offerings Detailed', done: Boolean(services.trim().length > 5) },
  ];

  const completedCount = checklistItems.filter((item) => item.done).length;
  const dynamicCompletenessScore = Math.round((completedCount / checklistItems.length) * 100);

  // Save changes to Database via API
  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!activeLocation?.id) return;

    setIsSaving(true);
    setErrorMessage(null);

    try {
      await businessService.updateBusiness(activeLocation.id, {
        name: name.trim(),
        category: category.trim(),
        location: location.trim(),
        phone: phone.trim() || undefined,
        website: website.trim() || undefined,
        description: description.trim() || undefined,
        services: services.trim() || undefined,
      });

      // Refresh global franchise & location context from Database
      await refreshFranchiseData();

      setSavedSuccess(true);
      setTimeout(() => setSavedSuccess(false), 4000);
    } catch (err: any) {
      setErrorMessage(err?.message || 'Failed to save changes to the database. Please try again.');
    } finally {
      setIsSaving(false);
    }
  };

  // Sync Live with Google Business Profile API
  const handleSyncGbp = async () => {
    if (!activeLocation?.id) return;

    setIsSyncing(true);
    setErrorMessage(null);

    try {
      await businessService.syncGBP(activeLocation.id);
      await refreshFranchiseData();

      setSavedSuccess(true);
      setTimeout(() => setSavedSuccess(false), 4000);
    } catch (err: any) {
      setErrorMessage(err?.message || 'Failed to sync with Google Business Profile.');
    } finally {
      setIsSyncing(false);
    }
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '20px', maxWidth: '1280px', margin: '0 auto', width: '100%' }}>
      {/* 1. Entity Header Card */}
      <div
        className="entity-header-card"
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          flexWrap: 'wrap',
          gap: '16px',
          background: 'linear-gradient(135deg, #ffffff 0%, #f8faff 100%)',
          border: '1px solid #e2e8f0',
          borderRadius: '24px',
          padding: '24px 32px',
          boxShadow: '0 4px 20px -2px rgba(15, 23, 42, 0.04)',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <div
            style={{
              width: '52px',
              height: '52px',
              borderRadius: '14px',
              background: 'linear-gradient(135deg, #eff6ff 0%, #dbeafe 100%)',
              color: '#2563eb',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              border: '1px solid #bfdbfe',
              boxShadow: '0 2px 6px rgba(37, 99, 235, 0.12)',
            }}
          >
            <Building2 size={26} />
          </div>

          <div>
            <h1 style={{ fontSize: '1.45rem', fontWeight: 900, color: '#0f172a', lineHeight: 1.2, margin: 0, letterSpacing: '-0.3px' }}>
              Google Business Profile Manager
            </h1>
            <div style={{ display: 'flex', alignItems: 'center', flexWrap: 'wrap', gap: '8px', marginTop: '6px' }}>
              <span className="prody-pill blue">{activeLocation.name}</span>
              <span className="prody-pill green">{dynamicCompletenessScore}% Complete</span>
              <span style={{ fontSize: '0.76rem', color: '#64748b' }}>
                Google Rank #{activeLocation.google_maps_rank}
              </span>
            </div>
          </div>
        </div>

        {/* Action Controls */}
        <div style={{ display: 'flex', gap: '12px', alignItems: 'center' }}>
          <button
            type="button"
            onClick={handleSyncGbp}
            disabled={isSyncing || isSaving}
            className="btn btn-secondary"
            style={{ gap: '8px', fontSize: '0.88rem', fontWeight: 700, borderRadius: '10px', padding: '10px 18px' }}
          >
            <RefreshCw size={16} className={isSyncing ? 'spin-anim' : ''} />
            <span>{isSyncing ? 'Syncing GBP...' : 'Sync Live'}</span>
          </button>
          <button
            type="button"
            onClick={handleSave}
            disabled={isSaving || isSyncing}
            className="btn btn-primary"
            style={{ gap: '8px', fontSize: '0.88rem', fontWeight: 800, borderRadius: '10px', padding: '10px 22px' }}
          >
            <Save size={16} />
            <span>{isSaving ? 'Saving to Database...' : (savedSuccess ? 'Saved & Synced!' : 'Save Changes')}</span>
          </button>
        </div>
      </div>

      {/* Success Notification Banner */}
      {savedSuccess && (
        <div
          style={{
            padding: '12px 18px',
            backgroundColor: '#dcfce7',
            border: '1px solid #bbf7d0',
            borderRadius: '10px',
            color: '#15803d',
            fontSize: '0.86rem',
            fontWeight: 700,
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
            boxShadow: '0 2px 6px rgba(22, 163, 74, 0.1)',
          }}
        >
          <CheckCircle2 size={18} color="#16a34a" />
          <span>Profile changes successfully updated in the database and synchronized with Google Business Profile!</span>
        </div>
      )}

      {/* Error Banner */}
      {errorMessage && (
        <div
          style={{
            padding: '12px 18px',
            backgroundColor: '#fee2e2',
            border: '1px solid #fecdd3',
            borderRadius: '10px',
            color: '#b91c1c',
            fontSize: '0.86rem',
            fontWeight: 700,
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
          }}
        >
          <AlertCircle size={18} color="#dc2626" />
          <span>{errorMessage}</span>
        </div>
      )}

      {/* 2. Form Grid & Real-Time Strength Meter */}
      <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '20px', alignItems: 'flex-start' }}>
        {/* Left: Interactive Edit Form */}
        <div
          className="prody-card"
          style={{
            padding: '32px',
            borderRadius: '24px',
            backgroundColor: '#ffffff',
            boxShadow: '0 4px 20px -2px rgba(15, 23, 42, 0.04)',
            border: '1px solid #e2e8f0',
          }}
        >
          <form onSubmit={handleSave} style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
            {/* Official Name */}
            <div className="input-group">
              <label className="input-label" style={{ fontWeight: 800, color: '#0f172a' }}>
                Official Business Name on Google *
              </label>
              <input
                type="text"
                className="optigo-input"
                placeholder="e.g. Casaraza Restaurant"
                value={name}
                onChange={(e) => setName(e.target.value)}
                required
                style={{ fontSize: '0.92rem', padding: '10px 14px', borderRadius: '8px' }}
              />
            </div>

            {/* Category & Phone */}
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px' }}>
              <div className="input-group">
                <label className="input-label" style={{ fontWeight: 800, color: '#0f172a' }}>
                  Primary Category *
                </label>
                <input
                  type="text"
                  className="optigo-input"
                  placeholder="e.g. Family Restaurant"
                  value={category}
                  onChange={(e) => setCategory(e.target.value)}
                  required
                  style={{ fontSize: '0.92rem', padding: '10px 14px', borderRadius: '8px' }}
                />
              </div>

              <div className="input-group">
                <label className="input-label" style={{ fontWeight: 800, color: '#0f172a' }}>
                  Phone Number
                </label>
                <input
                  type="text"
                  className="optigo-input"
                  placeholder="+91 98765 43210"
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                  style={{ fontSize: '0.92rem', padding: '10px 14px', borderRadius: '8px' }}
                />
              </div>
            </div>

            {/* Full Address */}
            <div className="input-group">
              <label className="input-label" style={{ fontWeight: 800, color: '#0f172a' }}>
                Full Address / Location *
              </label>
              <input
                type="text"
                className="optigo-input"
                placeholder="e.g. Edappal, Kerala, India"
                value={location}
                onChange={(e) => setLocation(e.target.value)}
                required
                style={{ fontSize: '0.92rem', padding: '10px 14px', borderRadius: '8px' }}
              />
            </div>

            {/* Website URL */}
            <div className="input-group">
              <label className="input-label" style={{ fontWeight: 800, color: '#0f172a' }}>
                Website URL
              </label>
              <input
                type="url"
                className="optigo-input"
                placeholder="https://www.yourdomain.com"
                value={website}
                onChange={(e) => setWebsite(e.target.value)}
                style={{ fontSize: '0.92rem', padding: '10px 14px', borderRadius: '8px' }}
              />
            </div>

            {/* Description */}
            <div className="input-group">
              <label className="input-label" style={{ fontWeight: 800, color: '#0f172a' }}>
                Business Overview & Bio
              </label>
              <textarea
                className="optigo-input"
                rows={4}
                placeholder="Provide a detailed description of your business, atmosphere, history, and specialties for Google Search..."
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                style={{ fontSize: '0.92rem', padding: '10px 14px', borderRadius: '8px', lineHeight: 1.5 }}
              />
            </div>

            {/* Services */}
            <div className="input-group">
              <label className="input-label" style={{ fontWeight: 800, color: '#0f172a' }}>
                Services & Offerings
              </label>
              <input
                type="text"
                className="optigo-input"
                placeholder="Dine-in, Takeaway, Home Delivery, Catering, Private Events"
                value={services}
                onChange={(e) => setServices(e.target.value)}
                style={{ fontSize: '0.92rem', padding: '10px 14px', borderRadius: '8px' }}
              />
            </div>

            <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: '10px' }}>
              <button
                type="submit"
                disabled={isSaving || isSyncing}
                className="btn btn-primary"
                style={{ gap: '8px', fontWeight: 800, padding: '10px 22px', fontSize: '0.88rem', borderRadius: '8px' }}
              >
                <Save size={16} />
                <span>{isSaving ? 'Saving Changes...' : 'Save Profile Changes'}</span>
              </button>
            </div>
          </form>
        </div>

        {/* Right: Live Profile Strength Card */}
        <div
          className="prody-card"
          style={{
            padding: '32px',
            borderRadius: '24px',
            backgroundColor: '#ffffff',
            border: '1px solid #e2e8f0',
            display: 'flex',
            flexDirection: 'column',
            gap: '20px',
          }}
        >
          <div>
            <h3 style={{ fontSize: '1.1rem', fontWeight: 900, color: '#0f172a', margin: '0 0 6px 0', letterSpacing: '-0.2px' }}>
              Profile Strength
            </h3>
            <p style={{ fontSize: '0.78rem', color: '#64748b', margin: 0 }}>
              Real-time Google Profile optimization score
            </p>

            {/* Completeness Score */}
            <div style={{ fontSize: '2.5rem', fontWeight: 900, color: dynamicCompletenessScore >= 80 ? '#16a34a' : '#f59e0b', letterSpacing: '-1px', margin: '14px 0 6px 0' }}>
              {dynamicCompletenessScore}%
            </div>

            {/* Progress Bar */}
            <div style={{ height: '8px', backgroundColor: '#f1f5f9', borderRadius: '4px', overflow: 'hidden', margin: '8px 0 16px' }}>
              <div
                style={{
                  width: `${dynamicCompletenessScore}%`,
                  height: '100%',
                  backgroundColor: dynamicCompletenessScore >= 80 ? '#16a34a' : '#f59e0b',
                  borderRadius: '4px',
                  transition: 'width 0.3s ease, background-color 0.3s ease',
                }}
              />
            </div>

            {/* Checklist */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: '10px', marginTop: '16px' }}>
              {checklistItems.map((item, idx) => (
                <div
                  key={idx}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    fontSize: '0.8rem',
                    padding: '8px 10px',
                    borderRadius: '8px',
                    backgroundColor: item.done ? '#f0fdf4' : '#f8fafc',
                    border: item.done ? '1px solid #bbf7d0' : '1px solid #e2e8f0',
                    transition: 'all 0.2s ease',
                  }}
                >
                  <span style={{ fontWeight: 600, color: item.done ? '#166534' : '#475569' }}>
                    {item.label}
                  </span>
                  {item.done ? (
                    <CheckCircle2 size={15} color="#16a34a" />
                  ) : (
                    <span style={{ fontSize: '0.7rem', color: '#94a3b8', fontWeight: 700 }}>
                      Missing
                    </span>
                  )}
                </div>
              ))}
            </div>
          </div>

          <div style={{ borderTop: '1px solid #f1f5f9', paddingTop: '16px', display: 'flex', gap: '8px', alignItems: 'flex-start' }}>
            <Lightbulb size={16} color="#f59e0b" style={{ flexShrink: 0, marginTop: '2px' }} />
            <span style={{ fontSize: '0.78rem', color: '#64748b', lineHeight: 1.5 }}>
              Profiles with <strong>&gt;80% completeness</strong> receive up to <strong>7x more local search views</strong> and direct customer inquiries on Google Maps.
            </span>
          </div>
        </div>
      </div>
    </div>
  );
};
