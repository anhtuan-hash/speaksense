import '@testing-library/jest-dom/vitest';
import { act, render, screen } from '@testing-library/react';
import { describe, expect, test } from 'vitest';
import {
  AuthProvider,
  type AuthSession,
  type AuthSource,
  useAuth,
} from '../../src/auth/AuthProvider';

function Probe() {
  const { session, profile, loading, error } = useAuth();
  if (loading) return <p>loading</p>;
  if (error) return <p role="alert">{error}</p>;
  if (!session) return <p>signed out</p>;
  return <p>{`${profile?.role}:${profile?.displayName}`}</p>;
}

function sourceWith(
  initialSession: AuthSession | null,
  profile: Awaited<ReturnType<AuthSource['loadProfile']>>,
) {
  let listener: ((session: AuthSession | null) => void) | undefined;
  const source: AuthSource = {
    getSession: async () => initialSession,
    loadProfile: async () => profile,
    subscribe(next) {
      listener = next;
      return () => {
        listener = undefined;
      };
    },
  };
  return { source, emit: (session: AuthSession | null) => listener?.(session) };
}

describe('AuthProvider', () => {
  test('loads the current user profile after resolving an authenticated session', async () => {
    const { source } = sourceWith(
      { userId: 'teacher-1' },
      {
        id: 'teacher-1',
        role: 'teacher',
        displayName: 'Teacher One',
        username: null,
      },
    );

    render(
      <AuthProvider source={source}>
        <Probe />
      </AuthProvider>,
    );

    expect(screen.getByText('loading')).toBeInTheDocument();
    expect(await screen.findByText('teacher:Teacher One')).toBeInTheDocument();
  });

  test('reports a safe error when an authenticated user has no application profile', async () => {
    const { source } = sourceWith({ userId: 'missing-profile' }, null);

    render(
      <AuthProvider source={source}>
        <Probe />
      </AuthProvider>,
    );

    expect(await screen.findByRole('alert')).toHaveTextContent(/profile could not be loaded/i);
  });

  test('reacts to subsequent auth-state changes', async () => {
    const { source, emit } = sourceWith(null, {
      id: 'student-1',
      role: 'student',
      displayName: 'Student One',
      username: 'student01',
    });

    render(
      <AuthProvider source={source}>
        <Probe />
      </AuthProvider>,
    );

    expect(await screen.findByText('signed out')).toBeInTheDocument();

    await act(async () => {
      emit({ userId: 'student-1' });
    });

    expect(await screen.findByText('student:Student One')).toBeInTheDocument();
  });
});
