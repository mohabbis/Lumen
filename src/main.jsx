import React, { useMemo, useState } from 'react';
import { createRoot } from 'react-dom/client';
import { motion, AnimatePresence } from 'framer-motion';
import {
  ArrowRight,
  Brain,
  CheckCircle2,
  Home,
  Layers3,
  Lightbulb,
  LockKeyhole,
  Moon,
  RadioTower,
  Sparkles,
  Waves
} from 'lucide-react';

const storySteps = [
  {
    label: 'Rooms',
    title: 'Lumen begins with place.',
    body: 'Every device belongs to a room, zone, and purpose. The interface thinks in spaces before switches.',
    stat: '12 rooms',
    icon: Home
  },
  {
    label: 'Presence',
    title: 'The home learns rhythm without becoming intrusive.',
    body: 'Motion, contact, time of day, and sensor history become context for useful suggestions.',
    stat: '4 sensors',
    icon: Waves
  },
  {
    label: 'Intent',
    title: 'Suggestions are framed as choices.',
    body: 'Lumen proposes scenes based on context, but it does not silently take over sensitive actions.',
    stat: 'confirm first',
    icon: Brain
  },
  {
    label: 'Action',
    title: 'One clean confirmation controls the room.',
    body: 'HomeKit executes today. The Muhome architecture keeps the bridge layer ready for Matter and local devices.',
    stat: 'HomeKit',
    icon: Lightbulb
  }
];

const architecture = [
  ['01', 'Experience layer', 'The polished iPhone surface for rooms, scenes, suggestions, sensor state, remotes, and explicit confirmations.'],
  ['02', 'Semantic home model', 'Homes, rooms, zones, planned devices, routines, presence, and environmental state are structured as context.'],
  ['03', 'Capability graph', 'Devices expose abilities instead of brand assumptions: brightness, color, motion, power, contact, temperature, and scene participation.'],
  ['04', 'Bridge layer', 'HomeKit is the first execution bridge. The architecture leaves room for Matter, LAN devices, and future adapters.'],
  ['05', 'Local-first storage', 'SwiftData keeps the home model on device, while iCloud and CloudKit support continuity without becoming the operating dependency.'],
  ['06', 'Intelligence and safety', 'The AI layer observes, explains, and suggests. It asks before acting when device control could matter.']
];

const stack = [
  ['Interface', 'SwiftUI iPhone app'],
  ['State', 'Observation framework'],
  ['Persistence', 'SwiftData schema'],
  ['Sync', 'iCloud / CloudKit'],
  ['Home bridge', 'HomeKit / HMHomeManager'],
  ['Future bridge', 'Matter + LAN devices'],
  ['Model', 'Rooms, zones, capabilities'],
  ['Safety', 'Suggest first, confirm action']
];

const fadeUp = {
  initial: { opacity: 0, y: 28 },
  whileInView: { opacity: 1, y: 0 },
  viewport: { once: true, margin: '-80px' },
  transition: { duration: 0.7, ease: [0.22, 1, 0.36, 1] }
};

function AmbientLighting() {
  return (
    <div className="ambient" aria-hidden="true">
      <div className="orb orb-one" />
      <div className="orb orb-two" />
      <div className="orb orb-three" />
      <div className="grid-glow" />
    </div>
  );
}

