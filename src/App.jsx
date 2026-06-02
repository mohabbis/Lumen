import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { ArrowRight, Brain, CheckCircle2, Home, Infinity, Lightbulb, LockKeyhole, Menu, Microchip, RadioTower, Shield, Sparkles, SunMedium, Waves, X } from 'lucide-react';
import './App.css';

const screens = [
  { id: 'awareness', label: 'Awareness', title: 'Welcome Home, Muha', subtitle: 'Your location detected — 4 devices ready.', card: 'Favorite rooms', icon: Home, rows: ['Bedroom 21.5 deg', 'Desk lamp ready', 'Kitchen all off', 'Hallway quiet'], insight: 'You arrived 2 min ago. Evening scene ready to run.', action: 'Welcome Home' },
  { id: 'control', label: 'Control', title: 'Living Room', subtitle: 'Comfortable - 4 devices - 2 sensors', card: 'Devices', icon: Lightbulb, rows: ['Lights 70% to 42%', 'Shades open 35%', 'Temperature 22.5 deg', 'Air quality excellent'], insight: 'Late-day glare is dropping. Warm light will feel better than bright white.', action: 'Tune room' },
  { id: 'reasoning', label: 'Reasoning', title: 'Why Lumen dimmed the lights', subtitle: 'Sunset, presence, and temperature moved together.', card: 'Signals', icon: Brain, rows: ['Presence detected', 'Sunset matched', 'Temperature +1.2 deg', 'Confidence high'], insight: 'Lumen explains the logic before acting, so automation never feels random.', action: 'Review logic' },
  { id: 'action', label: 'Action', title: 'Evening Comfort', subtitle: 'Ready to apply with your approval.', card: 'Scene changes', icon: CheckCircle2, rows: ['Lights 70% to 40%', 'Temperature 22.5 to 21.5 deg', 'Shades 35% to 60%', 'Scene Warm Evening'], insight: 'A single confirmation applies the scene and keeps manual control close.', action: 'Apply scene' }
];

const architecture = [['Devices','Matter / local'],['Sensors','Environmental'],['Presence','People and pets'],['Automations','Context aware'],['Scenes','Adaptive'],['Insights','Private AI']];

const devStatus = [
  { status: '✓ Shipped', items: ['Location awareness with Welcome Home greeting', 'Away Mode UI + distance display', 'Geofence-triggered automations (arrival/departure)', 'Scene execution on HomeKit devices', 'Local temperature & humidity sensors', 'HomeKit device discovery & control', 'SwiftData persistence', 'iCloud/CloudKit sync ready'] },
  { status: '⏳ In Progress', items: ['Scene trigger UI controls', 'Automation notifications', 'Multi-home support', 'Advanced sensor reasoning'] },
  { status: '🎯 Coming Soon', items: ['On-device AI reasoning engine', 'Matter protocol support', 'Motion & occupancy analysis', 'Energy insights dashboard', 'TestFlight beta'] }
];

const stack = [['SwiftUI','Native iPhone interface'],['HomeKit','Secure home control'],['SwiftData','Local home model'],['CloudKit','Private continuity'],['On-device AI','Reasoning without surveillance'],['Matter-ready','Built to evolve']];

const rooms = [
  { name: 'Bedroom', temp: 21.5, light: 38, motion: 12, state: 'Winding down' },
  { name: 'Living', temp: 22.4, light: 61, motion: 82, state: 'Occupied' },
  { name: 'Kitchen', temp: 22.0, light: 8, motion: 4, state: 'Quiet' },
  { name: 'Entry', temp: 20.8, light: 18, motion: 0, state: 'Secure' }
];

const timeline = [['Signal','Presence continues in living room while sunset lowers natural light.'],['Reason','Brightness can drop without hurting visibility or comfort.'],['Suggest','Warm Evening lowers bulbs, closes shades slightly, and keeps manual override close.'],['Act','Apply after approval. Nothing runs silently.']];

function FadeIn({ children, delay = 0, className = '' }) {
  return <motion.div className={className} initial={{ opacity: 0, y: 24 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true, margin: '-80px' }} transition={{ duration: 0.7, delay, ease: [0.21, 0.8, 0.32, 1] }}>{children}</motion.div>;
}

function AppScreen({ screen, featured = false }) {
  const Icon = screen.icon;
  return <div className={featured ? 'phone phone-featured' : 'phone mini-phone'}><div className="phone-screen"><div className="phone-status"><span>9:41</span><span className="dynamic-island"/><span>5G</span></div><div className="app-brand">LUMEN</div><div className="screen-header"><div><p className="screen-kicker">{screen.label}</p><h3>{screen.title}</h3><p>{screen.subtitle}</p></div><div className="avatar-dot"><Icon size={18}/></div></div><div className="chip-row"><span>4 rooms</span><span>12 devices</span><span>3 automations</span></div><div className="main-card"><div className="main-card-head"><b>{screen.card}</b><ArrowRight size={15}/></div><div className="room-grid">{screen.rows.map((row, i) => <div className="room-cell" key={row}><span>{row}</span><small>{i % 2 === 0 ? 'Active' : 'Ready'}</small></div>)}</div></div><div className="reason-card"><b>Lumen noticed</b><span>{screen.insight}</span></div><div className="presence-card"><div><b>{screen.action}</b><span>{screen.id === 'action' ? 'Confirm scene changes' : 'Suggested by Muhome'}</span></div><div className="pulse-dot"/></div><div className="tabbar"><span className="active">Home</span><span>Rooms</span><span>Intel</span><span>Auto</span></div></div></div>;
}

