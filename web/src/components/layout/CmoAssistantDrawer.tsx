// ==================================================
// OptigoAI Enterprise — Clean Light Marketing Advisor Drawer
// ==================================================

import React, { useState } from 'react';
import { useLocation } from '../../context/LocationContext';
import { useFranchise } from '../../context/FranchiseContext';
import { cmoService, ChatMessage } from '../../services/cmoService';
import {
  MessageSquare,
  Send,
  X,
  Building2,
  TrendingUp,
  ArrowRight,
  ShieldCheck,
  RefreshCw,
} from 'lucide-react';

interface CmoAssistantDrawerProps {
  isOpen: boolean;
  onClose: () => void;
}

export const CmoAssistantDrawer: React.FC<CmoAssistantDrawerProps> = ({ isOpen, onClose }) => {
  const { scope, activeLocation } = useLocation();
  const { overview } = useFranchise();

  const [messages, setMessages] = useState<ChatMessage[]>([
    {
      id: 'init-1',
      sender: 'cmo',
      text:
        scope === 'franchise'
          ? `Welcome to your Franchise Marketing Advisor. I have synchronized data across your locations with an aggregate health score of ${overview.aggregate_health_score}/100. How can I assist your team today?`
          : `Hello! I am your Marketing Advisor for ${activeLocation?.name || 'this location'}. How can I help boost your Google Maps rankings and customer inquiries today?`,
      timestamp: 'Just now',
      recommended_actions:
        scope === 'franchise'
          ? [
              'Which locations have the largest ranking growth opportunity?',
              'Generate an executive summary of customer inquiry momentum',
              'Draft an action plan to address locations needing fixes',
            ]
          : [
              'How can we increase our Google Maps local rank?',
              'Analyze our customer review sentiment',
              'Recommend marketing campaigns for this month',
            ],
    },
  ]);

  const [input, setInput] = useState('');
  const [isTyping, setIsTyping] = useState(false);

  if (!isOpen) return null;

  const handleSend = async (textToSend?: string) => {
    const text = textToSend || input;
    if (!text.trim()) return;

    const userMsg: ChatMessage = {
      id: `user-${Date.now()}`,
      sender: 'user',
      text,
      timestamp: 'Just now',
    };

    setMessages((prev) => [...prev, userMsg]);
    setInput('');
    setIsTyping(true);

    try {
      const bizId = activeLocation?.id || '';
      const reply = await cmoService.sendMessage(bizId, text, scope === 'franchise' ? 'FranchiseOverview' : 'BranchDashboard');
      setMessages((prev) => [...prev, reply]);
    } catch {
      // Fallback
    } finally {
      setIsTyping(false);
    }
  };

  return (
    <div className="drawer-overlay" onClick={onClose}>
      <div className="drawer-panel" onClick={(e) => e.stopPropagation()}>
        {/* Header */}
        <div
          style={{
            padding: '20px 24px',
            borderBottom: '1px solid var(--border-subtle)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            backgroundColor: '#FFFFFF',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <div
              style={{
                width: '36px',
                height: '36px',
                borderRadius: '8px',
                backgroundColor: 'var(--primary-50)',
                color: 'var(--primary-700)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <MessageSquare size={18} />
            </div>
            <div>
              <h3 style={{ fontSize: '1rem', fontWeight: 700, color: 'var(--text-primary)' }}>
                Strategic Marketing Advisor
              </h3>
              <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                {scope === 'franchise' ? 'Network-wide Strategic Counsel' : activeLocation?.name}
              </p>
            </div>
          </div>

          <button
            onClick={onClose}
            style={{ background: 'transparent', border: 'none', color: '#94A3B8', cursor: 'pointer', padding: '4px' }}
          >
            <X size={20} />
          </button>
        </div>

        {/* Messages Stream */}
        <div style={{ flex: 1, overflowY: 'auto', padding: '20px', display: 'flex', flexDirection: 'column', gap: '16px', backgroundColor: 'var(--bg-app)' }}>
          {messages.map((msg) => (
            <div
              key={msg.id}
              style={{
                display: 'flex',
                flexDirection: 'column',
                alignItems: msg.sender === 'user' ? 'flex-end' : 'flex-start',
              }}
            >
              <div
                style={{
                  maxWidth: '85%',
                  padding: '12px 16px',
                  borderRadius: msg.sender === 'user' ? '14px 14px 2px 14px' : '14px 14px 14px 2px',
                  backgroundColor: msg.sender === 'user' ? 'var(--primary-600)' : '#FFFFFF',
                  color: msg.sender === 'user' ? '#FFFFFF' : 'var(--text-primary)',
                  fontSize: '0.875rem',
                  lineHeight: 1.5,
                  border: msg.sender === 'user' ? 'none' : '1px solid var(--border-subtle)',
                  boxShadow: 'var(--shadow-sm)',
                }}
              >
                {msg.text}
              </div>

              {msg.recommended_actions && msg.recommended_actions.length > 0 && (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '6px', marginTop: '10px', width: '100%' }}>
                  <span style={{ fontSize: '0.72rem', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '0.04em' }}>
                    Suggested Strategy Inquiries:
                  </span>
                  {msg.recommended_actions.map((act, i) => (
                    <button
                      key={i}
                      onClick={() => handleSend(act)}
                      style={{
                        textAlign: 'left',
                        padding: '8px 12px',
                        backgroundColor: '#FFFFFF',
                        border: '1px solid var(--border-subtle)',
                        borderRadius: 'var(--radius-md)',
                        color: 'var(--primary-700)',
                        fontSize: '0.8rem',
                        cursor: 'pointer',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'space-between',
                        boxShadow: 'var(--shadow-sm)',
                        transition: 'all 0.15s ease',
                      }}
                      onMouseEnter={(e) => {
                        (e.currentTarget as HTMLElement).style.borderColor = 'var(--primary-300)';
                        (e.currentTarget as HTMLElement).style.backgroundColor = 'var(--primary-50)';
                      }}
                      onMouseLeave={(e) => {
                        (e.currentTarget as HTMLElement).style.borderColor = 'var(--border-subtle)';
                        (e.currentTarget as HTMLElement).style.backgroundColor = '#FFFFFF';
                      }}
                    >
                      <span>{act}</span>
                      <ArrowRight size={13} color="var(--primary-600)" />
                    </button>
                  ))}
                </div>
              )}
            </div>
          ))}

          {isTyping && (
            <div style={{ display: 'flex', gap: '8px', alignItems: 'center', color: 'var(--text-muted)', fontSize: '0.8rem' }}>
              <RefreshCw size={14} className="spin-anim" color="var(--primary-600)" />
              <span>Analyzing marketing strategies...</span>
            </div>
          )}
        </div>

        {/* Input Bar */}
        <div style={{ padding: '16px 20px', borderTop: '1px solid var(--border-subtle)', backgroundColor: '#FFFFFF' }}>
          <form
            onSubmit={(e) => {
              e.preventDefault();
              handleSend();
            }}
            style={{ display: 'flex', gap: '10px' }}
          >
            <input
              type="text"
              className="optigo-input"
              placeholder="Ask a question about marketing, rankings, or performance..."
              value={input}
              onChange={(e) => setInput(e.target.value)}
            />
            <button type="submit" className="btn btn-primary" style={{ padding: '0 16px' }}>
              <Send size={15} />
            </button>
          </form>
        </div>
      </div>
    </div>
  );
};
