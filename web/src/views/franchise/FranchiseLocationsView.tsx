// ==================================================
// OptigoAI Enterprise — Pure Franchise Locations Directory
// Focused purely on location management (Name, Category, City, Status, Manage)
// Performance metrics (Health, Rating, Rank) live exclusively in Insights
// ==================================================

import React from 'react';
import { useFranchise } from '../../context/FranchiseContext';
import { useLocation } from '../../context/LocationContext';
import {
  Building2,
  Search,
  Plus,
  ArrowRight,
  ExternalLink,
  MapPin,
  CheckCircle2,
  AlertCircle,
} from 'lucide-react';

export const FranchiseLocationsView: React.FC = () => {
  const { filteredLocations, searchQuery, setSearchQuery } = useFranchise();
  const { selectLocation, setIsOnboardingOpen } = useLocation();

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '20px', maxWidth: '1280px', margin: '0 auto', width: '100%' }}>
      {/* 1. Directory Header Card */}
      <div className="entity-header-card" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '14px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
          <div className="entity-icon-badge" style={{ backgroundColor: '#eff6ff', color: '#2563eb' }}>
            <Building2 size={24} />
          </div>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <h1 style={{ fontSize: '1.4rem', fontWeight: 800, color: '#0f172a', lineHeight: 1.2, margin: 0 }}>
                Locations Directory
              </h1>
              <span className="prody-pill blue" style={{ fontSize: '0.72rem' }}>
                {filteredLocations.length} Branches Managed
              </span>
            </div>
            <p style={{ fontSize: '0.8rem', color: '#64748b', margin: '4px 0 0 0' }}>
              Registry of all physical store branches, categories, Google Business Profile links, and management controls.
            </p>
          </div>
        </div>

        <button
          onClick={() => setIsOnboardingOpen(true)}
          className="btn btn-primary"
          style={{ gap: '8px', fontSize: '0.88rem', fontWeight: 800, padding: '10px 20px', borderRadius: '10px' }}
        >
          <Plus size={16} />
          <span>Add Location</span>
        </button>
      </div>

      {/* 2. Search Bar */}
      <div className="prody-card" style={{ padding: '16px 20px' }}>
        <div style={{ position: 'relative', width: '100%', maxWidth: '480px' }}>
          <Search size={16} color="#64748b" style={{ position: 'absolute', left: '14px', top: '50%', transform: 'translateY(-50%)' }} />
          <input
            type="text"
            placeholder="Search branch name, category, or city..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            style={{
              width: '100%',
              padding: '11px 16px 11px 40px',
              borderRadius: '10px',
              border: '1.5px solid #cbd5e1',
              fontSize: '0.88rem',
              fontWeight: 500,
              outline: 'none',
              backgroundColor: '#f8fafc',
            }}
          />
        </div>
      </div>

      {/* 4. Pure Directory Table (Name, Category, City, Status, Manage) */}
      <div className="prody-card" style={{ padding: 0, overflow: 'hidden' }}>
        <div className="prody-table-wrapper" style={{ border: 'none', borderRadius: 0 }}>
          <table className="prody-table">
            <thead>
              <tr>
                <th style={{ width: '40px' }}>#</th>
                <th>Branch Name</th>
                <th>Category</th>
                <th>City / Area</th>
                <th>Public Website</th>
                <th>Status</th>
                <th style={{ textAlign: 'right' }}>Action</th>
              </tr>
            </thead>
            <tbody>
              {filteredLocations.map((loc, idx) => {
                const isHealthy = (loc.health_score || 0) >= 65 && (loc.unreplied_reviews || 0) === 0;

                return (
                  <tr key={loc.id} style={{ cursor: 'pointer' }} onClick={() => selectLocation(loc.id)}>
                    <td style={{ color: '#94a3b8', fontWeight: 700, fontSize: '0.78rem' }}>
                      {String(idx + 1).padStart(2, '0')}
                    </td>
                    <td>
                      <div style={{ fontWeight: 800, color: '#0f172a' }}>{loc.name}</div>
                    </td>
                    <td>
                      <span className="prody-pill blue" style={{ fontSize: '0.72rem' }}>
                        {loc.category || 'Business'}
                      </span>
                    </td>
                    <td style={{ color: '#64748b', fontSize: '0.82rem' }}>
                      {loc.location}
                    </td>
                    <td>
                      {loc.public_website_url ? (
                        <a
                          href={loc.public_website_url}
                          target="_blank"
                          rel="noreferrer"
                          onClick={(e) => e.stopPropagation()}
                          style={{
                            color: '#2563eb',
                            fontWeight: 600,
                            fontSize: '0.8rem',
                            display: 'flex',
                            alignItems: 'center',
                            gap: '4px',
                            textDecoration: 'none',
                          }}
                        >
                          <span>{loc.public_website_url.replace('https://', '')}</span>
                          <ExternalLink size={12} />
                        </a>
                      ) : (
                        <span style={{ color: '#94a3b8' }}>—</span>
                      )}
                    </td>
                    <td>
                      {isHealthy ? (
                        <span className="prody-pill green" style={{ fontSize: '0.72rem', gap: '4px' }}>
                          <CheckCircle2 size={11} /> Healthy
                        </span>
                      ) : (
                        <span className="prody-pill coral" style={{ fontSize: '0.72rem', gap: '4px' }}>
                          <AlertCircle size={11} /> Action Required
                        </span>
                      )}
                    </td>
                    <td style={{ textAlign: 'right' }}>
                      <button
                        onClick={(e) => {
                          e.stopPropagation();
                          selectLocation(loc.id);
                        }}
                        className="btn btn-secondary"
                        style={{ fontSize: '0.84rem', fontWeight: 800, padding: '7px 14px', borderRadius: '8px', gap: '6px' }}
                      >
                        <span>Manage</span>
                        <ArrowRight size={14} />
                      </button>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