function ProductGallery() {
  const [active, setActive] = useState(0);
  return <section className="section gallery" id="product"><FadeIn className="section-copy centered"><p className="eyebrow">The Lumen experience</p><h2>From awareness to action. All in one calm flow.</h2></FadeIn><div className="story-steps">{screens.map((screen, index) => { const Icon = screen.icon; return <button key={screen.id} className={active === index ? 'active' : ''} onClick={() => setActive(index)}><Icon size={18}/><b>{screen.label}</b><span>{screen.insight}</span></button>; })}</div><div className="screen-gallery">{screens.map((screen, index) => <motion.div layout className={active === index ? 'selected' : ''} key={screen.id}><AppScreen screen={screen}/></motion.div>)}</div></section>;
}

function SensorVisualization() {
  return <section className="sensor-section" id="live-room"><FadeIn className="section-copy"><p className="eyebrow">Live room intelligence</p><h2>A room model, not a remote control.</h2><p>Lumen reads light, motion, temperature, and device state as one context layer. This mock feed is ready to be swapped for real Muhome sensor data.</p></FadeIn><div className="sensor-board">{rooms.map((room) => <div className="sensor-room" key={room.name}><div><b>{room.name}</b><span>{room.state}</span></div><div className="sensor-meter"><span style={{ width: `${room.light}%` }}/></div><div className="sensor-stats"><small>{room.temp} deg</small><small>{room.light}% light</small><small>{room.motion}% motion</small></div></div>)}</div><div className="reasoning-timeline">{timeline.map(([name, text]) => <div key={name}><b>{name}</b><p>{text}</p></div>)}</div></section>;
}

function DevelopmentStatus() {
  return <section className="dev-status" id="status"><FadeIn className="section-copy"><p className="eyebrow">iOS Development</p><h2>Building in the open. Ship monthly.</h2><p>Here's what's live on iPhone and what's next. All changes tracked on GitHub.</p></FadeIn><div className="status-grid">{devStatus.map(({ status, items }) => <div className="status-card" key={status}><div className="status-header">{status}</div><ul className="status-list">{items.map((item, i) => <li key={i}><span className="status-bullet">•</span> {item}</li>)}</ul></div>)}</div><div className="github-link"><a href="https://github.com/mohabbis/lumen" target="_blank" rel="noopener noreferrer">View on GitHub <ArrowRight size={15}/></a></div></section>;
}

function Architecture() {
  return <section className="deep-section" id="architecture"><div className="architecture-card"><FadeIn><p className="eyebrow">Muhome architecture</p><h2>The foundation behind Lumen.</h2><p>Muhome is the local brain. It unifies devices, sensors, presence, routines, and room semantics into a single model your home can understand.</p><a href="#live-room">See the room model <ArrowRight size={15}/></a></FadeIn><div className="muhome-diagram"><div className="cube">Muhome</div>{architecture.map(([name, meta]) => <div className="node" key={name}><b>{name}</b><span>{meta}</span></div>)}</div><FadeIn delay={0.1}><p className="eyebrow">Technical stack</p><h2>Modern. Private. Built to last.</h2><div className="stack-list">{stack.map(([name, meta]) => <div key={name}><Sparkles size={15}/><span><b>{name}</b><small>{meta}</small></span></div>)}</div></FadeIn></div></section>;
}

function Waitlist() {
  const [status, setStatus] = useState('idle');
  async function handleSubmit(event) {
    event.preventDefault();
    const form = event.currentTarget;
    const email = new FormData(form).get('email');
    setStatus('loading');
    try {
      const endpoint = import.meta.env.VITE_WAITLIST_ENDPOINT;
      const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
      const supabaseKey = import.meta.env.VITE_SUPABASE_ANON_KEY;
      if (endpoint) {
        await fetch(endpoint, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email, source: 'lumen-site' }) });
      } else if (supabaseUrl && supabaseKey) {
        await fetch(`${supabaseUrl}/rest/v1/lumen_waitlist`, { method: 'POST', headers: { apikey: supabaseKey, Authorization: `Bearer ${supabaseKey}`, 'Content-Type': 'application/json', Prefer: 'return=minimal' }, body: JSON.stringify({ email, source: 'lumen-site', user_agent: navigator.userAgent }) });
      } else {
        window.location.href = `mailto:m.rafiq2006@icloud.com?subject=Lumen%20Early%20Access&body=${encodeURIComponent(`Please add me to the Lumen waitlist: ${email}`)}`;
      }
      setStatus('success');
      form.reset();
    } catch {
      setStatus('error');
    }
  }
  return <section className="access" id="access"><div><p className="eyebrow">Early access</p><h2>Your home should know you.</h2><p>Lumen is a HomeKit-native iOS app that understands presence, light, and context — and acts with your approval. Everything runs on-device. Nothing leaves your home. Launching 2026.</p><form onSubmit={handleSubmit}><input name="email" type="email" placeholder="Your email address" required/><button disabled={status === 'loading'}>{status === 'loading' ? 'Joining...' : 'Request access'} <ArrowRight size={16}/></button></form><div className="checks"><span>iOS first</span><span>Private beta</span><span>No spam</span></div>{status === 'success' && <p className="form-note">You're on the list — we'll reach out when Lumen is ready.</p>}{status === 'error' && <p className="form-note error">Something went wrong. Try again or email <a href="mailto:m.rafiq2006@icloud.com">m.rafiq2006@icloud.com</a>.</p>}</div><div className="launch-card"><SunMedium size={36}/><b>Launching 2026</b><span>HomeKit native · On-device AI · Matter ready</span></div></section>;
}

