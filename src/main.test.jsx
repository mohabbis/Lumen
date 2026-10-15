import { describe, expect, it } from 'vitest';
import { fireEvent, render, screen, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { axe } from 'jest-axe';
import { App } from './App.jsx';
const clickTab = async (user, name) => user.click(within(screen.getByRole('navigation', { name: 'Preview navigation' })).getByRole('button', { name, exact: true }));
describe('Lumen experience', () => {
  it('opens every destination and preserves active navigation', async () => {
    const user = userEvent.setup(); render(<App />);
    expect(screen.getByRole('heading', { level: 1 })).toHaveTextContent('Your home.Less to manage.');
    for (const name of ['Rooms', 'Intel', 'Auto', 'Settings', 'Home']) {
      await clickTab(user, name);
      expect(within(screen.getByRole('navigation', { name: 'Preview navigation' })).getByRole('button', { name, exact: true })).toHaveAttribute('aria-current', 'page');
    }
    expect(document.body.textContent).not.toMatch(/neurodiverg|autism|\bADHD\b|—/);
  });
  it('stages brightness, cancels safely, and synchronizes applied power and brightness', async () => {
    const user = userEvent.setup(); render(<App />);
    await user.click(screen.getByRole('button', { name: 'Living Room 2 lights on' }));
    await user.click(screen.getByRole('button', { name: 'Ceiling Light On · 72%' }));
    fireEvent.change(screen.getByRole('slider', { name: 'Brightness' }), { target: { value: '25' } });
    await user.click(screen.getByRole('button', { name: 'Cancel', exact: true }));
    expect(screen.getByRole('button', { name: 'Ceiling Light On · 72%' })).toBeInTheDocument();
    await user.click(screen.getByRole('button', { name: 'Ceiling Light On · 72%' }));
    fireEvent.change(screen.getByRole('slider', { name: 'Brightness' }), { target: { value: '25' } });
    await user.click(screen.getByRole('button', { name: 'Apply changes' }));
    await clickTab(user, 'Intel');
    expect(screen.getByRole('button', { name: 'Ceiling Light On · 25%' })).toBeInTheDocument();
    await user.click(screen.getByRole('button', { name: 'Ceiling Light On · 25%' }));
    await user.click(screen.getByRole('switch', { name: 'Ceiling Light power' }));
    expect(screen.getByRole('slider', { name: 'Brightness' })).toBeDisabled();
    await user.click(screen.getByRole('button', { name: 'Apply changes' }));
    await clickTab(user, 'Home');
    expect(screen.getByRole('button', { name: 'Living Room 1 light on' })).toBeInTheDocument();
  });
  it('previews, cancels, and applies exact scene values across screens', async () => {
    const user = userEvent.setup(); render(<App />);
    await clickTab(user, 'Auto'); await user.click(screen.getByRole('button', { name: /Evening Softer/ }));
    expect(screen.getAllByText('Power on · 40% brightness · 2700 K')).toHaveLength(2);
    await user.click(screen.getByRole('button', { name: 'Cancel', exact: true })); await clickTab(user, 'Intel');
    expect(screen.getByRole('button', { name: 'Ceiling Light On · 72%' })).toBeInTheDocument();
    await clickTab(user, 'Auto'); await user.click(screen.getByRole('button', { name: /Evening Softer/ }));
    await user.click(screen.getByRole('button', { name: 'Apply Evening', exact: true })); await clickTab(user, 'Intel');
    expect(screen.getByRole('button', { name: 'Ceiling Light On · 40%' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Pendant Light Off' })).toBeInTheDocument();
    await clickTab(user, 'Rooms'); expect(screen.getByRole('button', { name: 'Kitchen 0 lights on' })).toBeInTheDocument();
  });
  it('dismisses without changing devices and explains unavailable devices', async () => {
    const user = userEvent.setup(); render(<App />);
    await user.click(screen.getByRole('button', { name: /Lumen noticed A softer/ }));
    expect(screen.getByRole('dialog', { name: 'A softer evening?' })).toBeInTheDocument();
    await user.click(screen.getByRole('button', { name: 'Not now' }));
    expect(screen.getByText('Your home, your pace.')).toBeInTheDocument();
    await clickTab(user, 'Intel'); expect(screen.getByRole('button', { name: 'Ceiling Light On · 72%' })).toBeInTheDocument();
    await user.click(screen.getByRole('button', { name: 'Window Sensor Unavailable' }));
    expect(screen.queryByRole('button', { name: 'Apply changes' })).not.toBeInTheDocument();
    await user.click(screen.getByRole('button', { name: 'Close', exact: true }));
    await user.click(screen.getByRole('button', { name: 'Reset demo', exact: true }));
    expect(screen.getByRole('button', { name: /Lumen noticed A softer/ })).toBeInTheDocument();
  });
  it('guides, skips, restarts, and completes without autoplay', async () => {
    const user = userEvent.setup(); render(<App />);
    await user.click(screen.getByRole('button', { name: 'Try an evening routine' }));
    expect(screen.getByText('Step 1 of 2 · Review, then decide')).toBeInTheDocument();
    await user.click(screen.getByRole('button', { name: 'Skip walkthrough' }));
    expect(screen.queryByRole('dialog', { name: 'A softer evening?' })).not.toBeInTheDocument();
    await user.click(screen.getByRole('button', { name: 'Close preview' }));
    await user.click(screen.getByRole('button', { name: 'Try an evening routine' }));
    await user.click(screen.getByRole('button', { name: 'Apply Evening', exact: true }));
    expect(screen.getByText(/Step 2 of 2 · Evening applied/)).toBeInTheDocument();
    await user.click(screen.getByRole('button', { name: 'Restart', exact: true }));
    expect(screen.getByRole('dialog', { name: 'A softer evening?' })).toBeInTheDocument();
  });
  it('expands the same preview and restores focus on Escape', async () => {
    const user = userEvent.setup(); render(<App />);
    const opener = screen.getByRole('button', { name: 'Expand preview' });
    await user.click(opener); expect(screen.getByRole('dialog', { name: 'Interactive Lumen preview' })).toBeInTheDocument();
    expect(document.body.style.overflow).toBe('hidden');
    await user.keyboard('{Escape}');
    expect(screen.queryByRole('dialog', { name: 'Interactive Lumen preview' })).not.toBeInTheDocument();
    expect(opener).toHaveFocus();
  });
  it('dismisses responsive navigation with Escape and has no automated semantic violations', async () => {
    const user = userEvent.setup(); const { container } = render(<App />);
    const menu = container.querySelector('.menu-toggle');
    await user.click(menu);
    expect(menu).toHaveAttribute('aria-expanded', 'true');
    await user.keyboard('{Escape}'); expect(menu).toHaveFocus();
    expect((await axe(container)).violations).toEqual([]);
  });
});
