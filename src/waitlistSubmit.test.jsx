import { describe, expect, it, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { Waitlist } from "./components/Waitlist.jsx";
import { normalizeEmail, submitWaitlist } from "./waitlistSubmit.js";
const config = { endpoint: "/api/waitlist", contactEmail: "test@example.com" };
const response = (status, body) =>
  new Response(body ? JSON.stringify(body) : null, {
    status,
    headers: { "content-type": "application/json" },
  });
describe("waitlist delivery contract", () => {
  it("normalizes email and preserves the internal API payload", async () => {
    const fetchImpl = vi.fn().mockResolvedValue(response(200, { ok: true }));
    expect(normalizeEmail("  HELLO@Example.COM ")).toBe("hello@example.com");
    expect(
      await submitWaitlist(" HELLO@Example.COM ", config, { fetchImpl }),
    ).toEqual({ status: "success", email: "hello@example.com" });
    expect(JSON.parse(fetchImpl.mock.calls[0][1].body)).toEqual({
      email: "hello@example.com",
      source: "lumen-site",
    });
    expect(fetchImpl).toHaveBeenCalledTimes(1);
  });
  it.each([400, 429, 500])("rejects HTTP %s", async (status) => {
    await expect(
      submitWaitlist("hello@example.com", config, {
        fetchImpl: vi.fn().mockResolvedValue(response(status)),
      }),
    ).rejects.toThrow("confirm");
  });
  it.each([{ ok: false }, { success: true }, null])(
    "requires an explicit API acknowledgement: %s",
    async (body) => {
      await expect(
        submitWaitlist("hello@example.com", config, {
          fetchImpl: vi.fn().mockResolvedValue(response(200, body)),
        }),
      ).rejects.toThrow("confirm");
    },
  );
  it("recognizes only explicit duplicate responses", async () => {
    expect(
      (
        await submitWaitlist("hello@example.com", config, {
          fetchImpl: vi
            .fn()
            .mockResolvedValue(response(409, { code: "already_subscribed" })),
        })
      ).status,
    ).toBe("duplicate");
    await expect(
      submitWaitlist("hello@example.com", config, {
        fetchImpl: vi.fn().mockResolvedValue(response(409, { code: "other" })),
      }),
    ).rejects.toThrow();
  });
  it("handles network failure, timeout, and invalid addresses without provider fan-out", async () => {
    await expect(submitWaitlist("invalid", config)).rejects.toThrow(
      "valid email",
    );
    const fetchImpl = vi.fn().mockRejectedValue(new TypeError("offline"));
    await expect(
      submitWaitlist("a@example.com", config, { fetchImpl }),
    ).rejects.toThrow("connection");
    expect(fetchImpl).toHaveBeenCalledTimes(1);
    await expect(
      submitWaitlist("a@example.com", config, {
        timeoutMs: 1,
        fetchImpl: (_url, options) =>
          new Promise((_resolve, reject) =>
            options.signal.addEventListener("abort", () =>
              reject(new DOMException("timeout", "AbortError")),
            ),
          ),
      }),
    ).rejects.toThrow("unconfirmed");
  });
  it("validates, announces success, and prevents duplicate pending submits", async () => {
    const user = userEvent.setup();
    let resolve;
    const submit = vi.fn().mockImplementation(
      () =>
        new Promise((done) => {
          resolve = done;
        }),
    );
    render(<Waitlist config={config} submit={submit} />);
    await user.click(screen.getByRole("button", { name: "Join the waitlist" }));
    expect(screen.getByRole("alert")).toHaveTextContent("valid email");
    await user.type(screen.getByRole("textbox"), "hello@example.com");
    await user.dblClick(
      screen.getByRole("button", { name: "Join the waitlist" }),
    );
    expect(submit).toHaveBeenCalledTimes(1);
    expect(screen.getByRole("button", { name: "Joining…" })).toBeDisabled();
    resolve({ status: "success" });
    expect(
      await screen.findByText(/You’re on the waitlist/),
    ).toBeInTheDocument();
    expect(screen.getByRole("textbox")).toHaveValue("");
  });
  it("keeps email on failure and permits retry", async () => {
    const user = userEvent.setup();
    const submit = vi
      .fn()
      .mockRejectedValueOnce(new Error("Connection failed. Try again."))
      .mockResolvedValueOnce({ status: "success" });
    render(<Waitlist config={config} submit={submit} />);
    await user.type(screen.getByRole("textbox"), "hello@example.com");
    await user.click(screen.getByRole("button", { name: "Join the waitlist" }));
    expect(await screen.findByRole("alert")).toHaveTextContent(
      "Connection failed",
    );
    expect(screen.getByRole("textbox")).toHaveValue("hello@example.com");
    await user.click(screen.getByRole("button", { name: "Join the waitlist" }));
    expect(
      await screen.findByText(/You’re on the waitlist/),
    ).toBeInTheDocument();
  });
  it("offers an honest email handoff when unconfigured", () => {
    render(<Waitlist config={{ contactEmail: "test@example.com" }} />);
    expect(screen.queryByRole("textbox")).not.toBeInTheDocument();
    expect(
      screen.getByRole("link", { name: "Email to request access" }),
    ).toHaveAttribute(
      "href",
      "mailto:test@example.com?subject=Lumen%20waitlist",
    );
    expect(screen.getByText(/does not automatically join/)).toBeInTheDocument();
  });
});
