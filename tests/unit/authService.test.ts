import { describe, expect, test } from 'vitest';
import {
  homePathForRole,
  signInStaff,
  signInStudent,
  signOut,
  studentEmailForUsername,
} from '../../src/auth/authService';

describe('studentEmailForUsername', () => {
  test('normalizes a valid student username into the synthetic auth namespace', () => {
    expect(studentEmailForUsername(' 11A1_TuanAnh ')).toBe(
      '11a1_tuananh@students.speaksense.local',
    );
  });

  test('rejects unsupported characters and invalid lengths', () => {
    expect(() => studentEmailForUsername('bad name!')).toThrow();
    expect(() => studentEmailForUsername('ab')).toThrow();
  });
});

describe('role routing', () => {
  test('maps every application role to its protected route root', () => {
    expect(homePathForRole('student')).toBe('/student');
    expect(homePathForRole('teacher')).toBe('/teacher');
    expect(homePathForRole('admin')).toBe('/admin');
  });
});

describe('authentication commands', () => {
  test('student sign-in forwards normalized synthetic credentials', async () => {
    const received: Array<{ email: string; password: string }> = [];
    const gateway = {
      signInWithPassword: async (credentials: { email: string; password: string }) => {
        received.push(credentials);
        return {
          data: { user: { id: 'student-1', email: credentials.email } },
          error: null,
        };
      },
      signOut: async () => ({ error: null }),
    };

    await expect(signInStudent(' 11A1_TuanAnh ', 'secret', gateway)).resolves.toEqual({
      userId: 'student-1',
      email: '11a1_tuananh@students.speaksense.local',
    });
    expect(received).toEqual([
      { email: '11a1_tuananh@students.speaksense.local', password: 'secret' },
    ]);
  });

  test('staff sign-in preserves the supplied email and sign-out delegates safely', async () => {
    const received: Array<{ email: string; password: string }> = [];
    let signedOut = false;
    const gateway = {
      signInWithPassword: async (credentials: { email: string; password: string }) => {
        received.push(credentials);
        return {
          data: { user: { id: 'teacher-1', email: credentials.email } },
          error: null,
        };
      },
      signOut: async () => {
        signedOut = true;
        return { error: null };
      },
    };

    await expect(signInStaff('teacher@example.com', 'secret', gateway)).resolves.toEqual({
      userId: 'teacher-1',
      email: 'teacher@example.com',
    });
    await signOut(gateway);

    expect(received).toEqual([{ email: 'teacher@example.com', password: 'secret' }]);
    expect(signedOut).toBe(true);
  });

  test('surfaces authentication errors instead of returning a false success', async () => {
    const gateway = {
      signInWithPassword: async () => ({
        data: { user: null },
        error: new Error('Invalid login credentials'),
      }),
      signOut: async () => ({ error: null }),
    };

    await expect(signInStudent('student01', 'wrong', gateway)).rejects.toThrow(
      /Invalid login credentials/,
    );
  });
});
