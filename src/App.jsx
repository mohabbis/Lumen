import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { ArrowRight, Brain, CheckCircle2, Home, Infinity, Lightbulb, LockKeyhole, Menu, Microchip, RadioTower, Shield, Sparkles, SunMedium, Waves, X } from 'lucide-react';
import './App.css';
import './architecture-actions.css';

const screens = [
  { id: 'awareness', label: 'Morning', title: 'Good morning, Muha', subtitle: '6:47 AM · Bedroom at 30% · Coffee warming.', card: 'Favorite rooms', icon: Home, rows: ['Bedroom 30% warm', 'Kitchen warming', 'Hallway soft on', 'Sunrise in 12 min'], insight: 'Lumen noticed the sun coming up. Morning ease is already running: soft light, warm room.', action: 'Start morning' },
  { id: 'control', label: 'Moments', title: 'Evening Wind-Down', subtitle: 'A named moment, not a settings panel.', card: 'Scene', icon: Lightbulb, rows: ['Reading 45% warm', 'Shades 60% closed', 'Temperature 21.5 deg', 'Do not disturb on'], insight: 'Scenes are moods, not presets. Reading, Movie Night, and Wind Down stay one tap away.', action: 'Set the mood' },
  { id: 'reasoning', label: 'Works with', title: 'Works with what you already own', subtitle: 'Govee, GE Cync, Matter, HomeKit: unified.', card: 'Your devices', icon: Brain, rows: ['Govee strip connected', 'GE Cync ceiling linked', 'Matter bridge active', 'HomeKit hub synced'], insight: 'Multi-protocol is the how. The point is one calm place for every room.', action: 'See devices' },
  { id: 'action', label: 'Quietly', title: 'Home gets quieter', subtitle: 'Motion slowed. Lumen noticed.', card: 'Scene changes', icon: CheckCircle2, rows: ['Lights easing to 20%', 'Temperature 21.0 deg', 'Notifications paused', 'Scene Wind Down'], insight: 'Time, motion, and habit become suggestions. Manual control stays close.', action: 'Let it settle' }
];

const devStatus = [
  { status: '✓ Shipped', items: ['Location awareness with Welcome Home greeting', 'Away Mode UI + distance display', 'Geofence-triggered automations', 'Scene execution on HomeKit devices', 'Local temperature & humidity sensors', 'HomeKit discovery & control', 'SwiftData persistence', 'iCloud/CloudKit sync ready'] },
  { status: '⏳ In Progress', items: ['Scene trigger UI controls', 'Automation notifications', 'Multi-home support', 'Advanced sensor reasoning'] },
  { status: '🎯 Coming Soon', items: ['On-device AI reasoning engine', 'Matter protocol support', 'Motion & occupancy analysis', 'Energy insights dashboard', 'TestFlight beta'] }
];

const stack = [['SwiftUI', 'Native iPhone interface'], ['HomeKit', 'Secure home control'], ['SwiftData', 'Local home model'], ['CloudKit', 'Private continuity'], ['On-device AI', 'Reasoning without surveillance'], ['Matter-ready', 'Built to evolve']];

const rooms = [
  { name: 'Bedroom', temp: 21.5, light: 38, motion: 12, state: 'Winding down' },
  { name: 'Living', temp: 22.4, light: 61, motion: 82, state: 'Occupied' },
  { name: 'Kitchen', temp: 22.0, light: 8, motion: 4, state: 'Quiet' },
  { name: 'Entry', temp: 20.8, light: 18, motion: 0, state: 'Secure' }
];

const timeline = [['Signal', 'Presence continues while sunset lowers natural light.'], ['Reason', 'Brightness can drop without hurting comfort.'], ['Suggest', 'Warm Evening lowers bulbs and keeps override close.'], ['Act', 'Apply after approval. Nothing runs silently.']];

