import { beforeEach, describe, expect, it, vi } from "vitest";
vi.mock("../lib/waitlist.js", async (importOriginal) => ({
  ...(await importOriginal()),
  deliverWaitlist: vi.fn(),
}));
import handler from "./waitlist.js";
import { deliverWaitlist } from "../lib/waitlist.js";
function response() {
  return {
    code: null,
    headers: {},
    body: null,
    status(value) {
      this.code = value;
      return this;
    },
    setHeader(key, value) {
      this.headers[key] = value;
      return this;
    },
    end(value) {
      this.body = JSON.parse(value);
    },
  };
}
describe("waitlist API", () => {
  beforeEach(() => vi.clearAllMocks());
  it("rejects unsupported methods and invalid email without delivery", async () => {
    let res = response();
    await handler({ method: "GET" }, res);
    expect(res.code).toBe(405);
    res = response();
    await handler({ method: "POST", body: "{bad" }, res);
    expect(res.code).toBe(400);
    expect(deliverWaitlist).not.toHaveBeenCalled();
  });
  it("normalizes email and does not forward visitor user agents", async () => {
    deliverWaitlist.mockResolvedValueOnce(true);
    const res = response();
    await handler(
      {
        method: "POST",
        body: { email: "  HELLO@EXAMPLE.COM ", source: "hero" },
        headers: { "user-agent": "unnecessary-client-data" },
      },
      res,
    );
    expect(res.code).toBe(200);
    expect(res.body).toEqual({ ok: true });
    expect(res.headers["Cache-Control"]).toBe("no-store");
    expect(deliverWaitlist).toHaveBeenCalledWith(
      expect.objectContaining({ email: "hello@example.com", userAgent: "" }),
    );
  });
  it("returns a failure status when no provider accepts", async () => {
    deliverWaitlist.mockResolvedValueOnce(false);
    const res = response();
    await handler(
      { method: "POST", body: { email: "hello@example.com" } },
      res,
    );
    expect(res.code).toBe(503);
    expect(res.body.ok).toBe(false);
  });
  it("reports unconfirmed delivery without leaking provider errors", async () => {
    deliverWaitlist.mockRejectedValueOnce(new Error("secret provider context"));
    const res = response();
    await handler(
      { method: "POST", body: { email: "hello@example.com" } },
      res,
    );
    expect(res.code).toBe(503);
    expect(JSON.stringify(res.body)).not.toContain("secret");
  });
});
