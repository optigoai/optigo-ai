// ==================================================
// OptigoAI Enterprise — Prody Light Minimalist Login
// ==================================================

import React, { useState } from 'react';
import { useAuth } from '../../context/AuthContext';
import { Building2, Lock, Mail, ArrowRight } from 'lucide-react';

interface LoginViewProps {
  onNavigateSignup: () => void;
}

export const LoginView: React.FC<LoginViewProps> = ({ onNavigateSignup }) => {
  const { login, isLoading } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    if (!email.trim() || !password.trim()) {
      setError('Please enter your email and password.');
      return;
    }
    try {
      await login(email.trim(), password);
    } catch (err: any) {
      setError(err.message || 'Incorrect email or password. Please try again.');
    }
  };

  return (
    <div
      style={{
        width: '100vw',
        height: '100vh',
        backgroundColor: '#F9FAFB',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        padding: '20px',
      }}
    >
      <div
        className="prody-card"
        style={{
          width: '100%',
          maxWidth: '400px',
          padding: '32px 28px',
          backgroundColor: '#FFFFFF',
          boxShadow: 'var(--shadow-card)',
        }}
      >
        {/* Brand Header */}
        <div style={{ textAlign: 'center', marginBottom: '24px' }}>
          <div
            style={{
              width: '40px',
              height: '40px',
              borderRadius: '10px',
              backgroundColor: '#111827',
              display: 'inline-flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: '#FFFFFF',
              fontWeight: 800,
              fontSize: '1.2rem',
              marginBottom: '10px',
            }}
          >
            O
          </div>
          <h1 style={{ fontSize: '1.35rem', fontWeight: 800, color: '#111827', letterSpacing: '-0.02em' }}>
            OptigoAI Enterprise
          </h1>
          <p style={{ color: '#6B7280', fontSize: '0.82rem', marginTop: '3px' }}>
            Sign in to your multi-location workspace
          </p>
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

        {/* Form */}
        <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
          <div className="input-group">
            <label className="input-label">Work Email</label>
            <div style={{ position: 'relative' }}>
              <input
                type="email"
                className="optigo-input"
                placeholder="name@company.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                style={{ paddingLeft: '32px' }}
              />
              <Mail size={15} color="#9CA3AF" style={{ position: 'absolute', left: '10px', top: '10px' }} />
            </div>
          </div>

          <div className="input-group">
            <label className="input-label">Password</label>
            <div style={{ position: 'relative' }}>
              <input
                type="password"
                className="optigo-input"
                placeholder="••••••••"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                style={{ paddingLeft: '32px' }}
              />
              <Lock size={15} color="#9CA3AF" style={{ position: 'absolute', left: '10px', top: '10px' }} />
            </div>
          </div>

          <button
            type="submit"
            disabled={isLoading}
            className="btn btn-coral"
            style={{ width: '100%', padding: '10px', marginTop: '6px', fontSize: '0.86rem' }}
          >
            <span>{isLoading ? 'Authenticating...' : 'Sign In'}</span>
            <ArrowRight size={14} />
          </button>
        </form>

        {/* Switch to Signup */}
        <div style={{ textAlign: 'center', marginTop: '20px', paddingTop: '16px', borderTop: '1px solid var(--border-subtle)' }}>
          <span style={{ fontSize: '0.8rem', color: '#6B7280' }}>Don't have an enterprise account? </span>
          <button
            onClick={onNavigateSignup}
            style={{
              background: 'transparent',
              border: 'none',
              color: '#111827',
              fontWeight: 700,
              fontSize: '0.8rem',
              cursor: 'pointer',
              textDecoration: 'underline',
            }}
          >
            Create Organization
          </button>
        </div>
      </div>
    </div>
  );
};
