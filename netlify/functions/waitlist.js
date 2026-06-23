const DEFAULT_TO_EMAIL = 'm.rafiq2006@icloud.com';
const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function response(statusCode, body) {
  return {
    statusCode,
    headers: {
      'Content-Type': 'application/json',
      'Cache-Control': 'no-store',
    },
    body: JSON.stringify(body),
  };
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

  const result = await fetch(`${supabaseUrl.replace(/\/$/, '')}/rest/v1/lumen_waitlist`, {
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

  if (!result.ok) {
    const message = await result.text();
    throw new Error(`Supabase waitlist insert failed: ${result.status} ${message}`);
  }

  return true;
}

async function postWebhook(payload) {
  const webhookUrl = process.env.WAITLIST_WEBHOOK_URL || process.env.LUMEN_WAITLIST_WEBHOOK_URL;
  if (!webhookUrl) return false;

  const result = await fetch(webhookUrl, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });

  if (!result.ok) {
    const message = await result.text();
    throw new Error(`Waitlist webhook failed: ${result.status} ${message}`);
  }

  return true;
}

async function sendResendEmail({ email, source, userAgent }) {
  const apiKey = process.env.RESEND_API_KEY;
  if (!apiKey) return false;

  const to = process.env.WAITLIST_TO_EMAIL || DEFAULT_TO_EMAIL;
  const from = process.env.WAITLIST_FROM_EMAIL || 'Lumen Waitlist <onboarding@resend.dev>';

  const result = await fetch('https://api.resend.com/emails', {
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

  if (!result.ok) {
    const message = await result.text();
    throw new Error(`Resend waitlist email failed: ${result.status} ${message}`);
  }

  return true;
}

async function sendFormSubmitEmail({ email, source, userAgent }) {
  const to = process.env.WAITLIST_TO_EMAIL || DEFAULT_TO_EMAIL;
  const result = await fetch(`https://formsubmit.co/ajax/${encodeURIComponent(to)}`, {
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

  if (!result.ok) {
    const message = await result.text();
    throw new Error(`FormSubmit fallback failed: ${result.status} ${message}`);
  }

  return true;
}

export async function handler(event) {
  if (event.httpMethod !== 'POST') {
    return response(405, { ok: false, error: 'Method not allowed' });
  }

  let payload = {};
  try {
    payload = JSON.parse(event.body || '{}');
  } catch {
    payload = {};
  }

  const email = String(payload.email || '').trim().toLowerCase();
  const source = String(payload.source || 'lumen-site').trim();
  const userAgent = event.headers['user-agent'] || payload.user_agent || '';

  if (!EMAIL_PATTERN.test(email)) {
    return response(400, { ok: false, error: 'A valid email is required.' });
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

    return response(200, { ok: delivered });
  } catch (error) {
    console.error(error);
    return response(500, { ok: false, error: 'Unable to submit waitlist request.' });
  }
}
