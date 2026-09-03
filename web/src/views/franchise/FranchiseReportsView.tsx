// ==================================================
// OptigoAI Enterprise — Clean Reports & Multi-Format Export Center
// Neutral card borders, sentence-case labels, and standard primary download actions
// Full datasets are included in the generated files (PDF, Excel, CSV)
// ==================================================

import React, { useState } from 'react';
import { useFranchise } from '../../context/FranchiseContext';
import {
  exportToCSV,
  exportToExcel,
  exportToPDF,
} from '../../utils/reportExporter';
import {
  FileText,
  Download,
  CheckCircle2,
  FileSpreadsheet,
  FileType,
  Clock,
} from 'lucide-react';

export const FranchiseReportsView: React.FC = () => {
  const { overview, locations, benchmarks } = useFranchise();
  const [downloadSuccess, setDownloadSuccess] = useState<string | null>(null);

  const orgName = overview?.organization_id ? 'Casarasa Franchise Network' : 'Franchise Network';
  const lastGeneratedDate = new Date().toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });

  const triggerDownloadSuccess = (type: string) => {
    setDownloadSuccess(type);
    setTimeout(() => setDownloadSuccess(null), 3000);
  };

  // 1. FULL EXECUTIVE REPORT EXPORT (PDF)
  const handleExportFullPDF = () => {
    const summaryCards = [
      { label: 'Total Locations', value: overview?.total_locations || locations.length },
      { label: 'Aggregate Health', value: `${overview?.aggregate_health_score || 0}/100` },
      { label: 'Franchise Avg Rating', value: `${overview?.franchise_avg_rating || 0} ★` },
      { label: 'Total Reviews', value: overview?.total_reviews || 0 },
      { label: 'Discovery Searches', value: (overview?.total_searches || 0).toLocaleString() },
      { label: 'Customer Actions', value: (overview?.total_customer_actions || 0).toLocaleString() },
      { label: 'Phone Calls', value: (overview?.total_calls || 0).toLocaleString() },
      { label: 'Direction Requests', value: (overview?.total_direction_requests || 0).toLocaleString() },
    ];

    const locHeaders = ['Branch Name', 'Location', 'Region', 'Health Score', 'Rating', 'Reviews', 'Unreplied', 'Monthly Searches', 'Actions'];
    const locRows = locations.map((l) => [
      l.name,
      l.location,
      l.region || 'Primary',
      `${l.health_score || 0}/100`,
      `${l.average_rating || 0} ★`,
      l.total_reviews || 0,
      l.unreplied_reviews || 0,
      l.monthly_searches || 0,
      l.monthly_actions || 0,
    ]);

    const benchHeaders = ['Rank', 'Branch Name', 'Region', 'Health Score', 'Health Delta', 'Rating', 'Actions', 'Tier'];
    const benchRows = (benchmarks.rankings || []).map((r) => [
      r.rank,
      r.name,
      r.region,
      `${r.health_score}/100`,
      `${r.health_delta_vs_avg >= 0 ? '+' : ''}${r.health_delta_vs_avg} pts`,
      `${r.average_rating} ★`,
      r.monthly_actions,
      r.tier,
    ]);

    exportToPDF(
      `optigoai_executive_audit_${new Date().toISOString().slice(0, 10)}`,
      `${orgName} — Executive Performance Audit`,
      'Complete multi-location performance, Google Maps rankings, health analysis, and operational benchmark brief.',
      summaryCards,
      [
        { title: 'Multi-Location Performance Directory', headers: locHeaders, rows: locRows },
        { title: 'Cross-Branch Comparative Benchmark Matrix', headers: benchHeaders, rows: benchRows },
      ]
    );
    triggerDownloadSuccess('full_pdf');
  };

  // 2. MULTI-LOCATION OPERATIONAL DATASET (EXCEL)
  const handleExportFullExcel = () => {
    const headers = [
      'Branch Name',
      'Category',
      'Location Address',
      'Region Territory',
      'Health Score',
      'Completeness %',
      'Google Rating',
      'Total Reviews',
      'Unreplied Reviews',
      'Google Maps Rank',
      'Monthly Searches',
      'Monthly High-Intent Actions',
      'Website URL',
      'Operational Status',
    ];

    const rows = locations.map((l) => [
      l.name,
      l.category,
      l.location,
      l.region || 'Primary',
      l.health_score || 0,
      `${l.completeness_score || 85}%`,
      l.average_rating || 0,
      l.total_reviews || 0,
      l.unreplied_reviews || 0,
      l.google_maps_rank || 3,
      l.monthly_searches || 0,
      l.monthly_actions || 0,
      l.public_website_url || 'https://optigoai.com',
      l.status || 'active',
    ]);

    exportToExcel(
      `optigoai_franchise_full_dataset_${new Date().toISOString().slice(0, 10)}`,
      'Locations Performance',
      headers,
      rows,
      `${orgName} — Multi-Location Operational Dataset`
    );
    triggerDownloadSuccess('full_excel');
  };

  // 3. FRANCHISE RAW CSV EXPORT
  const handleExportFullCSV = () => {
    const headers = [
      'Branch ID',
      'Branch Name',
      'Category',
      'Location',
      'Region',
      'Health Score',
      'Completeness Score',
      'Average Rating',
      'Total Reviews',
      'Unreplied Reviews',
      'Google Maps Rank',
      'Monthly Searches',
      'Monthly Actions',
      'Status',
    ];

    const rows = locations.map((l) => [
      l.id,
      l.name,
      l.category,
      l.location,
      l.region || '',
      l.health_score || 0,
      l.completeness_score || 0,
      l.average_rating || 0,
      l.total_reviews || 0,
      l.unreplied_reviews || 0,
      l.google_maps_rank || 1,
      l.monthly_searches || 0,
      l.monthly_actions || 0,
      l.status || 'active',
    ]);

    exportToCSV(`optigoai_franchise_all_data_${new Date().toISOString().slice(0, 10)}`, headers, rows);
    triggerDownloadSuccess('full_csv');
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '20px', maxWidth: '1280px', margin: '0 auto', width: '100%' }}>
      {/* 1. Header Card */}
      <div className="entity-header-card" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '14px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
          <div className="entity-icon-badge" style={{ backgroundColor: '#eff6ff', color: '#2563eb' }}>
            <FileText size={24} />
          </div>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <h1 style={{ fontSize: '1.35rem', fontWeight: 800, color: '#0f172a', lineHeight: 1.2, margin: 0 }}>
                Executive Reports & Data Exports
              </h1>
              <span className="prody-pill blue" style={{ fontSize: '0.72rem' }}>
                PDF • Excel • CSV
              </span>
            </div>
            <p style={{ fontSize: '0.8rem', color: '#64748b', margin: '4px 0 0 0' }}>
              Generate structured executive briefs, full branch datasets, and raw CSV files for stakeholders and board presentations.
            </p>
          </div>
        </div>
      </div>

      {/* 3. Three Clean Neutral Export Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))', gap: '18px' }}>
        {/* Export Card 1: PDF Executive Audit */}
        <div
          className="prody-card"
          style={{
            padding: '22px',
            display: 'flex',
            flexDirection: 'column',
            justifyContent: 'space-between',
            gap: '16px',
            border: '1px solid #e2e8f0',
            backgroundColor: '#ffffff',
          }}
        >
          <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '8px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                <div
                  style={{
                    width: '34px',
                    height: '34px',
                    borderRadius: '8px',
                    backgroundColor: '#eff6ff',
                    color: '#2563eb',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                  }}
                >
                  <FileType size={18} />
                </div>
                <div>
                  <h3 style={{ fontSize: '1rem', fontWeight: 800, color: '#0f172a', margin: 0 }}>
                    Executive Performance Audit
                  </h3>
                  <span style={{ fontSize: '0.74rem', color: '#64748b', fontWeight: 600 }}>
                    Formatted PDF Document
                  </span>
                </div>
              </div>

              <div style={{ display: 'flex', alignItems: 'center', gap: '3px', fontSize: '0.7rem', color: '#94a3b8' }}>
                <Clock size={11} />
                <span>{lastGeneratedDate}</span>
              </div>
            </div>

            <p style={{ fontSize: '0.8rem', color: '#475569', lineHeight: 1.45, marginTop: '8px' }}>
              Designed for executive leadership, investors, and regional directors. Includes visual scorecards, performance summaries, and high-level tables.
            </p>

            {/* What's Included (Sentence case) */}
            <div style={{ marginTop: '12px', backgroundColor: '#f8fafc', padding: '10px 12px', borderRadius: '8px', border: '1px solid #e2e8f0' }}>
              <span style={{ fontSize: '0.72rem', fontWeight: 700, color: '#334155' }}>
                What's included:
              </span>
              <ul style={{ margin: '4px 0 0 0', paddingLeft: '16px', fontSize: '0.76rem', color: '#64748b', lineHeight: 1.55 }}>
                <li>Network Aggregate Health & Rating KPIs</li>
                <li>Discovery Searches & Conversion Actions</li>
                <li>Multi-Location Performance Directory</li>
                <li>Cross-Branch Comparative Benchmark Matrix</li>
              </ul>
            </div>
          </div>

          <button
            onClick={handleExportFullPDF}
            className="btn btn-primary"
            style={{
              gap: '8px',
              fontSize: '0.9rem',
              fontWeight: 800,
              padding: '12px 20px',
              borderRadius: '10px',
            }}
          >
            {downloadSuccess === 'full_pdf' ? <CheckCircle2 size={16} /> : <Download size={16} />}
            <span>{downloadSuccess === 'full_pdf' ? 'Downloaded PDF' : 'Download Executive PDF'}</span>
          </button>
        </div>

        {/* Export Card 2: Excel Operational Dataset */}
        <div
          className="prody-card"
          style={{
            padding: '22px',
            display: 'flex',
            flexDirection: 'column',
            justifyContent: 'space-between',
            gap: '16px',
            border: '1px solid #e2e8f0',
            backgroundColor: '#ffffff',
          }}
        >
          <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '8px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                <div
                  style={{
                    width: '34px',
                    height: '34px',
                    borderRadius: '8px',
                    backgroundColor: '#eff6ff',
                    color: '#2563eb',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                  }}
                >
                  <FileSpreadsheet size={18} />
                </div>
                <div>
                  <h3 style={{ fontSize: '1rem', fontWeight: 800, color: '#0f172a', margin: 0 }}>
                    Operational Spreadsheet
                  </h3>
                  <span style={{ fontSize: '0.74rem', color: '#64748b', fontWeight: 600 }}>
                    Excel (.xls XML Spreadsheet)
                  </span>
                </div>
              </div>

              <div style={{ display: 'flex', alignItems: 'center', gap: '3px', fontSize: '0.7rem', color: '#94a3b8' }}>
                <Clock size={11} />
                <span>{lastGeneratedDate}</span>
              </div>
            </div>

            <p style={{ fontSize: '0.8rem', color: '#475569', lineHeight: 1.45, marginTop: '8px' }}>
              Structured spreadsheet formatted with styled column headers and data types. Opens natively in Microsoft Excel, Apple Numbers, and Google Sheets.
            </p>

            {/* What's Included (Sentence case) */}
            <div style={{ marginTop: '12px', backgroundColor: '#f8fafc', padding: '10px 12px', borderRadius: '8px', border: '1px solid #e2e8f0' }}>
              <span style={{ fontSize: '0.72rem', fontWeight: 700, color: '#334155' }}>
                What's included:
              </span>
              <ul style={{ margin: '4px 0 0 0', paddingLeft: '16px', fontSize: '0.76rem', color: '#64748b', lineHeight: 1.55 }}>
                <li>Complete branch address & territory registry</li>
                <li>Profile completeness & health scores</li>
                <li>Monthly search impressions & inquiries</li>
                <li>Live public website links</li>
              </ul>
            </div>
          </div>

          <button
            onClick={handleExportFullExcel}
            className="btn btn-primary"
            style={{
              gap: '8px',
              fontSize: '0.9rem',
              fontWeight: 800,
              padding: '12px 20px',
              borderRadius: '10px',
            }}
          >
            {downloadSuccess === 'full_excel' ? <CheckCircle2 size={16} /> : <Download size={16} />}
            <span>{downloadSuccess === 'full_excel' ? 'Downloaded Excel' : 'Download Excel Dataset'}</span>
          </button>
        </div>

        {/* Export Card 3: Raw CSV Data Dump */}
        <div
          className="prody-card"
          style={{
            padding: '22px',
            display: 'flex',
            flexDirection: 'column',
            justifyContent: 'space-between',
            gap: '16px',
            border: '1px solid #e2e8f0',
            backgroundColor: '#ffffff',
          }}
        >
          <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '8px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                <div
                  style={{
                    width: '34px',
                    height: '34px',
                    borderRadius: '8px',
                    backgroundColor: '#eff6ff',
                    color: '#2563eb',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                  }}
                >
                  <FileText size={18} />
                </div>
                <div>
                  <h3 style={{ fontSize: '1rem', fontWeight: 800, color: '#0f172a', margin: 0 }}>
                    Raw CSV Data Dump
                  </h3>
                  <span style={{ fontSize: '0.74rem', color: '#64748b', fontWeight: 600 }}>
                    Comma-Separated Values (.csv)
                  </span>
                </div>
              </div>

              <div style={{ display: 'flex', alignItems: 'center', gap: '3px', fontSize: '0.7rem', color: '#94a3b8' }}>
                <Clock size={11} />
                <span>{lastGeneratedDate}</span>
              </div>
            </div>

            <p style={{ fontSize: '0.8rem', color: '#475569', lineHeight: 1.45, marginTop: '8px' }}>
              Standard unformatted CSV file containing every data field across all locations. Ideal for automated data ingestion into external warehouses.
            </p>

            {/* What's Included (Sentence case) */}
            <div style={{ marginTop: '12px', backgroundColor: '#f8fafc', padding: '10px 12px', borderRadius: '8px', border: '1px solid #e2e8f0' }}>
              <span style={{ fontSize: '0.72rem', fontWeight: 700, color: '#334155' }}>
                What's included:
              </span>
              <ul style={{ margin: '4px 0 0 0', paddingLeft: '16px', fontSize: '0.76rem', color: '#64748b', lineHeight: 1.55 }}>
                <li>Raw numerical metrics & timestamps</li>
                <li>Full location identifiers & coordinates</li>
                <li>Aggregate ratings & reviews</li>
                <li>Operational statuses</li>
              </ul>
            </div>
          </div>

          <button
            onClick={handleExportFullCSV}
            className="btn btn-secondary"
            style={{
              gap: '8px',
              fontSize: '0.9rem',
              fontWeight: 800,
              padding: '12px 20px',
              borderRadius: '10px',
            }}
          >
            {downloadSuccess === 'full_csv' ? <CheckCircle2 size={16} /> : <Download size={16} />}
            <span>{downloadSuccess === 'full_csv' ? 'Downloaded CSV' : 'Download Raw CSV'}</span>
          </button>
        </div>
      </div>
    </div>
  );
};
