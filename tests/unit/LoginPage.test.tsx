import '@testing-library/jest-dom/vitest';
import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import { describe, expect, test } from 'vitest';
import { LoginPage } from '../../src/pages/LoginPage';

describe('LoginPage', () => {
  test('defaults to student username sign-in and submits student credentials', async () => {
    const received: Array<[string, string]> = [];

    render(
      <LoginPage
        onStudentSignIn={async (username, password) => {
          received.push([username, password]);
        }}
        onStaffSignIn={async () => {}}
      />,
    );

    fireEvent.change(screen.getByLabelText(/username/i), { target: { value: '11a1_tuananh' } });
    fireEvent.change(screen.getByLabelText(/password/i), { target: { value: 'secret' } });
    fireEvent.click(screen.getByRole('button', { name: /sign in/i }));

    await waitFor(() => expect(received).toEqual([['11a1_tuananh', 'secret']]));
  });

  test('switches to staff email sign-in without exposing the student synthetic email', async () => {
    const received: Array<[string, string]> = [];

    render(
      <LoginPage
        onStudentSignIn={async () => {}}
        onStaffSignIn={async (email, password) => {
          received.push([email, password]);
        }}
      />,
    );

    fireEvent.click(screen.getByRole('button', { name: /teacher.*admin/i }));
    expect(screen.queryByLabelText(/username/i)).not.toBeInTheDocument();

    fireEvent.change(screen.getByLabelText(/email/i), { target: { value: 'teacher@example.com' } });
    fireEvent.change(screen.getByLabelText(/password/i), { target: { value: 'secret' } });
    fireEvent.click(screen.getByRole('button', { name: /sign in/i }));

    await waitFor(() => expect(received).toEqual([['teacher@example.com', 'secret']]));
    expect(screen.queryByText(/students\.speaksense\.local/i)).not.toBeInTheDocument();
  });

  test('renders authentication errors as an alert', async () => {
    render(
      <LoginPage
        onStudentSignIn={async () => {
          throw new Error('Invalid login credentials');
        }}
        onStaffSignIn={async () => {}}
      />,
    );

    fireEvent.change(screen.getByLabelText(/username/i), { target: { value: 'student01' } });
    fireEvent.change(screen.getByLabelText(/password/i), { target: { value: 'wrong' } });
    fireEvent.click(screen.getByRole('button', { name: /sign in/i }));

    expect(await screen.findByRole('alert')).toHaveTextContent(/invalid login credentials/i);
  });
});
