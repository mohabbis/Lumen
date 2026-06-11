import React, { useState } from 'react';
import { motion } from 'framer-motion';
import {
  ArrowRight, Brain, CheckCircle2, Home, Lightbulb, Menu, SunMedium, X,
} from 'lucide-react';
import './App.css';

// Data

const screens = [
  {
    id: 'awareness',
    label: 'Arrive',
    title: 'Welcome back',
    subtitle: 'Presence detected. Evening routine is ready.',
    card: 'Today',
    icon: Home,
    rows: ['Bedroom calm', 'Desk lamp ready', 'Kitchen off', 'Hallway quiet'],
    insight: 'Lumen noticed you arrived and prepared a soft evening setup.',
    action: 'Review setup',
  },
  {
    id: 'control',
    label: 'Tune',
    title: 'Living Room',
    subtitle: 'Comfortable light. Manual controls nearby.',
    card: 'Room state',
    icon: Lightbulb,
    rows: ['Lights 70% to 42%', 'Shades partly open', 'Temperature steady', 'Air quality clear'],
    insight: 'The room is bright for this time of day. Warmer light may feel better.',
    action: 'Tune room',
  },
  {
    id: 'reasoning',
    label: 'Explain',
    title: 'Why this suggestion?',
    subtitle: 'Presence, time, and room state moved together.',
    card: 'Signals',
    icon: Brain,
    rows: ['Presence confirmed', 'Sunset window', 'Room active', 'Confidence high'],
    insight: 'Every suggestion shows the signals behind it before anything changes.',
    action: 'Review logic',
  },
  {
    id: 'action',
    label: 'Approve',
    title: 'Evening Comfort',
    subtitle: 'Ready to apply. Nothing runs silently.',
    card: 'Scene preview',
    icon: CheckCircle2,
    rows: ['Lights soften', 'Temperature lowers', 'Shades adjust', 'Scene stays editable'],
    insight: 'One clear confirmation applies the scene. You stay in control.',
    action: 'Apply scene',
  },
];

const reasoning = [
  ['Signal', 'Lumen reads presence, light, time of day, and room state.'],
  ['Context', 'It compares those signals against your routines without sending them away.'],
  ['Suggestion', 'It proposes one calm next step instead of throwing another dashboard at you.'],
  ['Approval', 'You see the reason, review the change, and decide whether it runs.'],
];

const stack = [
  ['SwiftUI', 'Native iPhone interface'],
  ['Apple native integrations', 'Secure device access'],
  ['SwiftData', 'Local-first persistence'],
  ['Private sync ready', 'Continuity when enabled'],
  ['On-device reasoning', 'Suggestions without surveillance'],
  ['Matter-ready', 'Designed to support more ecosystems'],
];

const shipped = [
  'Arrival awareness with a clear welcome flow',
  'Background geofence support for arrival and departure',
  'Scene previews with confirmation before action',
  'Local temperature and humidity sensor support',
  'Native smart device discovery and control',
  'Local-first persistence for homes, rooms, and scenes',
];

const inProgress = [
  'Cleaner scene trigger controls',
  'Automation notifications',
  'Multi-home polish',
  'More useful sensor-based suggestions',
];

const coming = [
  'On-device reasoning engine',
  'Expanded Matter support',
  'TestFlight public beta',
  'Energy usage insights',
];

// Primitives

function FadeIn({ children, delay = 0, className = '' }) {
  return (
    <motion.div
      className={className}
      initial={{ opacity: 0, y: 18 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: '-60px' }}
      transition={{ duration: 0.65, delay, ease: [0.21, 0.8, 0.32, 1] }}
    >
      {children}
    </motion.div>
  );
}

