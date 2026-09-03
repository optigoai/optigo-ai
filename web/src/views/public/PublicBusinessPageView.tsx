// ==================================================
// OptigoAI Enterprise — Public Business Website Engine
// Dynamic single-template rendering for optigoai.com/{slug}
// Strictly displays real business data from PostgreSQL
// ==================================================

import React, { useEffect, useState } from 'react';
import { websiteService } from '../../services/websiteService';
import { PublicWebsiteData } from '../../types';
import {
  MapPin,
  Phone,
  Clock,
  Star,
  CheckCircle2,
  Navigation,
  ArrowRight,
  Sparkles,
  Award,
  Heart,
  ShieldCheck,
  ChevronDown,
  ChevronUp,
  Globe,
  Share2,
  ExternalLink,
} from 'lucide-react';

interface PublicBusinessPageViewProps {
  slug?: string;
  previewData?: PublicWebsiteData;
}

export const PublicBusinessPageView: React.FC<PublicBusinessPageViewProps> = ({
  slug,
  previewData,
}) => {
  const [siteData, setSiteData] = useState<PublicWebsiteData | null>(previewData || null);
  const [isLoading, setIsLoading] = useState<boolean>(!previewData);
  const [error, setError] = useState<string | null>(null);
  const [expandedFaq, setExpandedFaq] = useState<number | null>(0);
  const [copiedLink, setCopiedLink] = useState(false);

  const currentSlug = slug || window.location.pathname.replace(/^\/(site\/)?/, '').split('/')[0];

  useEffect(() => {
    if (previewData) {
      setSiteData(previewData);
      setIsLoading(false);
      return;
    }

    if (!currentSlug) {
      setError('No business slug specified.');
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    websiteService
      .getPublicWebsite(currentSlug)
      .then((data) => {
        setSiteData(data);
        if (data.seo_title) {
          document.title = data.seo_title;
        }
        if (data.schema_org_json) {
          const scriptId = 'optigo-jsonld-schema';
          let script = document.getElementById(scriptId) as HTMLScriptElement;
          if (!script) {
            script = document.createElement('script');
            script.id = scriptId;
            script.type = 'application/ld+json';
            document.head.appendChild(script);
          }
          script.textContent = JSON.stringify(data.schema_org_json);
        }
      })
      .catch((err) => {
        setError(err.message || 'Business page not found or currently private.');
      })
      .finally(() => {
        setIsLoading(false);
      });
  }, [currentSlug, previewData]);

  if (isLoading) {
    return (
      <div style={{ width: '100vw', minHeight: '100vh', backgroundColor: '#FFFFFF', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#0284C7', fontFamily: 'Plus Jakarta Sans, sans-serif' }}>
        <div style={{ textAlign: 'center' }}>
          <div style={{ width: '40px', height: '40px', border: '3px solid #E2E8F0', borderTopColor: '#0284C7', borderRadius: '50%', animation: 'spin 0.8s linear infinite', margin: '0 auto 12px' }} />
          <p style={{ color: '#64748B', fontSize: '0.9rem', fontWeight: 600 }}>Loading official business page...</p>
        </div>
      </div>
    );
  }

  if (error || !siteData) {
    return (
      <div style={{ width: '100vw', minHeight: '100vh', backgroundColor: '#F8FAFC', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '20px', fontFamily: 'Plus Jakarta Sans, sans-serif' }}>
        <div style={{ maxWidth: '440px', width: '100%', backgroundColor: '#FFFFFF', border: '1px solid #E2E8F0', borderRadius: '16px', padding: '36px 28px', textAlign: 'center', boxShadow: '0 4px 12px rgba(0,0,0,0.05)' }}>
          <div style={{ width: '48px', height: '48px', borderRadius: '12px', backgroundColor: '#FEE2E2', color: '#E11D48', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', marginBottom: '16px' }}>
            <Globe size={24} />
          </div>
          <h2 style={{ fontSize: '1.25rem', fontWeight: 800, color: '#0F172A', marginBottom: '6px' }}>Page Not Available</h2>
          <p style={{ fontSize: '0.85rem', color: '#64748B', lineHeight: 1.5, marginBottom: '20px' }}>
            {error || 'This business page does not exist or has not been published yet.'}
          </p>
          <a
            href="/"
            style={{ display: 'inline-flex', alignItems: 'center', gap: '6px', backgroundColor: '#1255E6', color: '#FFFFFF', padding: '10px 20px', borderRadius: '8px', fontSize: '0.85rem', fontWeight: 700, textDecoration: 'none' }}
          >
            <span>Visit OptigoAI Home</span>
            <ArrowRight size={14} />
          </a>
        </div>
      </div>
    );
  }

  const { content, business_name, category, location, phone } = siteData;
  const hero = content.hero;
  const about = content.about;
  const services = content.services || [];
  const whyUs = content.why_choose_us || [];
  const reviews = content.reviews;
  const hoursLoc = content.hours_location;
  const faqs = content.faqs || [];
  const cta = content.cta_banner;

  const mapsUrl = `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(hoursLoc?.maps_query || `${business_name} ${location}`)}`;

  const handleShare = () => {
    navigator.clipboard.writeText(window.location.href);
    setCopiedLink(true);
    setTimeout(() => setCopiedLink(false), 2000);
  };

  const hasReviews = reviews && reviews.featured_reviews && reviews.featured_reviews.length > 0;
  const avgRating = reviews?.average_rating || 0;
  const totalReviews = reviews?.total_reviews || 0;

  return (
    <div style={{ backgroundColor: '#FFFFFF', color: '#0F172A', fontFamily: 'Plus Jakarta Sans, -apple-system, BlinkMacSystemFont, sans-serif', minHeight: '100vh', scrollBehavior: 'smooth' }}>
      {/* Custom CSS overrides from Admin */}
      {siteData.custom_css && (
        <style dangerouslySetInnerHTML={{ __html: siteData.custom_css }} />
      )}

      {/* 1. Sticky Public Header */}
      <header
        style={{
          position: 'sticky',
          top: 0,
          zIndex: 100,
          backgroundColor: 'rgba(255, 255, 255, 0.95)',
          backdropFilter: 'blur(8px)',
          borderBottom: '1px solid #E2E8F0',
          padding: '12px 24px',
        }}
      >
        <div style={{ maxWidth: '1200px', margin: '0 auto', display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: '12px' }}>
          {/* Business Brand */}
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <div style={{ width: '36px', height: '36px', borderRadius: '10px', backgroundColor: '#EEF4FE', color: '#1255E6', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 800, fontSize: '1.1rem', border: '1px solid #BFDBFE' }}>
              {business_name.charAt(0)}
            </div>
            <div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                <span style={{ fontSize: '1.05rem', fontWeight: 800, color: '#173D35', letterSpacing: '-0.02em' }}>
                  {business_name}
                </span>
                <span style={{ padding: '2px 6px', backgroundColor: '#DCFCE7', color: '#15803D', fontSize: '0.68rem', fontWeight: 700, borderRadius: '4px' }}>
                  Verified
                </span>
              </div>
              <span style={{ fontSize: '0.75rem', color: '#64748B' }}>
                {category} {location ? `• ${location}` : ''}
              </span>
            </div>
          </div>

          {/* Quick Nav Links */}
          <nav style={{ display: 'flex', alignItems: 'center', gap: '18px', fontSize: '0.84rem', fontWeight: 600, color: '#475569' }} className="public-nav-links">
            <a href="#about" style={{ color: 'inherit', textDecoration: 'none' }}>About</a>
            <a href="#services" style={{ color: 'inherit', textDecoration: 'none' }}>Offerings</a>
            {hasReviews && <a href="#reviews" style={{ color: 'inherit', textDecoration: 'none' }}>Reviews</a>}
            <a href="#location" style={{ color: 'inherit', textDecoration: 'none' }}>Location & Hours</a>
            {faqs.length > 0 && <a href="#faqs" style={{ color: 'inherit', textDecoration: 'none' }}>FAQs</a>}
          </nav>

          {/* Direct CTA Buttons */}
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            {phone && (
              <a
                href={`tel:${phone}`}
                style={{
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: '6px',
                  padding: '8px 14px',
                  backgroundColor: '#F1F5F9',
                  border: '1px solid #CBD5E1',
                  borderRadius: '8px',
                  color: '#0F172A',
                  fontSize: '0.8rem',
                  fontWeight: 700,
                  textDecoration: 'none',
                }}
              >
                <Phone size={13} />
                <span>Call</span>
              </a>
            )}

            <a
              href={mapsUrl}
              target="_blank"
              rel="noopener noreferrer"
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: '6px',
                padding: '8px 14px',
                background: 'linear-gradient(135deg, #F43F5E 0%, #E11D48 100%)',
                color: '#FFFFFF',
                borderRadius: '8px',
                fontSize: '0.8rem',
                fontWeight: 700,
                textDecoration: 'none',
                boxShadow: '0 2px 6px rgba(225,29,72,0.25)',
              }}
            >
              <Navigation size={13} />
              <span>Directions</span>
            </a>

            <button
              onClick={handleShare}
              title="Share Page Link"
              style={{
                padding: '8px 10px',
                backgroundColor: '#F8FAFC',
                border: '1px solid #E2E8F0',
                borderRadius: '8px',
                color: '#64748B',
                cursor: 'pointer',
              }}
            >
              <Share2 size={14} />
            </button>
          </div>
        </div>
      </header>

      {/* 2. Hero Section */}
      <section style={{ backgroundColor: '#F8FAFC', borderBottom: '1px solid #E2E8F0', padding: '60px 24px', position: 'relative', overflow: 'hidden' }}>
        <div style={{ maxWidth: '1200px', margin: '0 auto', display: 'grid', gridTemplateColumns: '1.2fr 0.8fr', gap: '40px', alignItems: 'center' }}>
          <div>
            <div style={{ display: 'inline-flex', alignItems: 'center', gap: '6px', padding: '4px 10px', backgroundColor: '#E0F2FE', color: '#0369A1', borderRadius: '20px', fontSize: '0.75rem', fontWeight: 700, marginBottom: '16px' }}>
              <Sparkles size={13} />
              <span>{hero.badge || `Verified ${category}`}</span>
            </div>

            <h1 style={{ fontSize: '2.4rem', fontWeight: 800, color: '#0F172A', lineHeight: 1.15, letterSpacing: '-0.03em', marginBottom: '14px' }}>
              {hero.headline}
            </h1>

            <p style={{ fontSize: '1rem', color: '#475569', lineHeight: 1.6, marginBottom: '24px', maxWidth: '540px' }}>
              {hero.subheadline}
            </p>

            {/* Google Rating Meter (Strictly from DB) */}
            <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '28px', padding: '10px 14px', backgroundColor: '#FFFFFF', border: '1px solid #E2E8F0', borderRadius: '10px', width: 'fit-content' }}>
              {totalReviews > 0 ? (
                <>
                  <div style={{ display: 'flex', gap: '2px', color: '#F59E0B' }}>
                    {[...Array(Math.min(5, Math.max(1, Math.round(avgRating))))].map((_, i) => (
                      <Star key={i} size={15} fill="#F59E0B" />
                    ))}
                  </div>
                  <span style={{ fontSize: '0.84rem', fontWeight: 800, color: '#0F172A' }}>
                    {avgRating} / 5.0
                  </span>
                  <span style={{ fontSize: '0.78rem', color: '#64748B' }}>
                    ({totalReviews} Verified Google Reviews)
                  </span>
                </>
              ) : (
                <div style={{ display: 'flex', alignItems: 'center', gap: '6px', color: '#0F172A', fontSize: '0.84rem', fontWeight: 700 }}>
                  <CheckCircle2 size={16} color="#0284C7" />
                  <span>Official Verified Listing {location ? `in ${location}` : ''}</span>
                </div>
              )}
            </div>

            {/* Action Buttons */}
            <div style={{ display: 'flex', gap: '12px', flexWrap: 'wrap' }}>
              <a
                href={mapsUrl}
                target="_blank"
                rel="noopener noreferrer"
                style={{
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: '8px',
                  padding: '12px 22px',
                  background: 'linear-gradient(135deg, #F43F5E 0%, #E11D48 100%)',
                  color: '#FFFFFF',
                  borderRadius: '10px',
                  fontSize: '0.9rem',
                  fontWeight: 700,
                  textDecoration: 'none',
                  boxShadow: '0 4px 12px rgba(225,29,72,0.25)',
                }}
              >
                <Navigation size={16} />
                <span>{hero.primary_cta_text || 'Get Directions'}</span>
              </a>

              {phone && (
                <a
                  href={`tel:${phone}`}
                  style={{
                    display: 'inline-flex',
                    alignItems: 'center',
                    gap: '8px',
                    padding: '12px 22px',
                    backgroundColor: '#FFFFFF',
                    border: '1px solid #CBD5E1',
                    borderRadius: '10px',
                    color: '#0F172A',
                    fontSize: '0.9rem',
                    fontWeight: 700,
                    textDecoration: 'none',
                  }}
                >
                  <Phone size={16} />
                  <span>{hero.secondary_cta_text || 'Call Business'}</span>
                </a>
              )}
            </div>
          </div>

          {/* Hero Visual (Image from DB profile or clean brand card) */}
          <div>
            {hero.hero_image_url ? (
              <img
                src={hero.hero_image_url}
                alt={business_name}
                style={{
                  width: '100%',
                  height: '380px',
                  objectFit: 'cover',
                  borderRadius: '20px',
                  border: '1px solid #E2E8F0',
                  boxShadow: '0 12px 30px rgba(0,0,0,0.08)',
                }}
              />
            ) : (
              <div
                style={{
                  width: '100%',
                  height: '340px',
                  background: 'linear-gradient(135deg, #EEF4FE 0%, #EFF6FF 100%)',
                  borderRadius: '20px',
                  display: 'flex',
                  flexDirection: 'column',
                  alignItems: 'center',
                  justifyContent: 'center',
                  padding: '30px',
                  color: '#173D35',
                  textAlign: 'center',
                  border: '1px solid #99F6E4',
                  boxShadow: '0 12px 30px rgba(15,118,110,0.12)',
                }}
              >
                <div style={{ width: '64px', height: '64px', borderRadius: '16px', backgroundColor: '#FFFFFF', border: '1px solid #BFDBFE', color: '#1255E6', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '1.8rem', fontWeight: 800, marginBottom: '16px', boxShadow: '0 6px 16px rgba(18,85,230,0.1)' }}>
                  {business_name.charAt(0)}
                </div>
                <h3 style={{ fontSize: '1.4rem', fontWeight: 800, marginBottom: '4px' }}>{business_name}</h3>
                <span style={{ fontSize: '0.86rem', color: '#527267' }}>{category} {location ? `• ${location}` : ''}</span>
              </div>
            )}
          </div>
        </div>
      </section>

      {/* 3. About Us & Highlights */}
      <section id="about" style={{ padding: '60px 24px', maxWidth: '1200px', margin: '0 auto' }}>
        <div style={{ display: 'grid', gridTemplateColumns: about.image_url ? '0.9fr 1.1fr' : '1fr', gap: '40px', alignItems: 'center' }}>
          {about.image_url && (
            <div>
              <img
                src={about.image_url}
                alt="About Us"
                style={{ width: '100%', height: '340px', objectFit: 'cover', borderRadius: '16px', border: '1px solid #E2E8F0' }}
              />
            </div>
          )}

          <div>
            <span style={{ fontSize: '0.78rem', fontWeight: 800, color: '#0284C7', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
              Our Story & Profile
            </span>
            <h2 style={{ fontSize: '1.8rem', fontWeight: 800, color: '#0F172A', letterSpacing: '-0.02em', marginTop: '6px', marginBottom: '14px' }}>
              {about.title || `About ${business_name}`}
            </h2>
            <p style={{ fontSize: '0.94rem', color: '#475569', lineHeight: 1.7, marginBottom: '20px' }}>
              {about.story}
            </p>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
              {(about.highlights || []).map((item, idx) => (
                <div key={idx} style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                  <div style={{ width: '22px', height: '22px', borderRadius: '50%', backgroundColor: '#DCFCE7', color: '#15803D', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                    <CheckCircle2 size={14} />
                  </div>
                  <span style={{ fontSize: '0.88rem', fontWeight: 600, color: '#0F172A' }}>{item}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </section>

      {/* 4. Services & Offerings Catalog */}
      <section id="services" style={{ backgroundColor: '#F8FAFC', borderTop: '1px solid #E2E8F0', borderBottom: '1px solid #E2E8F0', padding: '60px 24px' }}>
        <div style={{ maxWidth: '1200px', margin: '0 auto' }}>
          <div style={{ textAlign: 'center', marginBottom: '36px' }}>
            <span style={{ fontSize: '0.78rem', fontWeight: 800, color: '#0284C7', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
              Specialties & Catalog
            </span>
            <h2 style={{ fontSize: '1.85rem', fontWeight: 800, color: '#0F172A', letterSpacing: '-0.02em', marginTop: '6px' }}>
              What We Offer
            </h2>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))', gap: '20px' }}>
            {services.map((svc, idx) => (
              <div
                key={idx}
                style={{
                  backgroundColor: '#FFFFFF',
                  border: '1px solid #E2E8F0',
                  borderRadius: '14px',
                  padding: '22px',
                  display: 'flex',
                  flexDirection: 'column',
                  justifyContent: 'space-between',
                  gap: '12px',
                  boxShadow: '0 1px 3px rgba(0,0,0,0.03)',
                }}
              >
                <div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '8px' }}>
                    <h3 style={{ fontSize: '1.05rem', fontWeight: 700, color: '#0F172A' }}>{svc.name}</h3>
                    {svc.badge && (
                      <span style={{ padding: '2px 8px', backgroundColor: '#E0F2FE', color: '#0369A1', fontSize: '0.7rem', fontWeight: 700, borderRadius: '4px' }}>
                        {svc.badge}
                      </span>
                    )}
                  </div>
                  <p style={{ fontSize: '0.84rem', color: '#64748B', lineHeight: 1.5 }}>{svc.description}</p>
                </div>

                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderTop: '1px solid #F1F5F9', paddingTop: '12px' }}>
                  <span style={{ fontSize: '0.78rem', fontWeight: 700, color: '#0284C7' }}>{svc.price_range || 'Details on Request'}</span>
                  {phone ? (
                    <a
                      href={`tel:${phone}`}
                      style={{ fontSize: '0.78rem', fontWeight: 700, color: '#0F172A', textDecoration: 'none', display: 'flex', alignItems: 'center', gap: '4px' }}
                    >
                      <span>Inquire</span>
                      <ArrowRight size={12} />
                    </a>
                  ) : (
                    <a
                      href={mapsUrl}
                      target="_blank"
                      rel="noopener noreferrer"
                      style={{ fontSize: '0.78rem', fontWeight: 700, color: '#0F172A', textDecoration: 'none', display: 'flex', alignItems: 'center', gap: '4px' }}
                    >
                      <span>Visit</span>
                      <ArrowRight size={12} />
                    </a>
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* 5. Why Choose Us */}
      <section style={{ padding: '60px 24px', maxWidth: '1200px', margin: '0 auto' }}>
        <div style={{ textAlign: 'center', marginBottom: '36px' }}>
          <span style={{ fontSize: '0.78rem', fontWeight: 800, color: '#0284C7', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
            Why Choose Us
          </span>
          <h2 style={{ fontSize: '1.85rem', fontWeight: 800, color: '#0F172A', letterSpacing: '-0.02em', marginTop: '6px' }}>
            The {business_name} Commitment
          </h2>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))', gap: '20px' }}>
          {whyUs.map((pillar, idx) => (
            <div
              key={idx}
              style={{
                padding: '24px 20px',
                backgroundColor: '#FFFFFF',
                border: '1px solid #E2E8F0',
                borderRadius: '14px',
                textAlign: 'left',
              }}
            >
              <div style={{ width: '40px', height: '40px', borderRadius: '10px', backgroundColor: '#EFF6FF', color: '#0284C7', display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: '14px' }}>
                <Award size={20} />
              </div>
              <h3 style={{ fontSize: '1rem', fontWeight: 700, color: '#0F172A', marginBottom: '6px' }}>{pillar.title}</h3>
              <p style={{ fontSize: '0.82rem', color: '#64748B', lineHeight: 1.5 }}>{pillar.description}</p>
            </div>
          ))}
        </div>
      </section>

      {/* 6. Verified Customer Reviews (Strictly from DB) */}
      {hasReviews && (
        <section id="reviews" style={{ backgroundColor: '#F8FAFC', borderTop: '1px solid #E2E8F0', borderBottom: '1px solid #E2E8F0', padding: '60px 24px' }}>
          <div style={{ maxWidth: '1200px', margin: '0 auto' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end', marginBottom: '32px', flexWrap: 'wrap', gap: '16px' }}>
              <div>
                <span style={{ fontSize: '0.78rem', fontWeight: 800, color: '#0284C7', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                  Real Feedback
                </span>
                <h2 style={{ fontSize: '1.85rem', fontWeight: 800, color: '#0F172A', letterSpacing: '-0.02em', marginTop: '4px' }}>
                  {reviews.title || 'Verified Customer Reviews'}
                </h2>
              </div>

              <div style={{ display: 'flex', alignItems: 'center', gap: '8px', padding: '8px 14px', backgroundColor: '#FFFFFF', border: '1px solid #E2E8F0', borderRadius: '8px' }}>
                <Star size={18} fill="#F59E0B" color="#F59E0B" />
                <span style={{ fontSize: '1.1rem', fontWeight: 800, color: '#0F172A' }}>{avgRating}</span>
                <span style={{ fontSize: '0.8rem', color: '#64748B' }}>({totalReviews} Reviews)</span>
              </div>
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))', gap: '20px' }}>
              {reviews.featured_reviews.map((rev, idx) => (
                <div
                  key={idx}
                  style={{
                    backgroundColor: '#FFFFFF',
                    border: '1px solid #E2E8F0',
                    borderRadius: '14px',
                    padding: '22px',
                    display: 'flex',
                    flexDirection: 'column',
                    justifyContent: 'space-between',
                    gap: '12px',
                  }}
                >
                  <div>
                    <div style={{ display: 'flex', gap: '2px', color: '#F59E0B', marginBottom: '10px' }}>
                      {[...Array(rev.rating || 5)].map((_, i) => (
                        <Star key={i} size={14} fill="#F59E0B" />
                      ))}
                    </div>
                    <p style={{ fontSize: '0.86rem', color: '#334155', lineHeight: 1.6, fontStyle: 'italic' }}>
                      "{rev.text}"
                    </p>
                  </div>

                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderTop: '1px solid #F1F5F9', paddingTop: '10px' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                      <span style={{ fontSize: '0.82rem', fontWeight: 700, color: '#0F172A' }}>{rev.author_name}</span>
                      <CheckCircle2 size={13} color="#15803D" />
                    </div>
                    <span style={{ fontSize: '0.72rem', color: '#94A3B8' }}>{rev.review_date || 'Google Review'}</span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </section>
      )}

      {/* 7. Location & Hours */}
      <section id="location" style={{ padding: '60px 24px', maxWidth: '1200px', margin: '0 auto' }}>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '36px' }}>
          <div>
            <span style={{ fontSize: '0.78rem', fontWeight: 800, color: '#0284C7', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
              Find Us
            </span>
            <h2 style={{ fontSize: '1.85rem', fontWeight: 800, color: '#0F172A', letterSpacing: '-0.02em', marginTop: '4px', marginBottom: '16px' }}>
              Location & Details
            </h2>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '14px', marginBottom: '24px' }}>
              {location && (
                <div style={{ display: 'flex', alignItems: 'flex-start', gap: '12px' }}>
                  <div style={{ width: '32px', height: '32px', borderRadius: '8px', backgroundColor: '#EFF6FF', color: '#0284C7', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                    <MapPin size={16} />
                  </div>
                  <div>
                    <div style={{ fontSize: '0.82rem', fontWeight: 700, color: '#64748B' }}>Address</div>
                    <div style={{ fontSize: '0.92rem', fontWeight: 600, color: '#0F172A' }}>{location}</div>
                  </div>
                </div>
              )}

              {phone && (
                <div style={{ display: 'flex', alignItems: 'flex-start', gap: '12px' }}>
                  <div style={{ width: '32px', height: '32px', borderRadius: '8px', backgroundColor: '#EFF6FF', color: '#0284C7', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                    <Phone size={16} />
                  </div>
                  <div>
                    <div style={{ fontSize: '0.82rem', fontWeight: 700, color: '#64748B' }}>Direct Phone</div>
                    <a href={`tel:${phone}`} style={{ fontSize: '0.92rem', fontWeight: 600, color: '#0284C7', textDecoration: 'none' }}>{phone}</a>
                  </div>
                </div>
              )}
            </div>

            <a
              href={mapsUrl}
              target="_blank"
              rel="noopener noreferrer"
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: '8px',
                padding: '12px 20px',
                background: 'linear-gradient(135deg, #F43F5E 0%, #E11D48 100%)',
                color: '#FFFFFF',
                borderRadius: '8px',
                fontSize: '0.86rem',
                fontWeight: 700,
                textDecoration: 'none',
              }}
            >
              <Navigation size={14} />
              <span>Open in Google Maps</span>
            </a>
          </div>

          {/* Operating Hours Box */}
          <div style={{ backgroundColor: '#F8FAFC', border: '1px solid #E2E8F0', borderRadius: '16px', padding: '24px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '16px' }}>
              <Clock size={18} color="#0284C7" />
              <h3 style={{ fontSize: '1.05rem', fontWeight: 700, color: '#0F172A' }}>Business Schedule</h3>
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
              {(hoursLoc?.opening_hours || []).map((h, i) => (
                <div
                  key={i}
                  style={{
                    padding: '8px 12px',
                    backgroundColor: '#FFFFFF',
                    border: '1px solid #E2E8F0',
                    borderRadius: '8px',
                    fontSize: '0.82rem',
                    color: '#334155',
                    fontWeight: 600,
                  }}
                >
                  {h}
                </div>
              ))}
            </div>
          </div>
        </div>
      </section>

      {/* 8. FAQs Section */}
      {faqs.length > 0 && (
        <section id="faqs" style={{ backgroundColor: '#F8FAFC', borderTop: '1px solid #E2E8F0', borderBottom: '1px solid #E2E8F0', padding: '60px 24px' }}>
          <div style={{ maxWidth: '800px', margin: '0 auto' }}>
            <div style={{ textAlign: 'center', marginBottom: '32px' }}>
              <span style={{ fontSize: '0.78rem', fontWeight: 800, color: '#0284C7', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                Frequently Asked Questions
              </span>
              <h2 style={{ fontSize: '1.85rem', fontWeight: 800, color: '#0F172A', letterSpacing: '-0.02em', marginTop: '4px' }}>
                Common Inquiries
              </h2>
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
              {faqs.map((faq, idx) => (
                <div
                  key={idx}
                  style={{
                    backgroundColor: '#FFFFFF',
                    border: '1px solid #E2E8F0',
                    borderRadius: '10px',
                    overflow: 'hidden',
                  }}
                >
                  <button
                    onClick={() => setExpandedFaq(expandedFaq === idx ? null : idx)}
                    style={{
                      width: '100%',
                      padding: '16px 20px',
                      background: 'transparent',
                      border: 'none',
                      display: 'flex',
                      justifyContent: 'space-between',
                      alignItems: 'center',
                      cursor: 'pointer',
                      textAlign: 'left',
                      fontSize: '0.92rem',
                      fontWeight: 700,
                      color: '#0F172A',
                    }}
                  >
                    <span>{faq.question}</span>
                    {expandedFaq === idx ? <ChevronUp size={16} color="#64748B" /> : <ChevronDown size={16} color="#64748B" />}
                  </button>

                  {expandedFaq === idx && (
                    <div style={{ padding: '0 20px 16px', fontSize: '0.84rem', color: '#475569', lineHeight: 1.6, borderTop: '1px solid #F1F5F9' }}>
                      {faq.answer}
                    </div>
                  )}
                </div>
              ))}
            </div>
          </div>
        </section>
      )}

      {/* 9. Bottom CTA Banner */}
      <section style={{ padding: '60px 24px', background: 'linear-gradient(135deg, #EEF4FE 0%, #F0F5FF 100%)', color: '#0F172A', textAlign: 'center', borderTop: '1px solid #BFDBFE', borderBottom: '1px solid #BFDBFE' }}>
        <div style={{ maxWidth: '700px', margin: '0 auto' }}>
          <h2 style={{ fontSize: '2rem', fontWeight: 800, marginBottom: '12px', letterSpacing: '-0.02em' }}>
            {cta?.title || `Connect with ${business_name}`}
          </h2>
          <p style={{ fontSize: '0.95rem', color: '#527267', lineHeight: 1.6, marginBottom: '24px' }}>
            {cta?.description || (location ? `Visit us in ${location} or navigate directly on Google Maps.` : `Contact ${business_name} today.`)}
          </p>

          <a
            href={mapsUrl}
            target="_blank"
            rel="noopener noreferrer"
            style={{
              display: 'inline-flex',
              alignItems: 'center',
              gap: '8px',
              padding: '12px 24px',
              background: 'linear-gradient(135deg, #F43F5E 0%, #E11D48 100%)',
              color: '#FFFFFF',
              borderRadius: '10px',
              fontSize: '0.9rem',
              fontWeight: 700,
              textDecoration: 'none',
              boxShadow: '0 4px 14px rgba(225,29,72,0.35)',
            }}
          >
            <Navigation size={15} />
            <span>{cta?.button_text || 'Open in Google Maps'}</span>
          </a>
        </div>
      </section>

      {/* 10. Footer */}
      <footer style={{ backgroundColor: '#F8FCFA', color: '#6B8B80', padding: '24px', fontSize: '0.78rem', borderTop: '1px solid #DCE7E3' }}>
        <div style={{ maxWidth: '1200px', margin: '0 auto', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '12px' }}>
          <div>
            © {new Date().getFullYear()} {business_name}. All rights reserved.
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
            <span>Official page hosted on</span>
            <a href="/" style={{ color: '#1255E6', fontWeight: 700, textDecoration: 'none' }}>OptigoAI Business Network</a>
          </div>
        </div>
      </footer>

      {/* Custom HTML Injected from Admin */}
      {siteData.custom_html && (
        <div dangerouslySetInnerHTML={{ __html: siteData.custom_html }} />
      )}
    </div>
  );
};
