import { type FormEvent, useState } from 'react';
import {
  joinClass,
  type ClassMembership,
} from '../../classes/classService';

type JoinClassHandler = (code: string) => Promise<ClassMembership>;

export function JoinClassPage({
  onJoinClass = joinClass,
}: {
  onJoinClass?: JoinClassHandler;
}) {
  const [code, setCode] = useState('');
  const [membership, setMembership] = useState<ClassMembership | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setSubmitting(true);
    setError(null);
    setMembership(null);

    try {
      const result = await onJoinClass(code);
      setMembership(result);
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : 'Unable to join class.');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <section aria-labelledby="join-class-title">
      <p className="eyebrow">Student access</p>
      <h1 id="join-class-title">Join a class</h1>
      <p>Enter the class code your teacher gave you.</p>

      <form onSubmit={handleSubmit}>
        <label>
          Class code
          <input
            value={code}
            onChange={(event) => setCode(event.target.value)}
            autoCapitalize="characters"
            autoComplete="off"
            required
          />
        </label>
        <button type="submit" disabled={submitting}>
          {submitting ? 'Joining…' : 'Join class'}
        </button>
      </form>

      {error ? <p role="alert">{error}</p> : null}
      {membership?.status === 'active' ? (
        <p role="status">Joined successfully. Your class membership is active.</p>
      ) : null}
    </section>
  );
}