const actionFlows = [
  { label: 'Arrive', command: 'Turn entry on', input: 'Geofence + door sensor', decision: 'You are home after sunset', output: 'Entry 40%, kitchen warm, hallway safe', cta: 'Preview arrival' },
  { label: 'Settle', command: 'Start Wind Down', input: 'Motion slowing + time', decision: 'Evening routine is likely', output: 'Bedroom 20%, alerts quiet, lights warm', cta: 'Run scene' },
  { label: 'Leave', command: 'Secure Away Mode', input: 'No presence detected', decision: 'Home is empty', output: 'Lights off, exceptions checked, status clear', cta: 'Check home' },
  { label: 'Focus', command: 'Protect calm', input: 'Manual scene + room state', decision: 'Keep distractions low', output: 'Office 55%, notifications muted, glare reduced', cta: 'Start focus' }
];

const architectureNodes = [
  ['Sense', 'Presence, light, temp, motion'],
  ['Model', 'Rooms, devices, routines'],
  ['Decide', 'Local reasoning + rules'],
  ['Act', 'Scenes, alerts, controls']
];

function FadeIn({ children, delay = 0, className = '' }) {
  return <motion.div className={className} initial={{ opacity: 0, y: 24 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true, margin: '-80px' }} transition={{ duration: 0.7, delay, ease: [0.21, 0.8, 0.32, 1] }}>{children}</motion.div>;
}

function AppScreen({ screen, featured = false }) {
  const Icon = screen.icon;
  return <div className={featured ? 'phone phone-featured' : 'phone mini-phone'}><div className="phone-screen"><div className="phone-status"><span>9:41</span><span className="dynamic-island"/><span>5G</span></div><div className="app-brand">LUMEN</div><div className="screen-header"><div><p className="screen-kicker">{screen.label}</p><h3>{screen.title}</h3><p>{screen.subtitle}</p></div><div className="avatar-dot"><Icon size={18}/></div></div><div className="chip-row"><span>4 rooms</span><span>12 devices</span><span>3 automations</span></div><div className="main-card"><div className="main-card-head"><b>{screen.card}</b><ArrowRight size={15}/></div><div className="room-grid">{screen.rows.map((row, i) => <div className="room-cell" key={row}><span>{row}</span><small>{i % 2 === 0 ? 'Active' : 'Ready'}</small></div>)}</div></div><div className="reason-card"><b>Lumen noticed</b><span>{screen.insight}</span></div><div className="presence-card"><div><b>{screen.action}</b><span>{screen.id === 'action' ? 'Confirm scene changes' : 'Suggested by Lumen'}</span></div><div className="pulse-dot"/></div><div className="tabbar"><span className="active">Home</span><span>Rooms</span><span>Intel</span><span>Auto</span></div></div></div>;
}

function ProductGallery() {
  const [active, setActive] = useState(0);
  return <section className="section gallery" id="product"><FadeIn className="section-copy centered"><p className="eyebrow">The Lumen experience</p><h2>Morning light. Evening wind-down. A home that responds before you reach for your phone.</h2></FadeIn><div className="story-steps">{screens.map((screen, index) => { const Icon = screen.icon; return <button key={screen.id} className={active === index ? 'active' : ''} onClick={() => setActive(index)}><Icon size={18}/><b>{screen.label}</b><span>{screen.insight}</span></button>; })}</div><div className="screen-gallery">{screens.map((screen, index) => <motion.div layout className={active === index ? 'selected' : ''} key={screen.id}><AppScreen screen={screen}/></motion.div>)}</div></section>;
}

function SensorVisualization() {
  return <section className="sensor-section" id="live-room"><FadeIn className="section-copy"><p className="eyebrow">Live room intelligence</p><h2>A room model, not a remote control.</h2><p>Lumen reads light, motion, temperature, and device state as one context layer. This mock feed is ready to be swapped for live sensor data.</p></FadeIn><div className="sensor-board">{rooms.map((room) => <div className="sensor-room" key={room.name}><div><b>{room.name}</b><span>{room.state}</span></div><div className="sensor-meter"><span style={{ width: `${room.light}%` }}/></div><div className="sensor-stats"><small>{room.temp} deg</small><small>{room.light}% light</small><small>{room.motion}% motion</small></div></div>)}</div><div className="reasoning-timeline">{timeline.map(([name, text]) => <div key={name}><b>{name}</b><p>{text}</p></div>)}</div></section>;
}

