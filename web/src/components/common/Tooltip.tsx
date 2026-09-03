// ==================================================
// OptigoAI Enterprise — Clean Info Tooltip Component
// Plain-English explainer for non-technical users
// ==================================================

import React, { useState } from 'react';
import { HelpCircle, Info } from 'lucide-react';

interface TooltipProps {
  content: string;
  children?: React.ReactNode;
}

export const Tooltip: React.FC<TooltipProps> = ({ content, children }) => {
  const [isVisible, setIsVisible] = useState(false);

  return (
    <div
      style={{ position: 'relative', display: 'inline-flex', alignItems: 'center', cursor: 'pointer' }}
      onMouseEnter={() => setIsVisible(true)}
      onMouseLeave={() => setIsVisible(false)}
      onClick={(e) => {
        e.stopPropagation();
        setIsVisible(!isVisible);
      }}
    >
      {children || <Info size={13} style={{ color: '#94a3b8', marginLeft: '4px', transition: 'color 0.15s ease' }} />}

      {isVisible && (
        <div
          style={{
            position: 'absolute',
            bottom: 'calc(100% + 8px)',
            left: '50%',
            transform: 'translateX(-50%)',
            backgroundColor: '#FFFFFF',
            color: '#173D35',
            border: '1px solid #B9CCC5',
            padding: '8px 12px',
            borderRadius: '8px',
            fontSize: '0.74rem',
            lineHeight: 1.35,
            fontWeight: 500,
            whiteSpace: 'normal',
            width: 'max-content',
            maxWidth: '240px',
            boxShadow: '0 10px 25px -5px rgba(0, 0, 0, 0.3)',
            zIndex: 9999,
            pointerEvents: 'none',
            textAlign: 'left',
          }}
        >
          {content}
          {/* Bottom Arrow Pointer */}
          <div
            style={{
              position: 'absolute',
              top: '100%',
              left: '50%',
              transform: 'translateX(-50%)',
              borderWidth: '5px',
              borderStyle: 'solid',
              borderColor: '#0f172a transparent transparent transparent',
            }}
          />
        </div>
      )}
    </div>
  );
};
