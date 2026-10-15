import {
  isValidWaitlistEmail,
  normalizeWaitlistPayload,
} from "../lib/waitlist.js";
import { getSignupConfig } from "./siteConfig.js";
export const normalizeEmail = (email) =>
  normalizeWaitlistPayload({ email }).email;
export const isValidEmail = isValidWaitlistEmail;

export async function submitWaitlist(
  email,
  config = getSignupConfig(),
  { fetchImpl = fetch, timeoutMs = 12000 } = {},
) {
  const normalized = normalizeEmail(email);
  if (!isValidEmail(normalized))
    throw new Error("Enter a valid email address.");
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    if (!config.endpoint)
      throw new Error(
        "Online signup is not configured. Please contact us by email.",
      );
    const response = await fetchImpl(config.endpoint, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email: normalized, source: "lumen-site" }),
      signal: controller.signal,
    });
    const body = await response.json().catch(() => null);
    if (response.status === 409 && body?.code === "already_subscribed")
      return { status: "duplicate", email: normalized };
    if (!response.ok || body?.ok !== true)
      throw new Error(
        "We couldn’t confirm your signup. Please try again, or contact us below.",
      );
    return { status: "success", email: normalized };
  } catch (error) {
    if (error.name === "AbortError")
      throw new Error(
        "The connection took too long. Your signup is unconfirmed. Please try again.",
      );
    if (error instanceof TypeError)
      throw new Error(
        "We couldn’t reach the signup service. Check your connection and try again.",
      );
    throw error;
  } finally {
    clearTimeout(timer);
  }
}
