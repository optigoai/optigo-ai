// ==================================================
// OptigoAI Enterprise — Prody Light Reports View
// ==================================================

import React, { useState } from 'react';
import { useFranchise } from '../../context/FranchiseContext';
import {
  FileText,
  Download,
  CheckCircle2,
  Table,
  Printer,
} from 'lucide-react';

export const FranchiseReportsView: React.FC = () => {
  const { overview, locations, benchmarks } = useFranchise();
  const [downloadSuccess, setDownloadSuccess] = useState<string | null>(null);

  const handleExportCSV = (type: string) => {
    let headers = '';
    let rows: string[] = [];

    if (type === 'locations') {
      headers = 'Location ID,Branch Name,Category,Location,Region,Health Score,Rating,Total Reviews,Google Rank,Monthly Actions\n';
      rows = locations.map(
        (l) => `"${l.id}","${l.name}","${l.category}","${l.location}","${l.region || ''}",${l.health_score},${l.average_rating},${l.total_reviews},${l.google_maps_rank},${l.monthly_actions}`
      );
    } else {
      headers = 'Rank,Branch Name,Region,Health Score,Vs Avg Delta,Average Rating,Monthly Actions,Tier\n';
      rows = benchmarks.rankings.map(
        (r) => `${r.rank},"${r.name}","${r.region}",${r.health_score},${r.health_delta_vs_avg},${r.average_rating},${r.monthly_actions},"${r.tier}"`
      );
    }

    const csvContent = 'data:text/csv;charset=utf-8,' + encodeURIComponent(headers + rows.join('\n'));
    const link = document.createElement('a');
    link.setAttribute('href', csvContent);
    link.setAttribute('download', `optigo_franchise_${type}_${new Date().toISOString().slice(0, 10)}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);

    setDownloadSuccess(type);
    setTimeout(() => setDownloadSuccess(null), 3000);
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
      {/* 1. Entity Header */}
      <div className="entity-header-card">
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <div className="entity-icon-badge">
            <FileText size={26} />
          </div>
          <div>
            <h1 style={{ fontSize: '1.45rem', fontWeight: 800, color: '#111827', lineHeight: 1.2 }}>
              Executive Reports & Data Exports
            </h1>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginTop: '6px' }}>
              <span className="prody-pill blue">Network Data Exports</span>
              <span className="prody-pill green">CSV & Printable Formats</span>
            </div>
          </div>
        </div>
      </div>

      {/* 2. 3 Export Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: '16px' }}>
        <div className="prody-card" style={{ display: 'flex', flexDirection: 'column', justifyContent: 'space-between', gap: '16px' }}>
          <div>
            <h3 style={{ fontSize: '1.05rem', fontWeight: 700, color: '#111827', marginBottom: '4px' }}>
              Locations Directory CSV
            </h3>
            <p style={{ fontSize: '0.82rem', color: '#6B7280', lineHeight: 1.4 }}>
              Complete dataset of all {locations.length} locations including address, phone, rank, and review metrics.
            </p>
          </div>
          <button onClick={() => handleExportCSV('locations')} className="btn btn-coral btn-sm">
            {downloadSuccess === 'locations' ? <CheckCircle2 size={14} /> : <Download size={14} />}
            <span>{downloadSuccess === 'locations' ? 'Downloaded' : 'Download Locations CSV'}</span>
          </button>
        </div>

        <div className="prody-card" style={{ display: 'flex', flexDirection: 'column', justifyContent: 'space-between', gap: '16px' }}>
          <div>
            <h3 style={{ fontSize: '1.05rem', fontWeight: 700, color: '#111827', marginBottom: '4px' }}>
              Benchmark Matrix CSV
            </h3>
            <p style={{ fontSize: '0.82rem', color: '#6B7280', lineHeight: 1.4 }}>
              Comparative dataset measuring branch performance against franchise network averages.
            </p>
          </div>
          <button onClick={() => handleExportCSV('benchmarks')} className="btn btn-primary btn-sm">
            {downloadSuccess === 'benchmarks' ? <CheckCircle2 size={14} /> : <Download size={14} />}
            <span>{downloadSuccess === 'benchmarks' ? 'Downloaded' : 'Download Benchmarks CSV'}</span>
          </button>
        </div>

        <div className="prody-card" style={{ display: 'flex', flexDirection: 'column', justifyContent: 'space-between', gap: '16px' }}>
          <div>
            <h3 style={{ fontSize: '1.05rem', fontWeight: 700, color: '#111827', marginBottom: '4px' }}>
              Printable Executive Brief
            </h3>
            <p style={{ fontSize: '0.82rem', color: '#6B7280', lineHeight: 1.4 }}>
              Formatted summary designed for executive stakeholder reporting.
            </p>
          </div>
          <button onClick={() => window.print()} className="btn btn-secondary btn-sm">
            <Printer size={14} />
            <span>Print Brief</span>
          </button>
        </div>
      </div>
    </div>
  );
};