function AppScreen({ screen, featured = false }) {
  const Icon = screen.icon;
  return (
    <div className={featured ? 'phone phone-featured' : 'phone mini-phone'}>
      <div className="phone-screen">
        <div className="phone-status">
          <span>9:41</span>
          <span className="dynamic-island" />
          <span>5G</span>
        </div>
        <div className="app-brand">LUMEN</div>
        <div className="screen-header">
          <div>
            <p className="screen-kicker">{screen.label}</p>
            <h3>{screen.title}</h3>
            <p>{screen.subtitle}</p>
          </div>
          <div className="avatar-dot"><Icon size={16} /></div>
        </div>
        <div className="chip-row">
          <span>4 rooms</span><span>12 devices</span><span>Private</span>
        </div>
        <div className="main-card">
          <div className="main-card-head"><b>{screen.card}</b><ArrowRight size={13} /></div>
          <div className="room-grid">
            {screen.rows.map((row, i) => (
              <div className="room-cell" key={row}>
                <span>{row}</span>
                <small>{i % 2 === 0 ? 'Active' : 'Ready'}</small>
              </div>
            ))}
          </div>
        </div>
        <div className="reason-card">
          <b>Lumen noticed</b>
          <span>{screen.insight}</span>
        </div>
        <div className="presence-card">
          <div>
            <b>{screen.action}</b>
            <span>{screen.id === 'action' ? 'Confirm changes' : 'Suggested'}</span>
          </div>
          <div className="pulse-dot" />
        </div>
        <div className="tabbar">
          <span className="active">Home</span>
          <span>Rooms</span>
          <span>Scenes</span>
          <span>Logic</span>
        </div>
      </div>
    </div>
  );
}

// Sections

function ProductGallery() {
  const [active, setActive] = useState(0);
  return (
    <section className="section gallery" id="product">
      <FadeIn className="section-copy centered">
        <p className="eyebrow">The experience</p>
        <h2>From awareness to action,<br />without the clutter.</h2>
        <p>
          Lumen turns scattered smart-home controls into one calm flow: notice,
          explain, preview, approve.
        </p>
      </FadeIn>

      <div className="story-steps">
        {screens.map((screen, i) => {
          const Icon = screen.icon;
          return (
            <button
              key={screen.id}
              className={active === i ? 'active' : ''}
              onClick={() => setActive(i)}
            >
              <Icon size={16} />
              <b>{screen.label}</b>
              <span>{screen.insight}</span>
            </button>
          );
        })}
      </div>

      <div className="screen-gallery">
        {screens.map((screen, i) => (
          <motion.div
            layout
            className={active === i ? 'selected' : ''}
            key={screen.id}
          >
            <AppScreen screen={screen} />
          </motion.div>
        ))}
      </div>
    </section>
  );
}

function ChallengeSection() {
  const modules = [
    {
      label: 'The problem',
      title: 'Smart homes still make you manage everything.',
      body: 'Most apps expose every device, toggle, scene, and automation at once. That is control, technically. It is also mental clutter with a prettier icon grid.',
      stat: '12+',
      statLabel: 'apps many smart homes end up juggling',
    },
    {
      label: 'The shift',
      title: 'Lumen starts with what is happening now.',
      body: 'It reads presence, time, light, and room state, then turns that context into one useful next step instead of another menu to decode.',
      stat: 'Local',
      statLabel: 'reasoning is designed to stay on device',
    },
    {
      label: 'The rule',
      title: 'No silent changes. No mystery automations.',
      body: 'Every suggestion is explained first. Every action gets a confirmation surface. The app earns trust by being legible, not by pretending to be magic.',
      stat: '1 tap',
      statLabel: 'review, approve, or ignore',
    },
  ];

  return (
    <section className="challenge-section" id="approach">
      <FadeIn className="challenge-header">
        <p className="eyebrow">Case study — Lumen</p>
        <h2>Reducing cognitive load<br />in the modern smart home.</h2>
      </FadeIn>
      <div className="impact-modules">
        {modules.map((mod, i) => (
          <FadeIn key={mod.label} delay={i * 0.07} className="impact-module">
            <p className="module-label">{mod.label}</p>
            <h3 className="module-title">{mod.title}</h3>
            <p className="module-body">{mod.body}</p>
            <div className="module-stat">
              <span className="stat-value">{mod.stat}</span>
              <span className="stat-label">{mod.statLabel}</span>
            </div>
          </FadeIn>
        ))}
      </div>
    </section>
  );
}

