// ==================================================
// OptigoAI Enterprise — Prody Light Onboarding View
// ==================================================

import React, { useState } from 'react';
import { useAuth } from '../../context/AuthContext';
import { useFranchise } from '../../context/FranchiseContext';
import { useLocation } from '../../context/LocationContext';
import { businessService } from '../../services/businessService';
import {
  Building2,
  MapPin,
  ArrowRight,
  ArrowLeft,
  CheckCircle2,
  Globe,
  Phone,
  Sparkles,
} from 'lucide-react';

interface BusinessOnboardingViewProps {
  onComplete?: () => void;
}

const CATEGORIES = [
  'Restaurant / Cafe',
  'Local Manufacturing & Mill',
  'Retail / Supermarket',
  'Health & Wellness',
  'Professional Services',
  'Automotive & Repair',
  'Beauty & Salon',
  'Real Estate & Construction',
  'Education & Coaching',
  'Other Local Business',
];

const LOCATION_SUGGESTIONS = [
  'Bengaluru, India',
  'Ponnani, Kerala',
  'Edappal, Kerala, India',
  'Mumbai, India',
  'Delhi NCR, India',
  'Kochi, Kerala',
  'Chennai, India',
  'Hyderabad, India',
  'Dubai, UAE',
  'Singapore',
];

