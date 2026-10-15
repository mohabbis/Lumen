import { describe, expect, it, beforeEach } from 'vitest';
import { trackWaitlistEvent } from './waitlistAnalytics.js';

describe('waitlistAnalytics', () => {
  beforeEach(() => {
    window.dataLayer = [];
  });

  it('pushes events to dataLayer', () => {
    trackWaitlistEvent('submit_success', { source: 'test' });
    expect(window.dataLayer).toHaveLength(1);
    expect(window.dataLayer[0].event).toBe('waitlist_submit_success');
    expect(window.dataLayer[0].source).toBe('test');
  });
  it('never copies email or arbitrary detail into analytics', () => {
    trackWaitlistEvent('submit_error', { source: 'test', email: 'private@example.com', error: 'private' });
    expect(JSON.stringify(window.dataLayer)).not.toContain('private');
  });
  it('does not interrupt signup when an analytics sink is blocked', () => {
    window.dataLayer = Object.freeze([]);
    expect(() => trackWaitlistEvent('submit_success')).not.toThrow();
  });
});
