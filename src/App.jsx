import React, { useState } from 'react';
import { motion } from 'framer-motion';
import {
  ArrowRight, CheckCircle2, Home, Lightbulb, Menu, MessageCircle,
  Send, SunMedium, Thermometer, Wifi, X, Zap,
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
    rows: ['Lights 70%', 'Shades open', 'Temp steady', 'Air clear'],
    insight: 'The room is bright for this time of day. Warmer light may feel better.',
    action: 'Tune room',
  },
  {
    id: 'action',
    label: 'Approve',
    title: 'Evening Comfort',
    subtitle: 'Ready to apply. Nothing runs silently.',
    card: 'Scene preview',
    icon: CheckCircle2,
    rows: ['Lights soften', 'Temp lowers', 'Shades adjust', 'Scene editable'],
    insight: 'One clear confirmation applies the scene. You stay in control.',
    action: 'Apply scene',
  },
  {
    id: 'explain',
    label: 'Signals',
    title: 'Why this?',
    subtitle: 'Presence, time, and room state moved together.',
    card: 'Signals',
    icon: SunMedium,
    rows: ['Presence confirmed', 'Sunset window', 'Room active', 'High confidence'],
    insight: 'Every suggestion shows its signals before anything changes.',
    action: 'Review logic',
  },
];

const deviceCards = [
  { icon: Lightbulb, name: 'Bedroom', state: 'Dimmed 35%', type: 'light', brightness: 35 },
  { icon: Lightbulb, name: 'Living Room', state: 'Warm 70%', type: 'light', brightness: 70 },
  { icon: Lightbulb, name: 'Desk Lamp', state: 'Full 100%', type: 'light', brightness: 100 },
  { icon: Lightbulb, name: 'Hallway', state: 'Off', type: 'light', brightness: 0 },
  { icon: Home, name: 'Home', state: "You're here", type: 'presence' },
  { icon: Thermometer, name: 'Living Room', state: '21°C', type: 'temp' },
  { icon: Wifi, name: 'Network', state: '12 active', type: 'network' },
  { icon: SunMedium, name: 'Evening Scene', state: 'Ready', type: 'scene' },
];

const aiCallouts = [
  { icon: Zap, label: 'Instant', sub: 'Commands sent live' },
  { icon: MessageCircle, label: 'Conversational', sub: 'Plain language control' },
  { icon: CheckCircle2, label: 'Your call', sub: 'Always one tap to apply' },
];

const flowSteps = [
  { screen: screens[0], label: 'Arrives home' },
  { screen: screens[1], label: 'Lumen notices' },
  { screen: screens[2], label: 'One tap to apply' },
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
          <span>Chat</span>
        </div>
      </div>
    </div>
  );
}

// Components

function DeviceCard({ icon: Icon, name, state, type, brightness }) {
  return (
    <div className="device-card">
      <div className="device-card-icon"><Icon size={18} /></div>
      <div className="device-card-name">{name}</div>
      {type === 'light' && (
        <div className="device-brightness-bar">
          <div className="device-brightness-fill" style={{ width: `${brightness}%` }} />
        </div>
      )}
      {type === 'presence' && <div className="pulse-dot" />}
      {type === 'scene' && <div className="scene-ready-dot" />}
      <div className="device-card-state">{state}</div>
    </div>
  );
}

function DeviceShowcaseSection() {
  return (
    <section className="device-showcase-section" id="showcase">
      <FadeIn className="section-copy centered">
        <p className="eyebrow">Your home at a glance</p>
        <h2>Every room,<br /><em>one place.</em></h2>
      </FadeIn>
      <div className="device-card-grid">
        {deviceCards.map((card, i) => (
          <FadeIn key={card.name + card.type} delay={i * 0.06}>
            <DeviceCard {...card} />
          </FadeIn>
        ))}
      </div>
    </section>
  );
}

