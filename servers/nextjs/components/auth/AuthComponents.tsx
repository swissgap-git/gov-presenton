/**
 * EIAM Authentication Components for Next.js
 * Provides login/logout buttons and authentication status display
 */

'use client';

import React from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { Button } from '@/components/ui/button';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { 
  DropdownMenu, 
  DropdownMenuContent, 
  DropdownMenuItem, 
  DropdownMenuTrigger,
  DropdownMenuSeparator,
  DropdownMenuLabel
} from '@/components/ui/dropdown-menu';
import { LogIn, LogOut, User, Settings } from 'lucide-react';

interface LoginButtonProps {
  redirectUrl?: string;
  className?: string;
}

export const LoginButton: React.FC<LoginButtonProps> = ({ 
  redirectUrl, 
  className = '' 
}) => {
  const { login, loading } = useAuth();

  return (
    <Button
      onClick={() => login(redirectUrl)}
      disabled={loading}
      className={`flex items-center gap-2 ${className}`}
    >
      <LogIn className="h-4 w-4" />
      {loading ? 'Anmelden...' : 'Anmelden'}
    </Button>
  );
};

export const LogoutButton: React.FC<{ className?: string }> = ({ 
  className = '' 
}) => {
  const { logout, loading } = useAuth();

  return (
    <Button
      onClick={logout}
      disabled={loading}
      variant="outline"
      className={`flex items-center gap-2 ${className}`}
    >
      <LogOut className="h-4 w-4" />
      {loading ? 'Abmelden...' : 'Abmelden'}
    </Button>
  );
};

export const UserMenu: React.FC<{ className?: string }> = ({ 
  className = '' 
}) => {
  const { user, logout, loading } = useAuth();

  if (!user) {
    return <LoginButton className={className} />;
  }

  const userInitials = user.name
    ? user.name
        .split(' ')
        .map((n: string) => n[0])
        .join('')
        .toUpperCase()
        .slice(0, 2)
    : user.email
    ? user.email.slice(0, 2).toUpperCase()
    : 'U';

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button
          variant="ghost"
          className={`relative h-8 w-8 rounded-full ${className}`}
        >
          <Avatar className="h-8 w-8">
            <AvatarImage src={undefined} alt={user.name || user.email} />
            <AvatarFallback>{userInitials}</AvatarFallback>
          </Avatar>
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent className="w-56" align="end" forceMount>
        <DropdownMenuLabel className="font-normal">
          <div className="flex flex-col space-y-1">
            <p className="text-sm font-medium leading-none">
              {user.name || 'Unbekannter Benutzer'}
            </p>
            <p className="text-xs leading-none text-muted-foreground">
              {user.email}
            </p>
            {user.department && (
              <p className="text-xs leading-none text-muted-foreground">
                {user.department}
              </p>
            )}
          </div>
        </DropdownMenuLabel>
        <DropdownMenuSeparator />
        <DropdownMenuItem>
          <User className="mr-2 h-4 w-4" />
          <span>Profil</span>
        </DropdownMenuItem>
        <DropdownMenuItem>
          <Settings className="mr-2 h-4 w-4" />
          <span>Einstellungen</span>
        </DropdownMenuItem>
        <DropdownMenuSeparator />
        <DropdownMenuItem onClick={logout} disabled={loading}>
          <LogOut className="mr-2 h-4 w-4" />
          <span>{loading ? 'Abmelden...' : 'Abmelden'}</span>
        </DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  );
};

interface AuthGuardProps {
  children: React.ReactNode;
  fallback?: React.ReactNode;
  requireRole?: string;
}

export const AuthGuard: React.FC<AuthGuardProps> = ({ 
  children, 
  fallback,
  requireRole 
}) => {
  const { isAuthenticated, user, loading } = useAuth();

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-gray-900"></div>
      </div>
    );
  }

  if (!isAuthenticated) {
    return fallback || <LoginButton />;
  }

  if (requireRole && user && !user.roles.includes(requireRole)) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-center">
          <h1 className="text-2xl font-bold text-gray-900 mb-2">
            Zugriff verweigert
          </h1>
          <p className="text-gray-600 mb-4">
            Sie benötigen die Rolle "{requireRole}" um auf diese Seite zuzugreifen.
          </p>
          <LogoutButton />
        </div>
      </div>
    );
  }

  return <>{children}</>;
};

interface AuthStatusProps {
  className?: string;
}

export const AuthStatus: React.FC<AuthStatusProps> = ({ className = '' }) => {
  const { isAuthenticated, user, loading } = useAuth();

  if (loading) {
    return (
      <div className={`text-sm text-gray-500 ${className}`}>
        Lade Authentifizierungsstatus...
      </div>
    );
  }

  if (!isAuthenticated) {
    return (
      <div className={`text-sm text-red-600 ${className}`}>
        Nicht authentifiziert
      </div>
    );
  }

  return (
    <div className={`text-sm text-green-600 ${className}`}>
      Angemeldet als: {user?.name || user?.email || 'Unbekannt'}
    </div>
  );
};
