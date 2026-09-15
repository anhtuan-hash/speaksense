import { type FormEvent, useState } from 'react';
import { signInStaff, signInStudent } from '../auth/authService';

type LoginHandler = (identifier: string, password: string) => Promise<unknown>;
type LoginMode = 'student' | 'staff';

export function LoginPage({
  onStudentSignIn = (username, password) => signInStudent(username, password),
  onStaffSignIn = (email, password) => signInStaff(email, password),
}: {
  onStudentSignIn?: LoginHandler;
  onStaffSignIn?: LoginHandler;
}) {
  const [mode, setMode] = useState<LoginMode>('student');
  const [identifier, setIdentifier] = useState('');
  const [password, setPassword] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const switchMode = (nextMode: LoginMode) => {
    setMode(nextMode);
    setIdentifier('');
    setPassword('');
    setError(null);
  };

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setSubmitting(true);
    setError(null);

    try {
      if (mode === 'student') {
        await onStudentSignIn(identifier, password);
      } else {
        await onStaffSignIn(identifier, password);
      }
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : 'Unable to sign in.');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <section aria-labelledby="login-title" className="auth-shell">
      <p className="eyebrow">Secure research access</p>
      <h1 id="login-title">Sign in to SpeakSense</h1>

      <div role="group" aria-label="Account type">
        <button
          type="button"
          aria-pressed={mode === 'student'}
          onClick={() => switchMode('student')}
        >
          Student
        </button>
        <button
          type="button"
          aria-pressed={mode === 'staff'}
          onClick={() => switchMode('staff')}
        >
          Teacher / Admin
        </button>
      </div>

      <form onSubmit={handleSubmit}>
        {mode === 'student' ? (
          <label>
            Username
            <input
              name="username"
              autoComplete="username"
              value={identifier}
              onChange={(event) => setIdentifier(event.target.value)}
              required
            />
          </label>
        ) : (
          <label>
            Email
            <input
              name="email"
              type="email"
              autoComplete="email"
              value={identifier}
              onChange={(event) => setIdentifier(event.target.value)}
              required
            />
          </label>
        )}

        <label>
          Password
          <input
            name="password"
            type="password"
            autoComplete="current-password"
            value={password}
            onChange={(event) => setPassword(event.target.value)}
            required
          />
        </label>

        {error ? <p role="alert">{error}</p> : null}

        <button type="submit" disabled={submitting}>
          {submitting ? 'Signing in…' : 'Sign in'}
        </button>
      </form>
    </section>
  );
}
