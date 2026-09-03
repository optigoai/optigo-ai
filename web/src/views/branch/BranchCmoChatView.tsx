// ==================================================
// OptigoAI Enterprise — Prody Light Advisor Chat
// ==================================================

import React, { useState } from 'react';
import { useLocation } from '../../context/LocationContext';
import { cmoService, ChatMessage } from '../../services/cmoService';
import {
  MessageSquare,
  Send,
  ArrowRight,
  RefreshCw,
  Sparkles,
  Clock3,
} from 'lucide-react';

export const BranchCmoChatView: React.FC = () => {
  const { activeLocation } = useLocation();

  const [messages, setMessages] = useState<ChatMessage[]>([
    {
      id: 'initial',
      sender: 'cmo',
      text: `Hello! I am your Marketing Advisor for ${activeLocation?.name || 'this location'}. How can I assist with local rankings, review responses, or marketing strategy today?`,
      timestamp: 'Just now',
      recommended_actions: [
        'How can we increase our Google Maps local rank?',
        'Draft a review invitation message for customers',
        'Analyze our top search keywords',
      ],
    },
  ]);
  const [inputText, setInputText] = useState('');
  const [isTyping, setIsTyping] = useState(false);

  if (!activeLocation) return null;

  const handleSend = async (textToSend?: string) => {
    const text = textToSend || inputText;
    if (!text.trim()) return;

    const userMsg: ChatMessage = {
      id: `user-${Date.now()}`,
      sender: 'user',
      text,
      timestamp: 'Just now',
    };

    setMessages((prev) => [...prev, userMsg]);
    setInputText('');
    setIsTyping(true);

    try {
      const reply = await cmoService.sendMessage(activeLocation.id, text, 'BranchAdvisorChat');
      setMessages((prev) => [...prev, reply]);
    } catch {
      // Fallback
    } finally {
      setIsTyping(false);
    }
  };

  return (
    <div className="advisor-workspace" style={{ display: 'flex', flexDirection: 'column', gap: '16px', height: 'calc(100vh - 120px)' }}>
      {/* 1. Entity Header */}
      <div className="entity-header-card" style={{ padding: '14px 20px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
          <div className="entity-icon-badge" style={{ width: '40px', height: '40px' }}>
            <MessageSquare size={20} />
          </div>
          <div>
            <h1 style={{ fontSize: '1.25rem', fontWeight: 800, color: '#111827', lineHeight: 1.2 }}>
              Marketing Advisor
            </h1>
            <span style={{ fontSize: '0.78rem', color: '#6B7280' }}>
              Strategic consultation for <strong>{activeLocation.name}</strong>
            </span>
          </div>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '14px', color: '#1255E6', fontSize: '0.76rem', fontWeight: 800 }}>
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: '5px' }}><span style={{ width: '7px', height: '7px', borderRadius: '50%', backgroundColor: '#10B981' }} />Live context</span>
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: '5px', color: '#64748B' }}><Clock3 size={13} />Replies in seconds</span>
        </div>
      </div>

      {/* 2. Chat Box */}
      <div
        className="prody-card"
        style={{
          flex: 1,
          display: 'flex',
          flexDirection: 'column',
          padding: 0,
          overflow: 'hidden',
        }}
      >
        <div style={{ flex: 1, overflowY: 'auto', padding: '24px clamp(16px, 4vw, 42px)', display: 'flex', flexDirection: 'column', gap: '18px', background: 'linear-gradient(180deg, #F0F4F9 0%, #F8FAFC 42%, #FFFFFF 100%)' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: '#1255E6', fontSize: '0.75rem', fontWeight: 800, letterSpacing: '0.04em', textTransform: 'uppercase' }}>
            <Sparkles size={14} /> Local growth desk
          </div>
          {messages.map((msg) => (
            <div key={msg.id} style={{ display: 'flex', flexDirection: 'column', alignItems: msg.sender === 'user' ? 'flex-end' : 'flex-start' }}>
              <div
                style={{
                  maxWidth: 'min(78%, 720px)',
                  padding: '12px 18px',
                  borderRadius: msg.sender === 'user' ? '16px 16px 4px 16px' : '16px 16px 16px 4px',
                  backgroundColor: msg.sender === 'user' ? '#1255E6' : '#ffffff',
                  backgroundImage: msg.sender === 'user' ? 'linear-gradient(135deg, #1255E6 0%, #1A64F5 100%)' : 'none',
                  color: msg.sender === 'user' ? '#ffffff' : '#0f172a',
                  border: msg.sender === 'user' ? 'none' : '1px solid #E2E8F0',
                  fontSize: '0.9rem',
                  lineHeight: 1.5,
                  boxShadow: msg.sender === 'user' ? '0 5px 14px rgba(18, 85, 230, 0.2)' : '0 3px 10px rgba(15, 23, 42, 0.04)',
                }}
              >
                {msg.text}
              </div>

              {msg.recommended_actions && (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '6px', marginTop: '10px', maxWidth: '75%' }}>
                  {msg.recommended_actions.map((act, i) => (
                    <button
                      key={i}
                      onClick={() => handleSend(act)}
                      style={{
                        textAlign: 'left',
                        padding: '8px 14px',
                        backgroundColor: '#ffffff',
                        border: '1px solid #CBD5E1',
                        borderRadius: '8px',
                        color: '#1255E6',
                        fontSize: '0.82rem',
                        fontWeight: 700,
                        cursor: 'pointer',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'space-between',
                        boxShadow: '0 2px 5px rgba(18, 85, 230, 0.05)',
                        transition: 'all 0.15s ease',
                      }}
                    >
                      <span>{act}</span>
                      <ArrowRight size={14} />
                    </button>
                  ))}
                </div>
              )}
            </div>
          ))}

          {isTyping && (
            <div style={{ display: 'flex', gap: '8px', alignItems: 'center', color: '#1255E6', fontSize: '0.84rem', fontWeight: 700 }}>
              <RefreshCw size={15} className="spin-anim" color="#1255E6" />
              <span>Analyzing recommendations with Gemini AI...</span>
            </div>
          )}
        </div>

        <div style={{ padding: '16px clamp(16px, 4vw, 42px) 20px', borderTop: '1px solid #E2E8F0', backgroundColor: '#ffffff' }}>
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
              placeholder={`Ask a question about ${activeLocation.name}...`}
              value={inputText}
              onChange={(e) => setInputText(e.target.value)}
              style={{ fontSize: '0.9rem', padding: '12px 18px', borderRadius: '10px', backgroundColor: '#F0F4F9' }}
            />
            <button type="submit" className="btn btn-primary" style={{ padding: '0 20px', borderRadius: '9px' }} aria-label="Send message">
              <Send size={16} />
            </button>
          </form>
        </div>
      </div>
    </div>
  );
};
