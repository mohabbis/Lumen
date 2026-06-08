import React, { useState } from 'react';
import { motion } from 'framer-motion';
import {
  ArrowRight, Brain, CheckCircle2, Home, Lightbulb,
  LockKeyhole, Menu, Microchip, SunMedium, X,
} from 'lucide-react';
import './App.css';

// ─── Data ───────────────────────────────────────────────────────────────────

const screens = [
  {
    id: 'awareness', label: 'Awareness',
    title: 'Welcome Home', subtitle: 'Your location detected — 4 devices ready.',
    card: 'Rooms', icon: Home,
    rows: ['Bedroom  21.5°', 'Desk lamp ready', 'Kitchen all off', 'Hallway quiet'],
    insight: 'You arrived 2 min ago. Evening scene ready to run.',
    action: 'Welcome Home',
  },
  {
    id: 'control', label: 'Control',
    title: 'Living Room', subtitle: 'Comfortable · 4 devices · 2 sensors',
    card: 'Devices', icon: Lightbulb,
    rows: ['Lights  70% → 42%', 'Shades  35% open', 'Temp  22.5°', 'Air quality  ✓'],
    insight: 'Late-day glare is falling. Warm light will feel better.',
    action: 'Tune room',
  },
  {
    id: 'reasoning', label: 'Reasoning',
    title: 'Why Lumen dimmed', subtitle: 'Sunset, presence, and temperature moved together.',
    card: 'Signals', icon: Brain,
    rows: ['Presence detected', 'Sunset matched', 'Temp  +1.2°', 'Confidence high'],
    insight: 'Lumen explains its logic before acting — nothing feels random.',
    action: 'Review logic',
  },
  {
    id: 'action', label: 'Action',
    title: 'Evening Comfort', subtitle: 'Ready to apply — your call.',
    card: 'Scene changes', icon: CheckCircle2,
    rows: ['Lights  70% → 40%', 'Temp  22.5° → 21.5°', 'Shades  35% → 60%', 'Warm Evening'],
    insight: 'One tap applies the scene. Manual control stays close.',
    action: 'Apply scene',
  },
];

const reasoning = [
  ['Signal',        'Presence detected in the living room. Sunset lowering ambient light by 40%.'],
  ['Context',       'Temperature up 1.2° over the last hour. Your comfort preference sits at 21.5°.'],
  ['Suggestion',    'Warm Evening — lower the bulbs, adjust the shades, cool slightly. Fits your patterns.'],
  ['Confirmation',  'Nothing runs without your approval. Every change is explained before it happens.'],
];

const stack = [
  ['SwiftUI',       'Native iPhone interface'],
  ['HomeKit',       'Deep, secure device access'],
  ['SwiftData',     'Local-first persistence'],
  ['CloudKit',      'Private continuity across devices'],
  ['On-device AI',  'Reasoning without surveillance'],
  ['Matter-ready',  'Built to evolve with your home'],
];

const shipped = [
  'Location awareness with arrival greeting',
  'Background geofence automations — arrival & departure, even with the app closed',
  'Scene execution across all HomeKit devices',
  'Local temperature and humidity sensor support',
  'HomeKit device discovery and control',
  'SwiftData persistence with iCloud sync ready',
];

const inProgress = [
  'Scene trigger UI controls',
  'Automation push notifications',
  'Multi-home support',
  'Advanced sensor-based reasoning',
];

const coming = [
  'On-device AI reasoning engine',
  'Matter protocol support',
  'TestFlight public beta',
  'Energy usage insights',
];

// ─── Primitives ──────────────────────────────────────────────────────────────

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
          <span>4 rooms</span><span>12 devices</span><span>3 automations</span>
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
          <span>Intel</span>
          <span>Auto</span>
        </div>
      </div>
    </div>
  );
}

// ─── Sections ────────────────────────────────────────────────────────────────

