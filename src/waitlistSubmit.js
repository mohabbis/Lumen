import { DEFAULT_TO_EMAIL } from '../lib/waitlist.js';

async function postJson(url, body) {
  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });

  let data = null;
  try {
    data = await response.json();
  } catch {
    // Some providers return empty bodies on success.
  }

  return { response, data };
}

async function submitViaApi(email, source) {
  const endpoint = import.meta.env.VITE_WAITLIST_ENDPOINT || '/api/waitlist';
  const { response, data } = await postJson(endpoint, { email, source });

  if (!response.ok) return false;
  if (data && data.ok === false) return false;
  return true;
}

async function submitViaWeb3Forms(email, source) {
  const accessKey = import.meta.env.VITE_WEB3FORMS_ACCESS_KEY;
  if (!accessKey) return false;

  const { response, data } = await postJson('https://api.web3forms.com/submit', {
    access_key: accessKey,
    subject: 'New Lumen waitlist request',
    from_name: 'Lumen Waitlist',
    email,
    message: `Email: ${email}\nSource: ${source}`,
  });

  return response.ok && data?.success === true;
}

async function submitViaFormSubmit(email, source) {
  const to = import.meta.env.VITE_WAITLIST_TO_EMAIL || DEFAULT_TO_EMAIL;
  const { response, data } = await postJson(`https://formsubmit.co/ajax/${encodeURIComponent(to)}`, {
    _subject: 'New Lumen waitlist request',
    _template: 'box',
    email,
    source,
  });

  if (!response.ok) return false;
  if (data && data.success === false) return false;
  return true;
}

export async function submitWaitlist(email, source = 'lumen-site') {
  const normalizedEmail = String(email || '').trim().toLowerCase();

  if (await submitViaApi(normalizedEmail, source)) {
    return true;
  }

  if (await submitViaWeb3Forms(normalizedEmail, source)) {
    return true;
  }

  return submitViaFormSubmit(normalizedEmail, source);
}
