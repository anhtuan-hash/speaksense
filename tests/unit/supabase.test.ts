import { describe, expect, test } from 'vitest';
import { getSupabaseClient } from '../../src/lib/supabase';

describe('Supabase client module', () => {
  test('can be imported without eagerly reading runtime environment values', () => {
    expect(getSupabaseClient).toBeTypeOf('function');
  });
});
