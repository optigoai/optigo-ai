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
import './SinglePageOnboardingView.css';

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

  // Debounced Place Search (Google Places API Autocomplete)
  useEffect(() => {
    if (searchTimeoutRef.current) clearTimeout(searchTimeoutRef.current);

    const q = searchQuery.trim();
    if (q.length < 2 || selectedPlace) {
      setSearchResults([]);
      setShowDropdown(false);
      return;
    }

    setIsSearching(true);
    searchTimeoutRef.current = setTimeout(async () => {
      try {
        const results = await leadService.searchPlaces(q, locationQuery.trim() || undefined);
        setSearchResults(results || []);
        setShowDropdown((results || []).length > 0);
      } catch {
        setSearchResults([]);
        setShowDropdown(false);
      } finally {
        setIsSearching(false);
      }
    }, 350);

    return () => clearTimeout(searchTimeoutRef.current);
  }, [searchQuery, locationQuery, selectedPlace]);

  // Click outside to dismiss dropdown
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
    setSelectedPlace(place);
    setSearchQuery(place.name);
    setShowDropdown(false);
    setErrorMessage(null);
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

    try {
      // Extract locality if business name was typed with a comma (e.g. "Casa Rasa Family Restaurant, Edappal")
      let inferredAddress = selectedPlace?.address || locationQuery || '';
      if (!inferredAddress && businessName.includes(',')) {
        const parts = businessName.split(',').map((s) => s.trim());
        if (parts.length > 1) {
          inferredAddress = parts.slice(1).join(', ');
        }
      }

      // 1. Create or update lead record
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

      // 2. Navigate immediately to report page with in-page generation flow
      if (onReportReady) {
        onReportReady(lead.id);
      } else {
        window.location.href = `/report/${lead.id}?generating=true`;
      }
    } catch (err: any) {
      setIsAuditing(false);
      setErrorMessage(err?.message || 'Unable to start the business audit. Please try again.');
    }
  };

  return (
    <div className="onboard-page-wrapper">
      {/* Background Subtle Luminous Glow */}
      <div className="onboard-ambient-glow" />

      {/* Top Header */}
      <header className="onboard-nav-header">
        <div className="onboard-brand">
          <img src={optigoLogo} alt="Optigo AI" className="onboard-brand-logo" />
          <span className="onboard-brand-name">
            Optigo<span className="onboard-brand-accent">AI</span>
          </span>
        </div>

        <div>
          <a href="/login" className="onboard-login-btn">
            Customer Login →
          </a>
        </div>
      </header>

      {/* Main Content Area */}
      <main className="onboard-main-shell">
        <div className="onboard-card-container">
          {/* Clean, Open Header */}
          <div className="onboard-header-block">
            <h1 className="onboard-title">
              Audit Your Business <span className="onboard-title-gradient">Visibility</span>
            </h1>
            <p className="onboard-subtitle">
              See your Google Maps ranking, rivals, and diverted customer calls.
            </p>
          </div>

            <form onSubmit={handleStartAudit} className="onboard-form">
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
                <label className="onboard-step-label">
                  <span className="onboard-step-badge">1</span>
                  <span>Type Your Business or Shop Name</span>
                </label>

                {selectedPlace ? (
                  /* Single Unified Selected Business Card (Fixes 2-time duplicate bug) */
                  <div className="onboard-selected-card">
                    <div className="onboard-selected-info">
                      <div className="onboard-selected-thumb">
                        {selectedPlace.photo_url ? (
                          <img
                            src={selectedPlace.photo_url}
                            alt={selectedPlace.name}
                            referrerPolicy="no-referrer"
                            onError={(e) => {
                              (e.currentTarget as HTMLElement).style.display = 'none';
                            }}
                          />
                        ) : (
                          <Building2 size={20} color="#7C3AED" />
                        )}
                        <CheckCircle2
                          size={14}
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
                      <div className="onboard-selected-texts">
                        <div className="onboard-selected-title-row">
                          <span className="onboard-selected-name">
                            {selectedPlace.name}
                          </span>
                          {selectedPlace.category && (
                            <span className="onboard-selected-cat">
                              {selectedPlace.category}
                            </span>
                          )}
                        </div>
                        {selectedPlace.address && (
                          <div className="onboard-selected-addr">
                            <MapPin size={12} color="#7C3AED" />
                            <span>{selectedPlace.address}</span>
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
                      className="onboard-change-btn"
                    >
                      Change
                    </button>
                  </div>
                ) : (
                  /* Standard Search Input (when no place is selected) */
                  <div className="onboard-input-box">
                    <Search size={18} className="onboard-input-icon" />
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
                    />
                    {isSearching && <Loader2 size={18} color="#7C3AED" style={{ animation: 'spin 1s linear infinite' }} />}
                  </div>
                )}

                {/* Autocomplete Dropdown with Star Ratings (hidden when a place is selected) */}
                {!selectedPlace && showDropdown && searchResults.length > 0 && (
                  <div className="onboard-dropdown-menu">
                    {searchResults.map((place) => (
                      <div
                        key={place.place_id}
                        onClick={() => handleSelectPlace(place)}
                        className="onboard-dropdown-item"
                      >
                        <div className="onboard-item-thumb">
                          {place.photo_url ? (
                            <img
                              src={place.photo_url}
                              alt={place.name}
                              referrerPolicy="no-referrer"
                              onError={(e) => {
                                (e.currentTarget as HTMLElement).style.display = 'none';
                              }}
                            />
                          ) : (
                            <Building2 size={16} color="#7C3AED" />
                          )}
                        </div>
                        <div className="onboard-item-details">
                          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '6px' }}>
                            <span className="onboard-item-name">{place.name}</span>
                            {place.rating ? (
                              <span className="onboard-item-stars">
                                <Star size={11} fill="#F59E0B" color="#F59E0B" />
                                <span>{place.rating.toFixed(1)}</span>
                                {place.review_count !== undefined && place.review_count > 0 && (
                                  <span style={{ color: '#94A3B8', fontWeight: 500, fontSize: '0.7rem' }}>
                                    ({place.review_count})
                                  </span>
                                )}
                              </span>
                            ) : null}
                          </div>
                          <div className="onboard-item-meta">
                            <MapPin size={11} color="#7C3AED" />
                            <span className="onboard-item-addr">{place.address || 'Local Listing'}</span>
                          </div>
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
                      marginBottom: '8px',
                    }}
                  >
                    City / Area (Optional)
                  </label>
                  <div className="onboard-input-box">
                    <MapPin size={18} className="onboard-input-icon" />
                    <input
                      type="text"
                      value={locationQuery}
                      onChange={(e) => setLocationQuery(e.target.value)}
                      placeholder="e.g., Kochi, Bengaluru, Mumbai..."
                    />
                  </div>
                </div>
              )}

              {/* Step 2: Phone Number Input */}
              <div>
                <label className="onboard-step-label">
                  <span className="onboard-step-badge">2</span>
                  <span>Business Phone Number</span>
                </label>

                <div className="onboard-phone-row">
                  {/* Country Code Selector */}
                  <select
                    value={countryCode}
                    onChange={(e) => setCountryCode(e.target.value)}
                    className="onboard-country-select"
                  >
                    {COUNTRY_CODES.map((item) => (
                      <option key={item.code} value={item.code}>
                        {item.label}
                      </option>
                    ))}
                  </select>

                  {/* Phone Input */}
                  <div className="onboard-input-box" style={{ flex: 1 }}>
                    <Phone size={18} className="onboard-input-icon" />
                    <input
                      type="tel"
                      value={phone}
                      onChange={(e) => setPhone(e.target.value.replace(/[^0-9]/g, ''))}
                      placeholder="9876543210"
                      maxLength={12}
                      required
                    />
                  </div>
                </div>
              </div>

              {/* Primary CTA Button */}
              <button
                type="submit"
                disabled={isAuditing}
                className="onboard-submit-btn"
              >
                {isAuditing ? (
                  <>
                    <Loader2 size={19} color="#FFFFFF" style={{ animation: 'spin 1s linear infinite' }} />
                    <span>Opening Audit Report...</span>
                  </>
                ) : (
                  <>
                    <span>Audit My Business</span>
                    <ArrowRight size={19} />
                  </>
                )}
              </button>
            </form>
          </div>
        </main>

      {/* Modern Simple Footer */}
      <footer className="onboard-footer">
        © {new Date().getFullYear()} Optigo AI. Helping local businesses get found and chosen on Google.
      </footer>
    </div>
  );
};
