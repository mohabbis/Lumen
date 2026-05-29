import { describe, expect, it } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

import './main.jsx';

describe('Lumen public preview', () => {
  it('renders the flagship hero and core product story', () => {
    render(document.body.querySelector('#root'));

    expect(screen.getByRole('heading', { name: /a calmer home, conducted by lumen/i })).toBeInTheDocument();
    expect(screen.getByText(/spatial intelligence for the home/i)).toBeInTheDocument();
    expect(screen.getByRole('link', { name: /request early access/i })).toHaveAttribute('href', '#access');
  });

  it('exposes accessible navigation links', () => {
    expect(screen.getByRole('link', { name: /story/i })).toHaveAttribute('href', '#story');
    expect(screen.getByRole('link', { name: /architecture/i })).toHaveAttribute('href', '#architecture');
    expect(screen.getByRole('link', { name: /stack/i })).toHaveAttribute('href', '#stack');
  });

  it('supports the early access form fields', async () => {
    const user = userEvent.setup();
    const email = screen.getByLabelText(/email address/i);
    const context = screen.getByLabelText(/what are you building toward/i);

    await user.type(email, 'muha@example.com');
    await user.type(context, 'Apartment test setup');

    expect(email).toHaveValue('muha@example.com');
    expect(context).toHaveValue('Apartment test setup');
    expect(screen.getByRole('button', { name: /join early access/i })).toBeInTheDocument();
  });
});
