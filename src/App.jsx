import React, { createContext, useCallback, useContext, useEffect, useRef, useState } from 'react';
import { motion } from 'framer-motion';
import {
  Activity, Apple, ArrowRight, Blinds, Check, DoorClosed, Droplets, Home, Lightbulb, Lock,
  Mail, Menu, Moon, Send, Sparkle, Sun, SunMedium, Thermometer, X, Zap,
} from 'lucide-react';
import { PhoneProvider, InteractivePhone, usePhone } from './InteractivePhone.jsx';
import { submitWaitlist } from './waitlistSubmit.js';
import {
  BuiltForCalmSection,
  AppShowcaseSection,
  FeaturesOverviewSection,
  RhythmFeatureSection,
  ScenesFeatureSection,
  DevicesFeatureSection,
} from './FeatureSections.jsx';
import './theme.css';
import './App.css';

const supportedCategories = [
  { label: 'Lights', icon: Lightbulb },
  { label: 'Plugs & switches', icon: Home },
  { label: 'Thermostats', icon: Thermometer },
  { label: 'Window blinds', icon: Blinds },
  { label: 'Door locks', icon: Lock },
  { label: 'Motion sensors', icon: Activity },
  { label: 'Door & window sensors', icon: DoorClosed },
  { label: 'Humidity', icon: Droplets },
];

const exampleBrands = ['Philips Hue', 'Eve', 'Aqara', 'Nanoleaf', 'Matter-enabled Cync'];

const actionFlowModes = [
  {
    tag: 'Awareness',
    icon: Activity,
    headline: 'Notices the moment',
    description: 'Time of day, presence, and reachable devices are read quietly in the background.',
  },
  {
    tag: 'Reasoning',
    icon: Sparkle,
    headline: 'Explains the why',
    description: 'Signals turn into a plain language sheet you can read, question, or dismiss.',
  },
  {
    tag: 'Action',
    icon: Lightbulb,
    headline: 'Shows what will change',
    description: 'A second sheet lists each device action and waits for your confirmation.',
  },
  {
    tag: 'Execution',
    icon: Zap,
    headline: 'Runs when you approve',
    description: 'Lights, locks, and thermostats update only after you tap Apply.',
  },
];

const FLOW_AMBIENT = ['138,180,248', '197,138,249', '124,197,255', '150,130,250'];
const FLOW_ADVANCE_MS = 4200;
const AMBIENT_IDLE = '120,150,235';
const THEME_STORAGE_KEY = 'lumen-theme';

function resolveTheme() {
  if (typeof window === 'undefined') return 'dark';
  const stored = window.localStorage.getItem(THEME_STORAGE_KEY);
  if (stored === 'light' || stored === 'dark') return stored;
  return 'dark';
}

function applyTheme(theme) {
  document.documentElement.dataset.theme = theme;
  const meta = document.querySelector('meta[name="theme-color"]');
  if (meta) meta.setAttribute('content', theme === 'light' ? '#f7f8fb' : '#08090d');
}

function useSiteTheme() {
  const [theme, setTheme] = useState(resolveTheme);

  useEffect(() => {
    applyTheme(theme);
    window.localStorage.setItem(THEME_STORAGE_KEY, theme);
  }, [theme]);

  const toggleTheme = useCallback(() => {
    setTheme(current => (current === 'dark' ? 'light' : 'dark'));
  }, []);

  return { theme, toggleTheme };
}

const AmbientContext = createContext(() => {});

function useSetAmbient() {
  return useContext(AmbientContext);
}

function useAmbientController(initial) {
  const frontRef = useRef(0);
  const currentRef = useRef(initial);
  const [colors, setColors] = useState([initial, initial]);
  const [front, setFront] = useState(0);

  const setAmbient = useCallback(color => {
    if (color === currentRef.current) return;
    currentRef.current = color;
    const back = 1 - frontRef.current;
    setColors(prev => {
      const next = [...prev];
      next[back] = color;
      return next;
    });
    requestAnimationFrame(() => {
      frontRef.current = back;
      setFront(back);
    });
  }, []);

  return { colors, front, setAmbient };
}

function AmbientBackdrop({ colors, front }) {
  return (
    <div className="ambient-backdrop" aria-hidden="true">
      {colors.map((rgb, i) => (
        <div
          key={i}
          className="ambient-layer"
          style={{
            opacity: i === front ? 1 : 0,
            background:
              `radial-gradient(ellipse 70% 55% at 50% -8%, rgba(${rgb},0.30) 0%, transparent 60%), `
              + `radial-gradient(ellipse 55% 45% at 8% 94%, rgba(${rgb},0.13) 0%, transparent 55%)`,
          }}
        />
      ))}
    </div>
  );
}

function useAmbientRegion(ref, color) {
  const setAmbient = useSetAmbient();
  const colorRef = useRef(color);
  colorRef.current = color;

  useEffect(() => {
    const el = ref.current;
    if (!el) return undefined;
    const observer = new IntersectionObserver(
      ([entry]) => { if (entry.isIntersecting) setAmbient(colorRef.current); },
      { threshold: 0.35 },
    );
    observer.observe(el);
    return () => observer.disconnect();
  }, [ref, setAmbient]);
}

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

