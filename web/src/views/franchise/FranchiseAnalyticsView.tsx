// ==================================================
// OptigoAI Enterprise — Prody Light Analytics View
// ==================================================

import React from 'react';
import { useFranchise } from '../../context/FranchiseContext';
import {
  TrendingUp,
  PhoneCall,
  Navigation,
  Globe,
} from 'lucide-react';

export const FranchiseAnalyticsView: React.FC = () => {
  const { overview } = useFranchise();

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
      {/* 1. Entity Header */}
      <div className="entity-header-card">
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <div className="entity-icon-badge">
            <TrendingUp size={26} />
          </div>
          <div>
            <h1 style={{ fontSize: '1.45rem', fontWeight: 800, color: '#111827', lineHeight: 1.2 }}>
              Franchise Marketing & Inquiries
            </h1>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginTop: '6px' }}>
              <span className="prody-pill blue">{overview.total_customer_actions.toLocaleString()} Total Inquiries</span>
              <span className="prody-pill green">{overview.positive_sentiment_pct}% Positive Sentiment</span>
            </div>
          </div>
        </div>
      </div>

      {/* 2. 3 Stat Boxes */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: '16px' }}>
        <div className="prody-card">
          <span style={{ fontSize: '0.75rem', fontWeight: 700, color: '#6B7280', textTransform: 'uppercase' }}>
            Customer Calls
          </span>
          <div style={{ fontSize: '1.8rem', fontWeight: 800, color: '#0284C7', marginTop: '4px' }}>
            {overview.total_calls.toLocaleString()}
          </div>
          <span style={{ fontSize: '0.75rem', color: '#6B7280' }}>Phone inquiries from Maps</span>
        </div>

        <div className="prody-card">
          <span style={{ fontSize: '0.75rem', fontWeight: 700, color: '#6B7280', textTransform: 'uppercase' }}>
            Driving Directions
          </span>
          <div style={{ fontSize: '1.8rem', fontWeight: 800, color: '#E11D48', marginTop: '4px' }}>
            {overview.total_direction_requests.toLocaleString()}
          </div>
          <span style={{ fontSize: '0.75rem', color: '#6B7280' }}>Customer route requests</span>
        </div>

        <div className="prody-card">
          <span style={{ fontSize: '0.75rem', fontWeight: 700, color: '#6B7280', textTransform: 'uppercase' }}>
            Website Visits
          </span>
          <div style={{ fontSize: '1.8rem', fontWeight: 800, color: '#059669', marginTop: '4px' }}>
            {overview.total_website_clicks.toLocaleString()}
          </div>
          <span style={{ fontSize: '0.75rem', color: '#6B7280' }}>Clicks from Google profile</span>
        </div>
      </div>

      {/* 3. Inquiry Channels Breakdown */}
      <div className="prody-card">
        <h3 style={{ fontSize: '1rem', fontWeight: 800, color: '#111827', marginBottom: '16px' }}>
          Inquiry Channels Breakdown
        </h3>

        <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
          <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.84rem', marginBottom: '4px' }}>
              <span style={{ color: '#111827', fontWeight: 600 }}>Google Maps Driving Directions</span>
              <strong style={{ color: '#111827' }}>{overview.total_direction_requests}</strong>
            </div>
            <div style={{ height: '6px', backgroundColor: '#F3F4F6', borderRadius: '3px', overflow: 'hidden' }}>
              <div style={{ width: '45%', height: '100%', backgroundColor: '#E11D48', borderRadius: '3px' }} />
            </div>
          </div>

          <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.84rem', marginBottom: '4px' }}>
              <span style={{ color: '#111827', fontWeight: 600 }}>Direct Phone Calls</span>
              <strong style={{ color: '#111827' }}>{overview.total_calls}</strong>
            </div>
            <div style={{ height: '6px', backgroundColor: '#F3F4F6', borderRadius: '3px', overflow: 'hidden' }}>
              <div style={{ width: '35%', height: '100%', backgroundColor: '#0284C7', borderRadius: '3px' }} />
            </div>
          </div>

          <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.84rem', marginBottom: '4px' }}>
              <span style={{ color: '#111827', fontWeight: 600 }}>Website & Menu Clicks</span>
              <strong style={{ color: '#111827' }}>{overview.total_website_clicks}</strong>
            </div>
            <div style={{ height: '6px', backgroundColor: '#F3F4F6', borderRadius: '3px', overflow: 'hidden' }}>
              <div style={{ width: '20%', height: '100%', backgroundColor: '#059669', borderRadius: '3px' }} />
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
