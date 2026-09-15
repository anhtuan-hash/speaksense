import '@testing-library/jest-dom/vitest';
import { render, screen } from '@testing-library/react';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import { describe, test } from 'vitest';
import {
  AuthStateContext,
  type AuthState,
} from '../../src/auth/AuthProvider';
import { RequireRole } from '../../src/auth/RequireRole';

function renderGuard(state: AuthState, allowed: Array<'student' | 'teacher' | 'admin'>) {
  render(
    <AuthStateContext.Provider value={state}>
      <MemoryRouter initialEntries={['/protected']}>
        <Routes>
          <Route
            path="/protected"
            element={
              <RequireRole allowed={allowed}>
                <h1>Protected content</h1>
              </RequireRole>
            }
          />
          <Route path="/login" element={<h1>Login destination</h1>} />
          <Route path="/student" element={<h1>Student home</h1>} />
          <Route path="/teacher" element={<h1>Teacher home</h1>} />
          <Route path="/admin" element={<h1>Admin home</h1>} />
        </Routes>
      </MemoryRouter>
    </AuthStateContext.Provider>,
  );
}

describe('RequireRole', () => {
  test('shows an explicit loading state while auth is resolving', () => {
    renderGuard({ session: null, profile: null, loading: true, error: null }, ['student']);
    screen.getByRole('status', { name: /checking session/i });
  });

  test('redirects unauthenticated users to login', () => {
    renderGuard({ session: null, profile: null, loading: false, error: null }, ['student']);
    screen.getByRole('heading', { name: /login destination/i });
  });

  test('redirects an authenticated user with the wrong role to their own home', () => {
    renderGuard(
      {
        session: { userId: 'student-1' },
        profile: {
          id: 'student-1',
          role: 'student',
          displayName: 'Student One',
          username: 'student01',
        },
        loading: false,
        error: null,
      },
      ['teacher'],
    );
    screen.getByRole('heading', { name: /student home/i });
  });

  test('renders protected content for an allowed role', () => {
    renderGuard(
      {
        session: { userId: 'teacher-1' },
        profile: {
          id: 'teacher-1',
          role: 'teacher',
          displayName: 'Teacher One',
          username: null,
        },
        loading: false,
        error: null,
      },
      ['teacher', 'admin'],
    );
    screen.getByRole('heading', { name: /protected content/i });
  });
});