function HeroCopy() {
  const phone = usePhone();
  return (
    <FadeIn className="hero-copy">
      <div className="pill">
        <span />
        Now in private beta
      </div>
      <h1>when your home shifts,<br /><em>you stay calm.</em></h1>
      <p className="hero-lede">
        Lumen reads the moment — time, presence, your devices — and surfaces one
        gentle suggestion. You read why, approve what changes, nothing runs on its own.
      </p>
      <div className="hero-actions">
        <a className="primary" href="#access">
          Join the beta <ArrowRight size={15} />
        </a>
        <a className="secondary" href="#flow">
          See how it works
        </a>
      </div>
      <p className="hero-platform-note">
        <Apple size={13} /> iPhone &amp; iPad · TestFlight · free
      </p>
      <p className="hero-hint">{phone.hint}</p>
    </FadeIn>
  );
}

function CompatibilitySection() {
  const sectionRef = useRef(null);
  useAmbientRegion(sectionRef, '138,180,248');

  return (
    <section className="app-tour-section compat-section" id="product" ref={sectionRef}>
      <FadeIn className="section-copy centered">
        <p className="eyebrow">works with your home</p>
        <h2>your Apple Home,<br /><em>HomeKit &amp; Matter.</em></h2>
        <p className="section-note">
          Lumen controls whatever lives in your Apple Home: every HomeKit accessory,
          plus the Matter ones you have added. No extra hubs, no brand logins.
        </p>
      </FadeIn>
      <FadeIn className="capability-chips-wrap">
        <p className="eyebrow">controls these accessories</p>
        <div className="capability-chips">
          {supportedCategories.map(({ label, icon: Icon }) => (
            <span className="capability-chip" key={label}>
              <Icon size={11} />
              {label}
            </span>
          ))}
        </div>
      </FadeIn>
      <FadeIn className="compat-brands">
        <p className="compat-brands-line">
          Works with certified brands through Apple Home, like{' '}
          {exampleBrands.map((brand, i) => (
            <React.Fragment key={brand}>
              <b>{brand}</b>{i < exampleBrands.length - 1 ? ', ' : '.'}
            </React.Fragment>
          ))}
        </p>
        <p className="compat-note">
          Lumen rides on Apple Home instead of each brand cloud. The calm rhythm layer
          keeps working with no smart hardware at all.
        </p>
      </FadeIn>
    </section>
  );
}

function ActionFlowSection() {
  const phone = usePhone();
  const [idleActive, setIdleActive] = useState(0);
  const sectionRef = useRef(null);
  const active = phone.touched ? phone.flowMode : idleActive;

  useAmbientRegion(sectionRef, FLOW_AMBIENT[active]);

  useEffect(() => {
    if (phone.touched) return undefined;
    const id = setInterval(() => {
      setIdleActive(a => (a + 1) % actionFlowModes.length);
    }, FLOW_ADVANCE_MS);
    return () => clearInterval(id);
  }, [phone.touched]);

  return (
    <section className="action-flow-section" id="flow" ref={sectionRef}>
      <FadeIn className="section-copy centered">
        <p className="eyebrow">how lumen thinks</p>
        <h2>the same calm loop,<br /><em>every suggestion.</em></h2>
        <p className="section-note">
          {phone.touched
            ? 'The cards below follow what you are doing in the live demo.'
            : 'Tap through the iPhone demo above, or watch the loop cycle on its own.'}
        </p>
      </FadeIn>
      <div className="flow-row">
        {actionFlowModes.map(({ tag, icon: Icon, headline, description }, i) => (
          <FadeIn key={tag} delay={i * 0.06}>
            <div className={`flow-card ${active === i ? 'active' : ''}`}>
              <div className="flow-card-top"><Icon size={16} /></div>
              <b className="flow-tag">{tag}</b>
              <span className="flow-headline">{headline}</span>
              <p className="flow-description">{description}</p>
            </div>
          </FadeIn>
        ))}
      </div>
    </section>
  );
}

