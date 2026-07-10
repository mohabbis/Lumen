import {
  deliverWaitlist,
  isValidWaitlistEmail,
  normalizeWaitlistPayload,
} from '../lib/waitlist.js';

function json(res, status, body) {
  res.status(status).setHeader('Content-Type', 'application/json');
  res.setHeader('Cache-Control', 'no-store');
  res.end(JSON.stringify(body));
}

function getPayload(req) {
  if (typeof req.body === 'object' && req.body !== null) return req.body;
  try {
    return JSON.parse(req.body || '{}');
  } catch {
    return {};
  }
}

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    return json(res, 405, { ok: false, error: 'Method not allowed' });
  }

  const payload = getPayload(req);
  const normalizedPayload = normalizeWaitlistPayload({
    email: payload.email,
    source: payload.source,
    userAgent: req.headers['user-agent'] || payload.user_agent || '',
  });

  if (!isValidWaitlistEmail(normalizedPayload.email)) {
    return json(res, 400, { ok: false, error: 'A valid email is required.' });
  }

  const delivered = await deliverWaitlist(normalizedPayload);
  return json(res, 200, { ok: delivered });
}
