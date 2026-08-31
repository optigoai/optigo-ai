// ==================================================
// OptigoAI Enterprise — Prody Light Branch Dashboard
// ==================================================

import React from 'react';
import { useLocation } from '../../context/LocationContext';
import {
  Building2,
  MapPin,
  Star,
  Compass,
  Zap,
  ArrowRight,
  ShieldCheck,
  Award,
  PhoneCall,
  Navigation,
} from 'lucide-react';

export const BranchDashboardView: React.FC = () => {
  const { activeLocation, setActiveBranchTab, switchToFranchiseView } = useLocation();

  if (!activeLocation) return null;

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
      {/* 1. Entity Profile Header Card */}
      <div className="entity-header-card">
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <div className="entity-icon-badge">
            <Building2 size={26} />
          </div>

          <div>
            <h1 style={{ fontSize: '1.45rem', fontWeight: 800, color: '#111827', lineHeight: 1.2 }}>
              {activeLocation.name}
            </h1>

            <div style={{ display: 'flex', alignItems: 'center', flexWrap: 'wrap', gap: '10px', marginTop: '6px' }}>
              <span className="prody-pill blue">
                <MapPin size={12} /> {activeLocation.location}
              </span>
              <span className="prody-pill green">
                Google Rank #{activeLocation.google_maps_rank}
              </span>
              <span style={{ fontSize: '0.78rem', color: '#6B7280' }}>
                Profile Completeness: <strong>{activeLocation.completeness_score}%</strong>
              </span>
            </div>
          </div>
        </div>

        {/* Metric Meters */}
        <div className="metric-meter-box">
          <div className="meter-item">
            <div className="meter-label">
              <span style={{ width: '6px', height: '6px', borderRadius: '50%', backgroundColor: '#059669' }} />
              <span>Health</span>
            </div>
            <div className="meter-value">
              {activeLocation.health_score}<span style={{ fontSize: '0.75rem', color: '#9CA3AF' }}>/100</span>
            </div>
          </div>

          <div style={{ width: '1px', height: '24px', backgroundColor: '#E5E7EB' }} />

          <div className="meter-item">
            <div className="meter-label">
              <span style={{ width: '6px', height: '6px', borderRadius: '50%', backgroundColor: '#D97706' }} />
              <span>Rating</span>
            </div>
            <div className="meter-value">
              {activeLocation.average_rating > 0 ? activeLocation.average_rating : '—'}★
            </div>
          </div>

          <div style={{ width: '1px', height: '24px', backgroundColor: '#E5E7EB' }} />

          <div className="meter-item">
            <div className="meter-label">
              <span style={{ width: '6px', height: '6px', borderRadius: '50%', backgroundColor: '#0284C7' }} />
              <span>Reviews</span>
            </div>
            <div className="meter-value">{activeLocation.total_reviews}</div>
          </div>
        </div>
      </div>

      {/* 2. 4 Quick Stat Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '16px' }}>
        <div className="prody-card">
          <span style={{ fontSize: '0.75rem', fontWeight: 700, color: '#6B7280', textTransform: 'uppercase' }}>
            Monthly Discovery
          </span>
          <div style={{ fontSize: '1.8rem', fontWeight: 800, color: '#0284C7', marginTop: '4px' }}>
            {activeLocation.monthly_searches.toLocaleString()}
          </div>
          <span style={{ fontSize: '0.75rem', color: '#6B7280' }}>Maps & search views</span>
        </div>

        <div className="prody-card">
          <span style={{ fontSize: '0.75rem', fontWeight: 700, color: '#6B7280', textTransform: 'uppercase' }}>
            Customer Inquiries
          </span>
          <div style={{ fontSize: '1.8rem', fontWeight: 800, color: '#E11D48', marginTop: '4px' }}>
            {activeLocation.monthly_actions.toLocaleString()}
          </div>
          <span style={{ fontSize: '0.75rem', color: '#6B7280' }}>Calls, clicks & directions</span>
        </div>

        <div className="prody-card">
          <span style={{ fontSize: '0.75rem', fontWeight: 700, color: '#6B7280', textTransform: 'uppercase' }}>
            Local SEO Pack
          </span>
          <div style={{ fontSize: '1.8rem', fontWeight: 800, color: '#059669', marginTop: '4px' }}>
            Rank #{activeLocation.google_maps_rank}
          </div>
          <span style={{ fontSize: '0.75rem', color: '#6B7280' }}>In {activeLocation.location}</span>
        </div>

        <div className="prody-card">
          <span style={{ fontSize: '0.75rem', fontWeight: 700, color: '#6B7280', textTransform: 'uppercase' }}>
            Review Sentiment
          </span>
          <div style={{ fontSize: '1.8rem', fontWeight: 800, color: '#111827', marginTop: '4px' }}>
            {activeLocation.average_rating > 0 ? `${activeLocation.average_rating}★` : '—'}
          </div>
          <span style={{ fontSize: '0.75rem', color: '#059669', fontWeight: 600 }}>{activeLocation.total_reviews} verified reviews</span>
        </div>
      </div>

      {/* 3. Action Launchpads */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: '16px' }}>
        <div className="prody-card clickable" onClick={() => setActiveBranchTab('seo')}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '10px' }}>
            <span className="prody-pill blue">Local SEO</span>
            <ArrowRight size={14} color="#0284C7" />
          </div>
          <h3 style={{ fontSize: '1.05rem', fontWeight: 700, color: '#111827', marginBottom: '4px' }}>
            Keywords & 3x3 Geo-Grid Radar
          </h3>
          <p style={{ fontSize: '0.82rem', color: '#6B7280' }}>
            Tracked local ranking positions and neighborhood search radius map.
          </p>
        </div>

        <div className="prody-card clickable" onClick={() => setActiveBranchTab('reviews')}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '10px' }}>
            <span className="prody-pill peach">Reviews</span>
            <ArrowRight size={14} color="#C2410C" />
          </div>
          <h3 style={{ fontSize: '1.05rem', fontWeight: 700, color: '#111827', marginBottom: '4px' }}>
            Customer Feedback & Responses
          </h3>
          <p style={{ fontSize: '0.82rem', color: '#6B7280' }}>
            Verified Google reviews, sentiment tracking, and 1-tap responses.
          </p>
        </div>

        <div className="prody-card clickable" onClick={() => setActiveBranchTab('profile')}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '10px' }}>
            <span className="prody-pill green">Google Profile</span>
            <ArrowRight size={14} color="#15803D" />
          </div>
          <h3 style={{ fontSize: '1.05rem', fontWeight: 700, color: '#111827', marginBottom: '4px' }}>
            Business Info & Operating Hours
          </h3>
          <p style={{ fontSize: '0.82rem', color: '#6B7280' }}>
            Category, address, contact details, and service offerings.
          </p>
        </div>
      </div>
    </div>
  );
};