function ReasoningSection() {
  return (
    <section className="reasoning-section">
      <div className="reasoning-inner">
        <FadeIn className="reasoning-copy">
          <p className="eyebrow">How Lumen thinks</p>
          <h2>Readable intelligence,<br />not black-box automation.</h2>
          <p>
            The interface is built around consent. Lumen can notice patterns,
            but it has to explain itself before it changes your environment.
          </p>
          <a className="reasoning-cta" href="#product">
            See the flow <ArrowRight size={14} />
          </a>
        </FadeIn>
        <div className="reasoning-steps">
          {reasoning.map(([label, text], i) => (
            <FadeIn key={label} delay={i * 0.07} className="reasoning-step">
              <span className="step-number">0{i + 1}</span>
              <div className="step-content">
                <b className="step-label">{label}</b>
                <p className="step-text">{text}</p>
              </div>
            </FadeIn>
          ))}
        </div>
      </div>
    </section>
  );
}

function StatusSection() {
  return (
    <section className="status-section" id="status">
      <FadeIn className="section-copy">
        <p className="eyebrow">Development status</p>
        <h2>Close to TestFlight.<br />Built carefully, not loudly.</h2>
        <p>What works now, what is being polished, and what comes next.</p>
      </FadeIn>
      <div className="status-columns">
        <div className="status-col">
          <div className="status-col-head shipped">Shipped</div>
          <ul>{shipped.map(item => <li key={item}>{item}</li>)}</ul>
        </div>
        <div className="status-col">
          <div className="status-col-head in-progress">In Progress</div>
          <ul>{inProgress.map(item => <li key={item}>{item}</li>)}</ul>
        </div>
        <div className="status-col">
          <div className="status-col-head coming">Coming Soon</div>
          <ul>{coming.map(item => <li key={item}>{item}</li>)}</ul>
        </div>
      </div>
      <div className="github-link">
        <a href="https://github.com/mohabbis/lumen" target="_blank" rel="noopener noreferrer">
          View on GitHub <ArrowRight size={14} />
        </a>
      </div>
    </section>
  );
}

function StackSection() {
  return (
    <section className="stack-section" id="architecture">
      <FadeIn className="section-copy">
        <p className="eyebrow">Technical foundation</p>
        <h2>Private by default.<br />Native where it matters.</h2>
        <p>
          Lumen is built around local data, explainable suggestions, and device
          control that feels calm instead of technical.
        </p>
      </FadeIn>
      <div className="stack-grid">
        {stack.map(([name, desc]) => (
          <div key={name} className="stack-item">
            <b>{name}</b>
            <span>{desc}</span>
          </div>
        ))}
      </div>
    </section>
  );
}

function Waitlist() {
  const [status, setStatus] = useState('idle');

  async function handleSubmit(e) {
    e.preventDefault();
    const email = new FormData(e.currentTarget).get('email');
    setStatus('loading');
    try {
      const endpoint = import.meta.env.VITE_WAITLIST_ENDPOINT;
      const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
      const supabaseKey = import.meta.env.VITE_SUPABASE_ANON_KEY;
      if (endpoint) {
        await fetch(endpoint, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ email, source: 'lumen-site' }),
        });
      } else if (supabaseUrl && supabaseKey) {
        await fetch(`${supabaseUrl}/rest/v1/lumen_waitlist`, {
          method: 'POST',
          headers: {
            apikey: supabaseKey,
            Authorization: `Bearer ${supabaseKey}`,
            'Content-Type': 'application/json',
            Prefer: 'return=minimal',
          },
          body: JSON.stringify({ email, source: 'lumen-site', user_agent: navigator.userAgent }),
        });
      } else {
        window.location.href = `mailto:m.rafiq2006@icloud.com?subject=Lumen%20Early%20Access&body=${encodeURIComponent(`Please add me to the Lumen waitlist: ${email}`)}`;
      }
      setStatus('success');
      e.target.reset();
    } catch {
      setStatus('error');
    }
  }

  return (
    <section className="waitlist-section" id="access">
      <div className="waitlist-inner">
        <FadeIn className="waitlist-copy">
          <p className="eyebrow">Early access</p>
          <h2>Try the calmer<br />smart-home layer.</h2>
          <p>
            A private iPhone beta for people who want their home to feel easier,
            not busier. No spam, no fake urgency, no app-store circus.
          </p>
        </FadeIn>
        <FadeIn delay={0.1} className="waitlist-form-wrap">
          <form className="waitlist-form" onSubmit={handleSubmit}>
            <input
              name="email"
              type="email"
              placeholder="Your email address"
              required
            />
            <button disabled={status === 'loading'}>
              {status === 'loading' ? 'Joining...' : 'Request access'}
              <ArrowRight size={15} />
            </button>
          </form>
          <div className="waitlist-checks">
            <span>iOS first</span>
            <span>Private beta</span>
            <span>No spam</span>
          </div>
          {status === 'success' && (
            <p className="form-note">
              You're on the list. We'll reach out when Lumen is ready.
            </p>
          )}
          {status === 'error' && (
            <p className="form-note error">
              Something went wrong. Try{' '}
              <a href="mailto:m.rafiq2006@icloud.com">m.rafiq2006@icloud.com</a>.
            </p>
          )}
        </FadeIn>
      </div>
    </section>
  );
}

