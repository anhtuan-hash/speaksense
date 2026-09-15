import { z } from 'zod';

const publicEnvSchema = z.object({
  VITE_SUPABASE_URL: z
    .string()
    .trim()
    .url('VITE_SUPABASE_URL must be a valid URL'),
  VITE_SUPABASE_ANON_KEY: z
    .string()
    .trim()
    .min(1, 'VITE_SUPABASE_ANON_KEY is required'),
});

export type PublicEnv = {
  supabaseUrl: string;
  supabaseAnonKey: string;
};

export function parsePublicEnv(raw: Record<string, unknown>): PublicEnv {
  const parsed = publicEnvSchema.parse(raw);
  return {
    supabaseUrl: parsed.VITE_SUPABASE_URL,
    supabaseAnonKey: parsed.VITE_SUPABASE_ANON_KEY,
  };
}

let cachedRuntimeEnv: PublicEnv | undefined;

function readRuntimeEnv(): PublicEnv {
  cachedRuntimeEnv ??= parsePublicEnv(
    import.meta.env as unknown as Record<string, unknown>,
  );
  return cachedRuntimeEnv;
}

export const env: PublicEnv = Object.freeze({
  get supabaseUrl() {
    return readRuntimeEnv().supabaseUrl;
  },
  get supabaseAnonKey() {
    return readRuntimeEnv().supabaseAnonKey;
  },
});
