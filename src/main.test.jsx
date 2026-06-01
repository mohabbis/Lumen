import { describe, expect, it } from 'vitest';
import { render, screen, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { App } from './App.jsx';

describe('Lumen landing page', () => {
  it('renders the hero heading', () => {
    render(<App />);
    const h1 = screen.getByRole('heading', { level: 1 });
    expect(h1).toHaveTextContent(/your home/i);
  });

  it('renders the coming soon pill', () => {
    render(<App />);
    expect(screen.getByText(/coming soon/i)).toBeInTheDocument();
  });

  it('renders core nav links', () => {
    render(<App />);
    const nav = screen.getByRole('navigation');
    expect(within(nav).getByRole('link', { name: /^product$/i })).toHaveAttribute('href', '#product');
    expect(within(nav).getByRole('link', { name: /^architecture$/i })).toHaveAttribute('href', '#architecture');
    expect(within(nav).getByRole('link', { name: /^privacy$/i })).toHaveAttribute('href', '/privacy');
  });

  it('renders the hero CTA pointing at the access section', () => {
    render(<App />);
    const ctas = screen.getAllByRole('link', { name: /join early access/i });
    expect(ctas.length).toBeGreaterThan(0);
    expect(ctas[0]).toHaveAttribute('href', '#access');
  });

  it('renders the waitlist email input', () => {
    render(<App />);
    const input = screen.getByPlaceholderText(/your email address/i);
    expect(input).toBeInTheDocument();
    expect(input).toHaveAttribute('type', 'email');
    expect(input).toHaveAttribute('name', 'email');
  });

  it('accepts email input in the waitlist form', async () => {
    render(<App />);
    const user = userEvent.setup();
    const input = screen.getByPlaceholderText(/your email address/i);
    await user.type(input, 'muha@example.com');
    expect(input).toHaveValue('muha@example.com');
  });

  it('renders the waitlist submit button', () => {
    render(<App />);
    expect(screen.getByRole('button', { name: /join early access/i })).toBeInTheDocument();
  });
});