// App shell

export function App() {
  const [menuOpen, setMenuOpen] = useState(false);
  const close = () => setMenuOpen(false);

  return (
    <main className="site-shell">
      <div className="grain" />

      <nav className="nav">
        <a className="logo" href="#top">
          <SunMedium size={22} />
          <span>LUMEN</span>
        </a>
        <div className="links">
          <a href="#product">The App</a>
          <a href="#approach">Approach</a>
          <a href="#status">Status</a>
          <a href="/privacy">Privacy</a>
        </div>
        <div className="nav-actions">
          <a href="#access">Request Access</a>
          <button
            aria-label={menuOpen ? 'Close menu' : 'Open menu'}
            onClick={() => setMenuOpen(o => !o)}
            className={menuOpen ? 'menu-btn open' : 'menu-btn'}
          >
            {menuOpen ? <X size={18} /> : <Menu size={18} />}
          </button>
        </div>
      </nav>

      {menuOpen && (
        <div className="mobile-menu" onClick={close}>
          <div className="mobile-menu-inner" onClick={e => e.stopPropagation()}>
            <a href="#product" onClick={close}><span>01</span>The App</a>
            <a href="#approach" onClick={close}><span>02</span>Approach</a>
            <a href="#status" onClick={close}><span>03</span>Status</a>
            <a href="/privacy" onClick={close} className="privacy-link"><span>04</span>Privacy</a>
            <a href="#access" onClick={close} className="mobile-cta">
              Request Access <ArrowRight size={14} />
            </a>
          </div>
        </div>
      )}

      <section className="hero" id="top">
        <div className="hero-bg" />

        <FadeIn className="hero-copy">
          <div className="pill">
            <span />
            Coming soon — iOS private beta
          </div>
          <h1>Your home<br /><em>should feel</em><br />lighter.</h1>
          <p>
            Lumen is a calm iPhone companion for your smart home. It notices
            context, explains what it sees, and asks before anything changes.
          </p>
          <div className="hero-actions">
            <a className="primary" href="#access">
              Request Early Access <ArrowRight size={15} />
            </a>
            <a className="ghost" href="#approach">See how it works</a>
          </div>
        </FadeIn>

        <motion.div
          className="hero-device"
          initial={{ opacity: 0, rotate: -8, y: 32 }}
          animate={{ opacity: 1, rotate: -4, y: 0 }}
          transition={{ duration: 1.0, delay: 0.15, ease: [0.21, 0.8, 0.32, 1] }}
        >
          <AppScreen screen={screens[0]} featured />
        </motion.div>
      </section>

      <div className="thesis-band">
        <FadeIn>
          <p>
            "Smart homes should reduce decisions,<br />
            not create a second operating system for your house."
          </p>
        </FadeIn>
      </div>

      <ChallengeSection />
      <ProductGallery />
      <ReasoningSection />
      <StatusSection />
      <StackSection />
      <Waitlist />

      <footer className="site-footer">
        <a className="logo" href="#top">
          <SunMedium size={17} /><span>LUMEN</span>
        </a>
        <p>Native iOS · On-device reasoning · Matter ready · Private beta</p>
        <div className="footer-links">
          <a href="/privacy">Privacy</a>
          <a
            href="https://github.com/mohabbis/lumen"
            target="_blank"
            rel="noopener noreferrer"
          >
            GitHub
          </a>
          <a href="mailto:m.rafiq2006@icloud.com">Contact</a>
        </div>
      </footer>
    </main>
  );
}
