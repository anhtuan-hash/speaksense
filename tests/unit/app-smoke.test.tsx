// @vitest-environment jsdom
import '@testing-library/jest-dom/vitest';
import { render, screen } from '@testing-library/react';
import { App } from '../../src/app/App';

test('renders SpeakSense shell', () => {
  render(<App />);
  expect(screen.getByText(/SpeakSense/i)).toBeInTheDocument();
});
