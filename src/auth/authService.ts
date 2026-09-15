export type AppRole = 'student' | 'teacher' | 'admin';

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
