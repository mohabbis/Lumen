import { afterEach, describe, expect, it, vi } from 'vitest';
import {
  DEFAULT_TO_EMAIL,
  deliverWaitlist,
  isValidWaitlistEmail,
  normalizeWaitlistPayload,
  postSupabase,
  postWebhook,
  sendResendEmail,
  sendWeb3FormsEmail,
} from '../lib/waitlist.js';

const payload = {
  email: 'beta@example.com',
  source: 'lumen-site',
  userAgent: 'vitest',
  submittedAt: '2026-07-10T00:00:00.000Z',
};

describe('waitlist helpers', () => {
  afterEach(() => {
    vi.unstubAllGlobals();
    vi.restoreAllMocks();
  });

  it('normalizes email and source', () => {
    expect(
      normalizeWaitlistPayload({
        email: '  Beta@Example.COM ',
        source: ' hero ',
        userAgent: 'test-agent',
      }),
    ).toEqual({
      email: 'beta@example.com',
      source: 'hero',
      userAgent: 'test-agent',
      submittedAt: expect.any(String),
    });
  });

  it('rejects invalid emails', () => {
    expect(isValidWaitlistEmail('not-an-email')).toBe(false);
    expect(isValidWaitlistEmail('beta@example.com')).toBe(true);
  });

  it('returns false when no configured provider succeeds', async () => {
    const fetchMock = vi.fn().mockResolvedValue({ ok: false, text: async () => 'blocked' });
    vi.stubGlobal('fetch', fetchMock);

    const delivered = await deliverWaitlist(payload, {});

    expect(delivered).toBe(false);
    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect(fetchMock.mock.calls[0][0]).toContain('formsubmit.co/ajax/');
  });

  it('continues when one configured provider fails', async () => {
    const fetchMock = vi
      .fn()
      .mockResolvedValueOnce({ ok: false, text: async () => 'webhook failed' })
      .mockResolvedValueOnce({ ok: true });
    vi.stubGlobal('fetch', fetchMock);

    const delivered = await deliverWaitlist(payload, {
      WAITLIST_WEBHOOK_URL: 'https://hooks.example/waitlist',
      RESEND_API_KEY: 're_test',
      WAITLIST_TO_EMAIL: DEFAULT_TO_EMAIL,
    });

    expect(delivered).toBe(true);
    expect(fetchMock).toHaveBeenCalledTimes(2);
  });

  it('posts to Supabase when configured', async () => {
    const fetchMock = vi.fn().mockResolvedValue({ ok: true });
    vi.stubGlobal('fetch', fetchMock);

    const delivered = await postSupabase(payload, {
      SUPABASE_URL: 'https://example.supabase.co',
      SUPABASE_ANON_KEY: 'anon-key',
    });

    expect(delivered).toBe(true);
    expect(fetchMock).toHaveBeenCalledWith(
      'https://example.supabase.co/rest/v1/lumen_waitlist',
      expect.objectContaining({
        method: 'POST',
        headers: expect.objectContaining({
          apikey: 'anon-key',
        }),
      }),
    );
  });

  it('returns false when webhook is missing', async () => {
    expect(await postWebhook(payload, {})).toBe(false);
  });

  it('returns false when Resend is missing', async () => {
    expect(await sendResendEmail(payload, {})).toBe(false);
  });

  it('accepts Web3Forms success responses', async () => {
    const fetchMock = vi.fn().mockResolvedValue({
      ok: true,
      json: async () => ({ success: true }),
    });
    vi.stubGlobal('fetch', fetchMock);

    const delivered = await sendWeb3FormsEmail(payload, {
      WEB3FORMS_ACCESS_KEY: 'web3-key',
    });

    expect(delivered).toBe(true);
  });
});
