/** Lightweight waitlist funnel events — no third-party SDK required. */

export function trackWaitlistEvent(event, detail = {}) {
  if (typeof window === 'undefined') return;

  const payload = {
    event: `waitlist_${event}`,
    timestamp: new Date().toISOString(),
    ...detail,
  };

  window.dataLayer = window.dataLayer || [];
  window.dataLayer.push(payload);

  if (import.meta.env.DEV) {
    console.info('[waitlist]', payload);
  }
}
