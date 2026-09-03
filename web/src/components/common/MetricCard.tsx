// ==================================================
// OptigoAI Enterprise — Premium MetricCard Component
// High-clarity, colorful accents, spacious padding, and elegant SaaS design
// ==================================================

import React from 'react';
import { Tooltip } from './Tooltip';
import { TrendingUp, TrendingDown } from 'lucide-react';

interface MetricCardProps {
  title: string;
  value: string | number;
  subtitle?: string;
  tooltip?: string;
  trend?: {
    value: number | string;
    isPositive?: boolean;
    label?: string;
  };
  sparklineData?: number[];
  isUrgent?: boolean;
  badge?: {
    text: string;
    status?: 'green' | 'amber' | 'red' | 'blue' | 'neutral';
  };
  icon?: React.ReactNode;
  onClick?: () => void;
  style?: React.CSSProperties;
}

export const MetricCard: React.FC<MetricCardProps> = ({
  title,
  value,
  subtitle,
  tooltip,
  trend,
  sparklineData,
  isUrgent = false,
  badge,
  icon,
  onClick,
  style,
}) => {
  // Smooth cubic spline calculation for sparkline
  const svgWidth = 84;
  const svgHeight = 28;

  let splinePath = '';
  let splineArea = '';
  let lastPoint: { x: number; y: number } | null = null;

  if (sparklineData && sparklineData.length >= 2) {
    const minVal = Math.min(...sparklineData);
    const maxVal = Math.max(...sparklineData);
    const range = maxVal - minVal || 1;

    const coords = sparklineData.map((val, idx) => ({
      x: (idx / (sparklineData.length - 1)) * svgWidth,
      y: svgHeight - ((val - minVal) / range) * (svgHeight - 8) - 4,
    }));

    lastPoint = coords[coords.length - 1];

    splinePath = `M ${coords[0].x.toFixed(1)},${coords[0].y.toFixed(1)}`;
    for (let i = 0; i < coords.length - 1; i++) {
      const p0 = i > 0 ? coords[i - 1] : coords[i];
      const p1 = coords[i];
      const p2 = coords[i + 1];
      const p3 = i < coords.length - 2 ? coords[i + 2] : p2;

      const cp1x = p1.x + (p2.x - p0.x) / 6;
      const cp1y = p1.y + (p2.y - p0.y) / 6;
      const cp2x = p2.x - (p3.x - p1.x) / 6;
      const cp2y = p2.y - (p3.y - p1.y) / 6;

      splinePath += ` C ${cp1x.toFixed(1)},${cp1y.toFixed(1)} ${cp2x.toFixed(1)},${cp2y.toFixed(1)} ${p2.x.toFixed(1)},${p2.y.toFixed(1)}`;
    }

    splineArea = `${splinePath} L ${svgWidth},${svgHeight} L 0,${svgHeight} Z`;
  }

  const getBadgeStyle = (status?: string) => {
    switch (status) {
      case 'green':
        return { bg: '#ecfdf5', text: '#047857', border: '#a7f3d0' };
      case 'amber':
        return { bg: '#fffbeb', text: '#b45309', border: '#fde68a' };
      case 'red':
        return { bg: '#fff1f2', text: '#be123c', border: '#fecdd3' };
      case 'blue':
        return { bg: '#eff6ff', text: '#1d4ed8', border: '#bfdbfe' };
      default:
        return { bg: '#f1f5f9', text: '#475569', border: '#e2e8f0' };
    }
  };

  const badgeStyle = badge ? getBadgeStyle(badge.status) : null;

  return (
    <div
      onClick={onClick}
      className="prody-card"
      style={{
        padding: '22px 24px',
        display: 'flex',
        flexDirection: 'column',
        justifyContent: 'space-between',
        cursor: onClick ? 'pointer' : 'default',
        border: isUrgent ? '1.5px solid #fecdd3' : '1px solid #e2e8f0',
        backgroundColor: isUrgent ? '#fffbfb' : '#ffffff',
        borderRadius: '16px',
        boxShadow: '0 1px 3px rgba(15, 23, 42, 0.04), 0 4px 12px -2px rgba(15, 23, 42, 0.02)',
        position: 'relative',
        overflow: 'hidden',
        transition: 'all 0.2s cubic-bezier(0.16, 1, 0.3, 1)',
        ...style,
      }}
    >
      <div>
        {/* Header Label Row with Tooltip & Optional Status Badge */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '10px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            {icon && (
              <div
                style={{
                  width: '28px',
                  height: '28px',
                  borderRadius: '8px',
                  backgroundColor: isUrgent ? '#fee2e2' : '#f1f5f9',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  flexShrink: 0,
                }}
              >
                {icon}
              </div>
            )}
            <span
              style={{
                fontSize: '0.76rem',
                fontWeight: 800,
                color: '#475569',
                textTransform: 'uppercase',
                letterSpacing: '0.4px',
              }}
            >
              {title}
            </span>
            {tooltip && <Tooltip content={tooltip} />}
          </div>

          {badge && badgeStyle && (
            <span
              style={{
                fontSize: '0.74rem',
                fontWeight: 800,
                padding: '3px 8px',
                borderRadius: '8px',
                backgroundColor: badgeStyle.bg,
                color: badgeStyle.text,
                border: `1px solid ${badgeStyle.border}`,
              }}
            >
              {badge.text}
            </span>
          )}
        </div>

        {/* Clean Neutral Main Value */}
        <div style={{ display: 'flex', alignItems: 'baseline', gap: '8px', marginTop: '4px' }}>
          <span
            style={{
              fontSize: '2.15rem',
              fontWeight: 900,
              color: '#0f172a',
              letterSpacing: '-0.8px',
              lineHeight: 1.1,
            }}
          >
            {value}
          </span>
        </div>
      </div>

      {/* Footer Subtitle & Plain English Trend Row */}
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          marginTop: '14px',
          borderTop: '1px solid #f1f5f9',
          paddingTop: '10px',
        }}
      >
        <div style={{ fontSize: '0.78rem', color: '#64748b', fontWeight: 500 }}>
          {subtitle && <span>{subtitle}</span>}
          {trend && (
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '5px',
                color: trend.isPositive !== false ? '#15803d' : '#b91c1c',
                fontWeight: 800,
              }}
            >
              {trend.isPositive !== false ? <TrendingUp size={14} /> : <TrendingDown size={14} />}
              <span>{trend.value}</span>
              {trend.label && <span style={{ color: '#64748b', fontWeight: 500, marginLeft: '3px' }}>{trend.label}</span>}
            </div>
          )}
        </div>

        {/* Refined Smooth Spline Sparkline with Soft Area Gradient */}
        {splinePath && (
          <div style={{ width: `${svgWidth}px`, height: `${svgHeight}px`, flexShrink: 0 }}>
            {(() => {
              const sparkColor = isUrgent
                ? '#ef4444'
                : trend?.isPositive === false
                ? '#f43f5e'
                : '#10b981';
              const gradId = `spark-grad-${title.replace(/[^a-zA-Z0-9]/g, '')}`;

              return (
                <svg width={svgWidth} height={svgHeight} style={{ overflow: 'visible' }}>
                  <defs>
                    <linearGradient id={gradId} x1="0" y1="0" x2="0" y2="1">
                      <stop offset="0%" stopColor={sparkColor} stopOpacity="0.25" />
                      <stop offset="100%" stopColor={sparkColor} stopOpacity="0.0" />
                    </linearGradient>
                  </defs>
                  <path d={splineArea} fill={`url(#${gradId})`} />
                  <path
                    d={splinePath}
                    fill="none"
                    stroke={sparkColor}
                    strokeWidth="2.5"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  />
                  {lastPoint && (
                    <circle
                      cx={lastPoint.x}
                      cy={lastPoint.y}
                      r="2.5"
                      fill={sparkColor}
                      stroke="#ffffff"
                      strokeWidth="1.5"
                    />
                  )}
                </svg>
              );
            })()}
          </div>
        )}
      </div>
    </div>
  );
};
