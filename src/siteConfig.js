/** Shared marketing copy + env-driven links (Vite `import.meta.env`). */

export const SITE_TAGLINE = 'when your home shifts, you stay calm.';
export const SITE_DESCRIPTION =
  'Lumen is a calm home companion for iPhone. Gentle suggestions, plain-language reasoning, and confirmation before your home changes.';

export const TESTFLIGHT_URL = import.meta.env.VITE_TESTFLIGHT_URL || '';

export const guidedDemoSteps = [
  {
    id: 'home',
    label: 'Home',
    short: 'Open the dashboard',
  },
  {
    id: 'noticed',
    label: 'Lumen noticed',
    short: 'Tap the suggestion card',
  },
  {
    id: 'reasoning',
    label: 'Read why',
    short: 'See the signals',
  },
  {
    id: 'action',
    label: 'Confirm',
    short: 'Review what changes',
  },
  {
    id: 'scenes',
    label: 'Scenes',
    short: 'Try manual approval',
  },
];
