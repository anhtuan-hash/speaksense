import { describe, expect, test } from 'vitest';
import { parsePublicEnv } from '../../src/lib/env';

describe('parsePublicEnv', () => {
  test('rejects missing Supabase values', () => {
    expect(() => parsePublicEnv({})).toThrow(/VITE_SUPABASE_URL/);
  });

  test('accepts valid public configuration', () => {
    expect(
      parsePublicEnv({
        VITE_SUPABASE_URL: 'https://example.supabase.co',
        VITE_SUPABASE_ANON_KEY: 'anon-key',
      }),
    ).toEqual({
      supabaseUrl: 'https://example.supabase.co',
      supabaseAnonKey: 'anon-key',
    });
  });

  test('rejects non-Supabase URL values', () => {
    expect(() =>
      parsePublicEnv({
        VITE_SUPABASE_URL: 'not-a-url',
        VITE_SUPABASE_ANON_KEY: 'anon-key',
      }),
    ).toThrow(/VITE_SUPABASE_URL/);
  });
});
