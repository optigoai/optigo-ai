// ==================================================
// OptigoAI Enterprise — Growth Directives
// Deduplicated directives stream, strict priority status colors,
// and clean actionable cards
// ==================================================

import React, { useState, useEffect } from 'react';
import { useLocation } from '../../context/LocationContext';
import { recommendationService } from '../../services/recommendationService';
import {
  Zap,
  CheckCircle2,
  RefreshCw,
  Clock,
  ArrowRight,
} from 'lucide-react';
import { RecommendationItem } from '../../types';

export const BranchRecommendationsView: React.FC = () => {
  const { activeLocation, setActiveBranchTab } = useLocation();

  const [recommendations, setRecommendations] = useState<RecommendationItem[]>([]);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [isGenerating, setIsGenerating] = useState<boolean>(false);
  const [filterTab, setFilterTab] = useState<'all' | 'urgent' | 'completed'>('all');

  // Intelligent de-duplication helper
  const deduplicateRecommendations = (items: RecommendationItem[]): RecommendationItem[] => {
    const seenThemes = new Set<string>();
    const deduplicated: RecommendationItem[] = [];

    for (const item of items) {
      const normalizedTitle = item.title.toLowerCase();
      let key = normalizedTitle;

      if (normalizedTitle.includes('review') || normalizedTitle.includes('unanswered') || normalizedTitle.includes('reply')) {
        key = 'reviews_response';
      } else if (normalizedTitle.includes('photo') || normalizedTitle.includes('image')) {
        key = 'profile_photos';
      } else if (normalizedTitle.includes('hour') || normalizedTitle.includes('schedule')) {
        key = 'profile_hours';
      } else if (normalizedTitle.includes('keyword') || normalizedTitle.includes('seo') || normalizedTitle.includes('rank')) {
        key = 'seo_optimization';
      } else if (normalizedTitle.includes('promo') || normalizedTitle.includes('campaign') || normalizedTitle.includes('post')) {
        key = 'marketing_campaign';
      }

      if (!seenThemes.has(key)) {
        seenThemes.add(key);
        deduplicated.push(item);
      }
    }

    return deduplicated;
  };

  const loadRecommendations = async () => {
    if (!activeLocation?.id) return;
    setIsLoading(true);
    try {
      const data = await recommendationService.getRecommendations(activeLocation.id);
      setRecommendations(deduplicateRecommendations(data));
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    loadRecommendations();
  }, [activeLocation?.id]);

  if (!activeLocation) return null;

  const handleGenerate = async () => {
    setIsGenerating(true);
    try {
      const fresh = await recommendationService.generateRecommendations(activeLocation.id);
      setRecommendations(deduplicateRecommendations(fresh));
    } finally {
      setIsGenerating(false);
    }
  };

  const handleStatusChange = async (recId: string, newStatus: 'completed' | 'in_progress' | 'pending') => {
    try {
      await recommendationService.updateStatus(recId, activeLocation.id, newStatus);
      setRecommendations((prev) =>
        prev.map((r) => (r.id === recId ? { ...r, status: newStatus } : r))
      );
    } catch {
      // Fallback
    }
  };

  const urgentCount = recommendations.filter((r) => r.status !== 'completed' && (r.priority === 'urgent' || r.impact === 'High')).length;
  const completedCount = recommendations.filter((r) => r.status === 'completed').length;

  const filtered = recommendations.filter((r) => {
    if (filterTab === 'urgent') return r.status !== 'completed' && (r.priority === 'urgent' || r.impact === 'High');
    if (filterTab === 'completed') return r.status === 'completed';
    return true;
  });

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '20px', maxWidth: '1280px', margin: '0 auto', width: '100%' }}>
      {/* 1. Entity Header */}
      <div className="entity-header-card" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '14px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <div className="entity-icon-badge" style={{ backgroundColor: '#eff6ff', color: '#2563eb' }}>
            <Zap size={24} />
          </div>
          <div>
            <h1 style={{ fontSize: '1.35rem', fontWeight: 800, color: '#0f172a', lineHeight: 1.2, margin: 0 }}>
              Autonomous Growth Directives
            </h1>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginTop: '6px', flexWrap: 'wrap' }}>
              <span className="prody-pill blue">{recommendations.length} Directives</span>
              <span className="prody-pill coral">{urgentCount} Urgent</span>
              <span className="prody-pill green">{completedCount} Implemented</span>
            </div>
          </div>
        </div>

        <button
          onClick={handleGenerate}
          disabled={isGenerating}
          className="btn btn-primary"
          style={{ gap: '8px', fontSize: '0.88rem', fontWeight: 800, padding: '10px 20px', borderRadius: '10px' }}
        >
          <RefreshCw size={16} className={isGenerating ? 'spin-anim' : ''} />
          <span>{isGenerating ? 'Analyzing Profile...' : 'Scan Profile & Generate'}</span>
        </button>
      </div>

      {/* 2. Directives Stream */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
        {/* Filter Pills */}
        <div style={{ display: 'flex', gap: '8px' }}>
          <button
            onClick={() => setFilterTab('all')}
            style={{
              padding: '6px 14px',
              borderRadius: '8px',
              border: 'none',
              backgroundColor: filterTab === 'all' ? '#1255E6' : '#f1f5f9',
              color: filterTab === 'all' ? '#ffffff' : '#64748b',
              fontSize: '0.82rem',
              fontWeight: 800,
              cursor: 'pointer',
              boxShadow: filterTab === 'all' ? '0 2px 6px rgba(18, 85, 230, 0.25)' : 'none',
              transition: 'all 0.15s ease',
            }}
          >
            All ({recommendations.length})
          </button>
          <button
            onClick={() => setFilterTab('urgent')}
            style={{
              padding: '6px 14px',
              borderRadius: '8px',
              border: 'none',
              backgroundColor: filterTab === 'urgent' ? '#ef4444' : '#f1f5f9',
              color: filterTab === 'urgent' ? '#ffffff' : '#64748b',
              fontSize: '0.82rem',
              fontWeight: 800,
              cursor: 'pointer',
              boxShadow: filterTab === 'urgent' ? '0 2px 6px rgba(239, 68, 68, 0.25)' : 'none',
              transition: 'all 0.15s ease',
            }}
          >
            Urgent ({urgentCount})
          </button>
          <button
            onClick={() => setFilterTab('completed')}
            style={{
              padding: '6px 14px',
              borderRadius: '8px',
              border: 'none',
              backgroundColor: filterTab === 'completed' ? '#10b981' : '#f1f5f9',
              color: filterTab === 'completed' ? '#ffffff' : '#64748b',
              fontSize: '0.82rem',
              fontWeight: 800,
              cursor: 'pointer',
              boxShadow: filterTab === 'completed' ? '0 2px 6px rgba(16, 185, 129, 0.25)' : 'none',
              transition: 'all 0.15s ease',
            }}
          >
            Implemented ({completedCount})
          </button>
        </div>

        {/* Directives List */}
        {filtered.map((item) => {
          const isDone = item.status === 'completed';
          const isUrgent = item.impact === 'High' || item.priority === 'urgent';

          return (
            <div
              key={item.id}
              className="prody-card"
              style={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                flexWrap: 'wrap',
                gap: '14px',
                opacity: isDone ? 0.65 : 1,
                padding: '18px 20px',
                border: isUrgent && !isDone ? '1px solid #fecdd3' : '1px solid #e2e8f0',
                backgroundColor: isUrgent && !isDone ? '#fffafb' : '#ffffff',
              }}
            >
              <div style={{ maxWidth: '75%' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '6px' }}>
                  <span className={`prody-pill ${isUrgent ? 'coral' : 'blue'}`} style={{ fontSize: '0.68rem' }}>
                    {item.related_feature || 'Optimization'}
                  </span>
                  <span className="prody-pill gray" style={{ fontSize: '0.68rem' }}>
                    {item.effort} Effort
                  </span>
                  <span className={`prody-pill ${isDone ? 'green' : (isUrgent ? 'coral' : 'blue')}`} style={{ fontSize: '0.68rem' }}>
                    {isDone ? 'Implemented' : (isUrgent ? 'Urgent Priority' : 'Recommended')}
                  </span>
                </div>

                <h3 style={{ fontSize: '0.96rem', fontWeight: 800, color: '#0f172a', margin: '0 0 4px 0' }}>
                  {item.title}
                </h3>
                <p style={{ fontSize: '0.82rem', color: '#475569', lineHeight: 1.45, margin: 0 }}>
                  {item.explanation || item.reason || item.suggested_action}
                </p>
              </div>

              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                {isDone ? (
                  <button
                    onClick={() => handleStatusChange(item.id, 'pending')}
                    className="btn btn-secondary btn-sm"
                    style={{ fontSize: '0.78rem' }}
                  >
                    Reopen
                  </button>
                ) : (
                  <button
                    onClick={() => handleStatusChange(item.id, 'completed')}
                    className="btn btn-primary btn-sm"
                    style={{ gap: '4px', fontSize: '0.78rem', fontWeight: 700 }}
                  >
                    <CheckCircle2 size={13} />
                    <span>Mark Done</span>
                  </button>
                )}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};
