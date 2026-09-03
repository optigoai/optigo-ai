// ==================================================
// OptigoAI Enterprise — Enhanced TrendChartGrid Component
// Multi-metric selectable trend chart with 8-point smooth curve,
// SVG area-fill, dynamic cursor-following tooltip, baseline reference line, and summary
// ==================================================

import React, { useState } from 'react';
import { DateRange } from '../../context/FranchiseContext';
import {
  Eye,
  PhoneCall,
  Activity,
  Star,
  TrendingUp,
} from 'lucide-react';

function getSplinePath(points: { x: number; y: number }[]): string {
  if (points.length === 0) return '';
  if (points.length === 1) return `M ${points[0].x},${points[0].y}`;

  let d = `M ${points[0].x.toFixed(1)},${points[0].y.toFixed(1)}`;
  for (let i = 0; i < points.length - 1; i++) {
    const p0 = i > 0 ? points[i - 1] : points[i];
    const p1 = points[i];
    const p2 = points[i + 1];
    const p3 = i < points.length - 2 ? points[i + 2] : p2;

    const cp1x = p1.x + (p2.x - p0.x) / 6;
    const cp1y = p1.y + (p2.y - p0.y) / 6;
    const cp2x = p2.x - (p3.x - p1.x) / 6;
    const cp2y = p2.y - (p3.y - p1.y) / 6;

    d += ` C ${cp1x.toFixed(1)},${cp1y.toFixed(1)} ${cp2x.toFixed(1)},${cp2y.toFixed(1)} ${p2.x.toFixed(1)},${p2.y.toFixed(1)}`;
  }
  return d;
}

function getSplineArea(points: { x: number; y: number }[], bottomY: number = 180): string {
  if (points.length < 2) return '';
  const curve = getSplinePath(points);
  const first = points[0];
  const last = points[points.length - 1];
  return `${curve} L ${last.x.toFixed(1)},${bottomY} L ${first.x.toFixed(1)},${bottomY} Z`;
}

interface MetricOption {
  id: 'views' | 'actions' | 'health' | 'rating';
  label: string;
  icon: React.ReactNode;
  color: string;
  unit: string;
}

interface TrendChartGridProps {
  totalDiscoveryViews: number;
  totalCustomerActions: number;
  aggregateHealthScore: number;
  averageRating: number;
  selectedDateRange: DateRange;
}

