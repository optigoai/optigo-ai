import React, { useState, useEffect, useRef } from 'react';
import {
  Search,
  Building2,
  Store,
  Phone,
  ArrowRight,
  MapPin,
  Star,
  Loader2,
  X,
  CheckCircle2,
  AlertTriangle,
  HelpCircle,
  Lightbulb,
  Rocket,
  FileText,
  Sparkles,
  Users,
  ShieldCheck,
} from 'lucide-react';
import { leadService, PlaceSearchResult } from '../../services/leadService';
import { resolveImageUrl } from '../../services/api';
import './SinglePageOnboardingView.css';

interface SinglePageOnboardingViewProps {
  onReportReady?: (leadId: string) => void;
}

const TRUSTED_BUSINESSES = [
  { name: 'Casa Raza Restaurant', logo: '/casaraza_restaurant.png' },
  { name: 'Chinese Wok', logo: '/chinese_wok.png' },
  { name: "Fahin's Interiors", logo: '/Fahins_Interiors.png' },
  { name: 'Focus Eye Hospital', logo: '/focus_eye_hospital.png' },
  { name: 'Mouzy Avilmilk', logo: '/mouzy_avilmilk.png' },
  { name: 'RVS Cleaning Service', logo: '/rvs_cleaning_service.png' },
];