function DevelopmentStatus() {
  return <section className="dev-status" id="status"><FadeIn className="section-copy"><p className="eyebrow">iOS Development</p><h2>Building in the open. Ship monthly.</h2><p>Here is what is live on iPhone and what is next. All changes tracked on GitHub.</p></FadeIn><div className="status-grid">{devStatus.map(({ status, items }) => <div className="status-card" key={status}><div className="status-header">{status}</div><ul className="status-list">{items.map((item, i) => <li key={i}><span className="status-bullet">•</span> {item}</li>)}</ul></div>)}</div><div className="github-link"><a href="https://github.com/mohabbis/lumen" target="_blank" rel="noopener noreferrer">View on GitHub <ArrowRight size={15}/></a></div></section>;
}

function Architecture() {
  const [active, setActive] = useState(0);
  const current = actionFlows[active];
  return <section className="deep-section action-architecture" id="architecture"><div className="architecture-action-shell"><FadeIn className="architecture-hero"><p className="eyebrow">Lumen architecture</p><h2>Less diagram. More doing.</h2><p>Pick a moment. Lumen shows the signal, the decision, and the action before anything changes.</p><div className="architecture-ctas"><a className="primary" href="#access">Request beta access <ArrowRight size={15}/></a><a href="#live-room">View live model</a></div></FadeIn><div className="action-console"><div className="action-tabs">{actionFlows.map((flow, index) => <button key={flow.label} className={active === index ? 'active' : ''} onClick={() => setActive(index)}><span>{String(index + 1).padStart(2, '0')}</span>{flow.label}</button>)}</div><motion.div className="command-card" key={current.label} initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.28 }}><div className="command-top"><span>Suggested action</span><b>{current.command}</b></div><div className="command-path"><div><small>Input</small><strong>{current.input}</strong></div><ArrowRight size={16}/><div><small>Decision</small><strong>{current.decision}</strong></div><ArrowRight size={16}/><div><small>Output</small><strong>{current.output}</strong></div></div><button>{current.cta} <ArrowRight size={15}/></button></motion.div></div><div className="architecture-flow">{architectureNodes.map(([title, text], index) => <div key={title}><span>{index + 1}</span><b>{title}</b><small>{text}</small></div>)}</div><FadeIn delay={0.1} className="stack-actions"><div><p className="eyebrow">Build stack</p><h2>Native. Local. Private.</h2></div><div className="stack-list">{stack.map(([name, meta]) => <div key={name}><Sparkles size={15}/><span><b>{name}</b><small>{meta}</small></span></div>)}</div></FadeIn></div></section>;
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
        const res = await fetch(`${supabaseUrl}/rest/v1/lumen_waitlist`, { method: 'POST', headers: { apikey: supabaseKey, Authorization: `Bearer ${supabaseKey}`, 'Content-Type': 'application/json', Prefer: 'return=minimal' }, body: JSON.stringify({ email, source: 'lumen_access_page', user_agent: navigator.userAgent }) });
        if (!res.ok) throw new Error(await res.text());
      } else {
        window.location.href = `mailto:m.rafiq2006@icloud.com?subject=Lumen%20Early%20Access&body=${encodeURIComponent(`Please add me to the Lumen waitlist: ${email}`)}`;
      }
      setStatus('success');
      form.reset();
    } catch {
      setStatus('error');
    }
  }
  return <section className="access" id="access"><div><p className="eyebrow">Early access</p><h2>Your home should know you.</h2><p>Lumen is a calm home companion for iPhone. It notices morning light, evening wind-down, and the habits your day falls into, then responds gently without you managing it. Works with HomeKit, Matter, Govee, and GE Cync. Everything runs on-device. Launching 2026.</p><form onSubmit={handleSubmit}><input name="email" type="email" placeholder="Your email address" required/><button disabled={status === 'loading'}>{status === 'loading' ? 'Joining...' : 'Request access'} <ArrowRight size={16}/></button></form><div className="checks"><span>iOS first</span><span>Private beta</span><span>No spam</span></div>{status === 'success' && <p className="form-note">You are on the list. We will reach out when Lumen is ready.</p>}{status === 'error' && <p className="form-note error">Something went wrong. Try again or email <a href="mailto:m.rafiq2006@icloud.com">m.rafiq2006@icloud.com</a>.</p>}</div><div className="launch-card"><SunMedium size={36}/><b>Launching 2026</b><span>Calm companion · On-device AI · Works with your devices</span></div></section>;
}