export function App() {
  const [menuOpen, setMenuOpen] = useState(false);
  const close = () => setMenuOpen(false);
  const featureStrip = [['Private by design','Your home. Your data.',LockKeyhole],['On-device intelligence','Fast, local, secure.',Microchip],['HomeKit native','Deep integration that works.',Home],['Future ready','Built to evolve with your home.',Infinity]];
  const pillars = [['Understands','Presence and context',Waves],['Thinks','On-device intelligence',Brain],['Acts','Beautifully, automatically',Sparkles],['Respects','Privacy always',Shield]];
  return <main className="site-shell"><div className="grain"/><nav className="nav"><a className="logo" href="#top"><SunMedium size={25}/><span>LUMEN</span></a><div className="links"><a href="#status">Development</a><a href="#product">Product</a><a href="#live-room">Live Model</a><a href="#architecture">Architecture</a><a href="#access">Early Access</a><a href="/privacy">Privacy</a></div><div className="nav-actions"><a href="#access">Join Waitlist</a><button aria-label={menuOpen ? 'Close menu' : 'Open menu'} onClick={() => setMenuOpen(o => !o)} className={menuOpen ? 'menu-btn open' : 'menu-btn'}>{menuOpen ? <X size={19}/> : <Menu size={19}/>}</button></div></nav>{menuOpen && <div className="mobile-menu" onClick={close}><div className="mobile-menu-inner" onClick={e => e.stopPropagation()}><a href="#status" onClick={close}><span>01</span>Development</a><a href="#product" onClick={close}><span>02</span>Product</a><a href="#live-room" onClick={close}><span>03</span>Live Model</a><a href="#architecture" onClick={close}><span>04</span>Architecture</a><a href="#access" onClick={close}><span>05</span>Early Access</a><a href="/privacy" onClick={close} className="privacy-link"><span>06</span>Privacy</a><a href="#access" className="mobile-cta" onClick={close}>Join Waitlist <ArrowRight size={15}/></a></div></div>}<section className="hero" id="top"><div className="hero-bg"/><FadeIn className="hero-copy"><div className="pill"><span/> In Development</div><h1>Your home, <em>understood.</em></h1><p>Lumen is a new kind of home intelligence. It understands presence, context, and intent so your home can respond beautifully.</p><div className="hero-chips"><span><LockKeyhole size={14}/> Private by design</span><span><Microchip size={14}/> On-device intelligence</span><span><Home size={14}/> Built for HomeKit</span></div><div className="hero-actions"><a className="primary" href="#access">Join Early Access <ArrowRight size={16}/></a><a href="#product">Explore product <span>Play</span></a></div></FadeIn><motion.div className="hero-device" initial={{ opacity: 0, rotate: -9, y: 34 }} animate={{ opacity: 1, rotate: -5, y: 0 }} transition={{ duration: 0.9 }}><AppScreen screen={screens[0]} featured/></motion.div><div className="hero-points" id="intelligence">{pillars.map(([title, text, Icon]) => <div key={title}><Icon/><b>{title}</b><span>{text}</span></div>)}</div></section><section className="detail-band" id="design"><div><p className="eyebrow">Every detail</p><h2>In every room.</h2><p>See what matters. Control what counts. Effortlessly.</p></div>{screens.map((screen) => <AppScreen key={screen.id} screen={screen}/>) }<div><p className="eyebrow">Intelligence</p><h2>Meets intention.</h2><p>Lumen explains, suggests, and acts with your approval.</p><a href="#product">Explore the experience <ArrowRight size={15}/></a></div></section><ProductGallery/><SensorVisualization/><div className="feature-strip">{featureStrip.map(([title, text, Icon]) => <div key={title}><Icon size={23}/><span><b>{title}</b><small>{text}</small></span></div>)}</div><DevelopmentStatus/><Architecture/><section className="asset-slots"><div><RadioTower/><b>Media slots ready</b><span>Replace mock screens with real SwiftUI screenshots, add dark room footage behind the hero, then wire the room model to live data.</span></div></section><Waitlist/></main>;
}
