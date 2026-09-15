import '@testing-library/jest-dom/vitest';
import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import { describe, expect, test } from 'vitest';
import { JoinClassPage } from '../../src/pages/student/JoinClassPage';

describe('JoinClassPage', () => {
  test('submits the entered class code and confirms active membership', async () => {
    const received: string[] = [];

    render(
      <JoinClassPage
        onJoinClass={async (code) => {
          received.push(code);
          return { classId: 'class-1', studentId: 'student-1', status: 'active' };
        }}
      />,
    );

    fireEvent.change(screen.getByLabelText(/class code/i), {
      target: { value: 'ab12cd34ef' },
    });
    fireEvent.click(screen.getByRole('button', { name: /join class/i }));

    await waitFor(() => expect(received).toEqual(['ab12cd34ef']));
    expect(await screen.findByRole('status')).toHaveTextContent(/joined successfully/i);
  });

  test('shows a database rejection without pretending the join succeeded', async () => {
    render(
      <JoinClassPage
        onJoinClass={async () => {
          throw new Error('Invalid or inactive class code');
        }}
      />,
    );

    fireEvent.change(screen.getByLabelText(/class code/i), {
      target: { value: 'badcode' },
    });
    fireEvent.click(screen.getByRole('button', { name: /join class/i }));

    expect(await screen.findByRole('alert')).toHaveTextContent(/invalid or inactive class code/i);
    expect(screen.queryByText(/joined successfully/i)).not.toBeInTheDocument();
  });
});