export const BusinessOnboardingView: React.FC<BusinessOnboardingViewProps> = ({ onComplete }) => {
  const { user, organization } = useAuth();
  const { refreshFranchiseData } = useFranchise();
  const { selectLocation } = useLocation();

  const [step, setStep] = useState<1 | 2 | 3>(1);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Step 1: Basic Info
  const [name, setName] = useState('');
  const [category, setCategory] = useState(CATEGORIES[0]);
  const [location, setLocation] = useState('Edappal, Kerala, India');
  const [website, setWebsite] = useState('');
  const [phone, setPhone] = useState('');
  const [description, setDescription] = useState('');

  // Step 2: Target Audience & Services
  const [targetCustomers, setTargetCustomers] = useState('');
  const [services, setServices] = useState('');

  // Step 3: Goals & Marketing Channels
  const [businessGoals, setBusinessGoals] = useState('');
  const [marketingChannels, setMarketingChannels] = useState('');

  const handleNext = () => {
    setError(null);
    if (step === 1) {
      if (!name.trim()) {
        setError('Please enter your business or branch name.');
        return;
      }
      if (!location.trim()) {
        setError('Please enter your business location.');
        return;
      }
      setStep(2);
    } else if (step === 2) {
      setStep(3);
    }
  };

  const handleBack = () => {
    setError(null);
    if (step > 1) {
      setStep((step - 1) as any);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setIsSubmitting(true);

    try {
      // 1. Create the base business in PostgreSQL
      const created = await businessService.createBusiness({
        name: name.trim(),
        category,
        location: location.trim(),
        website: website.trim() || undefined,
        phone: phone.trim() || undefined,
        description: description.trim() || undefined,
      });

      // 2. Persist the onboarding questionnaire (Step 2 and Step 3)
      try {
        await businessService.submitOnboarding(created.id, {
          services: services.trim() || undefined,
          target_customers: targetCustomers.trim() || undefined,
          business_goals: businessGoals.trim() || undefined,
          marketing_channels: marketingChannels.trim() || undefined,
        });
      } catch {
        // Continue even if secondary questionnaire is optional
      }

      // 3. Trigger initial live GBP data synchronization
      try {
        await businessService.syncGBP(created.id);
      } catch {
        // Async background task
      }

      await refreshFranchiseData();
      selectLocation(created.id);

      if (onComplete) {
        onComplete();
      }
    } catch (err: any) {
      setError(err.message || 'Failed to save business profile. Please try again.');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div
      style={{
        width: '100vw',
        minHeight: '100vh',
        backgroundColor: '#F9FAFB',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        padding: '32px 20px',
      }}
    >
      <div
        className="prody-card"
        style={{
          width: '100%',
          maxWidth: '580px',
          padding: '32px 30px',
          backgroundColor: '#FFFFFF',
          boxShadow: 'var(--shadow-card)',
        }}
      >
        {/* Header */}
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '20px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <div
              style={{
                width: '36px',
                height: '36px',
                borderRadius: '10px',
                backgroundColor: '#111827',
                color: '#FFFFFF',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontWeight: 800,
                fontSize: '1.1rem',
              }}
            >
              O
            </div>
            <div>
              <h2 style={{ fontSize: '1.25rem', fontWeight: 800, color: '#111827', letterSpacing: '-0.02em', lineHeight: 1.2 }}>
                Connect Branch Location
              </h2>
              <span style={{ fontSize: '0.78rem', color: '#6B7280' }}>
                {organization?.name || 'OptigoAI Enterprise'}
              </span>
            </div>
          </div>

          <span className="prody-pill blue">
            Step {step} of 3
          </span>
        </div>

        {/* Progress Bar */}
        <div style={{ height: '4px', backgroundColor: '#F3F4F6', borderRadius: '2px', overflow: 'hidden', marginBottom: '22px' }}>
          <div
            style={{
              width: `${(step / 3) * 100}%`,
              height: '100%',
              backgroundColor: '#E11D48',
              borderRadius: '2px',
              transition: 'width 0.25s ease',
            }}
          />
        </div>

        {error && (
          <div
            style={{
              padding: '8px 12px',
              backgroundColor: '#FFE4E6',
              border: '1px solid #FECDD3',
              borderRadius: 'var(--radius-sm)',
              color: '#BE123C',
              fontSize: '0.78rem',
              fontWeight: 600,
              marginBottom: '16px',
            }}
          >
            {error}
          </div>
        )}

        {/* Step 1: Business Basics */}
        {step === 1 && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
            <div className="input-group">
              <label className="input-label">Official Business Name on Google Maps *</label>
              <input
                type="text"
                className="optigo-input"
                placeholder="e.g. Casaraza Restaurant"
                value={name}
                onChange={(e) => setName(e.target.value)}
                required
              />
            </div>

            <div className="input-group">
              <label className="input-label">Primary Business Category *</label>
              <select
                className="optigo-input"
                value={category}
                onChange={(e) => setCategory(e.target.value)}
              >
                {CATEGORIES.map((cat) => (
                  <option key={cat} value={cat}>
                    {cat}
                  </option>
                ))}
              </select>
            </div>

            <div className="input-group">
              <label className="input-label">Business Location / City *</label>
              <input
                type="text"
                className="optigo-input"
                placeholder="e.g. Edappal, Kerala, India"
                value={location}
                onChange={(e) => setLocation(e.target.value)}
                required
              />
              <div style={{ display: 'flex', flexWrap: 'wrap', gap: '4px', marginTop: '4px' }}>
                {LOCATION_SUGGESTIONS.slice(0, 4).map((loc) => (
                  <button
                    key={loc}
                    type="button"
                    onClick={() => setLocation(loc)}
                    style={{
                      padding: '2px 7px',
                      borderRadius: '4px',
                      border: '1px solid var(--border-subtle)',
                      backgroundColor: '#F9FAFB',
                      color: '#4B5563',
                      fontSize: '0.7rem',
                      cursor: 'pointer',
                    }}
                  >
                    {loc}
                  </button>
                ))}
              </div>
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
              <div className="input-group">
                <label className="input-label">Phone Number</label>
                <input
                  type="text"
                  className="optigo-input"
                  placeholder="+91 98460 12345"
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                />
              </div>

              <div className="input-group">
                <label className="input-label">Website URL</label>
                <input
                  type="url"
                  className="optigo-input"
                  placeholder="https://casaraza.com"
                  value={website}
                  onChange={(e) => setWebsite(e.target.value)}
                />
              </div>
            </div>

            <div className="input-group">
              <label className="input-label">Business Overview</label>
              <textarea
                className="optigo-input"
                rows={2}
                placeholder="Brief description of this branch location..."
                value={description}
                onChange={(e) => setDescription(e.target.value)}
              />
            </div>
          </div>
        )}

        {/* Step 2: Target Customers & Offerings */}
        {step === 2 && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
            <div className="input-group">
              <label className="input-label">Key Services & Offerings</label>
              <textarea
                className="optigo-input"
                rows={3}
                placeholder="e.g. Fine Dining, Private Suites, Family Hall, Catering, Buffet"
                value={services}
                onChange={(e) => setServices(e.target.value)}
              />
            </div>

            <div className="input-group">
              <label className="input-label">Target Customer Demographics</label>
              <textarea
                className="optigo-input"
                rows={3}
                placeholder="e.g. Families, highway travelers, wedding groups, food enthusiasts"
                value={targetCustomers}
                onChange={(e) => setTargetCustomers(e.target.value)}
              />
            </div>
          </div>
        )}

        {/* Step 3: Goals & Confirmation */}
        {step === 3 && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
            <div className="input-group">
              <label className="input-label">Primary Business & Visibility Goals</label>
              <input
                type="text"
                className="optigo-input"
                placeholder="e.g. #1 Google Maps ranking, increase customer calls & bookings"
                value={businessGoals}
                onChange={(e) => setBusinessGoals(e.target.value)}
              />
            </div>

            <div className="input-group">
              <label className="input-label">Active Marketing Channels</label>
              <input
                type="text"
                className="optigo-input"
                placeholder="e.g. Google Business Profile, Instagram, Local Word of Mouth"
                value={marketingChannels}
                onChange={(e) => setMarketingChannels(e.target.value)}
              />
            </div>

            <div
              style={{
                padding: '12px 14px',
                backgroundColor: '#F9FAFB',
                border: '1px solid var(--border-subtle)',
                borderRadius: 'var(--radius-sm)',
                fontSize: '0.82rem',
                marginTop: '4px',
              }}
            >
              <div style={{ fontWeight: 700, color: '#111827', marginBottom: '2px' }}>
                Summary: {name || 'New Location'} ({category})
              </div>
              <div style={{ color: '#6B7280' }}>Location: {location}</div>
            </div>
          </div>
        )}

        {/* Action Controls */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: '24px', paddingTop: '16px', borderTop: '1px solid var(--border-subtle)' }}>
          {step > 1 ? (
            <button type="button" onClick={handleBack} className="btn btn-secondary btn-sm" style={{ gap: '6px' }}>
              <ArrowLeft size={13} />
              <span>Back</span>
            </button>
          ) : (
            <div />
          )}

          {step < 3 ? (
            <button type="button" onClick={handleNext} className="btn btn-coral btn-sm" style={{ gap: '6px' }}>
              <span>Continue</span>
              <ArrowRight size={13} />
            </button>
          ) : (
            <button
              type="button"
              onClick={handleSubmit}
              disabled={isSubmitting}
              className="btn btn-coral btn-sm"
              style={{ gap: '6px' }}
            >
              <span>{isSubmitting ? 'Connecting...' : 'Launch Location Profile'}</span>
              <CheckCircle2 size={14} />
            </button>
          )}
        </div>
      </div>
    </div>
  );
};