export function App() {
  const [menuOpen, setMenuOpen] = useState(false);
  const close = () => setMenuOpen(false);
  const featureStrip = [['Comes home with you', 'Arrive, and the house already knows.', Waves], ['Private by design', 'Your home. Your data.', LockKeyhole], ['On-device intelligence', 'Fast, local, secure.', Microchip], ['Works with your devices', 'Govee, GE Cync, Matter, HomeKit: one place.', Home], ['Future ready', 'Built to evolve with your home.', Infinity]];
  const pillars = [['Knows', 'Where you are', Waves], ['Thinks', 'On-device intelligence', Brain], ['Acts', 'Beautifully, automatically', Sparkles], ['Respects', 'Privacy always', Shield]];
  return <main className="site-shell"><div className="grain"/><nav className="nav"><a className="logo" href="#top"><SunMedium size={25}/><span>LUMEN</span></a><div className="links"><a href="#status">Development</a><a href="#product">Product</a><a href="#live-room">Live Model</a><a href="#architecture">Architecture</a><a href="#access">Early Access</a><a href="/privacy">Privacy</a></div><div className="nav-actions"><a href="#access">Join Waitlist</a><button aria-label={menuOpen ? 'Close menu' : 'Open menu'} onClick={() => setMenuOpen(o => !o)} className={menuOpen ? 'menu-btn open' : 'menu-btn'}>{menuOpen ? <X size={19}/> : <Menu size={19}/>}</button></div></nav>{menuOpen && <div className="mobile-menu" onClick={close}><div className="mobile-menu-inner" onClick={e => e.stopPropagation()}><a href="#status" onClick={close}><span>01</span>Development</a><a href="#product" onClick={close}><span>02</span>Product</a><a href="#live-room" onClick={close}><span>03</span>Live Model</a><a href="#architecture" onClick={close}><span>04</span>Architecture</a><a href="#access" onClick={close}><span>05</span>Early Access</a><a href="/privacy" onClick={close} className="privacy-link"><span>06</span>Privacy</a><a href="#access" className="mobile-cta" onClick={close}>Join Waitlist <ArrowRight size={15}/></a></div></div>}<section className="hero" id="top"><div className="hero-bg"/><FadeIn className="hero-copy"><div className="pill"><span/> In Development</div><h1>Your home, <em>understood.</em></h1><p>Lumen is a calm home companion. It notices morning light, evening wind-down, and the hour you settle in, then responds gently.</p><div className="hero-chips"><span><Waves size={14}/> Location aware</span><span><Microchip size={14}/> On-device intelligence</span><span><Home size={14}/> Works with your devices</span></div><div className="hero-actions"><a className="primary" href="#access">Join Early Access <ArrowRight size={16}/></a><a href="#architecture">See actions <span>Play</span></a></div></FadeIn><motion.div className="hero-device" initial={{ opacity: 0, rotate: -9, y: 34 }} animate={{ opacity: 1, rotate: -5, y: 0 }} transition={{ duration: 0.9 }}><AppScreen screen={screens[0]} featured/></motion.div><div className="hero-points" id="intelligence">{pillars.map(([title, text, Icon]) => <div key={title}><Icon/><b>{title}</b><span>{text}</span></div>)}</div></section><section className="detail-band" id="design"><div><p className="eyebrow">Every detail</p><h2>In every room.</h2><p>See what matters. Control what counts. Effortlessly.</p></div>{screens.map((screen) => <AppScreen key={screen.id} screen={screen}/>) }<div><p className="eyebrow">Intelligence</p><h2>Meets intention.</h2><p>Lumen explains, suggests, and acts with your approval.</p><a href="#product">Explore the experience <ArrowRight size={15}/></a></div></section><ProductGallery/><SensorVisualization/><div className="feature-strip">{featureStrip.map(([title, text, Icon]) => <div key={title}><Icon size={23}/><span><b>{title}</b><small>{text}</small></span></div>)}</div><DevelopmentStatus/><Architecture/><section className="asset-slots"><div><RadioTower/><b>Media slots ready</b><span>Replace mock screens with real SwiftUI screenshots, add dark room footage behind the hero, then wire the room model to live data.</span></div></section><Waitlist/></main>;
}
