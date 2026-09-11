// ==================================================
// OptigoAI Enterprise — Single-Page Onboarding & Lead Gen
// Fresh Light Theme (Crisp Blue & White)
// ==================================================

import React, { useState, useEffect, useRef } from 'react';
import {
  Search,
  Building2,
  Phone,
  CheckCircle2,
  AlertTriangle,
  ArrowRight,
  Sparkles,
  MapPin,
  Star,
  ShieldCheck,
  Zap,
  TrendingUp,
  Loader2,
} from 'lucide-react';
import optigoLogo from '../../assets/optigoai-logo.png';
import { leadService, PlaceSearchResult } from '../../services/leadService';

interface SinglePageOnboardingViewProps {
  onReportReady?: (leadId: string) => void;
}

const COUNTRY_CODES = [
  { code: '+91', country: 'IN', label: '+91 (India)' },
  { code: '+1', country: 'US', label: '+1 (USA / Canada)' },
  { code: '+44', country: 'GB', label: '+44 (UK)' },
  { code: '+971', country: 'AE', label: '+971 (UAE)' },
  { code: '+61', country: 'AU', label: '+61 (Australia)' },
  { code: '+65', country: 'SG', label: '+65 (Singapore)' },
];

const AUDIT_STEPS = [
  { id: 1, label: 'Finding your business on Google Maps' },
  { id: 2, label: 'Checking nearby competitors in your area' },
  { id: 3, label: 'Checking customer reviews and replies' },
  { id: 4, label: 'Finding missing details on your Google profile' },
  { id: 5, label: 'Preparing your simple business report' },
];