function ProductGallery() {
  const [active, setActive] = useState(0);
  return (
    <section className="section gallery" id="product">
      <FadeIn className="section-copy centered">
        <p className="eyebrow">The experience</p>
        <h2>Awareness to action —<br />one calm flow.</h2>
        <p>
          Four moments: knowing you're home, understanding what's happening,
          explaining the thinking, and waiting for your word.
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
      label: 'The challenge',
      title: 'Smart homes are reactive by design.',
      body: 'Devices respond to commands, not context. Every scene, schedule, and automation still requires you to initiate. Presence in the room isn\'t enough — you have to ask.',
      stat: '12+',
      statLabel: 'apps the average smart home owner manages',
    },
    {
      label: 'The approach',
      title: 'Presence, light, and context — unified.',
      body: 'Lumen builds a live model of each room: who\'s there, how bright it is, what the temperature is doing. It cross-references patterns from your history to understand what would feel right.',
      stat: 'On-device',
      statLabel: 'all reasoning runs locally — no cloud dependency',
    },
    {
      label: 'The outcome',
      title: 'Suggestions you\'d have made yourself.',
      body: 'Every action comes with an explanation. Approval is always yours. Nothing runs silently — Lumen earns trust by being transparent about every step of its reasoning.',
      stat: '< 0.5s',
      statLabel: 'from sensor change to suggestion on screen',
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
          <h2>Signal to suggestion<br />in four steps.</h2>
          <p>
            Every automation follows the same transparent chain. Lumen never
            acts without first walking you through its reasoning.
          </p>
          <a className="reasoning-cta" href="#product">
            See it in the app <ArrowRight size={14} />
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
        <h2>Close to the App Store.<br />Building in the open.</h2>
        <p>Here's exactly what's running on device today, what's in progress, and what comes next.</p>
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
        <h2>Modern. Private.<br />Built to last.</h2>
        <p>
          Every layer is chosen to keep your data on your device and your
          home control in your hands.
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
          <h2>Your home, ready<br />when you are.</h2>
          <p>
            A private beta for iPhone users with HomeKit. First on the list,
            first through the door. No spam, ever.
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
              {status === 'loading' ? 'Joining…' : 'Request access'}
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
              You're on the list — we'll reach out when Lumen is ready.
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

// ─── App Shell ───────────────────────────────────────────────────────────────

export function App() {
  const [menuOpen, setMenuOpen] = useState(false);
  const close = () => setMenuOpen(false);

  return (
    <main className="site-shell">
      <div className="grain" />

      {/* ── Navigation ── */}
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
            <a href="#product"  onClick={close}><span>01</span>The App</a>
            <a href="#approach" onClick={close}><span>02</span>Approach</a>
            <a href="#status"   onClick={close}><span>03</span>Status</a>
            <a href="/privacy"  onClick={close} className="privacy-link"><span>04</span>Privacy</a>
            <a href="#access"   onClick={close} className="mobile-cta">
              Request Access <ArrowRight size={14} />
            </a>
          </div>
        </div>
      )}

      {/* ── Hero ── */}
      <section className="hero" id="top">
        <div className="hero-bg" />

        <FadeIn className="hero-copy">
          <div className="pill">
            <span />
            Near App Store submission — iOS 2026
          </div>
          <h1>Your home<br /><em>should know</em><br />you.</h1>
          <p>
            Lumen is a calm HomeKit companion for iPhone. It reads presence,
            light, and context — then acts with your approval. Everything
            stays on-device.
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

      {/* ── Thesis band ── */}
      <div className="thesis-band">
        <FadeIn>
          <p>
            "Smart home technology gives you control.<br />
            Lumen gives you back your <em>attention.</em>"
          </p>
        </FadeIn>
      </div>

      {/* ── Case study ── */}
      <ChallengeSection />

      {/* ── Product gallery ── */}
      <ProductGallery />

      {/* ── Reasoning walkthrough ── */}
      <ReasoningSection />

      {/* ── Development status ── */}
      <StatusSection />

      {/* ── Technical stack ── */}
      <StackSection />

      {/* ── Early access ── */}
      <Waitlist />

      {/* ── Footer ── */}
      <footer className="site-footer">
        <a className="logo" href="#top">
          <SunMedium size={17} /><span>LUMEN</span>
        </a>
        <p>HomeKit native · On-device AI · Matter ready · iOS 2026</p>
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
