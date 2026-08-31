// ==================================================
// OptigoAI Enterprise — Real Auth Context
// ==================================================

import React, { createContext, useContext, useState, useEffect } from 'react';
import { User, Organization } from '../types';
import { apiRequest } from '../services/api';

interface AuthContextType {
  user: User | null;
  organization: Organization | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  login: (email: string, password?: string) => Promise<void>;
  signup: (fullName: string, email: string, orgName: string, password?: string) => Promise<void>;
  logout: () => void;
  refreshUser: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [organization, setOrganization] = useState<Organization | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(true);

  // Check auth session on startup
  const checkAuth = async () => {
    const token = localStorage.getItem('optigo_token');
    if (!token) {
      setUser(null);
      setOrganization(null);
      setIsLoading(false);
      return;
    }

    try {
      const res = await apiRequest<{ user: User; organization: Organization }>('/auth/me');
      if (res && res.user) {
        setUser(res.user);
        setOrganization(res.organization || null);
      } else {
        localStorage.removeItem('optigo_token');
        setUser(null);
        setOrganization(null);
      }
    } catch {
      localStorage.removeItem('optigo_token');
      setUser(null);
      setOrganization(null);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    checkAuth();
  }, []);

  const login = async (email: string, password?: string) => {
    setIsLoading(true);
    try {
      const res = await apiRequest<{ user: User; organization: Organization; tokens: { access_token: string } }>(
        '/auth/login',
        {
          method: 'POST',
          body: JSON.stringify({ email, password: password || '' }),
        }
      );
      if (res && res.tokens) {
        localStorage.setItem('optigo_token', res.tokens.access_token);
        setUser(res.user);
        setOrganization(res.organization || null);
      }
    } finally {
      setIsLoading(false);
    }
  };

  const signup = async (fullName: string, email: string, orgName: string, password?: string) => {
    setIsLoading(true);
    try {
      const res = await apiRequest<{ user: User; organization: Organization; tokens: { access_token: string } }>(
        '/auth/signup',
        {
          method: 'POST',
          body: JSON.stringify({
            full_name: fullName,
            email,
            organization_name: orgName,
            password: password || '',
          }),
        }
      );
      if (res && res.tokens) {
        localStorage.setItem('optigo_token', res.tokens.access_token);
        setUser(res.user);
        setOrganization(res.organization || null);
      }
    } finally {
      setIsLoading(false);
    }
  };

  const logout = () => {
    localStorage.removeItem('optigo_token');
    localStorage.removeItem('optigo_user');
    localStorage.removeItem('optigo_org');
    setUser(null);
    setOrganization(null);
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        organization,
        isAuthenticated: !!user,
        isLoading,
        login,
        signup,
        logout,
        refreshUser: checkAuth,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