function DeviceMockup({ activeStep = 2 }) {
  const current = storySteps[activeStep];
  const Icon = current.icon;

  return (
    <motion.div
      className="device-stage"
      initial={{ opacity: 0, y: 36, rotate: -2 }}
      whileInView={{ opacity: 1, y: 0, rotate: 0 }}
      viewport={{ once: true, margin: '-80px' }}
      transition={{ duration: 0.9, ease: [0.22, 1, 0.36, 1] }}
    >
      <div className="halo-ring" />
      <motion.div
        className="phone"
        animate={{ y: [0, -10, 0], rotateZ: [1, 0, 1] }}
        transition={{ duration: 7, repeat: Infinity, ease: 'easeInOut' }}
      >
        <div className="screen">
          <div className="status"><span>9:41</span><span className="island" /><span>Home</span></div>
          <div className="screen-copy">
            <p className="micro">Evening intelligence</p>
            <h2>Belgravia calm</h2>
            <p>Lumen detected low motion, warm lighting preference, and room context.</p>
          </div>
          <AnimatePresence mode="wait">
            <motion.div
              className="scene-card"
              key={current.label}
              initial={{ opacity: 0, y: 18, scale: 0.98 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              exit={{ opacity: 0, y: -12, scale: 0.98 }}
              transition={{ duration: 0.32, ease: 'easeOut' }}
            >
              <div className="scene-top"><span>{current.label}</span><span>Ready</span></div>
              <div className="glow-orb"><Icon size={36} strokeWidth={1.35} /></div>
              <h3>{current.title}</h3>
              <p>{current.body}</p>
              <div className="metric-grid">
                <div className="metric"><b>38%</b><span>Brightness</span></div>
                <div className="metric"><b>2700K</b><span>Warmth</span></div>
                <div className="metric"><b>{current.stat}</b><span>Context</span></div>
                <div className="metric"><b>Confirm</b><span>Before act</span></div>
              </div>
            </motion.div>
          </AnimatePresence>
          <button className="confirm-button" type="button">Apply suggested scene</button>
        </div>
      </motion.div>
    </motion.div>
  );
}

function ProductStory() {
  const [activeStep, setActiveStep] = useState(0);

  return (
    <section className="section story" id="story">
      <motion.div className="section-head centered" {...fadeUp}>
        <p className="eyebrow">Product story</p>
        <h2>Rooms become context. Context becomes intent.</h2>
        <p>Lumen is designed around a simple sequence: understand the space, read the moment, suggest the right action, and wait for confirmation.</p>
      </motion.div>
      <div className="story-grid">
        <motion.div className="story-tabs" {...fadeUp} transition={{ ...fadeUp.transition, delay: 0.08 }}>
          {storySteps.map((step, index) => {
            const Icon = step.icon;
            return (
              <button className={`story-tab ${activeStep === index ? 'active' : ''}`} key={step.label} onClick={() => setActiveStep(index)} type="button">
                <span className="tab-index">0{index + 1}</span>
                <span className="tab-icon"><Icon size={19} /></span>
                <span><b>{step.label}</b><small>{step.title}</small></span>
              </button>
            );
          })}
        </motion.div>
        <DeviceMockup activeStep={activeStep} />
      </div>
    </section>
  );
}

function Hero() {
  return (
    <section id="top" className="hero">
      <motion.div
        className="hero-copy"
        initial={{ opacity: 0, y: 34 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.85, ease: [0.22, 1, 0.36, 1] }}
      >
        <p className="eyebrow">Spatial intelligence for the home</p>
        <h1>A calmer home, conducted by <em>Lumen.</em></h1>
        <p className="lede">Lumen turns HomeKit, rooms, presence, scenes, sensors, and routines into one elegant iPhone experience. Muhome is the architecture underneath: local-first, capability-based, and designed to suggest before it acts.</p>
        <div className="actions">
          <a className="button primary" href="#access">Request early access <ArrowRight size={16} /></a>
          <a className="button secondary" href="#story">Explore the product</a>
        </div>
        <div className="trust-row">
          <span><CheckCircle2 size={16} /> Local-first</span>
          <span><LockKeyhole size={16} /> Confirmation-first</span>
          <span><RadioTower size={16} /> HomeKit bridge</span>
        </div>
      </motion.div>
      <DeviceMockup activeStep={2} />
    </section>
  );
}

function ArchitectureSection() {
  return (
    <section id="architecture" className="section paper">
      <motion.div className="section-head" {...fadeUp}>
        <p className="eyebrow">Muhome architecture</p>
        <h2>Not another remote. A model of the home.</h2>
        <p>Muhome separates interface, semantics, capabilities, bridges, persistence, sync, and intelligence so Lumen can feel simple while the system underneath remains durable.</p>
      </motion.div>
      <div className="architecture">
        {architecture.map(([num, title, text], index) => (
          <motion.article className="card" key={title} {...fadeUp} transition={{ ...fadeUp.transition, delay: index * 0.04 }}>
            <span className="num">{num}</span><h3>{title}</h3><p>{text}</p>
          </motion.article>
        ))}
      </div>
    </section>
  );
}

function StackSection() {
  return (
    <section id="stack" className="section dark-panel">
      <motion.div className="section-head" {...fadeUp}>
        <p className="eyebrow">Technical stack</p>
        <h2>A luxury surface over a serious system.</h2>
        <p>Each layer has a distinct job: present, model, persist, sync, bridge, observe, suggest, and confirm.</p>
      </motion.div>
      <div className="stack-grid">
        {stack.map(([k, v], index) => (
          <motion.div className="stack-item" key={k} {...fadeUp} transition={{ ...fadeUp.transition, delay: index * 0.035 }}>
            <b>{k}</b><span>{v}</span>
          </motion.div>
        ))}
      </div>
    </section>
  );
}

function Principles() {
  return (
    <section className="section principles dark-panel">
      <motion.blockquote {...fadeUp}>“A home app should feel like <em>a quiet collaborator</em> — present when needed, invisible when not.”</motion.blockquote>
      <motion.div className="principle-list" {...fadeUp} transition={{ ...fadeUp.transition, delay: 0.12 }}>
        <div className="principle"><Sparkles size={20} /><h3>Suggest, never seize control</h3><p>Automation should be explainable and reversible. Lumen can recommend actions, but Muhome keeps execution permissioned.</p></div>
        <div className="principle"><Layers3 size={20} /><h3>Architecture before interface</h3><p>The interface is only as strong as the model beneath it. Rooms, devices, sensors, remotes, and routines need a shared semantic backbone.</p></div>
        <div className="principle"><Moon size={20} /><h3>Device-agnostic by design</h3><p>The platform avoids becoming a list of brand integrations. Capability composition keeps the system flexible as hardware changes.</p></div>
      </motion.div>
    </section>
  );
}

function Waitlist() {
  return (
    <section id="access" className="section access">
      <motion.div {...fadeUp}>
        <p className="eyebrow">Early access</p>
        <h2>Follow the Lumen build.</h2>
        <p className="lede">This is the public preview surface while the iOS product and Muhome architecture mature. The form opens a prepared email so the waitlist can be handled manually until the backend is connected.</p>
      </motion.div>
      <motion.form className="signup" action="mailto:Muharafi@umich.edu" method="post" encType="text/plain" {...fadeUp} transition={{ ...fadeUp.transition, delay: 0.12 }}>
        <label htmlFor="email">Email address</label>
        <input id="email" name="email" type="email" placeholder="you@example.com" required />
        <label htmlFor="context">What are you building toward?</label>
        <input id="context" name="context" type="text" placeholder="Apartment, house, dorm, test lab..." />
        <button type="submit">Join Early Access</button>
        <p>No payment required. One update when Lumen is ready.</p>
      </motion.form>
    </section>
  );
}

export function App() {
  const marquee = useMemo(() => ['SwiftUI', 'SwiftData', 'HomeKit', 'Matter-ready', 'Capability graph', 'iCloud continuity', 'Local-first', 'Confirmation-first'], []);

  return (
    <main className="site-shell">
      <Style />
      <AmbientLighting />
      <nav className="nav">
        <a className="brand" href="#top" aria-label="Lumen home"><span className="brand-mark">L</span><span>Lumen</span></a>
        <div className="nav-links"><a href="#story">Story</a><a href="#architecture">Architecture</a><a href="#stack">Stack</a><a className="nav-cta" href="#access">Early access</a></div>
      </nav>
      <Hero />
      <div className="ribbon"><div className="ribbon-track">{[...marquee, ...marquee].map((item, index) => <span key={`${item}-${index}`}>{item}</span>)}</div></div>
      <ProductStory />
      <ArchitectureSection />
      <StackSection />
      <Principles />
      <Waitlist />
      <footer className="footer"><span>Lumen</span><span>Production app surface · Built on Muhome architecture</span></footer>
    </main>
  );
}

function Style() {
  return (
    <style>{`
      :root{color-scheme:dark;--night:#080504;--espresso:#140c08;--cream:#fff3dc;--cream-soft:#dfcdb0;--cream-muted:#a99473;--gold:#d9b76f;--gold-2:#f0d99f;--copper:#a96d43;--paper:#fbf4e8;--paper-2:#f1e4d1;--ink:#1a100a;--muted:#715842;--dark-line:#e2cfb6}*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;font-family:-apple-system,BlinkMacSystemFont,"SF Pro Display","Inter",system-ui,sans-serif;background:var(--night);color:var(--cream);-webkit-font-smoothing:antialiased}a{color:inherit;text-decoration:none}button,input{font:inherit}.site-shell{position:relative;min-height:100vh;overflow:hidden;background:radial-gradient(circle at 18% 8%,rgba(217,183,111,.15),transparent 26%),radial-gradient(circle at 82% 18%,rgba(169,109,67,.22),transparent 30%),linear-gradient(135deg,var(--night),var(--espresso) 46%,#070403)}.ambient{position:fixed;inset:0;pointer-events:none;overflow:hidden;z-index:0}.orb{position:absolute;border-radius:999px;filter:blur(30px);opacity:.52;animation:float 9s ease-in-out infinite alternate}.orb-one{width:420px;height:420px;left:-120px;top:80px;background:rgba(217,183,111,.23)}.orb-two{width:520px;height:520px;right:-160px;top:110px;background:rgba(169,109,67,.28);animation-delay:1.5s}.orb-three{width:360px;height:360px;left:42%;bottom:-180px;background:rgba(240,217,159,.12);animation-delay:2.5s}.grid-glow{position:absolute;inset:0;opacity:.16;background-image:linear-gradient(rgba(255,255,255,.05) 1px,transparent 1px),linear-gradient(90deg,rgba(255,255,255,.04) 1px,transparent 1px);background-size:72px 72px;mask-image:radial-gradient(circle at center,black,transparent 74%)}@keyframes float{from{transform:translate3d(0,0,0) scale(1)}to{transform:translate3d(24px,-18px,0) scale(1.08)}}.nav{position:fixed;inset:0 0 auto 0;z-index:30;height:76px;display:flex;align-items:center;justify-content:space-between;padding:0 clamp(22px,5vw,64px);background:rgba(9,6,4,.72);border-bottom:1px solid rgba(255,255,255,.09);backdrop-filter:blur(22px) saturate(150%)}.brand{display:flex;align-items:center;gap:12px;font-weight:720;letter-spacing:-.025em}.brand-mark{width:34px;height:34px;border-radius:13px;display:grid;place-items:center;color:#160d08;font-weight:900;background:linear-gradient(135deg,var(--gold-2),var(--gold) 52%,var(--copper));box-shadow:0 12px 34px rgba(217,183,111,.25),inset 0 1px 0 rgba(255,255,255,.55)}.nav-links{display:flex;gap:28px;align-items:center;color:var(--cream-soft);font-size:14px}.nav-links a:hover{color:var(--cream)}.nav-cta{padding:10px 18px;border-radius:999px;color:var(--night)!important;background:linear-gradient(135deg,var(--cream),var(--gold-2));font-weight:760;box-shadow:0 14px 32px rgba(217,183,111,.18)}.hero{position:relative;z-index:1;min-height:100vh;display:grid;grid-template-columns:minmax(0,1fr) minmax(360px,.92fr);gap:clamp(44px,7vw,92px);align-items:center;max-width:1320px;margin:0 auto;padding:150px clamp(22px,5vw,64px) 88px}.eyebrow{margin:0 0 20px;color:var(--gold-2);text-transform:uppercase;letter-spacing:.22em;font-size:11px;font-weight:820}h1{max-width:780px;margin:0 0 30px;font-size:clamp(56px,8.2vw,118px);line-height:.88;letter-spacing:-.075em;font-weight:210}h1 em,h2 em,blockquote em{font-style:normal;background:linear-gradient(120deg,#fff5d8,var(--gold-2) 42%,var(--copper));-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text}.lede{max-width:650px;color:var(--cream-soft);font-size:clamp(18px,1.7vw,22px);line-height:1.72;font-weight:320;margin:0 0 34px}.actions{display:flex;flex-wrap:wrap;gap:14px;align-items:center}.button{display:inline-flex;align-items:center;justify-content:center;gap:8px;min-height:48px;padding:0 21px;border-radius:999px;font-size:14px;font-weight:780;border:1px solid rgba(255,255,255,.14);transition:transform .2s ease,border-color .2s ease,background .2s ease}.button:hover{transform:translateY(-2px);border-color:rgba(255,255,255,.28)}.primary{color:var(--night);background:linear-gradient(135deg,var(--cream),var(--gold-2));box-shadow:0 18px 42px rgba(217,183,111,.18)}.secondary{color:var(--cream);background:rgba(255,255,255,.055)}.trust-row{display:flex;flex-wrap:wrap;gap:16px;margin-top:28px;color:var(--cream-muted);font-size:13px}.trust-row span{display:inline-flex;align-items:center;gap:7px}.device-stage{min-height:620px;display:grid;place-items:center;perspective:1200px;position:relative}.halo-ring{position:absolute;width:min(86%,440px);aspect-ratio:1;border-radius:999px;border:1px solid rgba(240,217,159,.18);box-shadow:0 0 120px rgba(217,183,111,.16),inset 0 0 80px rgba(217,183,111,.05)}.phone{width:min(100%,390px);aspect-ratio:9/18.5;border-radius:48px;padding:14px;background:linear-gradient(145deg,#3a271b,#0d0805 48%,#4a311d);border:1px solid rgba(255,255,255,.18);box-shadow:0 40px 120px rgba(0,0,0,.5),inset 0 0 0 1px rgba(255,255,255,.08);transform:rotateY(-10deg) rotateX(4deg) rotateZ(1deg)}.screen{height:100%;border-radius:38px;overflow:hidden;padding:24px;background:radial-gradient(circle at 76% 8%,rgba(217,183,111,.26),transparent 30%),linear-gradient(180deg,#17100b,#0b0705 60%,#130b07);border:1px solid rgba(255,255,255,.1)}.status{display:flex;justify-content:space-between;align-items:center;color:var(--cream-muted);font-size:12px;margin-bottom:28px}.island{width:92px;height:26px;border-radius:999px;background:#050302;box-shadow:inset 0 0 0 1px rgba(255,255,255,.06)}.screen-copy h2{font-size:36px;line-height:.98;letter-spacing:-.055em;font-weight:280;margin:0 0 8px}.screen-copy p,.scene-card p{color:var(--cream-soft);line-height:1.5;font-size:14px}.micro{color:var(--gold-2)!important;text-transform:uppercase;letter-spacing:.16em;font-size:10px!important;font-weight:800;margin:0 0 12px}.scene-card{margin-top:22px;padding:18px;border-radius:26px;background:linear-gradient(145deg,rgba(255,255,255,.12),rgba(255,255,255,.045));border:1px solid rgba(255,255,255,.12);box-shadow:inset 0 1px 0 rgba(255,255,255,.12)}.scene-top{display:flex;justify-content:space-between;color:var(--cream-muted);font-size:12px;margin-bottom:18px}.glow-orb{width:116px;height:116px;border-radius:50%;margin:0 auto 18px;display:grid;place-items:center;color:#1a100a;background:radial-gradient(circle at 35% 30%,#fff4c8,#e3b866 42%,#8d5530 68%,rgba(141,85,48,.15));box-shadow:0 0 70px rgba(217,183,111,.44),0 0 130px rgba(169,109,67,.22)}.scene-card h3{margin:0 0 8px;font-size:19px;letter-spacing:-.03em}.metric-grid{display:grid;grid-template-columns:1fr 1fr;gap:10px;margin-top:16px}.metric{padding:14px;border-radius:18px;background:rgba(0,0,0,.22);border:1px solid rgba(255,255,255,.08)}.metric b{display:block;font-size:18px;letter-spacing:-.02em}.metric span{color:var(--cream-muted);font-size:11px;text-transform:uppercase;letter-spacing:.12em}.confirm-button{width:100%;height:48px;margin-top:14px;border:0;border-radius:18px;color:#160d08;background:linear-gradient(135deg,var(--cream),var(--gold-2));font-weight:850}.ribbon{position:relative;z-index:1;overflow:hidden;border-block:1px solid rgba(255,255,255,.09);background:rgba(255,255,255,.035);padding:15px 0}.ribbon-track{display:flex;width:max-content;gap:42px;animation:drift 24s linear infinite}.ribbon span{color:var(--cream-muted);white-space:nowrap;text-transform:uppercase;letter-spacing:.1em;font-size:12px}.ribbon span::before{content:"✦";color:var(--gold);margin-right:20px}@keyframes drift{from{transform:translateX(0)}to{transform:translateX(-50%)}}.section{position:relative;z-index:1;padding:112px clamp(22px,5vw,64px)}.section-head{max-width:780px;margin:0 auto 52px 0}.section-head.centered{margin-inline:auto;text-align:center}.section-head h2,.access h2{font-size:clamp(38px,5vw,72px);line-height:.98;letter-spacing:-.06em;font-weight:240;margin:0 0 18px}.section-head p{color:var(--cream-soft);font-size:18px;line-height:1.68;margin:0}.story-grid{max-width:1220px;margin:0 auto;display:grid;grid-template-columns:minmax(320px,.86fr) minmax(360px,1fr);gap:56px;align-items:center}.story-tabs{display:grid;gap:14px}.story-tab{text-align:left;display:grid;grid-template-columns:44px 44px 1fr;gap:14px;align-items:center;padding:18px;border-radius:24px;border:1px solid rgba(255,255,255,.1);background:rgba(255,255,255,.045);color:var(--cream);cursor:pointer;transition:background .2s ease,transform .2s ease,border-color .2s ease}.story-tab:hover,.story-tab.active{transform:translateY(-2px);border-color:rgba(240,217,159,.34);background:rgba(255,255,255,.085)}.tab-index{color:var(--gold-2);font-size:12px;letter-spacing:.14em;font-weight:900}.tab-icon{width:44px;height:44px;border-radius:16px;display:grid;place-items:center;background:rgba(217,183,111,.12);color:var(--gold-2)}.story-tab b{display:block;font-size:18px;margin-bottom:4px}.story-tab small{display:block;color:var(--cream-soft);line-height:1.45}.paper{background:linear-gradient(180deg,var(--paper),var(--paper-2));color:var(--ink)}.paper .eyebrow{color:var(--copper)}.paper .section-head p{color:var(--muted)}.architecture{max-width:1220px;margin:0 auto;display:grid;grid-template-columns:repeat(3,1fr);gap:18px}.card{position:relative;overflow:hidden;min-height:245px;padding:28px;border-radius:30px;background:rgba(255,255,255,.68);border:1px solid var(--dark-line);box-shadow:0 24px 70px rgba(96,64,34,.08)}.card::after{content:"";position:absolute;inset:auto -20% -45% 34%;height:130px;background:radial-gradient(circle,rgba(169,109,67,.18),transparent 70%)}.num{color:var(--copper);font-size:12px;letter-spacing:.16em;text-transform:uppercase;font-weight:860}.card h3{margin:20px 0 12px;font-size:22px;letter-spacing:-.035em}.card p{color:var(--muted);line-height:1.64;font-size:15px;margin:0}.dark-panel{background:linear-gradient(180deg,rgba(20,12,8,.96),rgba(9,6,4,.98));border-block:1px solid rgba(255,255,255,.09)}.dark-panel>.section-head,.dark-panel>.stack-grid,.principles{max-width:1220px;margin-left:auto;margin-right:auto}.stack-grid{display:grid;grid-template-columns:repeat(4,1fr);border:1px solid rgba(255,255,255,.12);border-radius:34px;overflow:hidden;box-shadow:0 36px 100px rgba(0,0,0,.26)}.stack-item{min-height:150px;padding:26px;border-right:1px solid rgba(255,255,255,.1);border-bottom:1px solid rgba(255,255,255,.1);background:linear-gradient(145deg,rgba(255,255,255,.07),rgba(255,255,255,.025))}.stack-item b{display:block;color:var(--gold-2);margin-bottom:10px;font-size:12px;text-transform:uppercase;letter-spacing:.16em}.stack-item span{color:var(--cream-soft);font-size:15px;line-height:1.55}.principles{display:grid;grid-template-columns:1.05fr .95fr;gap:clamp(42px,7vw,92px);align-items:start}blockquote{font-size:clamp(34px,4.4vw,64px);line-height:1.05;letter-spacing:-.065em;font-weight:220;margin:0}.principle-list{display:grid;gap:18px}.principle{padding:22px;border-radius:24px;background:rgba(255,255,255,.045);border:1px solid rgba(255,255,255,.09)}.principle svg{color:var(--gold-2);margin-bottom:14px}.principle h3{color:var(--cream);font-size:17px;margin:0 0 8px;letter-spacing:-.02em}.principle p{color:var(--cream-soft);line-height:1.65;margin:0}.access{max-width:1220px;margin:0 auto;display:grid;grid-template-columns:1fr 460px;gap:56px;align-items:start}.signup{background:rgba(255,255,255,.07);border:1px solid rgba(255,255,255,.13);border-radius:28px;padding:26px;display:grid;gap:12px;box-shadow:0 30px 90px rgba(0,0,0,.24)}.signup label{font-size:13px;color:var(--cream-soft);font-weight:760}.signup input{height:52px;border:1px solid rgba(255,255,255,.14);border-radius:16px;padding:0 15px;background:rgba(255,255,255,.08);color:var(--cream);outline:none}.signup input::placeholder{color:var(--cream-muted)}.signup button{height:52px;border:0;border-radius:16px;background:linear-gradient(135deg,var(--gold),var(--copper));color:var(--night);font-weight:860;cursor:pointer}.signup p{margin:0;color:var(--cream-muted);font-size:13px;line-height:1.5}.footer{position:relative;z-index:1;display:flex;justify-content:space-between;gap:20px;padding:34px clamp(22px,5vw,64px);background:var(--espresso);color:var(--cream-muted);border-top:1px solid rgba(255,255,255,.09);font-size:14px}@media(max-width:960px){.nav-links a:not(.nav-cta){display:none}.hero,.story-grid,.access,.principles{grid-template-columns:1fr}.device-stage{min-height:auto}.phone{transform:none;width:min(100%,360px)}.architecture{grid-template-columns:1fr}.stack-grid{grid-template-columns:1fr 1fr}}@media(max-width:560px){.nav{height:68px}.brand span:last-child{display:none}.hero{padding-top:110px}h1{font-size:clamp(50px,16vw,72px)}.phone{border-radius:38px;padding:10px}.screen{border-radius:30px;padding:20px}.screen-copy h2{font-size:30px}.story-tab{grid-template-columns:34px 38px 1fr;padding:14px}.stack-grid{grid-template-columns:1fr}.footer{flex-direction:column}}
    `}</style>
  );
}

createRoot(document.getElementById('root')).render(<App />);
