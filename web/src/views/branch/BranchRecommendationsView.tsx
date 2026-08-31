// ==================================================
// OptigoAI Enterprise — Prody Light Growth Directives
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
  TrendingUp,
} from 'lucide-react';
import { RecommendationItem } from '../../types';

export const BranchRecommendationsView: React.FC = () => {
  const { activeLocation, setActiveBranchTab } = useLocation();

  const [recommendations, setRecommendations] = useState<RecommendationItem[]>([]);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [isGenerating, setIsGenerating] = useState<boolean>(false);
  const [filterTab, setFilterTab] = useState<'all' | 'urgent' | 'completed'>('all');

  const loadRecommendations = async () => {
    if (!activeLocation?.id) return;
    setIsLoading(true);
    try {
      const data = await recommendationService.getRecommendations(activeLocation.id);
      setRecommendations(data);
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
      setRecommendations(fresh);
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
    <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
      {/* 1. Entity Header */}
      <div className="entity-header-card">
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <div className="entity-icon-badge">
            <Zap size={26} />
          </div>
          <div>
            <h1 style={{ fontSize: '1.45rem', fontWeight: 800, color: '#111827', lineHeight: 1.2 }}>
              Autonomous Growth Directives
            </h1>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginTop: '6px' }}>
              <span className="prody-pill blue">{recommendations.length} Directives</span>
              <span className="prody-pill red">{urgentCount} High Priority</span>
              <span className="prody-pill green">{completedCount} Implemented</span>
            </div>
          </div>
        </div>

        <button
          onClick={handleGenerate}
          disabled={isGenerating}
          className="btn btn-coral btn-sm"
          style={{ gap: '6px' }}
        >
          <RefreshCw size={14} className={isGenerating ? 'spin-anim' : ''} />
          <span>{isGenerating ? 'Analyzing Profile...' : 'Scan Profile & Generate'}</span>
        </button>
      </div>

      {/* 2. Directives Stream */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
        {/* Filter Pills */}
        <div style={{ display: 'flex', gap: '6px' }}>
          <button
            onClick={() => setFilterTab('all')}
            style={{
              padding: '5px 12px',
              borderRadius: '4px',
              border: 'none',
              backgroundColor: filterTab === 'all' ? '#111827' : '#F3F4F6',
              color: filterTab === 'all' ? '#FFFFFF' : '#4B5563',
              fontSize: '0.78rem',
              fontWeight: 600,
              cursor: 'pointer',
            }}
          >
            All ({recommendations.length})
          </button>
          <button
            onClick={() => setFilterTab('urgent')}
            style={{
              padding: '5px 12px',
              borderRadius: '4px',
              border: 'none',
              backgroundColor: filterTab === 'urgent' ? '#E11D48' : '#F3F4F6',
              color: filterTab === 'urgent' ? '#FFFFFF' : '#4B5563',
              fontSize: '0.78rem',
              fontWeight: 600,
              cursor: 'pointer',
            }}
          >
            Urgent ({urgentCount})
          </button>
          <button
            onClick={() => setFilterTab('completed')}
            style={{
              padding: '5px 12px',
              borderRadius: '4px',
              border: 'none',
              backgroundColor: filterTab === 'completed' ? '#059669' : '#F3F4F6',
              color: filterTab === 'completed' ? '#FFFFFF' : '#4B5563',
              fontSize: '0.78rem',
              fontWeight: 600,
              cursor: 'pointer',
            }}
          >
            Implemented ({completedCount})
          </button>
        </div>

        {/* Directives List */}
        {filtered.map((item) => {
          const isDone = item.status === 'completed';
          const isHigh = item.impact === 'High' || item.priority === 'urgent';

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
                opacity: isDone ? 0.7 : 1,
              }}
            >
              <div style={{ maxWidth: '75%' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '4px' }}>
                  <span className={`prody-pill ${isHigh ? 'red' : 'blue'}`}>{item.related_feature || 'Optimization'}</span>
                  <span className="prody-pill grey">{item.effort} Effort</span>
                  <span className={`prody-pill ${isDone ? 'green' : 'peach'}`}>
                    {isDone ? 'Implemented' : 'Pending'}
                  </span>
                </div>

                <h3 style={{ fontSize: '1rem', fontWeight: 700, color: '#111827', marginBottom: '2px' }}>
                  {item.title}
                </h3>
                <p style={{ fontSize: '0.84rem', color: '#4B5563', lineHeight: 1.4 }}>
                  {item.explanation || item.reason || item.suggested_action}
                </p>
              </div>

              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                {isDone ? (
                  <button
                    onClick={() => handleStatusChange(item.id, 'pending')}
                    className="btn btn-secondary btn-sm"
                  >
                    Reopen
                  </button>
                ) : (
                  <button
                    onClick={() => handleStatusChange(item.id, 'completed')}
                    className="btn btn-coral btn-sm"
                    style={{ gap: '4px' }}
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
