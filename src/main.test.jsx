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

  it('renders the neurodivergent hero pill', () => {
    render(<App />);
    expect(screen.getByText(/built for neurodivergent minds/i)).toBeInTheDocument();
  });

  it('renders a light/dark theme toggle', () => {
    render(<App />);
    expect(screen.getByRole('button', { name: /switch to light mode/i })).toBeInTheDocument();
  });

  it('states Tiimo-inspired neurodivergent positioning', () => {
    render(<App />);
    expect(screen.getAllByText(/tiimo/i).length).toBeGreaterThan(0);
    expect(screen.getByText(/designed for neurodivergent minds first/i)).toBeInTheDocument();
    expect(screen.getAllByText(/open to everyone/i).length).toBeGreaterThan(0);
  });

  it('renders core nav links', () => {
    render(<App />);
    const nav = screen.getByRole('navigation');
    expect(within(nav).getByRole('link', { name: /^the app$/i })).toHaveAttribute('href', '#product');
    expect(within(nav).getByRole('link', { name: /^ai$/i })).toHaveAttribute('href', '#ai');
    expect(within(nav).getByRole('link', { name: /^privacy$/i })).toHaveAttribute('href', '/privacy');
  });

  it('renders the hero CTA pointing at the access section', () => {
    render(<App />);
    const ctas = screen.getAllByRole('link', { name: /request early access/i });
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
    expect(screen.getByRole('button', { name: /request access/i })).toBeInTheDocument();
  });

  it('renders interactive phone tabs', () => {
    render(<App />);
    expect(screen.getByRole('button', { name: /auto tab/i })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /home tab/i })).toBeInTheDocument();
  });

  it('states the honest Apple Home / HomeKit + Matter compatibility', () => {
    render(<App />);
    // The compatibility claim must survive refactors: Lumen controls what's in
    // your Apple Home (HomeKit + Matter), not bespoke brand integrations.
    const heading = screen.getByRole('heading', { name: /apple home/i });
    expect(heading).toHaveTextContent(/matter/i);
    expect(screen.getByText(/lumen controls whatever lives in your apple home/i)).toBeInTheDocument();
  });
});
