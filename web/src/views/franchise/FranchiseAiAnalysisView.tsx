// ==================================================
// OptigoAI Enterprise — AI Analysis & Strategic CMO Hub
// Synthesizes network-wide data into 4 clear sections:
// 1. Executive Summary, 2. Key Wins, 3. Key Risks, 4. Prioritized Action Plan,
// followed by conversational AI CMO chat
// ==================================================

import React, { useState, useEffect } from 'react';
import { useFranchise } from '../../context/FranchiseContext';
import { useLocation } from '../../context/LocationContext';
import { useAuth } from '../../context/AuthContext';
import { AIInsightCard } from '../../components/common/AIInsightCard';
import { cmoService, ChatMessage } from '../../services/cmoService';
import {
  Sparkles,
  RefreshCw,
  Clock,
  Send,
  Bot,
  Zap,
  CheckCircle2,
  AlertTriangle,
  Award,
} from 'lucide-react';

interface AIAnalysisData {
  timestamp: string;
  executiveSummary: string;
  keyWins: Array<{
    title: string;
    description: string;
    branchBadge?: string;
    impact?: 'Urgent' | 'High Impact' | 'Medium Impact' | 'Low Impact' | 'Growth';
  }>;
  keyRisks: Array<{
    title: string;
    description: string;
    branchBadge?: string;
    impact?: 'Urgent' | 'High Impact' | 'Medium Impact' | 'Low Impact' | 'Growth';
    actionLabel?: string;
    targetTab?: string;
    targetBranchId?: string;
  }>;
  prioritizedActions: Array<{
    title: string;
    description: string;
    branchBadge?: string;
    impact?: 'Urgent' | 'High Impact' | 'Medium Impact' | 'Low Impact' | 'Growth';
    actionLabel?: string;
    targetTab?: string;
    targetBranchId?: string;
  }>;
}