export const SinglePageOnboardingView: React.FC<SinglePageOnboardingViewProps> = ({ onReportReady }) => {
  // Form State
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedPlace, setSelectedPlace] = useState<PlaceSearchResult | null>(null);
  const [searchResults, setSearchResults] = useState<PlaceSearchResult[]>([]);
  const [isSearching, setIsSearching] = useState(false);
  const [showDropdown, setShowDropdown] = useState(false);

  // Phone State (10 digits)
  const [phone, setPhone] = useState('');

  // Execution State
  const [isAuditing, setIsAuditing] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const searchTimeoutRef = useRef<any>(null);
  const searchSeqRef = useRef<number>(0);
  const dropdownRef = useRef<HTMLDivElement | null>(null);

  // Debounced Place Search (Google Places API Autocomplete)
  useEffect(() => {
    if (searchTimeoutRef.current) clearTimeout(searchTimeoutRef.current);

    const q = searchQuery.trim();
    if (q.length < 3 || selectedPlace) {
      setSearchResults([]);
      setShowDropdown(false);
      setIsSearching(false);
      return;
    }

    searchTimeoutRef.current = setTimeout(async () => {
      const currentSeq = ++searchSeqRef.current;
      setIsSearching(true);
      try {
        const results = await leadService.searchPlaces(q);
        if (currentSeq === searchSeqRef.current) {
          setSearchResults(results || []);
          setShowDropdown((results || []).length > 0);
        }
      } catch {
        if (currentSeq === searchSeqRef.current) {
          setSearchResults([]);
          setShowDropdown(false);
        }
      } finally {
        if (currentSeq === searchSeqRef.current) {
          setIsSearching(false);
        }
      }
    }, 450);

    return () => clearTimeout(searchTimeoutRef.current);
  }, [searchQuery, selectedPlace]);

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

  const resetFormState = () => {
    setIsAuditing(false);
    setSelectedPlace(null);
    setSearchQuery('');
    setSearchResults([]);
    setShowDropdown(false);
    setPhone('');
    setErrorMessage(null);
  };

  // Reset form and cancel loading whenever page is restored from bfcache or shown
  useEffect(() => {
    const handlePageShow = () => {
      resetFormState();
    };

    const handlePageHide = () => {
      resetFormState();
    };

    window.addEventListener('pageshow', handlePageShow);
    window.addEventListener('pagehide', handlePageHide);
    return () => {
      window.removeEventListener('pageshow', handlePageShow);
      window.removeEventListener('pagehide', handlePageHide);
    };
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
      setErrorMessage('Please enter your business name.');
      return;
    }

    const cleanDigits = phone.trim().replace(/\D/g, '');
    // Allow standard 10-digit mobile number
    const nationalDigits = cleanDigits.startsWith('91') && cleanDigits.length === 12
      ? cleanDigits.slice(2)
      : cleanDigits;

    if (nationalDigits.length !== 10) {
      setErrorMessage('Please enter a valid 10-digit mobile number.');
      return;
    }

    setIsAuditing(true);

    try {
      let inferredAddress = selectedPlace?.address || '';
      if (!inferredAddress && businessName.includes(',')) {
        const parts = businessName.split(',').map((s) => s.trim());
        if (parts.length > 1) {
          inferredAddress = parts.slice(1).join(', ');
        }
      }

      // 1. Create lead record
      const lead = await leadService.createLead({
        business_name: businessName,
        place_id: selectedPlace?.place_id,
        phone: `+91${nationalDigits}`,
        country_code: '+91',
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

      // 2. Navigate immediately to report page
      const reportUrl = `/report/${lead.id}?generating=true`;
      if (onReportReady) {
        onReportReady(lead.id);
      } else {
        window.location.href = reportUrl;
      }

      setTimeout(() => {
        resetFormState();
      }, 100);
    } catch (err: any) {
      setIsAuditing(false);
      setErrorMessage(err?.message || 'Unable to start the business audit. Please try again.');
    }
  };

  return (
    <div className="onboard-mockup-viewport">
      {/* Top Header Navigation */}
      <header className="onboard-header-bar">
        {/* Brand Logo & Tagline matching mockup */}
        <div className="onboard-brand-container">
          <div className="onboard-brand-row">
            <img
              src="/optigoai-logo.png"
              alt="OptigoAI"
              className="onboard-brand-logo-img"
            />
            <div className="onboard-brand-title">
              <span className="onboard-brand-title-optigo">Optigo</span>
              <span className="onboard-brand-title-ai"> AI</span>
            </div>
          </div>
        </div>

        {/* Help Button (Pill button with question circle icon) */}
        <a
          href="tel:+917909188271"
          className="onboard-help-pill-btn"
          title="Customer Help: +91 7909188271"
          aria-label="Customer Help"
        >
          <HelpCircle size={16} className="onboard-help-icon" />
          <span className="onboard-help-text">Help</span>
        </a>
      </header>

      <div className="onboard-mockup-canvas">
        {/* Hero Section */}
        <div className="onboard-hero-area">
          <div className="onboard-hero-title-wrap">
            <h1 className="onboard-main-title">
              Get Your Free<br />
              <span className="onboard-title-purple">Business Audit</span>
            </h1>
          </div>
          <p className="onboard-hero-tagline">
            Let AI find new ways to grow your business
          </p>
        </div>

        {/* Three Circular Feature Badges */}
        <div className="onboard-features-grid">
          {/* Feature 1: Find Opportunities */}
          <div className="onboard-feature-card">
            <div className="onboard-feature-circle">
              <svg width="22" height="22" viewBox="0 0 24 24" fill="currentColor" className="onboard-feature-icon">
                <rect x="2.5" y="13" width="4.5" height="9" rx="2.25" />
                <rect x="9.75" y="7" width="4.5" height="15" rx="2.25" />
                <rect x="17" y="2" width="4.5" height="20" rx="2.25" />
              </svg>
            </div>
            <span className="onboard-feature-label">
              Find<br />Opportunities
            </span>
          </div>

          {/* Feature 2: Get Simple Recommendations */}
          <div className="onboard-feature-card">
            <div className="onboard-feature-circle">
              <Lightbulb size={24} className="onboard-feature-icon" />
            </div>
            <span className="onboard-feature-label">
              Get Simple<br />Recommendations
            </span>
          </div>

          {/* Feature 3: Grow Faster */}
          <div className="onboard-feature-card">
            <div className="onboard-feature-circle">
              <Rocket size={24} className="onboard-feature-icon" />
            </div>
            <span className="onboard-feature-label">
              Grow<br />Faster
            </span>
          </div>
        </div>

        {/* White Elevated Form Card */}
        <div className="onboard-form-card">
          <form onSubmit={handleStartAudit} className="onboard-card-form" autoComplete="off">
            {/* Error Message */}
            {errorMessage && (
              <div className="onboard-error-alert">
                <AlertTriangle size={17} color="#DC2626" />
                <span>{errorMessage}</span>
              </div>
            )}

            {/* Field 1: Business Name */}
            <div className="onboard-form-row">
              <div className="onboard-field-icon-badge">
                <Store size={20} className="onboard-field-icon" />
              </div>
              <div className="onboard-field-content" ref={dropdownRef}>
                <label className="onboard-field-title">Business Name</label>

                {selectedPlace ? (
                  <div className="onboard-pill-selected">
                    <div className="onboard-pill-info">
                      <span className="onboard-pill-name">{selectedPlace.name}</span>
                      {selectedPlace.address && (
                        <span className="onboard-pill-address">{selectedPlace.address}</span>
                      )}
                    </div>
                    <button
                      type="button"
                      onClick={() => {
                        setSelectedPlace(null);
                        setSearchQuery('');
                        setSearchResults([]);
                        setShowDropdown(false);
                      }}
                      className="onboard-pill-change-btn"
                    >
                      Change
                    </button>
                  </div>
                ) : (
                  <div className="onboard-text-input-wrap">
                    <input
                      type="text"
                      value={searchQuery}
                      autoComplete="off"
                      onChange={(e) => setSearchQuery(e.target.value)}
                      onFocus={() => {
                        if (searchResults.length > 0) setShowDropdown(true);
                      }}
                      placeholder="e.g. Paragon Restaurant"
                      className="onboard-text-input"
                    />
                    {isSearching && (
                      <Loader2 size={16} className="onboard-input-spinner" />
                    )}
                    {!isSearching && searchQuery.length > 0 && (
                      <button
                        type="button"
                        onClick={() => {
                          setSearchQuery('');
                          setSearchResults([]);
                          setShowDropdown(false);
                        }}
                        className="onboard-input-clear-btn"
                        aria-label="Clear"
                      >
                        <X size={14} />
                      </button>
                    )}
                  </div>
                )}

                {/* Autocomplete Dropdown */}
                {!selectedPlace && showDropdown && searchResults.length > 0 && (
                  <div className="onboard-dropdown-menu">
                    {searchResults.map((place) => (
                      <div
                        key={place.place_id}
                        onClick={() => handleSelectPlace(place)}
                        className="onboard-dropdown-item"
                      >
                        <div className="onboard-item-thumb">
                          {resolveImageUrl(place.photo_url) ? (
                            <img
                              src={resolveImageUrl(place.photo_url)}
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
                          <div className="onboard-item-header">
                            <span className="onboard-item-name">{place.name}</span>
                            {place.rating ? (
                              <span className="onboard-item-stars">
                                <Star size={11} fill="#F59E0B" color="#F59E0B" />
                                <span>{place.rating.toFixed(1)}</span>
                                {place.review_count !== undefined && place.review_count > 0 && (
                                  <span className="onboard-item-count">
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
            </div>

            {/* Field 2: Phone Number */}
            <div className="onboard-form-row">
              <div className="onboard-field-icon-badge">
                <Phone size={20} className="onboard-field-icon" />
              </div>
              <div className="onboard-field-content">
                <label className="onboard-field-title">Phone Number</label>
                <div className="onboard-text-input-wrap">
                  <input
                    type="tel"
                    value={phone}
                    autoComplete="tel-national"
                    onChange={(e) => {
                      // Keep only digits, up to 10
                      const digits = e.target.value.replace(/\D/g, '').slice(0, 10);
                      setPhone(digits);
                      if (errorMessage) setErrorMessage(null);
                    }}
                    placeholder="e.g. 7909188271"
                    maxLength={10}
                    inputMode="numeric"
                    className="onboard-text-input"
                  />
                  {phone.length === 10 && (
                    <CheckCircle2 size={16} color="#16A34A" style={{ flexShrink: 0 }} />
                  )}
                </div>
              </div>
            </div>

            {/* Submit Audit Button */}
            <button
              type="submit"
              disabled={isAuditing}
              className="onboard-submit-pill-btn"
            >
              {isAuditing ? (
                <>
                  <Loader2 size={18} className="onboard-btn-spinner" />
                  <span>Submitting Audit...</span>
                </>
              ) : (
                <>
                  <span>Submit Audit</span>
                  <ArrowRight size={18} className="onboard-submit-arrow" />
                </>
              )}
            </button>
          </form>
        </div>

        {/* Social Proof Section Below Card */}
        <div className="onboard-social-proof-section">
          <h2 className="onboard-proof-headline">
            1,000+ Businesses Onboarded
          </h2>
          <p className="onboard-proof-subtext">
            Trusted by businesses like yours
          </p>

          {/* Floating Horizontal Business Logos */}
          <div className="onboard-logos-carousel-wrap">
            <div className="onboard-logos-track">
              {[...TRUSTED_BUSINESSES, ...TRUSTED_BUSINESSES].map((biz, idx) => (
                <div key={`${biz.name}-${idx}`} className="onboard-logo-card" title={biz.name}>
                  <img
                    src={biz.logo}
                    alt={biz.name}
                    loading="lazy"
                    className="onboard-logo-img"
                  />
                </div>
              ))}
            </div>
          </div>

          {/* Slider bar indicator matching mockup */}
          <div className="onboard-slider-track">
            <div className="onboard-slider-thumb" />
          </div>
        </div>

        {/* "What happens next?" Section matching mockup */}
        <section className="onboard-next-steps-section">
          <h2 className="onboard-next-headline">What happens next?</h2>
          <p className="onboard-next-subtext">It's quick and easy. Here's how it works:</p>

          {/* 3-Step Process List with dotted timeline */}
          <div className="onboard-steps-timeline">
            <div className="onboard-timeline-line" />

            {/* Step 1 */}
            <div className="onboard-step-row">
              <div className="onboard-step-badge">1</div>
              <div className="onboard-step-icon-circle">
                <Search size={20} className="onboard-step-icon" />
              </div>
              <div className="onboard-step-content">
                <h3 className="onboard-step-heading">We review your business</h3>
                <p className="onboard-step-description">Our AI analyzes your online presence</p>
              </div>
            </div>

            {/* Step 2 */}
            <div className="onboard-step-row">
              <div className="onboard-step-badge">2</div>
              <div className="onboard-step-icon-circle">
                <FileText size={20} className="onboard-step-icon" />
              </div>
              <div className="onboard-step-content">
                <h3 className="onboard-step-heading">AI finds growth opportunities</h3>
                <p className="onboard-step-description">Get clear, personalized recommendations</p>
              </div>
            </div>

            {/* Step 3 */}
            <div className="onboard-step-row">
              <div className="onboard-step-badge">3</div>
              <div className="onboard-step-icon-circle">
                <Sparkles size={20} className="onboard-step-icon" />
              </div>
              <div className="onboard-step-content">
                <h3 className="onboard-step-heading">You get practical next steps</h3>
                <p className="onboard-step-description">Simple actions to grow your business</p>
              </div>
            </div>
          </div>

          {/* Example Audit Preview Card */}
          <div className="onboard-preview-card">
            <div className="onboard-preview-header">
              <span className="onboard-preview-title">Example audit preview</span>
              <span className="onboard-preview-pill">Sample Report</span>
            </div>

            {/* 3 Metric Preview Boxes */}
            <div className="onboard-preview-metrics-grid">
              {/* Metric 1: Online Presence */}
              <div className="onboard-metric-card">
                <div className="onboard-metric-icon-wrap onboard-metric-green">
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
                    <rect x="3" y="13" width="4.5" height="9" rx="2.25" />
                    <rect x="10" y="8" width="4.5" height="14" rx="2.25" />
                    <rect x="17" y="3" width="4.5" height="19" rx="2.25" />
                  </svg>
                </div>
                <span className="onboard-metric-label">Online Presence</span>
                <span className="onboard-metric-val onboard-val-green">Good</span>
                <div className="onboard-metric-bar-track">
                  <div className="onboard-metric-bar-fill onboard-fill-green" style={{ width: '70%' }} />
                </div>
              </div>

              {/* Metric 2: Customer Reach */}
              <div className="onboard-metric-card">
                <div className="onboard-metric-icon-wrap onboard-metric-amber">
                  <Users size={18} />
                </div>
                <span className="onboard-metric-label">Customer Reach</span>
                <span className="onboard-metric-val onboard-val-amber">Needs Improvement</span>
                <div className="onboard-metric-bar-track">
                  <div className="onboard-metric-bar-fill onboard-fill-amber" style={{ width: '45%' }} />
                </div>
              </div>

              {/* Metric 3: Growth Ideas */}
              <div className="onboard-metric-card">
                <div className="onboard-metric-icon-wrap onboard-metric-purple">
                  <Lightbulb size={18} />
                </div>
                <span className="onboard-metric-label">Growth Ideas</span>
                <span className="onboard-metric-val onboard-val-purple">5+ Opportunities</span>
                <div className="onboard-metric-bar-track">
                  <div className="onboard-metric-bar-fill onboard-fill-purple" style={{ width: '60%' }} />
                </div>
              </div>
            </div>

            {/* CTA Button: Start My Free Audit */}
            <button
              type="button"
              onClick={() => {
                window.scrollTo({ top: 0, behavior: 'smooth' });
                setTimeout(() => {
                  const input = document.querySelector<HTMLInputElement>('.onboard-text-input');
                  if (input) input.focus();
                }, 350);
              }}
              className="onboard-preview-cta-btn"
            >
              <span>Start My Free Audit</span>
              <ArrowRight size={18} className="onboard-submit-arrow" />
            </button>

            {/* Trust Footer below button */}
            <div className="onboard-preview-trust">
              <ShieldCheck size={16} className="onboard-trust-shield-icon" />
              <span>Join 1,000+ businesses growing with OptigoAI</span>
            </div>
          </div>
        </section>

        {/* Bottom Tagline matching mockup */}
        <div className="onboard-tagline-footer">
          <span className="onboard-tagline-line1">BETTER BUSINESSES</span>
          <span className="onboard-tagline-line2">A BRIGHTER TOMORROW</span>
        </div>
      </div>
    </div>
  );
};

