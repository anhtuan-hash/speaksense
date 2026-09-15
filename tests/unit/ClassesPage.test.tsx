import '@testing-library/jest-dom/vitest';
import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import { describe, expect, test } from 'vitest';
import { ClassesPage } from '../../src/pages/teacher/ClassesPage';

describe('ClassesPage', () => {
  test('creates a Grade 11 class and reveals the one-time join code', async () => {
    const received: Array<{ name: string; grade: 10 | 11 | 12 }> = [];

    render(
      <ClassesPage
        onCreateClass={async (input) => {
          received.push(input);
          return {
            id: 'class-1',
            name: input.name,
            grade: input.grade,
            joinCode: 'AB12CD34EF',
          };
        }}
        onRotateJoinCode={async () => ({ joinCode: 'ZX90YU12QP' })}
      />,
    );

    fireEvent.change(screen.getByLabelText(/class name/i), {
      target: { value: '11A1 Pronunciation' },
    });
    fireEvent.change(screen.getByLabelText(/grade/i), { target: { value: '11' } });
    fireEvent.click(screen.getByRole('button', { name: /create class/i }));

    await waitFor(() => {
      expect(received).toEqual([{ name: '11A1 Pronunciation', grade: 11 }]);
    });
    expect(await screen.findByText('AB12CD34EF')).toBeInTheDocument();
    expect(screen.getByText(/save this code/i)).toBeInTheDocument();
  });

  test('rotates the displayed join code for the created class', async () => {
    const rotated: string[] = [];

    render(
      <ClassesPage
        onCreateClass={async (input) => ({
          id: 'class-1',
          name: input.name,
          grade: input.grade,
          joinCode: 'AB12CD34EF',
        })}
        onRotateJoinCode={async (classId) => {
          rotated.push(classId);
          return { joinCode: 'ZX90YU12QP' };
        }}
      />,
    );

    fireEvent.change(screen.getByLabelText(/class name/i), {
      target: { value: '11A1 Pronunciation' },
    });
    fireEvent.click(screen.getByRole('button', { name: /create class/i }));
    await screen.findByText('AB12CD34EF');

    fireEvent.click(screen.getByRole('button', { name: /rotate join code/i }));

    expect(await screen.findByText('ZX90YU12QP')).toBeInTheDocument();
    expect(rotated).toEqual(['class-1']);
    expect(screen.queryByText('AB12CD34EF')).not.toBeInTheDocument();
  });
});
