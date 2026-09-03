// ==================================================
// OptigoAI Enterprise — Reusable DonutChart Component
// Visual percentage distribution for review sentiment, ratings, and shares
// ==================================================

import React, { useState } from 'react';

export interface DonutSegment {
  label: string;
  count: number;
  percentage: number;
  color: string;
}

interface DonutChartProps {
  title: string;
  subtitle?: string;
  segments: DonutSegment[];
  centerValue?: string;
  centerLabel?: string;
}

export const DonutChart: React.FC<DonutChartProps> = ({
  title,
  subtitle,
  segments,
  centerValue = '62%',
  centerLabel = 'Positive',
}) => {
  const [hoveredIndex, setHoveredIndex] = useState<number | null>(null);

  const radius = 60;
  const strokeWidth = 18;
  const circumference = 2 * Math.PI * radius;

  let cumulativeOffset = 0;

  return (
    <div className="prody-card" style={{ padding: '22px', display: 'flex', flexDirection: 'column', gap: '16px' }}>
      <div>
        <h3 style={{ fontSize: '1.05rem', fontWeight: 800, color: '#0f172a', margin: 0 }}>
          {title}
        </h3>
        {subtitle && (
          <p style={{ fontSize: '0.8rem', color: '#64748b', margin: '3px 0 0 0' }}>
            {subtitle}
          </p>
        )}
      </div>

      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-around', flexWrap: 'wrap', gap: '20px' }}>
        {/* SVG Donut */}
        <div style={{ position: 'relative', width: '160px', height: '160px' }}>
          <svg viewBox="0 0 160 160" style={{ width: '100%', height: '100%', transform: 'rotate(-90deg)' }}>
            {/* Background Track Circle */}
            <circle
              cx="80"
              cy="80"
              r={radius}
              fill="transparent"
              stroke="#f1f5f9"
              strokeWidth={strokeWidth}
            />

            {/* Segment Rings */}
            {segments.map((seg, idx) => {
              const strokeDasharray = `${(seg.percentage / 100) * circumference} ${circumference}`;
              const strokeDashoffset = -cumulativeOffset;
              cumulativeOffset += (seg.percentage / 100) * circumference;
              const isHovered = hoveredIndex === idx;

              return (
                <circle
                  key={idx}
                  cx="80"
                  cy="80"
                  r={radius}
                  fill="transparent"
                  stroke={seg.color}
                  strokeWidth={isHovered ? strokeWidth + 4 : strokeWidth}
                  strokeDasharray={strokeDasharray}
                  strokeDashoffset={strokeDashoffset}
                  strokeLinecap="round"
                  style={{
                    cursor: 'pointer',
                    transition: 'all 0.2s ease',
                    opacity: hoveredIndex === null || isHovered ? 1 : 0.45,
                  }}
                  onMouseEnter={() => setHoveredIndex(idx)}
                  onMouseLeave={() => setHoveredIndex(null)}
                />
              );
            })}
          </svg>

          {/* Center Hole Badge Text */}
          <div
            style={{
              position: 'absolute',
              top: '50%',
              left: '50%',
              transform: 'translate(-50%, -50%)',
              textAlign: 'center',
              pointerEvents: 'none',
            }}
          >
            <div style={{ fontSize: '1.4rem', fontWeight: 900, color: '#0f172a', lineHeight: 1 }}>
              {hoveredIndex !== null ? `${segments[hoveredIndex].percentage}%` : centerValue}
            </div>
            <div style={{ fontSize: '0.68rem', fontWeight: 700, color: '#64748b', textTransform: 'uppercase', marginTop: '2px' }}>
              {hoveredIndex !== null ? segments[hoveredIndex].label.split(' ')[0] : centerLabel}
            </div>
          </div>
        </div>

        {/* Legend List */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '10px', minWidth: '180px' }}>
          {segments.map((seg, idx) => {
            const isHovered = hoveredIndex === idx;

            return (
              <div
                key={idx}
                onMouseEnter={() => setHoveredIndex(idx)}
                onMouseLeave={() => setHoveredIndex(null)}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  padding: '6px 10px',
                  borderRadius: '8px',
                  backgroundColor: isHovered ? '#f8fafc' : 'transparent',
                  border: isHovered ? `1px solid ${seg.color}` : '1px solid transparent',
                  cursor: 'pointer',
                  transition: 'all 0.15s ease',
                }}
              >
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <div
                    style={{
                      width: '10px',
                      height: '10px',
                      borderRadius: '50%',
                      backgroundColor: seg.color,
                      flexShrink: 0,
                    }}
                  />
                  <span style={{ fontSize: '0.82rem', fontWeight: 600, color: '#0f172a' }}>
                    {seg.label}
                  </span>
                </div>

                <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                  <span style={{ fontSize: '0.84rem', fontWeight: 800, color: '#0f172a' }}>
                    {seg.percentage}%
                  </span>
                  <span style={{ fontSize: '0.72rem', color: '#94a3b8' }}>
                    ({seg.count})
                  </span>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
};