export const FranchiseAiAnalysisView: React.FC = () => {
  const { overview, locations, selectedDateRange } = useFranchise();
  const { selectLocation, setActiveBranchTab, activeLocation, scope } = useLocation();
  const { organization, user } = useAuth();

  const [analysis, setAnalysis] = useState<AIAnalysisData | null>(null);
  const [isGenerating, setIsGenerating] = useState<boolean>(false);

  // Chat State
  const [messages, setMessages] = useState<ChatMessage[]>([
    {
      id: 'welcome',
      sender: 'cmo',
      text: `Hello ${user?.full_name?.split(' ')[0] || 'there'}! I'm your AI Chief Marketing Officer. I've synthesized your multi-location Google performance. Ask me any follow-up questions or request specific marketing tactics.`,
      timestamp: 'Just now',
      recommended_actions: [
        'How can I get Casarasa Ponnani to 80+ Health Score?',
        'Draft response templates for recent reviews',
        'What marketing campaign should we launch this weekend?',
      ],
    },
  ]);
  const [chatInput, setChatInput] = useState<string>('');
  const [isChatSending, setIsChatSending] = useState<boolean>(false);

  const cacheKey = `optigoai_ai_analysis_v2_${scope}_${activeLocation?.id || 'all'}_${selectedDateRange}_${locations.length}_${overview.aggregate_health_score}_${overview.unreplied_reviews_count}`;

  // Load or generate analysis
  useEffect(() => {
    const cached = localStorage.getItem(cacheKey);
    if (cached) {
      try {
        setAnalysis(JSON.parse(cached));
        return;
      } catch {
        // Fallback
      }
    }
    generateFreshAnalysis();
  }, [cacheKey]);

  const generateFreshAnalysis = () => {
    setIsGenerating(true);

    const totalImpressions = (overview.total_searches || 0) + (overview.total_maps_views || 0);
    const totalActions = overview.total_customer_actions || 0;
    const aggHealth = overview.aggregate_health_score || 0;
    const avgRating = overview.franchise_avg_rating || 0;
    const unrepliedCount = overview.unreplied_reviews_count || 0;
    const topBranch = [...locations].sort((a, b) => (b.health_score || 0) - (a.health_score || 0))[0] || locations[0];
    const lagBranch = [...locations].sort((a, b) => (a.health_score || 0) - (b.health_score || 0))[0] || locations[0];
    const unrepliedBranch = locations.find((l) => (l.unreplied_reviews ?? 0) > 0) || locations[0];

    const generatedTimestamp = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', month: 'short', day: 'numeric' });

    setTimeout(() => {
      const freshData: AIAnalysisData = {
        timestamp: generatedTimestamp,
        executiveSummary: `${organization?.name || 'Franchise Network'} maintains an aggregate health baseline of ${aggHealth}/100 across ${locations.length} branches, generating ${totalImpressions.toLocaleString()} discovery search views and ${totalActions.toLocaleString()} direct customer inquiries. ${topBranch?.name || 'Top branch'} holds the network benchmark lead at ${topBranch?.health_score || 0}/100, while addressing ${unrepliedCount} pending reviews will unlock immediate ranking acceleration.`,
        keyWins: [
          {
            title: `Discovery Views & Google Maps Inquiries Rising`,
            description: `High local intent for your category generated ${totalImpressions.toLocaleString()} views and ${totalActions.toLocaleString()} direct calls and direction requests across branch territories.`,
            branchBadge: 'Network Trend',
            impact: 'High Impact',
          },
          {
            title: `Positive Customer Sentiment at ${overview.positive_sentiment_pct || 0}%`,
            description: `Customer review feedback consistently praises service and offerings with an average rating of ${avgRating} ★.`,
            branchBadge: 'Reputation',
            impact: 'High Impact',
          },
          {
            title: `${topBranch?.name || 'Top location'} Leading Network Benchmark`,
            description: `Top-performing branch with ${topBranch?.health_score || 0}/100 health score and Google Maps local Rank #${topBranch?.google_maps_rank || 1}.`,
            branchBadge: topBranch?.location || 'Primary',
            impact: 'High Impact',
          },
        ],
        keyRisks: [
          {
            title: `${unrepliedCount > 0 ? `${unrepliedCount} Unreplied Reviews in ${unrepliedBranch?.name || 'network'}` : 'Review Response Routine Check'}`,
            description: `Delayed responses to verified customer feedback create a drag on Google Maps rank velocity. Replying within 24h restores optimal engagement.`,
            branchBadge: unrepliedBranch?.name || 'Network',
            impact: 'Urgent',
            actionLabel: 'Reply to Reviews',
            targetTab: 'reviews',
            targetBranchId: unrepliedBranch?.id || locations[0]?.id,
          },
          {
            title: `${lagBranch?.name || 'Location'} Health Score at ${lagBranch?.health_score || 0}/100`,
            description: `Profile completeness is at ${lagBranch?.completeness_score || 0}%. Adding detailed services, photos, and attributes will raise health score.`,
            branchBadge: lagBranch?.location || 'Branch',
            impact: 'Medium Impact',
            actionLabel: 'Audit Profile',
            targetTab: 'profile',
            targetBranchId: lagBranch?.id,
          },
        ],
        prioritizedActions: [
          {
            title: `Respond to ${unrepliedCount} Pending Reviews in ${unrepliedBranch?.name || 'network'}`,
            description: `Use AI Review Studio to generate personalized, empathetic replies in seconds and boost Google local sentiment.`,
            branchBadge: unrepliedBranch?.name || 'Network',
            impact: 'Urgent',
            actionLabel: 'Open Review Studio',
            targetTab: 'reviews',
            targetBranchId: unrepliedBranch?.id || locations[0]?.id,
          },
          {
            title: `Complete Missing Profile Attributes for ${lagBranch?.name || 'Location'}`,
            description: `Ensure working hours, phone numbers, and categories are 100% synchronized with Google Business API.`,
            branchBadge: 'casaraza Edappal',
            impact: 'Medium Impact',
            actionLabel: 'Edit Profile',
            targetTab: 'profile',
            targetBranchId: lagBranch?.id,
          },
          {
            title: `Launch Weekend Promotional Campaign in Marketing Studio`,
            description: `Publish AI-designed promotional banners and social copy to Google Posts and Instagram to capture weekend family diners.`,
            branchBadge: 'Marketing Studio',
            impact: 'Growth',
            actionLabel: 'Create Campaign',
            targetTab: 'content',
            targetBranchId: locations[0]?.id,
          },
        ],
      };

      setAnalysis(freshData);
      localStorage.setItem(cacheKey, JSON.stringify(freshData));
      setIsGenerating(false);
    }, 600);
  };

  const handleActionClick = (targetTab?: string, branchId?: string) => {
    if (!targetTab) return;
    if (branchId) {
      selectLocation(branchId);
    } else if (locations[0]) {
      selectLocation(locations[0].id);
    }
    setActiveBranchTab(targetTab);
  };

  const handleSendChat = async (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    if (!chatInput.trim() || isChatSending) return;

    const userText = chatInput.trim();
    setChatInput('');

    const userMsg: ChatMessage = {
      id: `user-${Date.now()}`,
      sender: 'user',
      text: userText,
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
    };

    setMessages((prev) => [...prev, userMsg]);
    setIsChatSending(true);

    try {
      const activeBizId = locations[0]?.id || '4d69a79b-b985-4072-9c99-3848e95fd85a';
      const cmoReply = await cmoService.sendMessage(activeBizId, userText, 'AIAnalysisScreen');
      setMessages((prev) => [...prev, cmoReply]);
    } catch {
      setTimeout(() => {
        const fallbackReply: ChatMessage = {
          id: `cmo-${Date.now()}`,
          sender: 'cmo',
          text: `Based on your live metrics: Focus on replying to pending reviews and completing missing profile attributes across your locations. This will boost your aggregate Health Score from ${overview.aggregate_health_score || 0} towards 85+ and increase Google Maps rank velocity.`,
          timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
          recommended_actions: ['Open Reviews Studio', 'Open Marketing Studio'],
        };
        setMessages((prev) => [...prev, fallbackReply]);
      }, 400);
    } finally {
      setIsChatSending(false);
    }
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '20px', maxWidth: '1280px', margin: '0 auto', width: '100%' }}>
      {/* 1. Header Card with Cache Timestamp & Regenerate Button */}
      <div className="entity-header-card" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '14px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
          <div className="entity-icon-badge" style={{ backgroundColor: '#eff6ff', color: '#2563eb' }}>
            <Sparkles size={24} />
          </div>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px', flexWrap: 'wrap' }}>
              <h1 style={{ fontSize: '1.35rem', fontWeight: 800, color: '#0f172a', lineHeight: 1.2, margin: 0 }}>
                AI Strategic Analysis & CMO Advisory
              </h1>
              <span className="prody-pill blue" style={{ gap: '4px', fontSize: '0.72rem' }}>
                <Zap size={11} /> Gemini Synthesizer
              </span>
            </div>
            <p style={{ fontSize: '0.8rem', color: '#64748b', margin: '4px 0 0 0' }}>
              Executive narrative, auto-identified wins & risks, and prioritized action directives for {organization?.name || 'Casarasa'}.
            </p>
          </div>
        </div>

        {/* Regenerate Action & Timestamp */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px', flexWrap: 'wrap' }}>
          {analysis && (
            <div style={{ display: 'flex', alignItems: 'center', gap: '4px', fontSize: '0.76rem', color: '#64748b' }}>
              <Clock size={12} color="#94a3b8" />
              <span>Generated {analysis.timestamp}</span>
            </div>
          )}

          <button
            onClick={generateFreshAnalysis}
            disabled={isGenerating}
            className="btn btn-secondary"
            style={{ gap: '8px', fontSize: '0.88rem', fontWeight: 800, padding: '10px 18px', borderRadius: '10px' }}
          >
            <RefreshCw size={16} className={isGenerating ? 'spin-anim' : ''} color="#2563eb" />
            <span>{isGenerating ? 'Analyzing...' : 'Regenerate Analysis'}</span>
          </button>
        </div>
      </div>

      {/* 3. Section 1: Executive Summary */}
      {analysis && (
        <div
          className="prody-card"
          style={{
            padding: '20px 22px',
            backgroundColor: '#ffffff',
            border: '1px solid #e2e8f0',
            boxShadow: '0 1px 3px rgba(0,0,0,0.02)',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '8px' }}>
            <Award size={18} color="#2563eb" />
            <h3 style={{ fontSize: '1rem', fontWeight: 800, color: '#0f172a', margin: 0 }}>
              1. Executive Summary
            </h3>
          </div>
          <p style={{ fontSize: '0.88rem', color: '#334155', lineHeight: 1.55, margin: 0, fontWeight: 500 }}>
            {analysis.executiveSummary}
          </p>
        </div>
      )}

      {/* 4. Section 2 & 3: Key Wins and Key Risks */}
      {analysis && (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(360px, 1fr))', gap: '18px' }}>
          {/* Section 2: Key Wins */}
          <div className="prody-card" style={{ padding: '20px', display: 'flex', flexDirection: 'column', gap: '12px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <CheckCircle2 size={17} color="#16a34a" />
              <h3 style={{ fontSize: '0.96rem', fontWeight: 800, color: '#0f172a', margin: 0 }}>
                2. Key Performance Wins
              </h3>
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
              {analysis.keyWins.map((win, idx) => (
                <AIInsightCard
                  key={idx}
                  type="win"
                  title={win.title}
                  description={win.description}
                  branchBadge={win.branchBadge}
                  impact={win.impact}
                />
              ))}
            </div>
          </div>

          {/* Section 3: Key Risks */}
          <div className="prody-card" style={{ padding: '20px', display: 'flex', flexDirection: 'column', gap: '12px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <AlertTriangle size={17} color="#dc2626" />
              <h3 style={{ fontSize: '0.96rem', fontWeight: 800, color: '#0f172a', margin: 0 }}>
                3. Key Risks & Watch-outs
              </h3>
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
              {analysis.keyRisks.map((risk, idx) => (
                <AIInsightCard
                  key={idx}
                  type="risk"
                  title={risk.title}
                  description={risk.description}
                  branchBadge={risk.branchBadge}
                  impact={risk.impact}
                  actionButton={
                    risk.actionLabel
                      ? {
                          label: risk.actionLabel,
                          onClick: () => handleActionClick(risk.targetTab, risk.targetBranchId),
                        }
                      : undefined
                  }
                />
              ))}
            </div>
          </div>
        </div>
      )}

      {/* 5. Section 4: Prioritized Growth Action Plan (Non-competing numbering) */}
      {analysis && (
        <div className="prody-card" style={{ padding: '22px' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '14px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <Zap size={18} color="#2563eb" />
              <h3 style={{ fontSize: '1rem', fontWeight: 800, color: '#0f172a', margin: 0 }}>
                4. Prioritized Growth Action Plan
              </h3>
            </div>
            <span className="prody-pill blue" style={{ fontSize: '0.7rem' }}>
              Ranked by ROI
            </span>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
            {analysis.prioritizedActions.map((act, idx) => (
              <AIInsightCard
                key={idx}
                type="action"
                title={act.title}
                description={act.description}
                branchBadge={act.branchBadge}
                impact={act.impact}
                actionButton={
                  act.actionLabel
                    ? {
                        label: act.actionLabel,
                        onClick: () => handleActionClick(act.targetTab, act.targetBranchId),
                      }
                    : undefined
                }
              />
            ))}
          </div>
        </div>
      )}

      {/* 6. Section Divider */}
      <hr style={{ border: 'none', borderTop: '1px solid #e2e8f0', margin: '4px 0' }} />

      {/* 7. Section 5: Conversational AI CMO Chat Box */}
      <div className="prody-card" style={{ padding: '22px', display: 'flex', flexDirection: 'column', gap: '14px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          <div
            style={{
              width: '32px',
              height: '32px',
              borderRadius: '8px',
              backgroundColor: '#eff6ff',
              color: '#2563eb',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            <Bot size={18} />
          </div>
          <div>
            <h3 style={{ fontSize: '0.98rem', fontWeight: 800, color: '#0f172a', margin: 0 }}>
              Ask Your AI CMO a Follow-Up Question
            </h3>
            <p style={{ fontSize: '0.78rem', color: '#64748b', margin: '2px 0 0 0' }}>
              Dig deeper into your performance, request tailored promotional tactics, or generate review response drafts.
            </p>
          </div>
        </div>

        {/* Chat History Thread */}
        <div
          style={{
            maxHeight: '260px',
            overflowY: 'auto',
            display: 'flex',
            flexDirection: 'column',
            gap: '12px',
            padding: '12px',
            backgroundColor: '#f8fafc',
            borderRadius: '10px',
            border: '1px solid #e2e8f0',
          }}
        >
          {messages.map((msg) => {
            const isUser = msg.sender === 'user';
            return (
              <div
                key={msg.id}
                style={{
                  display: 'flex',
                  flexDirection: 'column',
                  alignItems: isUser ? 'flex-end' : 'flex-start',
                  gap: '4px',
                }}
              >
                <div
                  style={{
                    maxWidth: '80%',
                    padding: '10px 14px',
                    borderRadius: isUser ? '14px 14px 2px 14px' : '14px 14px 14px 2px',
                    backgroundColor: isUser ? '#2563eb' : '#ffffff',
                    color: isUser ? '#ffffff' : '#0f172a',
                    border: isUser ? 'none' : '1px solid #e2e8f0',
                    fontSize: '0.84rem',
                    lineHeight: 1.45,
                    boxShadow: '0 1px 2px rgba(0,0,0,0.02)',
                  }}
                >
                  {msg.text}
                </div>

                {msg.recommended_actions && msg.recommended_actions.length > 0 && (
                  <div style={{ display: 'flex', gap: '6px', flexWrap: 'wrap', marginTop: '4px' }}>
                    {msg.recommended_actions.map((act, aIdx) => (
                      <button
                        key={aIdx}
                        onClick={() => setChatInput(act)}
                        style={{
                          padding: '3px 8px',
                          borderRadius: '6px',
                          backgroundColor: '#eff6ff',
                          border: '1px solid #bfdbfe',
                          color: '#2563eb',
                          fontSize: '0.72rem',
                          fontWeight: 700,
                          cursor: 'pointer',
                        }}
                      >
                        {act}
                      </button>
                    ))}
                  </div>
                )}
              </div>
            );
          })}
        </div>

        {/* Chat Input Bar */}
        <form onSubmit={handleSendChat} style={{ display: 'flex', gap: '12px' }}>
          <input
            type="text"
            placeholder="Ask your AI CMO a strategic marketing or ranking question..."
            value={chatInput}
            onChange={(e) => setChatInput(e.target.value)}
            disabled={isChatSending}
            style={{
              flex: 1,
              padding: '12px 18px',
              borderRadius: '10px',
              border: '1.5px solid #cbd5e1',
              fontSize: '0.9rem',
              outline: 'none',
              backgroundColor: '#ffffff',
            }}
          />
          <button
            type="submit"
            disabled={isChatSending || !chatInput.trim()}
            className="btn btn-primary"
            style={{ gap: '8px', fontSize: '0.9rem', fontWeight: 800, padding: '12px 24px', borderRadius: '10px' }}
          >
            <span>{isChatSending ? 'Thinking...' : 'Send'}</span>
            <Send size={15} />
          </button>
        </form>
      </div>
    </div>
  );
};
