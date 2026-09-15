import { createContext, type ReactNode, useContext } from 'react';
import type { AppRole } from './authService';

export type AuthSession = {
  userId: string;
};

export type AuthProfile = {
  id: string;
  role: AppRole;
  displayName: string;
  username: string | null;
};

export type AuthState = {
  session: AuthSession | null;
  profile: AuthProfile | null;
  loading: boolean;
  error: string | null;
};

export const AuthStateContext = createContext<AuthState | undefined>(undefined);

export function useAuth(): AuthState {
  const state = useContext(AuthStateContext);
  if (!state) {
    throw new Error('useAuth must be used within AuthProvider.');
  }
  return state;
}

export function AuthProvider({
  children,
  state,
}: {
  children: ReactNode;
  state: AuthState;
}) {
  return <AuthStateContext.Provider value={state}>{children}</AuthStateContext.Provider>;
}
