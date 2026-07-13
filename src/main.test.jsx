import { describe, expect, it } from 'vitest';
import { render, screen, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { App } from './App.jsx';

describe('Lumen landing page', () => {
  it('renders the hero heading', () => {
    render(<App />);
    const h1 = screen.getByRole('heading', { level: 1 });
    expect(h1).toHaveTextContent(/when your home shifts/i);
    expect(h1).toHaveTextContent(/you stay calm/i);
  });

  it('renders the beta pill', () => {
    render(<App />);
    expect(screen.getByText(/now in private beta/i)).toBeInTheDocument();
  });

  it('renders a light/dark theme toggle', () => {
    render(<App />);
    expect(screen.getByRole('button', { name: /switch to light mode/i })).toBeInTheDocument();
  });

  it('states calm consent-first positioning', () => {
    render(<App />);
    expect(screen.getAllByText(/nothing runs on its own/i).length).toBeGreaterThan(0);
    expect(screen.getAllByText(/open to everyone/i).length).toBeGreaterThan(0);
  });

  it('renders core nav links', () => {
    render(<App />);
    const nav = screen.getByRole('navigation');
    expect(within(nav).getByRole('link', { name: /features/i })).toHaveAttribute('href', '#features');
    expect(within(nav).getByRole('link', { name: /live demo/i })).toHaveAttribute('href', '#demo');
    expect(within(nav).getByRole('link', { name: /privacy/i })).toHaveAttribute('href', '/privacy');
  });

  it('renders guided demo steps', () => {
    render(<App />);
    expect(screen.getByText(/try the flow/i)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /lumen noticed/i })).toBeInTheDocument();
  });

  it('renders getting started section', () => {
    render(<App />);
    expect(screen.getByRole('heading', { name: /set up in/i })).toBeInTheDocument();
  });

  it('renders the hero CTA pointing at the access section', () => {
    render(<App />);
    const ctas = screen.getAllByRole('link', { name: /(join the beta|request) (early )?access/i });
    expect(ctas.length).toBeGreaterThan(0);
    expect(ctas.some(a => a.getAttribute('href') === '#access')).toBe(true);
  });

  it('renders the sign-up email input', () => {
    render(<App />);
    const input = screen.getByPlaceholderText(/you@example\.com/i);
    expect(input).toBeInTheDocument();
    expect(input).toHaveAttribute('type', 'email');
    expect(input).toHaveAttribute('name', 'email');
  });

  it('accepts email input in the sign-up form', async () => {
    render(<App />);
    const user = userEvent.setup();
    const input = screen.getByPlaceholderText(/you@example\.com/i);
    await user.type(input, 'muha@example.com');
    expect(input).toHaveValue('muha@example.com');
  });

  it('renders the sign-up submit button', () => {
    render(<App />);
    expect(screen.getByRole('button', { name: /continue/i })).toBeInTheDocument();
  });

  it('renders the live interactive demo', () => {
    render(<App />);
    expect(screen.getByText(/live interactive demo/i)).toBeInTheDocument();
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
