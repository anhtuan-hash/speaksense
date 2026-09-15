import type { ReactNode } from 'react';
import { Navigate } from 'react-router-dom';
import { homePathForRole, type AppRole } from './authService';
import { useAuth } from './AuthProvider';

export function RequireRole({
  allowed,
  children,
}: {
  allowed: readonly AppRole[];
  children: ReactNode;
}) {
  const { session, profile, loading, error } = useAuth();

  if (loading) {
    return <p role="status" aria-label="Checking session">Checking session…</p>;
  }

  if (error) {
    return <p role="alert">{error}</p>;
  }

  if (!session) {
    return <Navigate to="/login" replace />;
  }

  if (!profile) {
    return <p role="alert">Your account profile could not be loaded.</p>;
  }

  if (!allowed.includes(profile.role)) {
    return <Navigate to={homePathForRole(profile.role)} replace />;
  }

  return children;
}