function AIChatScreen() {
  return (
    <div className="phone phone-featured">
      <div className="phone-screen">
        <div className="phone-status">
          <span>9:41</span>
          <span className="dynamic-island" />
          <span>5G</span>
        </div>
        <div className="app-brand">LUMEN</div>
        <div className="chat-header">
          <div className="chat-avatar"><MessageCircle size={14} /></div>
          <div>
            <b>Lumen</b>
            <small>AI assistant</small>
          </div>
        </div>
        <div className="chat-thread">
          <div className="chat-msg user">Make the bedroom cozy</div>
          <div className="chat-msg ai">
            Dimming to 30%, warming colour to 2700K.
            <div className="chat-chips">
              <button className="chat-chip apply">Apply</button>
              <button className="chat-chip">Edit</button>
            </div>
          </div>
          <div className="chat-msg user">Also turn off the hallway</div>
          <div className="chat-msg ai">
            Hallway off. Ready when you are.
            <div className="chat-chips">
              <button className="chat-chip apply">Apply</button>
            </div>
          </div>
        </div>
        <div className="chat-input-bar">
          <span className="chat-input-placeholder">Ask Lumen...</span>
          <button className="chat-send-btn"><Send size={12} /></button>
        </div>
        <div className="tabbar">
          <span>Home</span>
          <span className="active">Chat</span>
          <span>Rooms</span>
          <span>Scenes</span>
        </div>
      </div>
    </div>
  );
}

function AIChatSection() {
  return (
    <section className="ai-chat-section" id="ai">
      <div className="ai-chat-inner">
        <FadeIn className="ai-chat-phone-wrap">
          <AIChatScreen />
        </FadeIn>
        <FadeIn delay={0.1} className="ai-chat-copy">
          <p className="eyebrow">Built-in AI</p>
          <h2>Just say it.<br /><em>Lumen handles it.</em></h2>
          <div className="ai-callouts">
            {aiCallouts.map(({ icon: Icon, label, sub }) => (
              <div className="ai-callout" key={label}>
                <Icon size={16} />
                <div>
                  <b>{label}</b>
                  <span>{sub}</span>
                </div>
              </div>
            ))}
          </div>
        </FadeIn>
      </div>
    </section>
  );
}

function AppFlowSection() {
  return (
    <section className="app-flow-section" id="product">
      <FadeIn className="section-copy centered">
        <p className="eyebrow">The flow</p>
        <h2>From arrival<br />to comfort.</h2>
      </FadeIn>
      <div className="flow-phones">
        {flowSteps.map(({ screen, label }, i) => (
          <FadeIn key={label} delay={i * 0.1} className="flow-step">
            <AppScreen screen={screen} />
            <div className="flow-step-label">
              <span className="flow-step-num">0{i + 1}</span>
              <span>{label}</span>
            </div>
          </FadeIn>
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
            A private iPhone beta. No spam, no fake urgency.
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
          <a href="#ai">AI</a>
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
            <a href="#ai" onClick={close}><span>02</span>AI</a>
            <a href="/privacy" onClick={close} className="privacy-link"><span>03</span>Privacy</a>
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
          <h1>Your home,<br /><em>understood.</em></h1>
          <p>
            Calm smart-home control that shows its work<br />before anything changes.
          </p>
          <div className="hero-actions">
            <a className="primary" href="#access">
              Request Early Access <ArrowRight size={15} />
            </a>
            <a className="ghost" href="#product">See how it works</a>
          </div>
        </FadeIn>

        <div className="hero-phones">
          <div className="hero-glow" />
          <motion.div
            className="hero-phone-side"
            initial={{ opacity: 0, rotate: -12, x: -24, y: 32 }}
            animate={{ opacity: 0.55, rotate: -6, x: 0, y: 0 }}
            transition={{ duration: 1.0, delay: 0.25, ease: [0.21, 0.8, 0.32, 1] }}
          >
            <AppScreen screen={screens[0]} />
          </motion.div>
          <motion.div
            className="hero-phone-center"
            initial={{ opacity: 0, y: 40 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 1.0, delay: 0.1, ease: [0.21, 0.8, 0.32, 1] }}
          >
            <AppScreen screen={screens[3]} featured />
          </motion.div>
          <motion.div
            className="hero-phone-side"
            initial={{ opacity: 0, rotate: 12, x: 24, y: 32 }}
            animate={{ opacity: 0.55, rotate: 6, x: 0, y: 0 }}
            transition={{ duration: 1.0, delay: 0.25, ease: [0.21, 0.8, 0.32, 1] }}
          >
            <AppScreen screen={screens[1]} />
          </motion.div>
        </div>
      </section>

      <DeviceShowcaseSection />
      <AIChatSection />
      <AppFlowSection />
      <Waitlist />

      <footer className="site-footer">
        <a className="logo" href="#top">
          <SunMedium size={17} /><span>LUMEN</span>
        </a>
        <p>Native iOS · On-device reasoning · AI assistant · Private beta</p>
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
