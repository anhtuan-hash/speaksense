import { type FormEvent, useState } from 'react';
import {
  createClass,
  rotateJoinCode,
  type ClassRecord,
  type GradeLevel,
} from '../../classes/classService';

type CreateClassHandler = (input: {
  name: string;
  grade: GradeLevel;
}) => Promise<ClassRecord>;

type RotateCodeHandler = (classId: string) => Promise<{ joinCode: string }>;

export function ClassesPage({
  onCreateClass = createClass,
  onRotateJoinCode = rotateJoinCode,
}: {
  onCreateClass?: CreateClassHandler;
  onRotateJoinCode?: RotateCodeHandler;
}) {
  const [name, setName] = useState('');
  const [grade, setGrade] = useState<GradeLevel>(11);
  const [createdClass, setCreatedClass] = useState<ClassRecord | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [rotating, setRotating] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleCreate = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setSubmitting(true);
    setError(null);

    try {
      const record = await onCreateClass({ name, grade });
      setCreatedClass(record);
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : 'Unable to create class.');
    } finally {
      setSubmitting(false);
    }
  };

  const handleRotate = async () => {
    if (!createdClass) return;
    setRotating(true);
    setError(null);

    try {
      const { joinCode } = await onRotateJoinCode(createdClass.id);
      setCreatedClass({ ...createdClass, joinCode });
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : 'Unable to rotate join code.');
    } finally {
      setRotating(false);
    }
  };

  return (
    <section aria-labelledby="classes-title">
      <p className="eyebrow">Teacher workspace</p>
      <h1 id="classes-title">Classes</h1>

      <form onSubmit={handleCreate}>
        <label>
          Class name
          <input
            value={name}
            onChange={(event) => setName(event.target.value)}
            required
            maxLength={120}
          />
        </label>

        <label>
          Grade
          <select
            value={grade}
            onChange={(event) => setGrade(Number(event.target.value) as GradeLevel)}
          >
            <option value={10}>10</option>
            <option value={11}>11</option>
            <option value={12}>12</option>
          </select>
        </label>

        <button type="submit" disabled={submitting}>
          {submitting ? 'Creating…' : 'Create class'}
        </button>
      </form>

      {error ? <p role="alert">{error}</p> : null}

      {createdClass ? (
        <article aria-label={`${createdClass.name} class access`}>
          <h2>{createdClass.name}</h2>
          <p>Grade {createdClass.grade}</p>
          <p>
            Join code: <strong>{createdClass.joinCode}</strong>
          </p>
          <p>Save this code now. Only its hash is stored by SpeakSense.</p>
          <button type="button" onClick={handleRotate} disabled={rotating}>
            {rotating ? 'Rotating…' : 'Rotate join code'}
          </button>
        </article>
      ) : null}
    </section>
  );
}
