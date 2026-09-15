import { describe, expect, test } from 'vitest';
import {
  homePathForRole,
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

describe('homePathForRole', () => {
  test('maps every application role to its protected route root', () => {
    expect(homePathForRole('student')).toBe('/student');
    expect(homePathForRole('teacher')).toBe('/teacher');
    expect(homePathForRole('admin')).toBe('/admin');
  });
});
