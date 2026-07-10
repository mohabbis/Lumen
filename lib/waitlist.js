export const DEFAULT_TO_EMAIL = 'm.rafiq2006@icloud.com';
export const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export function normalizeWaitlistPayload({ email, source, userAgent }) {
  return {
    email: String(email || '').trim().toLowerCase(),
    source: String(source || 'lumen-site').trim(),
    userAgent: String(userAgent || '').trim(),
    submittedAt: new Date().toISOString(),
  };
}

export function isValidWaitlistEmail(email) {
  return EMAIL_PATTERN.test(String(email || '').trim().toLowerCase());
}

async function tryProvider(provider) {
  try {
    return await provider();
  } catch (error) {
    console.error(error);
    return false;
  }
}

export async function postWebhook(payload, env = process.env) {
  const webhookUrl = env.WAITLIST_WEBHOOK_URL || env.LUMEN_WAITLIST_WEBHOOK_URL;
  if (!webhookUrl) return false;

  const response = await fetch(webhookUrl, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });

  return response.ok;
}

export async function postSupabase(payload, env = process.env) {
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
      email: payload.email,
      source: payload.source,
      user_agent: payload.userAgent,
      submitted_at: payload.submittedAt,
    }),
  });

  return response.ok;
}

export async function sendResendEmail(payload, env = process.env) {
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
      text: `Email: ${payload.email}\nSource: ${payload.source}\nUser agent: ${payload.userAgent || 'unknown'}`,
    }),
  });

  return response.ok;
}

export async function sendWeb3FormsEmail(payload, env = process.env) {
  const accessKey = env.WEB3FORMS_ACCESS_KEY || env.VITE_WEB3FORMS_ACCESS_KEY;
  if (!accessKey) return false;

  const response = await fetch('https://api.web3forms.com/submit', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      access_key: accessKey,
      subject: 'New Lumen waitlist request',
      from_name: 'Lumen Waitlist',
      email: payload.email,
      message: `Email: ${payload.email}\nSource: ${payload.source}\nUser agent: ${payload.userAgent || 'unknown'}`,
    }),
  });

  if (!response.ok) return false;

  try {
    const data = await response.json();
    return data.success === true;
  } catch {
    return false;
  }
}

export async function sendFormSubmitEmail(payload, env = process.env) {
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
      email: payload.email,
      source: payload.source,
      user_agent: payload.userAgent || 'unknown',
    }),
  });

  return response.ok;
}

export async function deliverWaitlist(payload, env = process.env) {
  const providers = [
    () => postWebhook(payload, env),
    () => postSupabase(payload, env),
    () => sendResendEmail(payload, env),
    () => sendWeb3FormsEmail(payload, env),
    () => sendFormSubmitEmail(payload, env),
  ];

  for (const provider of providers) {
    if (await tryProvider(provider)) {
      return true;
    }
  }

  return false;
}