export const SinglePageOnboardingView: React.FC<SinglePageOnboardingViewProps> = ({ onReportReady }) => {
  // Form State
  const [searchQuery, setSearchQuery] = useState('');
  const [locationQuery, setLocationQuery] = useState('');
  const [selectedPlace, setSelectedPlace] = useState<PlaceSearchResult | null>(null);
  const [searchResults, setSearchResults] = useState<PlaceSearchResult[]>([]);
  const [isSearching, setIsSearching] = useState(false);
  const [showDropdown, setShowDropdown] = useState(false);

  const [countryCode, setCountryCode] = useState('+91');
  const [phone, setPhone] = useState('');

  // Execution State
  const [isAuditing, setIsAuditing] = useState(false);
  const [auditStepIndex, setAuditStepIndex] = useState(0);
  const [auditProgress, setAuditProgress] = useState(10);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const searchTimeoutRef = useRef<any>(null);
  const dropdownRef = useRef<HTMLDivElement | null>(null);

  // Debounced Places Search
  // Debounced Places Search
  useEffect(() => {
    if (searchTimeoutRef.current) {
      clearTimeout(searchTimeoutRef.current);
    }

    // If a place is selected and the search query matches it, don't re-trigger search
    if (selectedPlace && selectedPlace.name.trim().toLowerCase() === searchQuery.trim().toLowerCase()) {
      setShowDropdown(false);
      setIsSearching(false);
      return;
    }

    if (!searchQuery || searchQuery.trim().length < 2) {
      setSearchResults([]);
      setIsSearching(false);
      setShowDropdown(false);
      return;
    }

    setIsSearching(true);
    searchTimeoutRef.current = setTimeout(async () => {
      try {
        const results = await leadService.searchPlaces(searchQuery, locationQuery);
        setSearchResults(results);
        setShowDropdown(true);
      } catch (err) {
        console.error('Failed to search places:', err);
      } finally {
        setIsSearching(false);
      }
    }, 350);

    return () => {
      if (searchTimeoutRef.current) {
        clearTimeout(searchTimeoutRef.current);
      }
    };
  }, [searchQuery, locationQuery, selectedPlace]);

  // Click outside to close dropdown
  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(e.target as Node)) {
        setShowDropdown(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const handleSelectPlace = (place: PlaceSearchResult) => {
    if (searchTimeoutRef.current) {
      clearTimeout(searchTimeoutRef.current);
    }
    setSelectedPlace(place);
    setSearchQuery(place.name);
    setSearchResults([]);
    setShowDropdown(false);
    setIsSearching(false);
    if (place.phone && !phone) {
      const clean = place.phone.replace(/[^0-9]/g, '');
      if (clean.length >= 10) {
        setPhone(clean.slice(-10));
      }
    }
  };

  const handleStartAudit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMessage(null);

    const businessName = selectedPlace ? selectedPlace.name : searchQuery.trim();
    if (!businessName) {
      setErrorMessage('Please search or enter your business name.');
      return;
    }

    const cleanPhone = phone.trim().replace(/[^0-9]/g, '');
    if (!cleanPhone || cleanPhone.length < 8) {
      setErrorMessage('Please provide a valid phone number so we can deliver your audit.');
      return;
    }

    setIsAuditing(true);
    setAuditStepIndex(0);
    setAuditProgress(15);

    // Step progression timer
    const stepInterval = setInterval(() => {
      setAuditStepIndex((prev) => {
        const next = prev < AUDIT_STEPS.length - 1 ? prev + 1 : prev;
        setAuditProgress(Math.min(92, 20 + next * 18));
        return next;
      });
    }, 1200);

    try {
      // Extract locality if business name was typed with a comma (e.g. "Casa Rasa Family Restaurant, Edappal")
      let inferredAddress = selectedPlace?.address || locationQuery || '';
      if (!inferredAddress && businessName.includes(',')) {
        const parts = businessName.split(',').map((s) => s.trim());
        if (parts.length > 1) {
          inferredAddress = parts.slice(1).join(', ');
        }
      }

      // 1. Create or update lead
      const lead = await leadService.createLead({
        business_name: businessName,
        place_id: selectedPlace?.place_id,
        phone: `${countryCode}${cleanPhone}`,
        country_code: countryCode,
        address: inferredAddress,
        category: selectedPlace?.category,
        rating: selectedPlace?.rating,
        review_count: selectedPlace?.review_count,
        website: selectedPlace?.website,
        photo_url: selectedPlace?.photo_url,
        latitude: selectedPlace?.latitude,
        longitude: selectedPlace?.longitude,
        raw_places_data: selectedPlace,
      });

      // 2. Trigger asynchronous analysis
      await leadService.analyzeLead(lead.id);

      // Finish progress
      clearInterval(stepInterval);
      setAuditProgress(100);

      setTimeout(() => {
        if (onReportReady) {
          onReportReady(lead.id);
        } else {
          window.location.href = `/report/${lead.id}`;
        }
      }, 700);
    } catch (err: any) {
      clearInterval(stepInterval);
      setIsAuditing(false);
      setErrorMessage(err?.message || 'Unable to complete the business audit. Please try again.');
    }
  };

  return (
    <div
      style={{
        minHeight: '100vh',
        background: 'linear-gradient(180deg, #FFFFFF 0%, #FAF8FF 50%, #F5F2FE 100%)',
        color: '#0F172A',
        fontFamily: "'Manrope', system-ui, -apple-system, sans-serif",
        display: 'flex',
        flexDirection: 'column',
        position: 'relative',
        overflowX: 'hidden',
      }}
    >
      {/* Background Subtle Luminous Glow */}
      <div
        style={{
          position: 'absolute',
          top: '-160px',
          left: '50%',
          transform: 'translateX(-50%)',
          width: '900px',
          height: '480px',
          background: 'radial-gradient(circle, rgba(124, 58, 237, 0.08) 0%, rgba(245, 243, 255, 0) 70%)',
          pointerEvents: 'none',
        }}
      />

      {/* Top Header */}
      <header
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          padding: '14px 28px',
          background: 'rgba(255, 255, 255, 0.92)',
          backdropFilter: 'blur(12px)',
          borderBottom: '1px solid #EDE9FE',
          position: 'sticky',
          top: 0,
          zIndex: 40,
          width: '100%',
          boxSizing: 'border-box',
          boxShadow: '0 1px 3px rgba(124, 58, 237, 0.04)',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
          <img src={optigoLogo} alt="Optigo AI" style={{ height: '32px', width: 'auto' }} />
          <span
            style={{
              fontWeight: 800,
              fontSize: '1.22rem',
              letterSpacing: '-0.02em',
              color: '#0F172A',
            }}
          >
            Optigo<span style={{ color: '#7C3AED' }}>AI</span>
          </span>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <a
            href="/login"
            style={{
              color: '#6D28D9',
              textDecoration: 'none',
              fontSize: '0.86rem',
              fontWeight: 700,
              padding: '7px 15px',
              borderRadius: '999px',
              background: '#F5F3FF',
              border: '1px solid #DDD6FE',
              transition: 'all 0.2s',
            }}
            onMouseOver={(e) => {
              (e.currentTarget as HTMLElement).style.background = '#7C3AED';
              (e.currentTarget as HTMLElement).style.color = '#FFFFFF';
            }}
            onMouseOut={(e) => {
              (e.currentTarget as HTMLElement).style.background = '#F5F3FF';
              (e.currentTarget as HTMLElement).style.color = '#6D28D9';
            }}
          >
            Customer Login →
          </a>
        </div>
      </header>

      {/* Main Content Area */}
      <main
        className="onboarding-main-container"
        style={{
          flex: 1,
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          padding: '24px 16px 40px',
          maxWidth: '680px',
          margin: '0 auto',
          width: '100%',
          boxSizing: 'border-box',
          position: 'relative',
          zIndex: 1,
        }}
      >
        {isAuditing ? (
          /* Live Animated Audit Progress Screen (Open Seamless Layout) */
          <div
            style={{
              width: '100%',
              maxWidth: '560px',
              textAlign: 'center',
              boxSizing: 'border-box',
            }}
          >
            <div
              style={{
                width: '74px',
                height: '74px',
                borderRadius: '50%',
                background: '#F5F3FF',
                border: '2.5px solid #DDD6FE',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                margin: '0 auto 20px',
                position: 'relative',
                boxShadow: '0 8px 24px rgba(124, 58, 237, 0.16)',
                overflow: 'hidden',
              }}
            >
              {selectedPlace?.photo_url ? (
                <img
                  src={selectedPlace.photo_url}
                  alt={selectedPlace.name}
                  referrerPolicy="no-referrer"
                  style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                  onError={(e) => {
                    (e.currentTarget as HTMLElement).style.display = 'none';
                  }}
                />
              ) : (
                <Loader2 size={34} color="#7C3AED" style={{ animation: 'spin 1.5s linear infinite' }} />
              )}
            </div>

            <h2 style={{ fontSize: '1.45rem', fontWeight: 800, marginBottom: '6px', color: '#1E1B4B' }}>
              Checking {selectedPlace?.name || searchQuery}
            </h2>
            <p style={{ color: '#64748B', fontSize: '0.88rem', marginBottom: '28px', lineHeight: 1.45 }}>
              Checking your Google profile, nearby competitors, and customer reviews in your area...
            </p>

            {/* Progress Bar */}
            <div
              style={{
                width: '100%',
                height: '8px',
                background: '#F1EFF9',
                borderRadius: '999px',
                overflow: 'hidden',
                marginBottom: '28px',
              }}
            >
              <div
                style={{
                  height: '100%',
                  width: `${auditProgress}%`,
                  background: 'linear-gradient(90deg, #6366F1 0%, #7C3AED 50%, #A855F7 100%)',
                  borderRadius: '999px',
                  transition: 'width 0.4s ease-in-out',
                }}
              />
            </div>

            {/* Audit Checklist Steps */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: '10px', textAlign: 'left' }}>
              {AUDIT_STEPS.map((step, idx) => {
                const isCompleted = idx < auditStepIndex;
                const isCurrent = idx === auditStepIndex;

                return (
                  <div
                    key={step.id}
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      gap: '12px',
                      padding: '13px 16px',
                      borderRadius: '14px',
                      background: isCurrent ? '#FFFFFF' : isCompleted ? '#FAF9FE' : 'transparent',
                      border: isCurrent ? '1.5px solid #C4B5FD' : '1px solid #EBE8F6',
                      boxShadow: isCurrent ? '0 4px 16px rgba(124, 58, 237, 0.08)' : 'none',
                      transition: 'all 0.25s',
                    }}
                  >
                    {isCompleted ? (
                      <CheckCircle2 size={18} color="#10B981" />
                    ) : isCurrent ? (
                      <Loader2 size={18} color="#7C3AED" style={{ animation: 'spin 1s linear infinite' }} />
                    ) : (
                      <div
                        style={{
                          width: '18px',
                          height: '18px',
                          borderRadius: '50%',
                          border: '2px solid #CBD5E1',
                          boxSizing: 'border-box',
                        }}
                      />
                    )}
                    <span
                      style={{
                        fontSize: '0.9rem',
                        color: isCompleted ? '#334155' : isCurrent ? '#5B21B6' : '#94A3B8',
                        fontWeight: isCurrent ? 700 : isCompleted ? 600 : 400,
                      }}
                    >
                      {step.label}
                    </span>
                  </div>
                );
              })}
            </div>
          </div>
        ) : (
          /* Seamless Open Single-Page Form (No Boxed Login Container) */
          <div
            style={{
              width: '100%',
              maxWidth: '520px',
              margin: '0 auto',
              boxSizing: 'border-box',
            }}
          >
            {/* Clean, Open Header */}
            <div style={{ textAlign: 'center', marginBottom: '26px' }}>
              <h1
                style={{
                  fontSize: '1.55rem',
                  fontWeight: 800,
                  color: '#1E1B4B',
                  margin: '0 0 8px',
                  letterSpacing: '-0.02em',
                  lineHeight: 1.25,
                }}
              >
                Audit Your Business Visibility
              </h1>
              <p style={{ fontSize: '0.88rem', color: '#64748B', margin: 0, lineHeight: 1.45 }}>
                See your Google Maps ranking, rivals, and diverted customer calls.
              </p>
            </div>

            <form onSubmit={handleStartAudit} style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
              {/* Error Banner */}
              {errorMessage && (
                <div
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '10px',
                    padding: '12px 16px',
                    borderRadius: '12px',
                    background: '#FEF2F2',
                    border: '1px solid #FECACA',
                    color: '#B91C1C',
                    fontSize: '0.88rem',
                  }}
                >
                  <AlertTriangle size={18} color="#DC2626" />
                  <span>{errorMessage}</span>
                </div>
              )}

              {/* Step 1: Business Search Input */}
              <div style={{ position: 'relative' }} ref={dropdownRef}>
                <label
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '8px',
                    fontSize: '0.88rem',
                    fontWeight: 700,
                    color: '#1E1B4B',
                    marginBottom: '8px',
                  }}
                >
                  <span
                    style={{
                      width: '22px',
                      height: '22px',
                      borderRadius: '50%',
                      background: '#F5F3FF',
                      border: '1px solid #DDD6FE',
                      color: '#7C3AED',
                      fontSize: '0.74rem',
                      fontWeight: 800,
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                    }}
                  >
                    1
                  </span>
                  <span>Type Your Business or Shop Name</span>
                </label>

                {selectedPlace ? (
                  /* Single Unified Selected Business Card (Fixes 2-time duplicate bug) */
                  <div
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'space-between',
                      background: '#FAF8FF',
                      border: '2px solid #7C3AED',
                      borderRadius: '14px',
                      padding: '12px 16px',
                      boxShadow: '0 0 0 4px rgba(124, 58, 237, 0.12)',
                    }}
                  >
                    <div style={{ display: 'flex', alignItems: 'center', gap: '12px', minWidth: 0 }}>
                      <div style={{ position: 'relative', width: '38px', height: '38px', flexShrink: 0 }}>
                        {selectedPlace.photo_url ? (
                          <img
                            src={selectedPlace.photo_url}
                            alt={selectedPlace.name}
                            referrerPolicy="no-referrer"
                            style={{
                              width: '38px',
                              height: '38px',
                              borderRadius: '10px',
                              objectFit: 'cover',
                              border: '1.5px solid #DDD6FE',
                            }}
                            onError={(e) => {
                              (e.currentTarget as HTMLElement).style.display = 'none';
                            }}
                          />
                        ) : (
                          <div
                            style={{
                              width: '38px',
                              height: '38px',
                              borderRadius: '10px',
                              background: '#EDE9FE',
                              display: 'flex',
                              alignItems: 'center',
                              justifyContent: 'center',
                            }}
                          >
                            <Building2 size={20} color="#7C3AED" />
                          </div>
                        )}
                        <CheckCircle2
                          size={15}
                          color="#7C3AED"
                          style={{
                            position: 'absolute',
                            bottom: '-2px',
                            right: '-2px',
                            background: '#FFFFFF',
                            borderRadius: '50%',
                          }}
                        />
                      </div>
                      <div style={{ minWidth: 0 }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '6px', flexWrap: 'wrap' }}>
                          <span style={{ fontWeight: 800, color: '#1E1B4B', fontSize: '0.98rem' }}>
                            {selectedPlace.name}
                          </span>
                          {selectedPlace.category && (
                            <span
                              style={{
                                fontSize: '0.72rem',
                                color: '#6D28D9',
                                background: '#EDE9FE',
                                padding: '2px 7px',
                                borderRadius: '6px',
                                fontWeight: 600,
                              }}
                            >
                              {selectedPlace.category}
                            </span>
                          )}
                        </div>
                        {selectedPlace.address && (
                          <div
                            style={{
                              fontSize: '0.78rem',
                              color: '#64748B',
                              marginTop: '2px',
                              whiteSpace: 'nowrap',
                              overflow: 'hidden',
                              textOverflow: 'ellipsis',
                            }}
                          >
                            {selectedPlace.address}
                          </div>
                        )}
                      </div>
                    </div>

                    <button
                      type="button"
                      onClick={() => {
                        setSelectedPlace(null);
                        setSearchQuery('');
                        setSearchResults([]);
                        setShowDropdown(false);
                      }}
                      style={{
                        background: '#FFFFFF',
                        border: '1px solid #DDD6FE',
                        color: '#7C3AED',
                        fontSize: '0.82rem',
                        fontWeight: 700,
                        padding: '6px 12px',
                        borderRadius: '8px',
                        cursor: 'pointer',
                        flexShrink: 0,
                        marginLeft: '12px',
                        boxShadow: '0 1px 3px rgba(0, 0, 0, 0.05)',
                        transition: 'all 0.15s ease',
                      }}
                      onMouseOver={(e) => {
                        (e.currentTarget as HTMLElement).style.background = '#EDE9FE';
                      }}
                      onMouseOut={(e) => {
                        (e.currentTarget as HTMLElement).style.background = '#FFFFFF';
                      }}
                    >
                      Change
                    </button>
                  </div>
                ) : (
                  /* Standard Search Input (when no place is selected) */
                  <div
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      background: '#FFFFFF',
                      border: '1.5px solid #E2E8F0',
                      borderRadius: '14px',
                      padding: '0 16px',
                      boxShadow: '0 2px 8px rgba(99, 102, 241, 0.04)',
                      transition: 'all 0.2s ease',
                    }}
                  >
                    <Search size={19} color="#64748B" style={{ marginRight: '12px' }} />
                    <input
                      type="text"
                      value={searchQuery}
                      onChange={(e) => {
                        setSearchQuery(e.target.value);
                      }}
                      onFocus={() => {
                        if (searchResults.length > 0) setShowDropdown(true);
                      }}
                      placeholder="e.g., Royal Bakery & Cafe, Apollo Dental..."
                      style={{
                        width: '100%',
                        background: 'transparent',
                        border: 'none',
                        color: '#0F172A',
                        fontSize: '1rem',
                        padding: '14px 0',
                        outline: 'none',
                      }}
                    />
                    {isSearching && <Loader2 size={18} color="#7C3AED" style={{ animation: 'spin 1s linear infinite' }} />}
                  </div>
                )}

                {/* Autocomplete Dropdown with Star Ratings (hidden when a place is selected) */}
                {!selectedPlace && showDropdown && searchResults.length > 0 && (
                  <div
                    style={{
                      position: 'absolute',
                      top: 'calc(100% + 6px)',
                      left: 0,
                      right: 0,
                      background: '#FFFFFF',
                      border: '1.5px solid #E4DCF9',
                      borderRadius: '16px',
                      maxHeight: '260px',
                      overflowY: 'auto',
                      zIndex: 50,
                      boxShadow: '0 16px 36px rgba(124, 58, 237, 0.12), 0 2px 8px rgba(15, 23, 42, 0.04)',
                    }}
                  >
                    {searchResults.map((place) => (
                      <div
                        key={place.place_id}
                        onClick={() => handleSelectPlace(place)}
                        style={{
                          padding: '12px 16px',
                          borderBottom: '1px solid #F1F0FB',
                          cursor: 'pointer',
                          display: 'flex',
                          flexDirection: 'column',
                          gap: '4px',
                          transition: 'background 0.15s',
                        }}
                        onMouseOver={(e) => ((e.currentTarget as HTMLElement).style.background = '#F5F3FF')}
                        onMouseOut={(e) => ((e.currentTarget as HTMLElement).style.background = 'transparent')}
                      >
                        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '8px' }}>
                          <span style={{ fontWeight: 700, color: '#0F172A', fontSize: '0.94rem' }}>{place.name}</span>
                          {place.rating ? (
                            <span
                              style={{
                                display: 'inline-flex',
                                alignItems: 'center',
                                gap: '3px',
                                fontSize: '0.78rem',
                                color: '#D97706',
                                fontWeight: 700,
                                background: '#FFFBEB',
                                border: '1px solid #FDE68A',
                                padding: '2px 7px',
                                borderRadius: '999px',
                                flexShrink: 0,
                              }}
                            >
                              <Star size={11} fill="#F59E0B" color="#F59E0B" />
                              <span>{place.rating.toFixed(1)}</span>
                              {place.review_count !== undefined && place.review_count > 0 && (
                                <span style={{ color: '#92400E', fontWeight: 500, fontSize: '0.72rem' }}>
                                  ({place.review_count})
                                </span>
                              )}
                            </span>
                          ) : null}
                        </div>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '6px', color: '#64748B', fontSize: '0.8rem' }}>
                          <MapPin size={13} color="#7C3AED" />
                          <span style={{ whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                            {place.address || 'Local Listing'}
                          </span>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>

              {/* Optional City/Area Filter if not selected from Google Place */}
              {!selectedPlace && (
                <div>
                  <label
                    style={{
                      display: 'block',
                      fontSize: '0.84rem',
                      fontWeight: 600,
                      color: '#475569',
                      marginBottom: '6px',
                    }}
                  >
                    City / Area (Optional)
                  </label>
                  <div
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      background: '#FFFFFF',
                      border: '1.5px solid #E2E8F0',
                      borderRadius: '14px',
                      padding: '0 16px',
                      boxShadow: '0 2px 8px rgba(99, 102, 241, 0.04)',
                    }}
                  >
                    <MapPin size={18} color="#64748B" style={{ marginRight: '12px' }} />
                    <input
                      type="text"
                      value={locationQuery}
                      onChange={(e) => setLocationQuery(e.target.value)}
                      placeholder="e.g., Kochi, Bengaluru, Mumbai..."
                      style={{
                        width: '100%',
                        background: 'transparent',
                        border: 'none',
                        color: '#0F172A',
                        fontSize: '0.98rem',
                        padding: '13px 0',
                        outline: 'none',
                      }}
                    />
                  </div>
                </div>
              )}

              {/* Step 2: Phone Number Input */}
              <div>
                <label
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '8px',
                    fontSize: '0.88rem',
                    fontWeight: 700,
                    color: '#1E1B4B',
                    marginBottom: '8px',
                  }}
                >
                  <span
                    style={{
                      width: '22px',
                      height: '22px',
                      borderRadius: '50%',
                      background: '#F5F3FF',
                      border: '1px solid #DDD6FE',
                      color: '#7C3AED',
                      fontSize: '0.74rem',
                      fontWeight: 800,
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                    }}
                  >
                    2
                  </span>
                  <span>Business Phone Number</span>
                </label>

                <div style={{ display: 'flex', gap: '10px' }}>
                  {/* Country Code Selector */}
                  <select
                    value={countryCode}
                    onChange={(e) => setCountryCode(e.target.value)}
                    style={{
                      background: '#FFFFFF',
                      border: '1.5px solid #E2E8F0',
                      borderRadius: '14px',
                      color: '#0F172A',
                      padding: '13px 12px',
                      fontSize: '0.92rem',
                      fontWeight: 600,
                      outline: 'none',
                      cursor: 'pointer',
                      boxShadow: '0 2px 8px rgba(99, 102, 241, 0.04)',
                    }}
                  >
                    {COUNTRY_CODES.map((item) => (
                      <option key={item.code} value={item.code} style={{ background: '#FFFFFF', color: '#0F172A' }}>
                        {item.label}
                      </option>
                    ))}
                  </select>

                  {/* Phone Input */}
                  <div
                    style={{
                      flex: 1,
                      display: 'flex',
                      alignItems: 'center',
                      background: '#FFFFFF',
                      border: '1.5px solid #E2E8F0',
                      borderRadius: '14px',
                      padding: '0 16px',
                      boxShadow: '0 2px 8px rgba(99, 102, 241, 0.04)',
                    }}
                  >
                    <Phone size={18} color="#64748B" style={{ marginRight: '10px' }} />
                    <input
                      type="tel"
                      value={phone}
                      onChange={(e) => setPhone(e.target.value.replace(/[^0-9]/g, ''))}
                      placeholder="9876543210"
                      maxLength={12}
                      required
                      style={{
                        width: '100%',
                        background: 'transparent',
                        border: 'none',
                        color: '#0F172A',
                        fontSize: '0.98rem',
                        padding: '13px 0',
                        outline: 'none',
                      }}
                    />
                  </div>
                </div>
              </div>

              {/* Primary CTA Button */}
              <button
                type="submit"
                disabled={isAuditing}
                style={{
                  marginTop: '8px',
                  width: '100%',
                  padding: '16px 24px',
                  borderRadius: '14px',
                  background: 'linear-gradient(135deg, #6366F1 0%, #7C3AED 50%, #9333EA 100%)',
                  border: 'none',
                  color: '#FFFFFF',
                  fontSize: '1.04rem',
                  fontWeight: 800,
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: '10px',
                  boxShadow: '0 8px 24px rgba(124, 58, 237, 0.32)',
                  transition: 'all 0.15s ease',
                }}
                onMouseOver={(e) => {
                  (e.currentTarget as HTMLElement).style.transform = 'translateY(-1px)';
                  (e.currentTarget as HTMLElement).style.boxShadow = '0 12px 28px rgba(124, 58, 237, 0.42)';
                }}
                onMouseOut={(e) => {
                  (e.currentTarget as HTMLElement).style.transform = 'translateY(0)';
                  (e.currentTarget as HTMLElement).style.boxShadow = '0 8px 24px rgba(124, 58, 237, 0.32)';
                }}
              >
                <span>Audit My Business</span>
                <ArrowRight size={19} />
              </button>
            </form>
          </div>
        )}
      </main>

      {/* Modern Simple Footer */}
      <footer
        style={{
          borderTop: '1px solid #EDE9FE',
          background: '#FFFFFF',
          padding: '16px 20px',
          textAlign: 'center',
          color: '#64748B',
          fontSize: '0.8rem',
        }}
      >
        © {new Date().getFullYear()} Optigo AI. Helping local businesses get found and chosen on Google.
      </footer>

      {/* Global CSS for Animations and Mobile Responsiveness */}
      <style>{`
        @keyframes spin {
          from { transform: rotate(0deg); }
          to { transform: rotate(360deg); }
        }

        @media (max-width: 640px) {
          .onboarding-main-container {
            padding: 20px 16px 32px !important;
          }
        }
      `}</style>
    </div>
  );
};
