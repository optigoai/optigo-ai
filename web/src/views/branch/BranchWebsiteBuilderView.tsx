// ==================================================
// OptigoAI Enterprise — Prody Light Website Builder
// Admin & Business Management for optigoai.com/{slug}
// ==================================================

import React, { useState, useEffect } from 'react';
import { useLocation } from '../../context/LocationContext';
import { websiteService } from '../../services/websiteService';
import { BusinessWebsiteItem } from '../../types';
import { PublicBusinessPageView } from '../public/PublicBusinessPageView';
import {
  Globe,
  Sparkles,
  RefreshCw,
  Eye,
  CheckCircle2,
  ExternalLink,
  Code,
  Settings,
  Trash2,
  Save,
  Monitor,
  Tablet,
  Smartphone,
  Copy,
  Check,
  Plus,
  ArrowRight,
  AlertTriangle,
} from 'lucide-react';

export const BranchWebsiteBuilderView: React.FC = () => {
  const { activeLocation } = useLocation();

  const [website, setWebsite] = useState<BusinessWebsiteItem | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [isGenerating, setIsGenerating] = useState<boolean>(false);
  const [isSaving, setIsSaving] = useState<boolean>(false);
  const [saveSuccess, setSaveSuccess] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  // Active builder tab
  const [activeTab, setActiveTab] = useState<'content' | 'seo' | 'code' | 'preview' | 'danger'>('content');
  const [previewDevice, setPreviewDevice] = useState<'desktop' | 'tablet' | 'mobile'>('desktop');
  const [copiedUrl, setCopiedUrl] = useState<boolean>(false);

  // Form State
  const [slug, setSlug] = useState<string>('');
  const [seoTitle, setSeoTitle] = useState<string>('');
  const [seoDescription, setSeoDescription] = useState<string>('');
  const [content, setContent] = useState<any>(null);
  const [customHtml, setCustomHtml] = useState<string>('');
  const [customCss, setCustomCss] = useState<string>('');
  const [customJs, setCustomJs] = useState<string>('');

  const loadWebsite = async () => {
    if (!activeLocation?.id) return;
    setIsLoading(true);
    setError(null);
    try {
      const data = await websiteService.getWebsite(activeLocation.id);
      setWebsite(data);
      setSlug(data.slug || '');
      setSeoTitle(data.seo_title || '');
      setSeoDescription(data.seo_description || '');
      setContent(data.content_json || {});
      setCustomHtml(data.custom_html || '');
      setCustomCss(data.custom_css || '');
      setCustomJs(data.custom_js || '');
    } catch (err: any) {
      setError(err.message || 'Failed to load website configuration.');
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    loadWebsite();
  }, [activeLocation?.id]);

  if (!activeLocation) return null;

  const handleGenerate = async () => {
    setIsGenerating(true);
    setError(null);
    try {
      const fresh = await websiteService.generateWebsite(activeLocation.id);
      setWebsite(fresh);
      setSlug(fresh.slug || '');
      setSeoTitle(fresh.seo_title || '');
      setSeoDescription(fresh.seo_description || '');
      setContent(fresh.content_json || {});
      setSaveSuccess(true);
      setTimeout(() => setSaveSuccess(false), 3000);
    } catch (err: any) {
      setError(err.message || 'Failed to generate website with AI.');
    } finally {
      setIsGenerating(false);
    }
  };

  const handleSave = async (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    setIsSaving(true);
    setError(null);
    try {
      const updated = await websiteService.updateWebsite(activeLocation.id, {
        slug: slug.trim(),
        seo_title: seoTitle.trim(),
        seo_description: seoDescription.trim(),
        content_json: content,
        custom_html: customHtml,
        custom_css: customCss,
        custom_js: customJs,
      });
      setWebsite(updated);
      setSaveSuccess(true);
      setTimeout(() => setSaveSuccess(false), 3000);
    } catch (err: any) {
      setError(err.message || 'Failed to save website changes.');
    } finally {
      setIsSaving(false);
    }
  };

  const handleTogglePublish = async () => {
    if (!website) return;
    const newStatus = website.status === 'published' ? 'draft' : 'published';
    try {
      const updated = await websiteService.updateStatus(activeLocation.id, newStatus);
      setWebsite(updated);
    } catch (err: any) {
      setError(err.message || 'Failed to update publishing status.');
    }
  };

  const handleDelete = async () => {
    if (!window.confirm(`Are you sure you want to delete and reset the public website for ${activeLocation.name}?`)) {
      return;
    }
    try {
      await websiteService.deleteWebsite(activeLocation.id);
      await loadWebsite();
    } catch (err: any) {
      setError(err.message || 'Failed to delete website.');
    }
  };

  const publicUrl = `https://optigoai.com/${slug || website?.slug || ''}`;
  const localPreviewUrl = `/${slug || website?.slug || ''}`;

  const copyPublicUrl = () => {
    navigator.clipboard.writeText(publicUrl);
    setCopiedUrl(true);
    setTimeout(() => setCopiedUrl(false), 2000);
  };

  // Helper to construct preview payload
  const constructPreviewData = () => {
    if (!content) return undefined;
    return {
      id: website?.id || 'preview',
      business_name: activeLocation.name,
      category: activeLocation.category || 'Local Business',
      location: activeLocation.location || 'Local Area',
      phone: activeLocation.phone,
      website_url: activeLocation.website,
      slug: slug || website?.slug || 'business',
      seo_title: seoTitle || `${activeLocation.name} — Official Website`,
      seo_description: seoDescription || 'Official business page.',
      content: content,
      custom_html: customHtml,
      custom_css: customCss,
      custom_js: customJs,
      published_at: website?.published_at,
      canonical_url: publicUrl,
      schema_org_json: {},
    };
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
      {/* 1. Entity Header & Website Control */}
      <div className="entity-header-card">
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px', flexWrap: 'wrap' }}>
          <div className="entity-icon-badge">
            <Globe size={26} />
          </div>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
              <h1 style={{ fontSize: '1.45rem', fontWeight: 800, color: '#111827', lineHeight: 1.2 }}>
                Public Website Builder
              </h1>
              <span className={`prody-pill ${website?.status === 'published' ? 'green' : 'peach'}`}>
                {website?.status === 'published' ? '● Published Live' : '○ Draft Mode'}
              </span>
            </div>

            <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginTop: '6px' }}>
              <span style={{ fontSize: '0.8rem', color: '#6B7280', fontFamily: 'monospace' }}>
                {publicUrl}
              </span>
              <button
                onClick={copyPublicUrl}
                style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#6B7280', padding: 0 }}
                title="Copy URL"
              >
                {copiedUrl ? <Check size={13} color="#059669" /> : <Copy size={13} />}
              </button>
              <span style={{ fontSize: '0.78rem', color: '#9CA3AF' }}>•</span>
              <span style={{ fontSize: '0.78rem', color: '#0284C7', fontWeight: 600 }}>
                {website?.view_count || 0} Page Views
              </span>
            </div>
          </div>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '10px', flexWrap: 'wrap' }}>
          <button
            onClick={handleGenerate}
            disabled={isGenerating}
            className="btn btn-secondary btn-sm"
            style={{ gap: '6px' }}
          >
            <Sparkles size={14} color="#0284C7" />
            <span>{isGenerating ? 'Synthesizing Profile...' : 'AI Re-Generate'}</span>
          </button>

          <a
            href={localPreviewUrl}
            target="_blank"
            rel="noopener noreferrer"
            className="btn btn-secondary btn-sm"
            style={{ gap: '6px', textDecoration: 'none' }}
          >
            <ExternalLink size={14} />
            <span>View Live</span>
          </a>

          <button
            onClick={handleTogglePublish}
            className={`btn btn-sm ${website?.status === 'published' ? 'btn-secondary' : 'btn-coral'}`}
            style={{ gap: '6px' }}
          >
            <CheckCircle2 size={14} />
            <span>{website?.status === 'published' ? 'Unpublish' : 'Publish Live'}</span>
          </button>
        </div>
      </div>

      {saveSuccess && (
        <div style={{ padding: '10px 14px', backgroundColor: '#DCFCE7', border: '1px solid #BBF7D0', borderRadius: 'var(--radius-sm)', color: '#15803D', fontSize: '0.82rem', fontWeight: 600 }}>
          Website settings and content saved successfully!
        </div>
      )}

      {error && (
        <div style={{ padding: '10px 14px', backgroundColor: '#FFE4E6', border: '1px solid #FECDD3', borderRadius: 'var(--radius-sm)', color: '#BE123C', fontSize: '0.82rem', fontWeight: 600 }}>
          {error}
        </div>
      )}

      {/* 2. Builder Navigation Tabs */}
      <div style={{ display: 'flex', gap: '8px', borderBottom: '1px solid var(--border-subtle)', paddingBottom: '8px', overflowX: 'auto' }}>
        {[
          { key: 'content', label: 'Section Content', icon: Globe },
          { key: 'seo', label: 'SEO & URL Slug', icon: Settings },
          { key: 'code', label: '<Code Editor>', icon: Code },
          { key: 'preview', label: 'Live Device Preview', icon: Eye },
          { key: 'danger', label: 'Delete & Reset', icon: Trash2 },
        ].map((tab) => {
          const Icon = tab.icon;
          const isActive = activeTab === tab.key;
          return (
            <button
              key={tab.key}
              onClick={() => setActiveTab(tab.key as any)}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '6px',
                padding: '6px 14px',
                borderRadius: '6px',
                border: 'none',
                backgroundColor: isActive ? '#111827' : '#F3F4F6',
                color: isActive ? '#FFFFFF' : '#4B5563',
                fontSize: '0.8rem',
                fontWeight: 700,
                cursor: 'pointer',
              }}
            >
              <Icon size={14} />
              <span>{tab.label}</span>
            </button>
          );
        })}
      </div>

      {/* Tab 1: Section Content Editor */}
      {activeTab === 'content' && content && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
          {/* Hero Editor */}
          <div className="prody-card">
            <h3 style={{ fontSize: '1rem', fontWeight: 800, color: '#111827', marginBottom: '12px' }}>Hero Section</h3>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
              <div className="input-group">
                <label className="input-label">Headline</label>
                <input
                  type="text"
                  className="optigo-input"
                  value={content.hero?.headline || ''}
                  onChange={(e) => setContent({ ...content, hero: { ...content.hero, headline: e.target.value } })}
                />
              </div>

              <div className="input-group">
                <label className="input-label">Badge Tag</label>
                <input
                  type="text"
                  className="optigo-input"
                  value={content.hero?.badge || ''}
                  onChange={(e) => setContent({ ...content, hero: { ...content.hero, badge: e.target.value } })}
                />
              </div>
            </div>

            <div className="input-group" style={{ marginTop: '10px' }}>
              <label className="input-label">Subheadline Description</label>
              <textarea
                className="optigo-input"
                rows={2}
                value={content.hero?.subheadline || ''}
                onChange={(e) => setContent({ ...content, hero: { ...content.hero, subheadline: e.target.value } })}
              />
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginTop: '10px' }}>
              <div className="input-group">
                <label className="input-label">Primary CTA Button</label>
                <input
                  type="text"
                  className="optigo-input"
                  value={content.hero?.primary_cta_text || ''}
                  onChange={(e) => setContent({ ...content, hero: { ...content.hero, primary_cta_text: e.target.value } })}
                />
              </div>

              <div className="input-group">
                <label className="input-label">Hero Image URL</label>
                <input
                  type="url"
                  className="optigo-input"
                  value={content.hero?.hero_image_url || ''}
                  onChange={(e) => setContent({ ...content, hero: { ...content.hero, hero_image_url: e.target.value } })}
                />
              </div>
            </div>
          </div>

          {/* About Section */}
          <div className="prody-card">
            <h3 style={{ fontSize: '1rem', fontWeight: 800, color: '#111827', marginBottom: '12px' }}>About & Story Section</h3>
            <div className="input-group">
              <label className="input-label">Story Narrative</label>
              <textarea
                className="optigo-input"
                rows={3}
                value={content.about?.story || ''}
                onChange={(e) => setContent({ ...content, about: { ...content.about, story: e.target.value } })}
              />
            </div>
          </div>

          {/* Services Catalog */}
          <div className="prody-card">
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px' }}>
              <h3 style={{ fontSize: '1rem', fontWeight: 800, color: '#111827' }}>Services & Offerings</h3>
              <button
                type="button"
                onClick={() => {
                  const newServices = [...(content.services || []), { name: 'New Specialty', description: 'Description of offering', price_range: 'Best Value', badge: 'Special' }];
                  setContent({ ...content, services: newServices });
                }}
                className="btn btn-secondary btn-sm"
                style={{ gap: '4px' }}
              >
                <Plus size={13} />
                <span>Add Item</span>
              </button>
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
              {(content.services || []).map((svc: any, idx: number) => (
                <div key={idx} style={{ display: 'grid', gridTemplateColumns: '2fr 3fr 1.5fr auto', gap: '8px', alignItems: 'center', padding: '10px', backgroundColor: '#F9FAFB', borderRadius: '8px', border: '1px solid var(--border-subtle)' }}>
                  <input
                    type="text"
                    className="optigo-input"
                    placeholder="Service Name"
                    value={svc.name}
                    onChange={(e) => {
                      const updated = [...content.services];
                      updated[idx].name = e.target.value;
                      setContent({ ...content, services: updated });
                    }}
                  />
                  <input
                    type="text"
                    className="optigo-input"
                    placeholder="Short description"
                    value={svc.description}
                    onChange={(e) => {
                      const updated = [...content.services];
                      updated[idx].description = e.target.value;
                      setContent({ ...content, services: updated });
                    }}
                  />
                  <input
                    type="text"
                    className="optigo-input"
                    placeholder="Price/Badge"
                    value={svc.price_range || ''}
                    onChange={(e) => {
                      const updated = [...content.services];
                      updated[idx].price_range = e.target.value;
                      setContent({ ...content, services: updated });
                    }}
                  />
                  <button
                    type="button"
                    onClick={() => {
                      const updated = content.services.filter((_: any, i: number) => i !== idx);
                      setContent({ ...content, services: updated });
                    }}
                    style={{ background: 'none', border: 'none', color: '#E11D48', cursor: 'pointer', padding: '6px' }}
                  >
                    <Trash2 size={15} />
                  </button>
                </div>
              ))}
            </div>
          </div>

          <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
            <button onClick={() => handleSave()} disabled={isSaving} className="btn btn-coral btn-sm" style={{ gap: '6px' }}>
              <Save size={14} />
              <span>{isSaving ? 'Saving Changes...' : 'Save Content'}</span>
            </button>
          </div>
        </div>
      )}

      {/* Tab 2: SEO & Slug Settings */}
      {activeTab === 'seo' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
          <div className="prody-card">
            <h3 style={{ fontSize: '1rem', fontWeight: 800, color: '#111827', marginBottom: '14px' }}>
              Public URL Slug & Canonical Domain
            </h3>

            <div className="input-group" style={{ marginBottom: '14px' }}>
              <label className="input-label">Unique Business Slug</label>
              <div style={{ display: 'flex', alignItems: 'center' }}>
                <span style={{ padding: '8px 12px', backgroundColor: '#F3F4F6', border: '1px solid var(--border-subtle)', borderRight: 'none', borderRadius: '6px 0 0 6px', fontSize: '0.84rem', color: '#6B7280', fontWeight: 600 }}>
                  optigoai.com/
                </span>
                <input
                  type="text"
                  className="optigo-input"
                  style={{ borderRadius: '0 6px 6px 0' }}
                  value={slug}
                  onChange={(e) => setSlug(e.target.value.toLowerCase().replace(/\s+/g, '-'))}
                />
              </div>
            </div>

            <div className="input-group" style={{ marginBottom: '14px' }}>
              <label className="input-label">SEO Meta Title (Browser & Search Engines)</label>
              <input
                type="text"
                className="optigo-input"
                value={seoTitle}
                onChange={(e) => setSeoTitle(e.target.value)}
              />
            </div>

            <div className="input-group">
              <label className="input-label">SEO Meta Description</label>
              <textarea
                className="optigo-input"
                rows={3}
                value={seoDescription}
                onChange={(e) => setSeoDescription(e.target.value)}
              />
            </div>

            {/* Google SERP Preview */}
            <div style={{ marginTop: '18px', padding: '14px', backgroundColor: '#F8FAFC', border: '1px solid #E2E8F0', borderRadius: '10px' }}>
              <div style={{ fontSize: '0.75rem', fontWeight: 700, color: '#64748B', textTransform: 'uppercase', marginBottom: '8px' }}>
                Google Search Appearance Preview
              </div>
              <div style={{ fontSize: '0.8rem', color: '#202124' }}>
                <div style={{ color: '#202124', fontSize: '0.78rem' }}>optigoai.com › {slug}</div>
                <div style={{ color: '#1a0dab', fontSize: '1rem', fontWeight: 600, marginTop: '2px' }}>{seoTitle || 'Business Title'}</div>
                <div style={{ color: '#4d5156', fontSize: '0.82rem', marginTop: '3px', lineHeight: 1.4 }}>{seoDescription || 'Business description snippet in search engines.'}</div>
              </div>
            </div>
          </div>

          <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
            <button onClick={() => handleSave()} disabled={isSaving} className="btn btn-coral btn-sm" style={{ gap: '6px' }}>
              <Save size={14} />
              <span>{isSaving ? 'Saving...' : 'Save SEO & Slug'}</span>
            </button>
          </div>
        </div>
      )}

      {/* Tab 3: <Code Editor> (Custom HTML/CSS/JS) */}
      {activeTab === 'code' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
          <div className="prody-card">
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '8px' }}>
              <Code size={18} color="#0284C7" />
              <h3 style={{ fontSize: '1rem', fontWeight: 800, color: '#111827' }}>
                Custom Code & Style Overrides
              </h3>
            </div>
            <p style={{ fontSize: '0.82rem', color: '#6B7280', marginBottom: '16px' }}>
              Administrators can inject custom CSS styling, custom HTML embed snippets (e.g. reservation widgets), or analytics scripts.
            </p>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
              <div className="input-group">
                <label className="input-label">Custom CSS Overrides</label>
                <textarea
                  className="optigo-input"
                  rows={4}
                  style={{ fontFamily: 'monospace', fontSize: '0.8rem', backgroundColor: '#1E293B', color: '#38BDF8' }}
                  placeholder="/* Example: .public-nav-links { font-size: 0.9rem; } */"
                  value={customCss}
                  onChange={(e) => setCustomCss(e.target.value)}
                />
              </div>

              <div className="input-group">
                <label className="input-label">Custom HTML Injection (Widgets / Badges)</label>
                <textarea
                  className="optigo-input"
                  rows={4}
                  style={{ fontFamily: 'monospace', fontSize: '0.8rem', backgroundColor: '#1E293B', color: '#A7F3D0' }}
                  placeholder="<!-- Custom HTML snippets or external widget embeds -->"
                  value={customHtml}
                  onChange={(e) => setCustomHtml(e.target.value)}
                />
              </div>

              <div className="input-group">
                <label className="input-label">Custom JavaScript / Analytics</label>
                <textarea
                  className="optigo-input"
                  rows={3}
                  style={{ fontFamily: 'monospace', fontSize: '0.8rem', backgroundColor: '#1E293B', color: '#FDE047' }}
                  placeholder="// Custom JS scripts"
                  value={customJs}
                  onChange={(e) => setCustomJs(e.target.value)}
                />
              </div>
            </div>
          </div>

          <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
            <button onClick={() => handleSave()} disabled={isSaving} className="btn btn-coral btn-sm" style={{ gap: '6px' }}>
              <Save size={14} />
              <span>{isSaving ? 'Saving Code...' : 'Save Custom Code'}</span>
            </button>
          </div>
        </div>
      )}

      {/* Tab 4: Live Device Preview */}
      {activeTab === 'preview' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
          <div style={{ display: 'flex', justifyContent: 'center', gap: '8px', padding: '8px', backgroundColor: '#FFFFFF', border: '1px solid var(--border-subtle)', borderRadius: '10px' }}>
            <button
              onClick={() => setPreviewDevice('desktop')}
              style={{ display: 'flex', alignItems: 'center', gap: '6px', padding: '6px 12px', borderRadius: '6px', border: 'none', backgroundColor: previewDevice === 'desktop' ? '#111827' : 'transparent', color: previewDevice === 'desktop' ? '#FFFFFF' : '#6B7280', fontSize: '0.78rem', fontWeight: 600, cursor: 'pointer' }}
            >
              <Monitor size={14} />
              <span>Desktop View</span>
            </button>

            <button
              onClick={() => setPreviewDevice('tablet')}
              style={{ display: 'flex', alignItems: 'center', gap: '6px', padding: '6px 12px', borderRadius: '6px', border: 'none', backgroundColor: previewDevice === 'tablet' ? '#111827' : 'transparent', color: previewDevice === 'tablet' ? '#FFFFFF' : '#6B7280', fontSize: '0.78rem', fontWeight: 600, cursor: 'pointer' }}
            >
              <Tablet size={14} />
              <span>Tablet (768px)</span>
            </button>

            <button
              onClick={() => setPreviewDevice('mobile')}
              style={{ display: 'flex', alignItems: 'center', gap: '6px', padding: '6px 12px', borderRadius: '6px', border: 'none', backgroundColor: previewDevice === 'mobile' ? '#111827' : 'transparent', color: previewDevice === 'mobile' ? '#FFFFFF' : '#6B7280', fontSize: '0.78rem', fontWeight: 600, cursor: 'pointer' }}
            >
              <Smartphone size={14} />
              <span>Mobile (375px)</span>
            </button>
          </div>

          <div
            style={{
              display: 'flex',
              justifyContent: 'center',
              backgroundColor: '#E2E8F0',
              padding: '20px',
              borderRadius: '16px',
              overflow: 'hidden',
              minHeight: '600px',
            }}
          >
            <div
              style={{
                width: previewDevice === 'desktop' ? '100%' : previewDevice === 'tablet' ? '768px' : '375px',
                height: '750px',
                overflowY: 'auto',
                backgroundColor: '#FFFFFF',
                borderRadius: previewDevice === 'desktop' ? '8px' : '24px',
                border: previewDevice === 'desktop' ? '1px solid #CBD5E1' : '8px solid #1E293B',
                boxShadow: '0 10px 25px rgba(0,0,0,0.15)',
                transition: 'width 0.3s ease',
              }}
            >
              <PublicBusinessPageView previewData={constructPreviewData()} />
            </div>
          </div>
        </div>
      )}

      {/* Tab 5: Delete / Danger Zone */}
      {activeTab === 'danger' && (
        <div className="prody-card" style={{ borderColor: '#FECDD3', backgroundColor: '#FFF1F2' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '8px' }}>
            <AlertTriangle size={20} color="#E11D48" />
            <h3 style={{ fontSize: '1rem', fontWeight: 800, color: '#9F1239' }}>Delete & Reset Public Website</h3>
          </div>
          <p style={{ fontSize: '0.84rem', color: '#881337', lineHeight: 1.5, marginBottom: '16px' }}>
            Deleting this public website will immediately unpublish it from <strong>optigoai.com/{slug}</strong> and remove all customized content. You can generate a new website with AI at any time.
          </p>

          <button
            onClick={handleDelete}
            style={{
              padding: '10px 16px',
              backgroundColor: '#E11D48',
              color: '#FFFFFF',
              border: 'none',
              borderRadius: '8px',
              fontWeight: 700,
              fontSize: '0.84rem',
              cursor: 'pointer',
              display: 'inline-flex',
              alignItems: 'center',
              gap: '6px',
            }}
          >
            <Trash2 size={14} />
            <span>Confirm & Delete Website</span>
          </button>
        </div>
      )}
    </div>
  );
};