function Waitlist() {
  const [status, setStatus] = useState('idle');
  const sectionRef = useRef(null);
  useAmbientRegion(sectionRef, '138,180,248');

  async function handleSubmit(e) {
    e.preventDefault();
    const email = new FormData(e.currentTarget).get('email');
    setStatus('loading');
    try {
      const delivered = await submitWaitlist(email, 'lumen-site');
      if (!delivered) throw new Error('Waitlist submission failed');
      setStatus('success');
      e.target.reset();
    } catch {
      setStatus('error');
    }
  }

  const steps = [
    { icon: Mail, title: 'Enter your email', sub: 'One field. No account to create yet.' },
    { icon: Send, title: 'Get your TestFlight invite', sub: 'We send an Apple TestFlight link when a spot opens.' },
    { icon: Apple, title: 'Install on your iPhone', sub: 'Tap install and Lumen opens like any App Store app.' },
  ];

  return (
    <section className="waitlist-section" id="access" ref={sectionRef}>
      <FadeIn className="signup-card">
        <div className="signup-head">
          <div className="signup-logo"><SunMedium size={20} /></div>
          <p className="eyebrow">open beta</p>
          <h2>try <em>lumen.</em></h2>
          <p className="signup-sub">
            We&apos;re inviting testers now. Free to install via TestFlight — open to everyone,
            no spam, no strings.
          </p>
        </div>

        <ol className="signup-steps">
          {steps.map(({ icon: Icon, title, sub }, i) => (
            <li className="signup-step" key={title}>
              <span className="signup-step-num">{i + 1}</span>
              <span className="signup-step-icon"><Icon size={16} /></span>
              <span className="signup-step-text">
                <b>{title}</b>
                <span>{sub}</span>
              </span>
            </li>
          ))}
        </ol>

        <form className="waitlist-form" onSubmit={handleSubmit}>
          <div className="signup-field">
            <Mail size={15} className="signup-field-icon" />
            <input name="email" type="email" placeholder="you@example.com" required />
          </div>
          <button disabled={status === 'loading'}>
            {status === 'loading' ? 'Setting up…' : 'Continue'}
            <ArrowRight size={15} />
          </button>
        </form>

        <div className="waitlist-checks">
          <span><Check size={12} /> Free during beta</span>
          <span><Check size={12} /> Open to everyone</span>
          <span><Check size={12} /> No spam</span>
        </div>

        <p className="signup-platform">Requires iPhone · iOS 17 or later</p>

        {status === 'success' && (
          <p className="form-note">You&apos;re in. We&apos;ll email your TestFlight invite when a spot opens.</p>
        )}
        {status === 'error' && (
          <p className="form-note error">
            Something went wrong. Try{' '}
            <a href="mailto:m.rafiq2006@icloud.com">m.rafiq2006@icloud.com</a>.
          </p>
        )}
      </FadeIn>
    </section>
  );
}

function SiteShell() {
  const [menuOpen, setMenuOpen] = useState(false);
  const { theme, toggleTheme } = useSiteTheme();
  const close = () => setMenuOpen(false);
  const ambient = useAmbientController(AMBIENT_IDLE);

  return (
    <AmbientContext.Provider value={ambient.setAmbient}>
      <PhoneProvider onAmbientChange={ambient.setAmbient}>
        <main className="site-shell">
          <AmbientBackdrop colors={ambient.colors} front={ambient.front} />
          <div className="grain" />

          <nav className="nav">
            <a className="logo" href="#top">
              <SunMedium size={22} />
              <span>LUMEN</span>
            </a>
            <div className="links">
              <a href="#features">Features</a>
              <a href="#demo">Live demo</a>
              <a href="#flow">How it works</a>
              <a href="/privacy">Privacy</a>
            </div>
            <div className="nav-actions">
              <button
                type="button"
                className="theme-toggle"
                onClick={toggleTheme}
                aria-label={theme === 'dark' ? 'Switch to light mode' : 'Switch to dark mode'}
              >
                {theme === 'dark' ? <Sun size={16} /> : <Moon size={16} />}
              </button>
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
                <a href="#demo" onClick={close}>Live demo</a>
                <a href="#features" onClick={close}>Features</a>
                <a href="#flow" onClick={close}>How it works</a>
                <a href="/privacy" onClick={close} className="privacy-link">Privacy</a>
                <a href="#access" onClick={close} className="mobile-cta">
                  Request Access <ArrowRight size={14} />
                </a>
              </div>
            </div>
          )}

          <section className="hero hero-split" id="top">
            <div className="hero-bg" />
            <div className="hero-inner">
              <HeroCopy />
              <div className="hero-demo" id="demo">
                <div className="demo-live-badge">
                  <span className="demo-live-dot" />
                  Live interactive demo
                </div>
                <div className="hero-glow" />
                <InteractivePhone />
              </div>
            </div>
          </section>

          <BuiltForCalmSection />
          <AppShowcaseSection />
          <FeaturesOverviewSection />
          <RhythmFeatureSection />
          <ScenesFeatureSection />
          <DevicesFeatureSection />
          <CompatibilitySection />
          <ActionFlowSection />
          <Waitlist />

          <footer className="site-footer">
            <a className="logo" href="#top">
              <SunMedium size={17} /><span>LUMEN</span>
            </a>
            <p>Calm by design · Open to everyone · Native iOS · Private beta</p>
            <div className="footer-links">
              <a href="#access" className="footer-cta">
                Request Early Access <ArrowRight size={13} />
              </a>
              <a href="#demo">Live demo</a>
              <a href="/privacy">Privacy</a>
              <a href="https://github.com/mohabbis/lumen" target="_blank" rel="noopener noreferrer">GitHub</a>
              <a href="mailto:m.rafiq2006@icloud.com">Contact</a>
            </div>
          </footer>
        </main>
      </PhoneProvider>
    </AmbientContext.Provider>
  );
}

export function App() {
  return <SiteShell />;
}
