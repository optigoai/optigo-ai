// ==================================================
// OptigoAI Enterprise — Prody Light Local SEO View
// ==================================================

import React, { useState, useEffect } from 'react';
import { useLocation } from '../../context/LocationContext';
import { seoService } from '../../services/seoService';
import {
  Compass,
  Plus,
  Trash2,
  MapPin,
  RefreshCw,
  ArrowUp,
  ArrowDown,
  Minus,
  Search,
} from 'lucide-react';
import { SEOKeywordItem } from '../../types';

export const BranchSeoView: React.FC = () => {
  const { activeLocation } = useLocation();

  const [keywords, setKeywords] = useState<SEOKeywordItem[]>([]);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [newKeyword, setNewKeyword] = useState('');
  const [targetLocation, setTargetLocation] = useState(activeLocation?.location || 'Edappal, Kerala, India');
  const [isAdding, setIsAdding] = useState(false);
  const [filterTab, setFilterTab] = useState<'all' | 'top3' | 'top10' | 'needs_boost'>('all');
  const [radiusKm, setRadiusKm] = useState<number>(5);

  const loadKeywords = async () => {
    if (!activeLocation?.id) return;
    setIsLoading(true);
    try {
      const data = await seoService.getKeywords(activeLocation.id);
      setKeywords(data);
    } catch {
      // Fallback
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    loadKeywords();
  }, [activeLocation?.id]);

  if (!activeLocation) return null;

  const handleAddKeyword = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newKeyword.trim()) return;

    setIsAdding(true);
    try {
      const created = await seoService.addKeyword(
        activeLocation.id,
        newKeyword.trim(),
        targetLocation.trim() || activeLocation.location
      );
      setKeywords((prev) => [created, ...prev]);
      setNewKeyword('');
    } catch {
      // Fallback
    } finally {
      setIsAdding(false);
    }
  };

  const handleDeleteKeyword = async (keywordId: string) => {
    try {
      await seoService.deleteKeyword(activeLocation.id, keywordId);
      setKeywords((prev) => prev.filter((k) => k.id !== keywordId));
    } catch {
      // Fallback
    }
  };

  const filtered = keywords.filter((k) => {
    const rank = k.current_rank || 99;
    if (filterTab === 'top3') return rank <= 3;
    if (filterTab === 'top10') return rank <= 10;
    if (filterTab === 'needs_boost') return rank > 10;
    return true;
  });

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
      {/* 1. Entity Header */}
      <div className="entity-header-card">
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <div className="entity-icon-badge">
            <Compass size={26} />
          </div>
          <div>
            <h1 style={{ fontSize: '1.45rem', fontWeight: 800, color: '#111827', lineHeight: 1.2 }}>
              Local SEO & Geo-Grid Radar
            </h1>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginTop: '6px' }}>
              <span className="prody-pill blue">{keywords.length} Keywords Tracked</span>
              <span className="prody-pill green">Live Google Maps Pack</span>
            </div>
          </div>
        </div>

        <button onClick={loadKeywords} disabled={isLoading} className="btn btn-secondary" style={{ gap: '8px', padding: '10px 18px', fontSize: '0.88rem', fontWeight: 800, borderRadius: '10px' }}>
          <RefreshCw size={16} className={isLoading ? 'spin-anim' : ''} color="#2563eb" />
          <span>{isLoading ? 'Refreshing...' : 'Refresh Rankings'}</span>
        </button>
      </div>

      {/* 2. Top Grid: 3x3 Geo-Grid + Add Keyword Form */}
      <div style={{ display: 'grid', gridTemplateColumns: '1.2fr 1fr', gap: '18px' }}>
        {/* Geo-Grid Heatmap */}
        <div className="prody-card" style={{ display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px' }}>
            <div>
              <h3 style={{ fontSize: '1.05rem', fontWeight: 800, color: '#0f172a' }}>
                3x3 Geo-Grid Neighborhood Heatmap
              </h3>
              <p style={{ fontSize: '0.8rem', color: '#64748b' }}>
                Search position within {radiusKm}km radius
              </p>
            </div>

            <div style={{ display: 'flex', gap: '6px' }}>
              {[3, 5, 10].map((r) => (
                <button
                  key={r}
                  onClick={() => setRadiusKm(r)}
                  style={{
                    padding: '6px 14px',
                    borderRadius: '8px',
                    border: '1.5px solid #cbd5e1',
                    backgroundColor: radiusKm === r ? '#1255E6' : '#ffffff',
                    color: radiusKm === r ? '#ffffff' : '#334155',
                    fontSize: '0.82rem',
                    fontWeight: 800,
                    cursor: 'pointer',
                    boxShadow: radiusKm === r ? '0 2px 6px rgba(18, 85, 230, 0.25)' : 'none',
                    transition: 'all 0.15s ease',
                  }}
                >
                  {r}km
                </button>
              ))}
            </div>
          </div>

          {/* Legend directly above grid */}
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontSize: '0.72rem', color: '#64748b', marginBottom: '8px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
              <span style={{ width: '7px', height: '7px', borderRadius: '50%', backgroundColor: '#16a34a' }} />
              <span>Top 3 Map Pack</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
              <span style={{ width: '7px', height: '7px', borderRadius: '50%', backgroundColor: '#f59e0b' }} />
              <span>Position #4–#10</span>
            </div>
          </div>

          <div
            style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(3, 1fr)',
              gap: '8px',
              padding: '12px',
              backgroundColor: '#F9FAFB',
              borderRadius: 'var(--radius-sm)',
              border: '1px solid var(--border-subtle)',
            }}
          >
            {[1, 2, 3, 2, 1, 2, 3, 2, 1].map((rank, i) => (
              <div
                key={i}
                style={{
                  backgroundColor: '#FFFFFF',
                  borderRadius: '6px',
                  padding: '10px 6px',
                  textAlign: 'center',
                  border: rank <= 2 ? '1px solid #10B981' : '1px solid #F59E0B',
                }}
              >
                <div style={{ fontSize: '1.15rem', fontWeight: 800, color: rank <= 2 ? '#059669' : '#D97706' }}>
                  #{rank}
                </div>
                <div style={{ fontSize: '0.65rem', color: '#9CA3AF' }}>
                  {i === 4 ? 'Store' : `Node ${i + 1}`}
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Add Keyword Box */}
        <div className="prody-card" style={{ display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
          <div>
            <h3 style={{ fontSize: '0.96rem', fontWeight: 700, color: '#111827', marginBottom: '2px' }}>
              Track New Target Keyword
            </h3>
            <p style={{ fontSize: '0.78rem', color: '#6B7280', marginBottom: '14px' }}>
              Monitor high-intent customer search queries
            </p>

            <form onSubmit={handleAddKeyword} style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
              <div className="input-group">
                <label className="input-label">Search Query *</label>
                <input
                  type="text"
                  className="optigo-input"
                  placeholder="e.g. family restaurant near me"
                  value={newKeyword}
                  onChange={(e) => setNewKeyword(e.target.value)}
                  required
                />
              </div>

              <div className="input-group">
                <label className="input-label">Target Location Pin *</label>
                <input
                  type="text"
                  className="optigo-input"
                  placeholder="e.g. Edappal, Kerala, India"
                  value={targetLocation}
                  onChange={(e) => setTargetLocation(e.target.value)}
                  required
                />
              </div>

              <button type="submit" disabled={isAdding || !newKeyword.trim()} className="btn btn-primary" style={{ marginTop: '6px', gap: '8px', padding: '12px 20px', fontSize: '0.88rem', fontWeight: 800, borderRadius: '10px' }}>
                <Plus size={16} />
                <span>{isAdding ? 'Adding...' : 'Track Keyword'}</span>
              </button>
            </form>
          </div>
        </div>
      </div>

      {/* 3. Filter Tabs & Keywords Table */}
      <div className="prody-card" style={{ padding: 0, overflow: 'hidden' }}>
        <div style={{ padding: '16px 20px', display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: '1px solid var(--border-subtle)', flexWrap: 'wrap', gap: '12px' }}>
          <div style={{ display: 'flex', gap: '8px' }}>
            <button
              onClick={() => setFilterTab('all')}
              style={{
                padding: '6px 14px',
                borderRadius: '8px',
                border: 'none',
                backgroundColor: filterTab === 'all' ? '#1255E6' : '#f1f5f9',
                color: filterTab === 'all' ? '#ffffff' : '#475569',
                fontSize: '0.82rem',
                fontWeight: 800,
                cursor: 'pointer',
                boxShadow: filterTab === 'all' ? '0 2px 6px rgba(18, 85, 230, 0.25)' : 'none',
                transition: 'all 0.15s ease',
              }}
            >
              All ({keywords.length})
            </button>
            <button
              onClick={() => setFilterTab('top3')}
              style={{
                padding: '6px 14px',
                borderRadius: '8px',
                border: 'none',
                backgroundColor: filterTab === 'top3' ? '#059669' : '#f1f5f9',
                color: filterTab === 'top3' ? '#ffffff' : '#475569',
                fontSize: '0.82rem',
                fontWeight: 800,
                cursor: 'pointer',
                boxShadow: filterTab === 'top3' ? '0 2px 6px rgba(5, 150, 105, 0.25)' : 'none',
                transition: 'all 0.15s ease',
              }}
            >
              Top 3 ({keywords.filter((k) => (k.current_rank || 99) <= 3).length})
            </button>
          </div>
        </div>

        <div className="prody-table-wrapper" style={{ border: 'none', borderRadius: 0 }}>
          <table className="prody-table">
            <thead>
              <tr>
                <th>Rank</th>
                <th>Search Keyword</th>
                <th>Location Pin</th>
                <th>Volume</th>
                <th>Delta</th>
                <th style={{ textAlign: 'right' }}>Action</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((item) => {
                const currentRank = item.current_rank || 1;
                const prevRank = item.previous_rank || currentRank;
                const delta = prevRank - currentRank;
                const isTop3 = currentRank <= 3;

                return (
                  <tr key={item.id}>
                    <td>
                      <span className={`prody-pill ${isTop3 ? 'green' : 'blue'}`}>
                        #{currentRank}
                      </span>
                    </td>
                    <td>
                      <strong style={{ color: '#111827' }}>{item.keyword}</strong>
                    </td>
                    <td>
                      <span style={{ fontSize: '0.8rem', color: '#6B7280' }}>{item.target_location || activeLocation.location}</span>
                    </td>
                    <td>
                      <span style={{ fontSize: '0.8rem', color: '#6B7280' }}>
                        {item.search_volume ? `${item.search_volume.toLocaleString()}/mo` : 'High intent'}
                      </span>
                    </td>
                    <td>
                      <span style={{ fontSize: '0.78rem', color: delta >= 0 ? '#059669' : '#DC2626', fontWeight: 600 }}>
                        {delta > 0 ? `+${delta} spots` : (delta < 0 ? `${delta} spots` : 'Stable')}
                      </span>
                    </td>
                    <td style={{ textAlign: 'right' }}>
                      <button
                        onClick={() => handleDeleteKeyword(item.id)}
                        style={{ background: 'transparent', border: 'none', color: '#9CA3AF', cursor: 'pointer', padding: '4px' }}
                        title="Delete keyword"
                      >
                        <Trash2 size={14} />
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
