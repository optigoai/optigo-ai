// ==================================================
// OptigoAI Enterprise — Reusable AIInsightCard Component
// Left-aligned tags under title, clean spacing without fake squiggles,
// and strict priority chips
// ==================================================

import React from 'react';
import {
  CheckCircle2,
  AlertTriangle,
  ArrowRight,
  Zap,
} from 'lucide-react';

export interface AIInsightCardProps {
  type: 'win' | 'risk' | 'action';
  title: string;
  description: string;
  branchBadge?: string;
  impact?: 'Urgent' | 'High Impact' | 'Medium Impact' | 'Low Impact' | 'Growth';
  actionButton?: {
    label: string;
    onClick: () => void;
  };
}

export const AIInsightCard: React.FC<AIInsightCardProps> = ({
  type,
  title,
  description,
  branchBadge,
  impact,
  actionButton,
}) => {
  const getTheme = () => {
    switch (type) {
      case 'win':
        return {
          icon: <CheckCircle2 size={16} color="#16a34a" />,
          borderColor: '#bbf7d0',
          bgColor: '#f0fdf4',
          badgeClass: 'prody-pill green',
        };
      case 'risk':
        return {
          icon: <AlertTriangle size={16} color="#dc2626" />,
          borderColor: '#fecdd3',
          bgColor: '#fff1f2',
          badgeClass: impact === 'Urgent' ? 'prody-pill coral' : 'prody-pill yellow',
        };
      case 'action':
        return {
          icon: <Zap size={16} color="#2563eb" />,
          borderColor: '#bfdbfe',
          bgColor: '#eff6ff',
          badgeClass: impact === 'Urgent' ? 'prody-pill coral' : (impact === 'High Impact' ? 'prody-pill blue' : 'prody-pill yellow'),
        };
    }
  };

  const theme = getTheme();

  return (
    <div
      style={{
        padding: '14px 16px',
        borderRadius: '10px',
        backgroundColor: theme.bgColor,
        border: `1px solid ${theme.borderColor}`,
        display: 'flex',
        flexDirection: 'column',
        justifyContent: 'space-between',
        gap: '10px',
        transition: 'all 0.15s ease',
      }}
    >
      <div>
        {/* Top Header Row with Icon & Title */}
        <div style={{ display: 'flex', alignItems: 'flex-start', gap: '8px' }}>
          <span style={{ marginTop: '2px', flexShrink: 0 }}>{theme.icon}</span>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '4px', flex: 1 }}>
            <h4 style={{ fontSize: '0.92rem', fontWeight: 800, color: '#0f172a', margin: 0 }}>
              {title}
            </h4>

            {/* Left-Aligned Category / Impact Tags directly below Title */}
            <div style={{ display: 'flex', alignItems: 'center', gap: '6px', flexWrap: 'wrap' }}>
              {branchBadge && (
                <span className="prody-pill gray" style={{ fontSize: '0.68rem', padding: '1px 6px' }}>
                  {branchBadge}
                </span>
              )}
              {impact && (
                <span className={theme.badgeClass} style={{ fontSize: '0.68rem', padding: '1px 6px' }}>
                  {impact}
                </span>
              )}
            </div>
          </div>
        </div>

        {/* Description Text */}
        <p style={{ fontSize: '0.8rem', color: '#334155', lineHeight: 1.45, margin: '8px 0 0 24px' }}>
          {description}
        </p>
      </div>

      {/* Action Button if provided */}
      {actionButton && (
        <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: '4px' }}>
          <button
            onClick={actionButton.onClick}
            style={{
              padding: '5px 12px',
              borderRadius: '8px',
              backgroundColor: '#ffffff',
              border: `1px solid ${theme.borderColor}`,
              color: '#0f172a',
              fontSize: '0.78rem',
              fontWeight: 700,
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: '4px',
              boxShadow: '0 1px 2px rgba(0,0,0,0.04)',
              transition: 'all 0.15s ease',
            }}
          >
            <span>{actionButton.label}</span>
            <ArrowRight size={12} color="#2563eb" />
          </button>
        </div>
      )}
    </div>
  );
};
