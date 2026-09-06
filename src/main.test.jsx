import { describe, expect, it } from 'vitest';
import { render, screen, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { App } from './App.jsx';

describe('Lumen landing page', () => {
  it('renders a hero heading that names what the app is', () => {
    render(<App />);
    const h1 = screen.getByRole('heading', { level: 1 });
    // The hero must state the product plainly, not just set a mood.
    expect(h1).toHaveTextContent(/home app/i);
    expect(h1).toHaveTextContent(/asks before it acts/i);
  });

  it('renders the beta pill', () => {
    render(<App />);
    expect(screen.getByText(/^beta on testflight$/i)).toBeInTheDocument();
  });

  it('renders a light/dark theme toggle', () => {
    render(<App />);
    expect(screen.getByRole('button', { name: /switch to light mode/i })).toBeInTheDocument();
  });

  it('states calm consent-first positioning', () => {
    render(<App />);
    expect(screen.getAllByText(/suggestions always ask first/i).length).toBeGreaterThan(0);
    expect(screen.getAllByText(/open to everyone/i).length).toBeGreaterThan(0);
  });

  it('renders core nav links', () => {
    render(<App />);
    const nav = screen.getByRole('navigation');
    expect(within(nav).getByRole('link', { name: /features/i })).toHaveAttribute('href', '#features');
    expect(within(nav).getByRole('link', { name: /preview/i })).toHaveAttribute('href', '#demo');
    expect(within(nav).getByRole('link', { name: /privacy/i })).toHaveAttribute('href', '/privacy');
  });

  it('links to the privacy and terms pages from the footer', () => {
    render(<App />);
    const footerLinks = screen.getAllByRole('link');
    expect(footerLinks.some(a => a.getAttribute('href') === '/terms')).toBe(true);
    expect(footerLinks.some(a => a.getAttribute('href') === '/privacy')).toBe(true);
  });

  it('renders guided demo steps', () => {
    render(<App />);
    expect(screen.getByText(/try the flow/i)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /lumen noticed: tap the suggestion card/i })).toBeInTheDocument();
  });

  it('renders getting started section', () => {
    render(<App />);
    expect(screen.getByRole('heading', { name: /to your first run/i })).toBeInTheDocument();
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

  it('renders the interactive preview without an overlay', () => {
    render(<App />);
    expect(screen.getByText(/^interactive preview$/i)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /auto tab/i })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /home tab/i })).toBeInTheDocument();
    expect(screen.queryByRole('button', { name: /close app preview/i })).not.toBeInTheDocument();
  });

  it('does not name a clinical audience in public copy', () => {
    render(<App />);
    expect(document.body.textContent).not.toMatch(/neurodiverg|autism|\bADHD\b|sensory processing/i);
  });

  it('keeps em dashes out of the rendered copy', () => {
    // Em dashes read as machine-written filler here; the house style is a
    // full stop or a comma instead. Guard it so it does not creep back.
    render(<App />);
    expect(document.body.textContent).not.toContain('\u2014');
  });

  it('hides the suggestion card when Suggestions is Quiet', async () => {
    const user = userEvent.setup();
    render(<App />);

    await user.click(screen.getByRole('button', { name: /settings tab/i }));
    await user.click(screen.getByRole('button', { name: /^quiet$/i }));
    await user.click(screen.getByRole('button', { name: /home tab/i }));

    expect(screen.getByText(/lumen is staying quiet/i)).toBeInTheDocument();
    expect(screen.queryByRole('button', { name: /review evening scene/i })).not.toBeInTheDocument();
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
