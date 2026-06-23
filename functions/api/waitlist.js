const DEFAULT_TO_EMAIL = 'm.rafiq2006@icloud.com';
const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function json(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      'Content-Type': 'application/json',
      'Cache-Control': 'no-store',
    },
  });
}

async function postSupabase(env, { email, source, userAgent }) {
  const supabaseUrl = env.LUMEN_SUPABASE_URL || env.SUPABASE_URL || env.VITE_SUPABASE_URL;
  const supabaseKey =
    env.LUMEN_SUPABASE_SERVICE_ROLE_KEY ||
    env.SUPABASE_SERVICE_ROLE_KEY ||
    env.LUMEN_SUPABASE_ANON_KEY ||
    env.SUPABASE_ANON_KEY ||
    env.VITE_SUPABASE_ANON_KEY;

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

async function postWebhook(env, payload) {
  const webhookUrl = env.WAITLIST_WEBHOOK_URL || env.LUMEN_WAITLIST_WEBHOOK_URL;
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

async function sendResendEmail(env, { email, source, userAgent }) {
  const apiKey = env.RESEND_API_KEY;
  if (!apiKey) return false;

  const to = env.WAITLIST_TO_EMAIL || DEFAULT_TO_EMAIL;
  const from = env.WAITLIST_FROM_EMAIL || 'Lumen Waitlist <onboarding@resend.dev>';

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

async function sendFormSubmitEmail(env, { email, source, userAgent }) {
  const to = env.WAITLIST_TO_EMAIL || DEFAULT_TO_EMAIL;
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

export async function onRequest(context) {
  const { request, env } = context;

  if (request.method !== 'POST') {
    return json({ ok: false, error: 'Method not allowed' }, 405);
  }

  let payload = {};
  try {
    payload = await request.json();
  } catch {
    payload = {};
  }

  const email = String(payload.email || '').trim().toLowerCase();
  const source = String(payload.source || 'lumen-site').trim();
  const userAgent = request.headers.get('user-agent') || payload.user_agent || '';

  if (!EMAIL_PATTERN.test(email)) {
    return json({ ok: false, error: 'A valid email is required.' }, 400);
  }

  const normalizedPayload = {
    email,
    source,
    userAgent,
    submittedAt: new Date().toISOString(),
  };

  try {
    const delivered =
      (await postWebhook(env, normalizedPayload)) ||
      (await postSupabase(env, normalizedPayload)) ||
      (await sendResendEmail(env, normalizedPayload)) ||
      (await sendFormSubmitEmail(env, normalizedPayload));

    return json({ ok: delivered });
  } catch (error) {
    console.error(error);
    return json({ ok: false, error: 'Unable to submit waitlist request.' }, 500);
  }
}
