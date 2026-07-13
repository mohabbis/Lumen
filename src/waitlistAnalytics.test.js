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
});
