// ==================================================
// OptigoAI Enterprise — Prody Light Reviews View
// ==================================================

import React, { useState, useEffect } from 'react';
import { useLocation } from '../../context/LocationContext';
import { useFranchise } from '../../context/FranchiseContext';
import { reviewsService } from '../../services/reviewsService';
import {
  Star,
  MessageSquare,
  RefreshCw,
  Send,
  X,
  Building2,
  ThumbsUp,
} from 'lucide-react';
import { ReviewItem } from '../../types';

export const BranchReviewsView: React.FC = () => {
  const { activeLocation } = useLocation();
  const { refreshFranchiseData } = useFranchise();

  const [reviews, setReviews] = useState<ReviewItem[]>([]);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [isSyncingGbp, setIsSyncingGbp] = useState<boolean>(false);
  const [filterTab, setFilterTab] = useState<'all' | 'pending' | 'positive' | 'critical'>('all');

  // AI Reply Modal
  const [activeReview, setActiveReview] = useState<ReviewItem | null>(null);
  const [generatedReply, setGeneratedReply] = useState('');
  const [selectedTone, setSelectedTone] = useState('Professional');
  const [isGenerating, setIsGenerating] = useState(false);
  const [isPosting, setIsPosting] = useState(false);

  const loadReviews = async () => {
    if (!activeLocation?.id) return;
    setIsLoading(true);
    try {
      const data = await reviewsService.getReviews(activeLocation.id);
      setReviews(data || []);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    loadReviews();
  }, [activeLocation?.id]);

  if (!activeLocation) return null;

  const handleSyncGbp = async () => {
    setIsSyncingGbp(true);
    try {
      await reviewsService.syncGbpReviews(activeLocation.id);
      await loadReviews();
      await refreshFranchiseData();
    } finally {
      setIsSyncingGbp(false);
    }
  };

  const handleOpenAiReply = async (rev: ReviewItem) => {
    setActiveReview(rev);
    setIsGenerating(true);
    const reply = await reviewsService.generateAiReply(rev.id, selectedTone, activeLocation.id);
    setGeneratedReply(reply);
    setIsGenerating(false);
  };

  const handleRegenerateWithTone = async (tone: string) => {
    setSelectedTone(tone);
    if (!activeReview) return;
    setIsGenerating(true);
    const reply = await reviewsService.generateAiReply(activeReview.id, tone, activeLocation.id);
    setGeneratedReply(reply);
    setIsGenerating(false);
  };

  const handlePostReply = async () => {
    if (!activeReview || !generatedReply) return;
    setIsPosting(true);
    try {
      await reviewsService.postReply(activeReview.id, generatedReply, activeLocation.id);
      setReviews((prev) =>
        prev.map((r) =>
          r.id === activeReview.id
            ? { ...r, is_replied: true, reply_text: generatedReply, reply_date: 'Just now' }
            : r
        )
      );
      setActiveReview(null);
    } finally {
      setIsPosting(false);
    }
  };

  const totalCount = reviews.length;
  const pendingReviews = reviews.filter((r) => !r.is_replied);
  const pendingCount = pendingReviews.length;
  const positiveReviews = reviews.filter((r) => r.rating >= 4 || r.sentiment === 'positive');
  const positiveCount = positiveReviews.length;

  const avgRating =
    totalCount > 0 ? (reviews.reduce((sum, r) => sum + r.rating, 0) / totalCount).toFixed(1) : '—';

  const filtered = reviews.filter((r) => {
    if (filterTab === 'pending') return !r.is_replied;
    if (filterTab === 'positive') return r.rating >= 4 || r.sentiment === 'positive';
    if (filterTab === 'critical') return r.rating <= 2 || r.sentiment === 'negative';
    return true;
  });

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
      {/* 1. Entity Header */}
      <div className="entity-header-card">
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <div className="entity-icon-badge">
            <Star size={26} />
          </div>
          <div>
            <h1 style={{ fontSize: '1.45rem', fontWeight: 800, color: '#111827', lineHeight: 1.2 }}>
              Customer Reviews & Feedback
            </h1>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginTop: '6px' }}>
              <span className="prody-pill blue">{totalCount} Verified Reviews</span>
              <span className="prody-pill green">{avgRating}★ Average Rating</span>
              <span className="prody-pill peach">{pendingCount} Pending Reply</span>
            </div>
          </div>
        </div>

        <button onClick={handleSyncGbp} disabled={isSyncingGbp} className="btn btn-secondary btn-sm" style={{ gap: '6px' }}>
          <RefreshCw size={14} className={isSyncingGbp ? 'spin-anim' : ''} />
          <span>{isSyncingGbp ? 'Syncing GBP...' : 'Sync GBP Reviews'}</span>
        </button>
      </div>

      {/* 2. Reviews Feed */}
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
            All ({totalCount})
          </button>
          <button
            onClick={() => setFilterTab('pending')}
            style={{
              padding: '5px 12px',
              borderRadius: '4px',
              border: 'none',
              backgroundColor: filterTab === 'pending' ? '#E11D48' : '#F3F4F6',
              color: filterTab === 'pending' ? '#FFFFFF' : '#4B5563',
              fontSize: '0.78rem',
              fontWeight: 600,
              cursor: 'pointer',
            }}
          >
            Pending ({pendingCount})
          </button>
          <button
            onClick={() => setFilterTab('positive')}
            style={{
              padding: '5px 12px',
              borderRadius: '4px',
              border: 'none',
              backgroundColor: filterTab === 'positive' ? '#059669' : '#F3F4F6',
              color: filterTab === 'positive' ? '#FFFFFF' : '#4B5563',
              fontSize: '0.78rem',
              fontWeight: 600,
              cursor: 'pointer',
            }}
          >
            Positive ({positiveCount})
          </button>
        </div>

        {/* Reviews List */}
        {filtered.map((rev) => {
          const reviewerName = rev.reviewer_name || rev.author_name || 'Verified Customer';
          const initials = reviewerName.substring(0, 2).toUpperCase();
          const commentBody = rev.text || rev.comment || '';

          return (
            <div key={rev.id} className="prody-card" style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                  <div
                    style={{
                      width: '32px',
                      height: '32px',
                      borderRadius: '50%',
                      backgroundColor: '#E0F2FE',
                      color: '#0369A1',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      fontWeight: 700,
                      fontSize: '0.78rem',
                    }}
                  >
                    {initials}
                  </div>
                  <div>
                    <div style={{ fontWeight: 700, fontSize: '0.9rem', color: '#111827' }}>{reviewerName}</div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                      {[...Array(5)].map((_, i) => (
                        <Star key={i} size={12} fill={i < rev.rating ? '#F59E0B' : '#E5E7EB'} color={i < rev.rating ? '#F59E0B' : '#E5E7EB'} />
                      ))}
                      <span style={{ fontSize: '0.72rem', color: '#9CA3AF' }}>• {rev.review_date}</span>
                    </div>
                  </div>
                </div>

                <span className={`prody-pill ${rev.is_replied ? 'green' : 'peach'}`}>
                  {rev.is_replied ? 'Replied' : 'Pending'}
                </span>
              </div>

              {commentBody && (
                <p style={{ fontSize: '0.86rem', color: '#4B5563', lineHeight: 1.5 }}>
                  "{commentBody}"
                </p>
              )}

              {rev.is_replied && rev.reply_text ? (
                <div style={{ padding: '10px 14px', backgroundColor: '#F9FAFB', borderRadius: 'var(--radius-sm)', borderLeft: '3px solid #111827', fontSize: '0.82rem' }}>
                  <span style={{ fontWeight: 700, color: '#111827' }}>Response from Owner: </span>
                  <span style={{ color: '#4B5563' }}>{rev.reply_text}</span>
                </div>
              ) : (
                <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
                  <button onClick={() => handleOpenAiReply(rev)} className="btn btn-coral btn-sm">
                    <MessageSquare size={13} />
                    <span>Draft Response</span>
                  </button>
                </div>
              )}
            </div>
          );
        })}
      </div>

      {/* Response Modal */}
      {activeReview && (
        <div className="modal-overlay" onClick={() => setActiveReview(null)}>
          <div className="modal-container" onClick={(e) => e.stopPropagation()}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
              <h3 style={{ fontSize: '1.15rem', fontWeight: 800, color: '#111827' }}>
                Draft Review Response
              </h3>
              <button onClick={() => setActiveReview(null)} style={{ background: 'transparent', border: 'none', color: '#9CA3AF', cursor: 'pointer' }}>
                <X size={18} />
              </button>
            </div>

            <div style={{ padding: '12px', backgroundColor: '#F9FAFB', borderRadius: 'var(--radius-sm)', marginBottom: '14px', fontSize: '0.84rem' }}>
              <strong>{activeReview.reviewer_name || activeReview.author_name} ({activeReview.rating}★)</strong>
              <p style={{ color: '#4B5563', marginTop: '2px' }}>"{activeReview.text || activeReview.comment}"</p>
            </div>

            <div className="input-group" style={{ marginBottom: '14px' }}>
              <label className="input-label">Response Text</label>
              <textarea
                className="optigo-input"
                rows={4}
                value={generatedReply}
                onChange={(e) => setGeneratedReply(e.target.value)}
              />
            </div>

            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '8px' }}>
              <button onClick={() => setActiveReview(null)} className="btn btn-secondary btn-sm">Cancel</button>
              <button onClick={handlePostReply} disabled={isPosting || !generatedReply} className="btn btn-coral btn-sm">
                <Send size={13} />
                <span>{isPosting ? 'Publishing...' : 'Publish Response'}</span>
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
