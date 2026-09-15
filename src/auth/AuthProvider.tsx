import {
  createContext,
  type ReactNode,
  useContext,
  useEffect,
  useMemo,
  useState,
} from 'react';
import { getSupabaseClient } from '../lib/supabase';
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

export type AuthSource = {
  getSession(): Promise<AuthSession | null>;
  loadProfile(userId: string): Promise<AuthProfile | null>;
  subscribe(listener: (session: AuthSession | null) => void): () => void;
};

export const AuthStateContext = createContext<AuthState | undefined>(undefined);

function createSupabaseAuthSource(): AuthSource {
  return {
    async getSession() {
      const { data, error } = await getSupabaseClient().auth.getSession();
      if (error) throw error;
      return data.session ? { userId: data.session.user.id } : null;
    },

    async loadProfile(userId) {
      const { data, error } = await getSupabaseClient()
        .from('profiles')
        .select('id, role, display_name, username')
        .eq('id', userId)
        .maybeSingle();

      if (error) throw error;
      if (!data) return null;

      return {
        id: data.id as string,
        role: data.role as AppRole,
        displayName: data.display_name as string,
        username: (data.username as string | null) ?? null,
      };
    },

    subscribe(listener) {
      const { data } = getSupabaseClient().auth.onAuthStateChange((_event, session) => {
        listener(session ? { userId: session.user.id } : null);
      });

      return () => data.subscription.unsubscribe();
    },
  };
}

export function useAuth(): AuthState {
  const state = useContext(AuthStateContext);
  if (!state) {
    throw new Error('useAuth must be used within AuthProvider.');
  }
  return state;
}

export function AuthProvider({
  children,
  source,
}: {
  children: ReactNode;
  source?: AuthSource;
}) {
  const authSource = useMemo(() => source ?? createSupabaseAuthSource(), [source]);
  const [state, setState] = useState<AuthState>({
    session: null,
    profile: null,
    loading: true,
    error: null,
  });

  useEffect(() => {
    let active = true;

    const resolveSession = async (session: AuthSession | null) => {
      if (!active) return;

      if (!session) {
        setState({ session: null, profile: null, loading: false, error: null });
        return;
      }

      setState((current) => ({
        ...current,
        session,
        profile: null,
        loading: true,
        error: null,
      }));

      try {
        const profile = await authSource.loadProfile(session.userId);
        if (!active) return;

        if (!profile) {
          setState({
            session,
            profile: null,
            loading: false,
            error: 'Your account profile could not be loaded.',
          });
          return;
        }

        setState({ session, profile, loading: false, error: null });
      } catch (error) {
        if (!active) return;
        setState({
          session,
          profile: null,
          loading: false,
          error: error instanceof Error ? error.message : 'Unable to load your account profile.',
        });
      }
    };

    void authSource
      .getSession()
      .then(resolveSession)
      .catch((error: unknown) => {
        if (!active) return;
        setState({
          session: null,
          profile: null,
          loading: false,
          error: error instanceof Error ? error.message : 'Unable to check your session.',
        });
      });

    const unsubscribe = authSource.subscribe((session) => {
      void resolveSession(session);
    });

    return () => {
      active = false;
      unsubscribe();
    };
  }, [authSource]);

  return <AuthStateContext.Provider value={state}>{children}</AuthStateContext.Provider>;
}
