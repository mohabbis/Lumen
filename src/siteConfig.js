export const TESTFLIGHT_URL = import.meta.env.VITE_TESTFLIGHT_URL || "";
export function getSignupConfig(env = import.meta.env) {
  return {
    endpoint: env.VITE_WAITLIST_ENDPOINT || "/api/waitlist",
    contactEmail: "m.rafiq2006@icloud.com",
  };
}
export const isSignupConfigured = (config) => Boolean(config.endpoint);
