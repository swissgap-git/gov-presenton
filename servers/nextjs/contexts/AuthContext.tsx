/**
 * EIAM Authentication Context for Next.js
 * Provides authentication state management for Swiss Federal EIAM integration
 */

'use client';

import React, { createContext, useContext, useEffect, useState, ReactNode } from 'react';

interface EIAMUser {
  sub: string;
  name?: string;
  email?: string;
  given_name?: string;
  family_name?: string;
  roles: string[];
  department?: string;
  organization?: string;
}

interface AuthState {
  isAuthenticated: boolean;
  user: EIAMUser | null;
  token: string | null;
  loading: boolean;
  error: string | null;
}

interface AuthContextType extends AuthState {
  login: (redirectUrl?: string) => void;
  logout: () => void;
  checkAuth: () => Promise<void>;
  refreshToken: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

interface AuthProviderProps {
  children: ReactNode;
}

export const AuthProvider: React.FC<AuthProviderProps> = ({ children }) => {
  const [authState, setAuthState] = useState<AuthState>({
    isAuthenticated: false,
    user: null,
    token: null,
    loading: true,
    error: null,
  });

  // Check authentication status on mount
  useEffect(() => {
    checkAuth();
  }, []);

  const checkAuth = async () => {
    try {
      setAuthState(prev => ({ ...prev, loading: true, error: null }));
      
      const response = await fetch('/api/v1/auth/check', {
        credentials: 'include',
      });
      
      const data = await response.json();
      
      if (data.authenticated && data.user) {
        setAuthState({
          isAuthenticated: true,
          user: data.user,
          token: null, // Token is stored server-side in session
          loading: false,
          error: null,
        });
      } else {
        setAuthState({
          isAuthenticated: false,
          user: null,
          token: null,
          loading: false,
          error: null,
        });
      }
    } catch (error) {
      console.error('Auth check failed:', error);
      setAuthState({
        isAuthenticated: false,
        user: null,
        token: null,
        loading: false,
        error: 'Authentication check failed',
      });
    }
  };

  const login = (redirectUrl?: string) => {
    const params = new URLSearchParams();
    if (redirectUrl) {
      params.set('redirect_url', redirectUrl);
    }
    
    const loginUrl = `/api/v1/auth/login${params.toString() ? '?' + params.toString() : ''}`;
    window.location.href = loginUrl;
  };

  const logout = async () => {
    try {
      await fetch('/api/v1/auth/logout', {
        method: 'POST',
        credentials: 'include',
      });
      
      setAuthState({
        isAuthenticated: false,
        user: null,
        token: null,
        loading: false,
        error: null,
      });
      
      // Redirect to home page or login page
      window.location.href = '/';
    } catch (error) {
      console.error('Logout failed:', error);
      // Force logout even if API call fails
      setAuthState({
        isAuthenticated: false,
        user: null,
        token: null,
        loading: false,
        error: null,
      });
      window.location.href = '/';
    }
  };

  const refreshToken = async () => {
    try {
      const response = await fetch('/api/v1/auth/token', {
        credentials: 'include',
      });
      
      if (!response.ok) {
        throw new Error('Token refresh failed');
      }
      
      const data = await response.json();
      
      if (data.success && data.user) {
        setAuthState(prev => ({
          ...prev,
          user: data.user,
          token: data.token,
          error: null,
        }));
      } else {
        // Token refresh failed, user needs to re-authenticate
        setAuthState({
          isAuthenticated: false,
          user: null,
          token: null,
          loading: false,
          error: 'Session expired',
        });
      }
    } catch (error) {
      console.error('Token refresh failed:', error);
      setAuthState({
        isAuthenticated: false,
        user: null,
        token: null,
        loading: false,
        error: 'Session expired',
      });
    }
  };

  const value: AuthContextType = {
    ...authState,
    login,
    logout,
    checkAuth,
    refreshToken,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};
