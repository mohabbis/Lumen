import React, { createContext, useCallback, useContext, useEffect, useRef, useState } from 'react';
import { motion } from 'framer-motion';
import {
  Activity, ArrowRight, Blinds, Brain, DoorClosed, Droplets, Eye, Hand, Home, Lightbulb, Lock,
  Menu, MessageCircle, Moon, Sparkle, Sparkles, Sun, SunMedium, Thermometer, X, Zap,
} from 'lucide-react';
import { PhoneProvider, InteractivePhone, usePhone } from './InteractivePhone.jsx';
import { submitWaitlist } from './waitlistSubmit.js';
import {
  FeaturesOverviewSection,
  RhythmFeatureSection,
  ScenesFeatureSection,
  DevicesFeatureSection,
  RoomsFeatureSection,
  PresenceFeatureSection,
  MoreCapabilitiesSection,
  PlatformsSection,
} from './FeatureSections.jsx';
import './theme.css';
import './App.css';

const aiCallouts = [
  { icon: MessageCircle, label: 'Plain language', sub: 'Say it your way' },
  { icon: Sparkles, label: 'Lumen proposes', sub: 'Never acts on its own' },
  { icon: Zap, label: 'You decide', sub: 'One tap to approve' },
];

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

const calmPrinciples = [
  {
    icon: Brain,
    headline: 'Low cognitive load',
    description: 'One gentle suggestion at a time. No dense grids of toggles fighting for attention.',
  },
  {
    icon: Hand,
    headline: 'Consent before action',
    description: 'Lumen proposes. You read the reasoning, see what will change, and approve.',
  },
  {
    icon: Eye,
    headline: 'Sensory-aware rhythm',
    description: 'Morning and evening blocks that match how your day actually feels, not alarm clocks.',
  },
  {
    icon: Sparkle,
    headline: 'Plain language',
    description: 'Every suggestion shows its signals in words you can question or dismiss.',
  },
];

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

const FLOW_AMBIENT = ['111,219,168', '160,108,240', '232,160,32', '212,130,90'];
const FLOW_ADVANCE_MS = 4200;
const AMBIENT_IDLE = '200,184,154';
const THEME_STORAGE_KEY = 'lumen-theme';

function resolveTheme() {
  if (typeof window === 'undefined') return 'dark';
  const stored = window.localStorage.getItem(THEME_STORAGE_KEY);
  if (stored === 'light' || stored === 'dark') return stored;
  if (typeof window.matchMedia !== 'function') return 'dark';
  return window.matchMedia('(prefers-color-scheme: light)').matches ? 'light' : 'dark';
}

function applyTheme(theme) {
  document.documentElement.dataset.theme = theme;
  const meta = document.querySelector('meta[name="theme-color"]');
  if (meta) meta.setAttribute('content', theme === 'light' ? '#faf8f5' : '#0c0814');
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
        Calm home companion
      </div>
      <h1>Your home,<br /><em>understood.</em></h1>
      <p className="hero-lede">
        Smart home apps can feel loud. Lumen notices the moment, explains why,
        and waits for your tap before anything changes.
      </p>
      <p className="hero-hint">{phone.hint}</p>
      <div className="hero-actions">
        <a className="primary" href="#access">
          Request Early Access <ArrowRight size={15} />
        </a>
      </div>
    </FadeIn>
  );
}

function WhyLumenSection() {
  const sectionRef = useRef(null);
  useAmbientRegion(sectionRef, '150,120,235');

  return (
    <section className="why-lumen-section surface-alt" id="why" ref={sectionRef}>
      <FadeIn className="section-copy centered">
        <p className="eyebrow">Why Lumen</p>
        <h2>Calm enough<br /><em>to stay open.</em></h2>
        <p className="section-note">
          HomeKit dashboards pack every toggle onto one screen. Lumen brings
          low-stress clarity to your home. The design is focused. The welcome is open.
        </p>
      </FadeIn>
      <div className="calm-principles-grid">
        {calmPrinciples.map(({ icon: Icon, headline, description }, i) => (
          <FadeIn key={headline} delay={i * 0.06}>
            <div className="calm-principle-card">
              <div className="calm-principle-icon"><Icon size={18} /></div>
              <b>{headline}</b>
              <p>{description}</p>
            </div>
          </FadeIn>
        ))}
      </div>
      <FadeIn className="why-lumen-contrast centered">
        <p>
          Lumen is not a tinkerer tool or a power-user controller. Anyone can use it.
          Building for calm first just makes it easier to keep open than dashboards
          built for everyone and optimised for no one.
        </p>
      </FadeIn>
    </section>
  );
}

