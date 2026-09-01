// ==================================================
// OptigoAI Enterprise — Report Exporter Utility
// Multi-Format Export Engine (PDF, Excel XML, CSV, Print)
// ==================================================

/**
 * Exports data to CSV with UTF-8 BOM encoding
 */
export function exportToCSV(
  filename: string,
  headers: string[],
  rows: (string | number)[][]
): void {
  const cleanField = (val: string | number | null | undefined): string => {
    if (val === null || val === undefined) return '""';
    const str = String(val).replace(/"/g, '""');
    return `"${str}"`;
  };

  const headerLine = headers.map(cleanField).join(',');
  const rowLines = rows.map((r) => r.map(cleanField).join(',')).join('\n');
  const csvContent = '\uFEFF' + headerLine + '\n' + rowLines;

  const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
  downloadBlob(blob, `${filename}.csv`);
}

/**
 * Exports data to Excel format (SpreadsheetML / XML format compatible with MS Excel, LibreOffice, Apple Numbers, Google Sheets)
 */
export function exportToExcel(
  filename: string,
  sheetName: string,
  headers: string[],
  rows: (string | number)[][],
  title?: string
): void {
  const sanitize = (val: string | number | null | undefined): string => {
    if (val === null || val === undefined) return '';
    return String(val)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  };

  let xml = `<?xml version="1.0"?>
<?mso-application progid="Excel.Sheet"?>
<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"
 xmlns:o="urn:schemas-microsoft-com:office:office"
 xmlns:x="urn:schemas-microsoft-com:office:excel"
 xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"
 xmlns:html="http://www.w3.org/TR/REC-html40">
 <Styles>
  <Style ss:ID="Default" ss:Name="Normal">
   <Alignment ss:Vertical="Center"/>
   <Font ss:FontName="Calibri" ss:Size="11" ss:Color="#000000"/>
  </Style>
  <Style ss:ID="TitleStyle">
   <Font ss:FontName="Calibri" ss:Size="16" ss:Bold="1" ss:Color="#1E3A8A"/>
   <Alignment ss:Horizontal="Left" ss:Vertical="Center"/>
  </Style>
  <Style ss:ID="HeaderStyle">
   <Font ss:FontName="Calibri" ss:Size="11" ss:Bold="1" ss:Color="#FFFFFF"/>
   <Interior ss:Color="#1E293B" ss:Pattern="Solid"/>
   <Alignment ss:Horizontal="Center" ss:Vertical="Center"/>
   <Borders>
    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#CBD5E1"/>
   </Borders>
  </Style>
  <Style ss:ID="DataStyle">
   <Alignment ss:Vertical="Center"/>
   <Borders>
    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#E2E8F0"/>
   </Borders>
  </Style>
  <Style ss:ID="NumericStyle">
   <Alignment ss:Horizontal="Right" ss:Vertical="Center"/>
   <Borders>
    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#E2E8F0"/>
   </Borders>
  </Style>
 </Styles>
 <Worksheet ss:Name="${sanitize(sheetName)}">
  <Table>`;

  // Title Row if provided
  if (title) {
    xml += `
   <Row ss:Height="30">
    <Cell ss:StyleID="TitleStyle" ss:MergeAcross="${headers.length - 1}"><Data ss:Type="String">${sanitize(
      title
    )}</Data></Cell>
   </Row>
   <Row ss:Height="12"></Row>`;
  }

  // Header Row
  xml += `
   <Row ss:Height="24">`;
  for (const h of headers) {
    xml += `<Cell ss:StyleID="HeaderStyle"><Data ss:Type="String">${sanitize(h)}</Data></Cell>`;
  }
  xml += `</Row>`;

  // Data Rows
  for (const row of rows) {
    xml += `
   <Row ss:Height="20">`;
    for (const cell of row) {
      const isNum = typeof cell === 'number';
      const cellStyle = isNum ? 'NumericStyle' : 'DataStyle';
      const cellType = isNum ? 'Number' : 'String';
      xml += `<Cell ss:StyleID="${cellStyle}"><Data ss:Type="${cellType}">${sanitize(cell)}</Data></Cell>`;
    }
    xml += `</Row>`;
  }

  xml += `
  </Table>
 </Worksheet>
</Workbook>`;

  const blob = new Blob([xml], { type: 'application/vnd.ms-excel' });
  downloadBlob(blob, `${filename}.xls`);
}

/**
 * Exports styled executive report to PDF via dedicated printable iframe
 */
export function exportToPDF(
  filename: string,
  title: string,
  subtitle: string,
  summaryCards: { label: string; value: string | number; change?: string }[],
  tables: { title: string; headers: string[]; rows: (string | number)[][] }[]
): void {
  const printWindow = window.open('', '_blank');
  if (!printWindow) {
    alert('Please allow popups to download and print the PDF report.');
    return;
  }

  const generatedDate = new Date().toLocaleString('en-US', {
    dateStyle: 'medium',
    timeStyle: 'short',
  });

  const html = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>${title}</title>
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');
    
    @page {
      size: A4 portrait;
      margin: 15mm 15mm 15mm 15mm;
    }
    
    body {
      font-family: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      color: #0f172a;
      background: #ffffff;
      margin: 0;
      padding: 20px;
      font-size: 11pt;
      line-height: 1.4;
    }
    
    .header-bar {
      display: flex;
      justify-content: space-between;
      align-items: center;
      border-bottom: 2px solid #2563eb;
      padding-bottom: 14px;
      margin-bottom: 20px;
    }
    
    .logo-badge {
      font-size: 20pt;
      font-weight: 900;
      color: #0f172a;
      letter-spacing: -0.5px;
    }
    
    .logo-badge span {
      color: #2563eb;
    }
    
    .report-title {
      font-size: 16pt;
      font-weight: 800;
      color: #0f172a;
      margin: 0 0 4px 0;
    }
    
    .report-subtitle {
      font-size: 9.5pt;
      color: #64748b;
      margin: 0;
    }
    
    .date-badge {
      font-size: 8.5pt;
      color: #64748b;
      text-align: right;
    }
    
    .summary-grid {
      display: grid;
      grid-template-columns: repeat(4, 1fr);
      gap: 12px;
      margin-bottom: 24px;
    }
    
    .summary-card {
      background: #f8fafc;
      border: 1px solid #e2e8f0;
      border-radius: 8px;
      padding: 12px;
    }
    
    .card-label {
      font-size: 8pt;
      text-transform: uppercase;
      font-weight: 700;
      color: #64748b;
      margin-bottom: 4px;
    }
    
    .card-value {
      font-size: 14pt;
      font-weight: 800;
      color: #0f172a;
    }
    
    .section-heading {
      font-size: 12pt;
      font-weight: 800;
      color: #0f172a;
      margin: 20px 0 10px 0;
      border-bottom: 1px solid #e2e8f0;
      padding-bottom: 6px;
    }
    
    table {
      width: 100%;
      border-collapse: collapse;
      margin-bottom: 24px;
      font-size: 9pt;
    }
    
    th {
      background: #1e293b;
      color: #ffffff;
      font-weight: 700;
      text-align: left;
      padding: 8px 10px;
    }
    
    td {
      padding: 7px 10px;
      border-bottom: 1px solid #e2e8f0;
      color: #334155;
    }
    
    tr:nth-child(even) td {
      background-color: #f8fafc;
    }
    
    .footer-bar {
      margin-top: 30px;
      border-top: 1px solid #e2e8f0;
      padding-top: 10px;
      display: flex;
      justify-content: space-between;
      font-size: 8pt;
      color: #94a3b8;
    }
  </style>
</head>
<body>
  <div class="header-bar">
    <div>
      <div class="logo-badge">Optigo<span>AI</span></div>
      <div class="report-subtitle">Enterprise Franchise Growth & Multi-Location Reputation Intelligence</div>
    </div>
    <div class="date-badge">
      <div>Generated on</div>
      <strong>${generatedDate}</strong>
    </div>
  </div>

  <h1 class="report-title">${title}</h1>
  <p class="report-subtitle" style="margin-bottom: 16px;">${subtitle}</p>

  ${
    summaryCards.length > 0
      ? `
  <div class="summary-grid">
    ${summaryCards
      .map(
        (c) => `
      <div class="summary-card">
        <div class="card-label">${c.label}</div>
        <div class="card-value">${c.value}</div>
      </div>
    `
      )
      .join('')}
  </div>`
      : ''
  }

  ${tables
    .map(
      (t) => `
    <div class="section-heading">${t.title}</div>
    <table>
      <thead>
        <tr>
          ${t.headers.map((h) => `<th>${h}</th>`).join('')}
        </tr>
      </thead>
      <tbody>
        ${t.rows
          .map(
            (row) => `
          <tr>
            ${row.map((cell) => `<td>${cell !== null && cell !== undefined ? cell : '-'}</td>`).join('')}
          </tr>
        `
          )
          .join('')}
      </tbody>
    </table>
  `
    )
    .join('')}

  <div class="footer-bar">
    <span>OptigoAI Enterprise Platform • Confidential Executive Audit</span>
    <span>Page 1 of 1</span>
  </div>

  <script>
    window.onload = function() {
      setTimeout(function() {
        window.print();
      }, 400);
    };
  </script>
</body>
</html>
`;

  printWindow.document.open();
  printWindow.document.write(html);
  printWindow.document.close();
}

function downloadBlob(blob: Blob, filename: string): void {
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = filename;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
}
