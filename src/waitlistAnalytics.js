/** Lightweight waitlist funnel events — no third-party SDK required. */

export function trackWaitlistEvent(event, detail = {}) {
  if (typeof window === 'undefined') return;

  const payload = {
    event: `waitlist_${event}`,
    timestamp: new Date().toISOString(),
    source: String(detail.source || 'lumen-site').slice(0, 64),
  };

  // Analytics must never interrupt a real signup or change its outcome.
  try {
    if (!Array.isArray(window.dataLayer)) window.dataLayer = [];
    window.dataLayer.push(payload);
  } catch { /* A blocked analytics sink is noncritical. */ }
}