function CompatibilitySection() {
  const sectionRef = useRef(null);
  useAmbientRegion(sectionRef, '200,184,154');

  return (
    <section className="app-tour-section compat-section" id="product" ref={sectionRef}>
      <FadeIn className="section-copy centered">
        <p className="eyebrow">Works with your home</p>
        <h2>Your Apple Home,<br /><em>HomeKit &amp; Matter.</em></h2>
        <p className="section-note">Lumen controls whatever lives in your Apple Home: every HomeKit accessory, plus the Matter ones you have added. No extra hubs, no brand logins.</p>
      </FadeIn>
      <FadeIn className="capability-chips-wrap">
        <p className="eyebrow">Controls these accessories</p>
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
          Lumen rides on Apple Home instead of each brand cloud. The calm rhythm layer keeps working with no smart hardware at all.
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
        <p className="eyebrow">How Lumen thinks</p>
        <h2>The same calm loop,<br /><em>every suggestion.</em></h2>
        <p className="section-note">
          {phone.touched
            ? 'The cards below follow what you are doing in the phone.'
            : 'Use the phone above, or watch the loop cycle on its own.'}
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

function AIChatSection() {
  const sectionRef = useRef(null);
  useAmbientRegion(sectionRef, '150,120,235');

  return (
    <section className="ai-chat-section surface-alt" id="ai" ref={sectionRef}>
      <div className="ai-chat-inner">
        <FadeIn className="ai-chat-copy">
          <p className="eyebrow">Coming soon · Built-in AI</p>
          <h2>Describe it.<br /><em>You approve it.</em></h2>
          <p className="ai-chat-lede">
            A conversational layer is on the way. Describe what you want in
            plain language, and Lumen proposes the scene, shows its
            reasoning, and waits for your tap.
          </p>
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

function Waitlist() {
  const [status, setStatus] = useState('idle');
  const sectionRef = useRef(null);
  useAmbientRegion(sectionRef, '200,184,154');

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

  return (
    <section className="waitlist-section" id="access" ref={sectionRef}>
      <div className="waitlist-inner">
        <FadeIn className="waitlist-copy">
          <p className="eyebrow">Early access</p>
          <h2>Try the calmer<br />smart-home layer.</h2>
          <p>A private iOS beta, open to everyone. No spam, no fake urgency.</p>
        </FadeIn>
        <FadeIn delay={0.1} className="waitlist-form-wrap">
          <form className="waitlist-form" onSubmit={handleSubmit}>
            <input name="email" type="email" placeholder="Your email address" required />
            <button disabled={status === 'loading'}>
              {status === 'loading' ? 'Joining...' : 'Request access'}
              <ArrowRight size={15} />
            </button>
          </form>
          <div className="waitlist-checks">
            <span>Open to everyone</span>
            <span>Private beta</span>
            <span>No spam</span>
          </div>
          {status === 'success' && (
            <p className="form-note">You are on the list. We will reach out when Lumen is ready.</p>
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
              <a href="#flow">How it works</a>
              <a href="#ai">AI</a>
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
                <a href="#features" onClick={close}>Features</a>
                <a href="#rhythm" onClick={close}>Rhythm</a>
                <a href="#scenes" onClick={close}>Scenes</a>
                <a href="#devices" onClick={close}>Devices</a>
                <a href="#flow" onClick={close}>How it works</a>
                <a href="#ai" onClick={close}>AI</a>
                <a href="/privacy" onClick={close} className="privacy-link">Privacy</a>
                <a href="#access" onClick={close} className="mobile-cta">
                  Request Access <ArrowRight size={14} />
                </a>
              </div>
            </div>
          )}

          <section className="hero" id="top">
            <div className="hero-bg" />
            <HeroCopy />
            <div className="hero-demo">
              <div className="hero-glow" />
              <InteractivePhone />
            </div>
          </section>

          <WhyLumenSection />
          <FeaturesOverviewSection />
          <RhythmFeatureSection />
          <ScenesFeatureSection />
          <DevicesFeatureSection />
          <RoomsFeatureSection />
          <PresenceFeatureSection />
          <CompatibilitySection />
          <ActionFlowSection />
          <MoreCapabilitiesSection />
          <PlatformsSection />
          <AIChatSection />
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
