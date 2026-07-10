import { afterEach, describe, expect, it, vi } from 'vitest';
import { submitWaitlist } from './waitlistSubmit.js';

describe('submitWaitlist', () => {
  afterEach(() => {
    vi.unstubAllGlobals();
    vi.restoreAllMocks();
  });

  it('succeeds when the API accepts the request', async () => {
    const fetchMock = vi.fn().mockResolvedValue({
      ok: true,
      json: async () => ({ ok: true }),
    });
    vi.stubGlobal('fetch', fetchMock);

    await expect(submitWaitlist('beta@example.com')).resolves.toBe(true);
    expect(fetchMock).toHaveBeenCalledTimes(1);
  });

  it('falls back to FormSubmit when the API rejects the request', async () => {
    const fetchMock = vi
      .fn()
      .mockResolvedValueOnce({
        ok: true,
        json: async () => ({ ok: false }),
      })
      .mockResolvedValueOnce({
        ok: true,
        json: async () => ({ success: true }),
      });
    vi.stubGlobal('fetch', fetchMock);

    await expect(submitWaitlist('beta@example.com')).resolves.toBe(true);
    expect(fetchMock).toHaveBeenCalledTimes(2);
    expect(fetchMock.mock.calls[1][0]).toContain('formsubmit.co/ajax/');
  });

  it('returns false when every channel fails', async () => {
    const fetchMock = vi.fn().mockResolvedValue({
      ok: false,
      json: async () => ({ ok: false }),
    });
    vi.stubGlobal('fetch', fetchMock);

    await expect(submitWaitlist('beta@example.com')).resolves.toBe(false);
  });
});