export const TrendChartGrid: React.FC<TrendChartGridProps> = ({
  totalDiscoveryViews,
  totalCustomerActions,
  aggregateHealthScore,
  averageRating,
  selectedDateRange,
}) => {
  const [activeMetric, setActiveMetric] = useState<'views' | 'actions' | 'health' | 'rating'>('views');
  const [hoveredIdx, setHoveredIdx] = useState<number | null>(null);

  const metrics: MetricOption[] = [
    {
      id: 'views',
      label: 'Discovery Views',
      icon: <Eye size={14} />,
      color: '#0284c7',
      unit: 'views',
    },
    {
      id: 'actions',
      label: 'Customer Actions',
      icon: <PhoneCall size={14} />,
      color: '#e11d48',
      unit: 'actions',
    },
    {
      id: 'health',
      label: 'Health Score',
      icon: <Activity size={14} />,
      color: '#2563eb',
      unit: '/100',
    },
    {
      id: 'rating',
      label: 'Google Rating',
      icon: <Star size={14} />,
      color: '#f59e0b',
      unit: '★',
    },
  ];

  const currentMetric = metrics.find((m) => m.id === activeMetric) || metrics[0];

  // 8 smooth data points across all time ranges
  const generateTrendPoints = () => {
    if (selectedDateRange === '7d') {
      const labels = ['Mon 9am', 'Mon 4pm', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat (Peak)', 'Sun'];
      const viewW = [0.09, 0.12, 0.13, 0.12, 0.14, 0.17, 0.22, 0.14];
      const actionW = [0.08, 0.11, 0.12, 0.11, 0.13, 0.18, 0.24, 0.15];
      const healthW = [61, 62, 63, 63, 64, 65, 65, 65];
      const ratingW = [3.5, 3.5, 3.5, 3.6, 3.6, 3.6, 3.6, 3.6];

      return labels.map((label, idx) => ({
        label,
        x: 40 + idx * 92,
        views: Math.round(totalDiscoveryViews * viewW[idx]),
        actions: Math.round(totalCustomerActions * actionW[idx]),
        health: healthW[idx],
        rating: ratingW[idx],
      }));
    } else if (selectedDateRange === '30d') {
      const labels = ['Day 1', 'Day 5', 'Day 10', 'Day 15', 'Day 20', 'Day 24 (Peak)', 'Day 28', 'Day 30'];
      const viewW = [0.08, 0.10, 0.12, 0.14, 0.15, 0.19, 0.18, 0.16];
      const actionW = [0.07, 0.09, 0.11, 0.13, 0.15, 0.21, 0.19, 0.17];
      const healthW = [59, 60, 62, 63, 64, 65, 65, 65];
      const ratingW = [3.4, 3.4, 3.5, 3.5, 3.6, 3.6, 3.6, 3.6];

      return labels.map((label, idx) => ({
        label,
        x: 40 + idx * 92,
        views: Math.round(totalDiscoveryViews * viewW[idx]),
        actions: Math.round(totalCustomerActions * actionW[idx]),
        health: healthW[idx],
        rating: ratingW[idx],
      }));
    } else {
      const labels = ['Wk 1', 'Wk 3', 'Wk 5', 'Wk 7', 'Wk 9', 'Wk 11 (Peak)', 'Wk 13', 'Wk 14'];
      const viewW = [0.08, 0.10, 0.12, 0.14, 0.15, 0.18, 0.17, 0.16];
      const actionW = [0.07, 0.09, 0.11, 0.13, 0.16, 0.20, 0.18, 0.17];
      const healthW = [56, 58, 60, 62, 63, 65, 65, 65];
      const ratingW = [3.3, 3.4, 3.4, 3.5, 3.5, 3.6, 3.6, 3.6];

      return labels.map((label, idx) => ({
        label,
        x: 40 + idx * 92,
        views: Math.round(totalDiscoveryViews * viewW[idx]),
        actions: Math.round(totalCustomerActions * actionW[idx]),
        health: healthW[idx],
        rating: ratingW[idx],
      }));
    }
  };

  const points = generateTrendPoints();

  const svgHeight = 160;
  const topPadding = 25;
  const bottomPadding = 25;
  const usableHeight = svgHeight - topPadding - bottomPadding;

  const getMetricValue = (p: typeof points[0]) => {
    switch (activeMetric) {
      case 'views': return p.views;
      case 'actions': return p.actions;
      case 'health': return p.health;
      case 'rating': return p.rating;
    }
  };

  const values = points.map(getMetricValue);
  const minVal = Math.min(...values);
  const maxVal = Math.max(...values);
  const range = maxVal - minVal || (activeMetric === 'rating' ? 1 : 10);

  const getYCoord = (val: number) => {
    if (activeMetric === 'health') {
      return svgHeight - bottomPadding - ((val - 45) / 55) * usableHeight;
    }
    if (activeMetric === 'rating') {
      return svgHeight - bottomPadding - ((val - 2.8) / 2.2) * usableHeight;
    }
    return svgHeight - bottomPadding - ((val - minVal) / range) * usableHeight;
  };

  const coords = points.map((p) => ({
    x: p.x,
    y: getYCoord(getMetricValue(p)),
  }));

  const splinePath = getSplinePath(coords);
  const splineArea = getSplineArea(coords, svgHeight);

  // Baseline reference line for Health Score (65/100)
  const baselineY = activeMetric === 'health' ? getYCoord(aggregateHealthScore) : null;

  return (
    <div className="prody-card" style={{ padding: '22px', display: 'flex', flexDirection: 'column', gap: '16px' }}>
      {/* 1. Header with Metric Selector Tabs */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '14px' }}>
        <div>
          <h2 style={{ fontSize: '1.15rem', fontWeight: 800, color: '#0f172a', margin: 0 }}>
            Performance & Trend Trajectory
          </h2>
          <p style={{ fontSize: '0.8rem', color: '#64748b', margin: '3px 0 0 0' }}>
            8-point smooth curve with area-fill and network baseline reference.
          </p>
        </div>

        {/* Metric Selector Tabs */}
        <div style={{ display: 'flex', gap: '6px', background: '#f8fafc', padding: '3px', borderRadius: '10px', border: '1px solid #e2e8f0', flexWrap: 'wrap' }}>
          {metrics.map((m) => {
            const isSelected = activeMetric === m.id;
            return (
              <button
                key={m.id}
                onClick={() => setActiveMetric(m.id)}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '6px',
                  padding: '6px 12px',
                  borderRadius: '8px',
                  border: 'none',
                  fontSize: '0.78rem',
                  fontWeight: isSelected ? 800 : 600,
                  backgroundColor: isSelected ? m.color : 'transparent',
                  color: isSelected ? '#ffffff' : '#64748b',
                  cursor: 'pointer',
                  transition: 'all 0.15s ease',
                  boxShadow: isSelected ? '0 2px 6px rgba(0,0,0,0.1)' : 'none',
                }}
              >
                {m.icon}
                <span>{m.label}</span>
              </button>
            );
          })}
        </div>
      </div>

      {/* 2. SVG Line Chart with Area Fill & Reference Line */}
      <div
        style={{ position: 'relative', width: '100%', height: '180px', marginTop: '6px' }}
        onMouseLeave={() => setHoveredIdx(null)}
      >
        <svg viewBox="0 0 740 180" style={{ width: '100%', height: '100%', overflow: 'visible' }}>
          <defs>
            <linearGradient id={`gradient-${activeMetric}`} x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor={currentMetric.color} stopOpacity="0.25" />
              <stop offset="100%" stopColor={currentMetric.color} stopOpacity="0.0" />
            </linearGradient>
          </defs>

          {/* Grid Background Horizontal Lines */}
          <line x1="0" y1="35" x2="740" y2="35" stroke="#f1f5f9" strokeDasharray="3 3" />
          <line x1="0" y1="80" x2="740" y2="80" stroke="#f1f5f9" strokeDasharray="3 3" />
          <line x1="0" y1="125" x2="740" y2="125" stroke="#f1f5f9" strokeDasharray="3 3" />

          {/* Network Benchmark Baseline Reference Line */}
          {baselineY !== null && (
            <g>
              <line x1="0" y1={baselineY} x2="740" y2={baselineY} stroke="#2563eb" strokeWidth="1.5" strokeDasharray="4 4" opacity="0.8" />
              <text x="630" y={baselineY - 6} fill="#2563eb" fontSize="10" fontWeight="700">
                Baseline: {aggregateHealthScore}/100
              </text>
            </g>
          )}

          {/* Shaded Area Fill */}
          <path d={splineArea} fill={`url(#gradient-${activeMetric})`} style={{ transition: 'all 0.3s ease' }} />

          {/* Smooth Spline Trend Line */}
          <path
            d={splinePath}
            fill="none"
            stroke={currentMetric.color}
            strokeWidth="3.5"
            strokeLinecap="round"
            strokeLinejoin="round"
            style={{ transition: 'all 0.3s ease' }}
          />

            {/* Interactive Data Points & SVG Labels */}
            {points.map((p, idx) => {
              const val = getMetricValue(p);
              const cy = getYCoord(val);
              const isHovered = hoveredIdx === idx;

              return (
                <g key={idx}>
                  {isHovered && (
                    <line x1={p.x} y1="10" x2={p.x} y2="155" stroke={currentMetric.color} strokeWidth="1.5" strokeDasharray="2 2" opacity="0.6" />
                  )}

                  <circle
                    cx={p.x}
                    cy={cy}
                    r={isHovered ? 7 : 4.5}
                    fill={currentMetric.color}
                    stroke="#ffffff"
                    strokeWidth="2.5"
                    style={{ cursor: 'pointer', transition: 'r 0.15s ease' }}
                    onMouseEnter={() => setHoveredIdx(idx)}
                  />

                  <circle
                    cx={p.x}
                    cy={cy}
                    r="26"
                    fill="transparent"
                    style={{ cursor: 'pointer' }}
                    onMouseEnter={() => setHoveredIdx(idx)}
                  />

                  <text
                    x={p.x}
                    y="172"
                    textAnchor="middle"
                    fill={isHovered ? '#0f172a' : '#94a3b8'}
                    fontSize="11"
                    fontWeight={isHovered ? '800' : '500'}
                    style={{ cursor: 'pointer' }}
                    onMouseEnter={() => setHoveredIdx(idx)}
                  >
                    {p.label}
                  </text>
                </g>
              );
            })}
          </svg>

          {/* Dynamic Tooltip Popup */}
          {hoveredIdx !== null && (
            <div
              style={{
                position: 'absolute',
                left: `${(points[hoveredIdx].x / 740) * 100}%`,
                top: `${getYCoord(getMetricValue(points[hoveredIdx])) - 35}px`,
                transform: 'translate(-50%, -100%)',
                backgroundColor: '#FFFFFF',
                color: '#173D35',
                border: '1px solid #B9CCC5',
                padding: '6px 12px',
                borderRadius: '8px',
                fontSize: '0.78rem',
                fontWeight: 800,
                boxShadow: '0 8px 20px rgba(0,0,0,0.25)',
                pointerEvents: 'none',
                zIndex: 10,
                whiteSpace: 'nowrap',
              }}
            >
              <div style={{ fontSize: '0.68rem', color: '#94a3b8', fontWeight: 600 }}>{points[hoveredIdx].label}</div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '4px', marginTop: '1px' }}>
                <span style={{ color: currentMetric.color }}>●</span>
                <span>
                  {getMetricValue(points[hoveredIdx]).toLocaleString()} {currentMetric.unit}
                </span>
              </div>
            </div>
          )}
        </div>

      {/* 3. Separate Clean Period Comparison Row */}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))',
          gap: '10px',
          borderTop: '1px solid #f1f5f9',
          paddingTop: '14px',
          fontSize: '0.76rem',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '6px 10px', borderRadius: '8px', backgroundColor: '#f8fafc' }}>
          <span style={{ color: '#64748b' }}>Discovery Views</span>
          <span style={{ color: '#16a34a', fontWeight: 700 }}>+14.8% this month</span>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '6px 10px', borderRadius: '8px', backgroundColor: '#f8fafc' }}>
          <span style={{ color: '#64748b' }}>Customer Inquiries</span>
          <span style={{ color: '#16a34a', fontWeight: 700 }}>+12.4% this month</span>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '6px 10px', borderRadius: '8px', backgroundColor: '#f8fafc' }}>
          <span style={{ color: '#64748b' }}>Health Velocity</span>
          <span style={{ color: '#2563eb', fontWeight: 700 }}>+3 pts momentum</span>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '6px 10px', borderRadius: '8px', backgroundColor: '#f8fafc' }}>
          <span style={{ color: '#64748b' }}>Positive Sentiment</span>
          <span style={{ color: '#16a34a', fontWeight: 700 }}>62% verified praise</span>
        </div>
      </div>
    </div>
  );
};
