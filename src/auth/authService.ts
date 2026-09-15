import { getSupabaseClient } from '../lib/supabase';

export type AppRole = 'student' | 'teacher' | 'admin';

export type AuthResult = {
  userId: string;
  email: string | null;
};

type AuthUserLike = {
  id: string;
  email?: string | null;
};

type SignInResponse = {
  data: { user: AuthUserLike | null };
  error: Error | null;
};

export type AuthGateway = {
  signInWithPassword(credentials: {
    email: string;
    password: string;
  }): Promise<SignInResponse>;
  signOut(): Promise<{ error: Error | null }>;
};

const STUDENT_AUTH_DOMAIN = 'students.speaksense.local';
const USERNAME_PATTERN = /^[a-z0-9._-]{3,40}$/;

export function normalizeStudentUsername(username: string): string {
  const normalized = username.trim().toLowerCase();

  if (!USERNAME_PATTERN.test(normalized)) {
    throw new Error(
      'Username must be 3–40 characters and use only letters, numbers, dot, underscore, or hyphen.',
    );
  }

  return normalized;
}

export function studentEmailForUsername(username: string): string {
  return `${normalizeStudentUsername(username)}@${STUDENT_AUTH_DOMAIN}`;
}

export function homePathForRole(role: AppRole): '/student' | '/teacher' | '/admin' {
  switch (role) {
    case 'student':
      return '/student';
    case 'teacher':
      return '/teacher';
    case 'admin':
      return '/admin';
  }
}

function getDefaultGateway(): AuthGateway {
  const auth = getSupabaseClient().auth;

  return {
    async signInWithPassword(credentials) {
      const { data, error } = await auth.signInWithPassword(credentials);
      return {
        data: {
          user: data.user
            ? { id: data.user.id, email: data.user.email ?? null }
            : null,
        },
        error,
      };
    },
    async signOut() {
      const { error } = await auth.signOut();
      return { error };
    },
  };
}

async function signInWithCredentials(
  email: string,
  password: string,
  gateway: AuthGateway = getDefaultGateway(),
): Promise<AuthResult> {
  const { data, error } = await gateway.signInWithPassword({ email, password });

  if (error) {
    throw error;
  }

  if (!data.user) {
    throw new Error('Authentication succeeded without a user.');
  }

  return {
    userId: data.user.id,
    email: data.user.email ?? null,
  };
}

export function signInStudent(
  username: string,
  password: string,
  gateway?: AuthGateway,
): Promise<AuthResult> {
  return signInWithCredentials(
    studentEmailForUsername(username),
    password,
    gateway ?? getDefaultGateway(),
  );
}

export function signInStaff(
  email: string,
  password: string,
  gateway?: AuthGateway,
): Promise<AuthResult> {
  const normalizedEmail = email.trim();
  if (!normalizedEmail) {
    throw new Error('Email is required.');
  }

  return signInWithCredentials(
    normalizedEmail,
    password,
    gateway ?? getDefaultGateway(),
  );
}

export async function signOut(gateway?: AuthGateway): Promise<void> {
  const { error } = await (gateway ?? getDefaultGateway()).signOut();
  if (error) {
    throw error;
  }
}
