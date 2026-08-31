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
    <div style={{ display: 'flex', flexDirection: 'column', gap: '16px', height: 'calc(100vh - 120px)' }}>
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
        <div style={{ flex: 1, overflowY: 'auto', padding: '20px', display: 'flex', flexDirection: 'column', gap: '14px', backgroundColor: '#FAFAFA' }}>
          {messages.map((msg) => (
            <div key={msg.id} style={{ display: 'flex', flexDirection: 'column', alignItems: msg.sender === 'user' ? 'flex-end' : 'flex-start' }}>
              <div
                style={{
                  maxWidth: '75%',
                  padding: '10px 14px',
                  borderRadius: 'var(--radius-md)',
                  backgroundColor: msg.sender === 'user' ? '#111827' : '#FFFFFF',
                  color: msg.sender === 'user' ? '#FFFFFF' : '#111827',
                  border: msg.sender === 'user' ? 'none' : '1px solid var(--border-subtle)',
                  fontSize: '0.86rem',
                  lineHeight: 1.4,
                  boxShadow: 'var(--shadow-xs)',
                }}
              >
                {msg.text}
              </div>

              {msg.recommended_actions && (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '4px', marginTop: '8px', maxWidth: '70%' }}>
                  {msg.recommended_actions.map((act, i) => (
                    <button
                      key={i}
                      onClick={() => handleSend(act)}
                      style={{
                        textAlign: 'left',
                        padding: '6px 10px',
                        backgroundColor: '#FFFFFF',
                        border: '1px solid var(--border-subtle)',
                        borderRadius: 'var(--radius-sm)',
                        color: '#0284C7',
                        fontSize: '0.78rem',
                        fontWeight: 600,
                        cursor: 'pointer',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'space-between',
                      }}
                    >
                      <span>{act}</span>
                      <ArrowRight size={12} />
                    </button>
                  ))}
                </div>
              )}
            </div>
          ))}

          {isTyping && (
            <div style={{ display: 'flex', gap: '6px', alignItems: 'center', color: '#6B7280', fontSize: '0.8rem' }}>
              <RefreshCw size={13} className="spin-anim" />
              <span>Analyzing recommendations...</span>
            </div>
          )}
        </div>

        <div style={{ padding: '12px 16px', borderTop: '1px solid var(--border-subtle)', backgroundColor: '#FFFFFF' }}>
          <form
            onSubmit={(e) => {
              e.preventDefault();
              handleSend();
            }}
            style={{ display: 'flex', gap: '8px' }}
          >
            <input
              type="text"
              className="optigo-input"
              placeholder={`Ask a question about ${activeLocation.name}...`}
              value={inputText}
              onChange={(e) => setInputText(e.target.value)}
            />
            <button type="submit" className="btn btn-coral btn-sm" style={{ padding: '0 16px' }}>
              <Send size={14} />
            </button>
          </form>
        </div>
      </div>
    </div>
  );
};
