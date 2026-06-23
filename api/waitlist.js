const DEFAULT_TO_EMAIL = 'm.rafiq2006@icloud.com';
const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

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

async function postSupabase({ email, source, userAgent }) {
  const supabaseUrl = process.env.LUMEN_SUPABASE_URL || process.env.SUPABASE_URL || process.env.VITE_SUPABASE_URL;
  const supabaseKey =
    process.env.LUMEN_SUPABASE_SERVICE_ROLE_KEY ||
    process.env.SUPABASE_SERVICE_ROLE_KEY ||
    process.env.LUMEN_SUPABASE_ANON_KEY ||
    process.env.SUPABASE_ANON_KEY ||
    process.env.VITE_SUPABASE_ANON_KEY;

  if (!supabaseUrl || !supabaseKey) return false;

  const response = await fetch(`${supabaseUrl.replace(/\/$/, '')}/rest/v1/lumen_waitlist`, {
    method: 'POST',
    headers: {
      apikey: supabaseKey,
      Authorization: `Bearer ${supabaseKey}`,
      'Content-Type': 'application/json',
      Prefer: 'return=minimal',
    },
    body: JSON.stringify({
      email,
      source,
      user_agent: userAgent,
      submitted_at: new Date().toISOString(),
    }),
  });

  if (!response.ok) {
    const message = await response.text();
    throw new Error(`Supabase waitlist insert failed: ${response.status} ${message}`);
  }

  return true;
}

async function postWebhook(payload) {
  const webhookUrl = process.env.WAITLIST_WEBHOOK_URL || process.env.LUMEN_WAITLIST_WEBHOOK_URL;
  if (!webhookUrl) return false;

  const response = await fetch(webhookUrl, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });

  if (!response.ok) {
    const message = await response.text();
    throw new Error(`Waitlist webhook failed: ${response.status} ${message}`);
  }

  return true;
}

async function sendResendEmail({ email, source, userAgent }) {
  const apiKey = process.env.RESEND_API_KEY;
  if (!apiKey) return false;

  const to = process.env.WAITLIST_TO_EMAIL || DEFAULT_TO_EMAIL;
  const from = process.env.WAITLIST_FROM_EMAIL || 'Lumen Waitlist <onboarding@resend.dev>';

  const response = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      from,
      to,
      subject: 'New Lumen waitlist request',
      text: `Email: ${email}\nSource: ${source}\nUser agent: ${userAgent || 'unknown'}`,
    }),
  });

  if (!response.ok) {
    const message = await response.text();
    throw new Error(`Resend waitlist email failed: ${response.status} ${message}`);
  }

  return true;
}

async function sendFormSubmitEmail({ email, source, userAgent }) {
  const to = process.env.WAITLIST_TO_EMAIL || DEFAULT_TO_EMAIL;
  const response = await fetch(`https://formsubmit.co/ajax/${encodeURIComponent(to)}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Accept: 'application/json',
    },
    body: JSON.stringify({
      _subject: 'New Lumen waitlist request',
      _template: 'box',
      email,
      source,
      user_agent: userAgent || 'unknown',
    }),
  });

  if (!response.ok) {
    const message = await response.text();
    throw new Error(`FormSubmit fallback failed: ${response.status} ${message}`);
  }

  return true;
}

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    return json(res, 405, { ok: false, error: 'Method not allowed' });
  }

  const payload = getPayload(req);
  const email = String(payload.email || '').trim().toLowerCase();
  const source = String(payload.source || 'lumen-site').trim();
  const userAgent = req.headers['user-agent'] || payload.user_agent || '';

  if (!EMAIL_PATTERN.test(email)) {
    return json(res, 400, { ok: false, error: 'A valid email is required.' });
  }

  const normalizedPayload = {
    email,
    source,
    userAgent,
    submittedAt: new Date().toISOString(),
  };

  try {
    const delivered =
      (await postWebhook(normalizedPayload)) ||
      (await postSupabase(normalizedPayload)) ||
      (await sendResendEmail(normalizedPayload)) ||
      (await sendFormSubmitEmail(normalizedPayload));

    return json(res, 200, { ok: delivered });
  } catch (error) {
    console.error(error);
    return json(res, 500, { ok: false, error: 'Unable to submit waitlist request.' });
  }
}
