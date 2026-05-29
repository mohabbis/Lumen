import React from 'react';
import { createRoot } from 'react-dom/client';

const architecture = [
  ['01', 'Experience layer', 'SwiftUI iPhone interface for rooms, scenes, sensors, routines, and confirmations. Lumen is the polished product surface.'],
  ['02', 'Semantic home model', 'Rooms, zones, planned devices, capabilities, scenes, and intent are modeled as structured home context instead of flat device lists.'],
  ['03', 'Capability graph', 'Devices expose what they can do: brightness, color, temperature, motion, contact, power, and scene participation.'],
  ['04', 'Bridge layer', 'HomeKit first through HMHomeManager, with a bridge-agnostic path for Matter, LAN devices, and future integrations.'],
  ['05', 'Local-first storage', 'SwiftData keeps the home model on device; CloudKit/iCloud sync is used for continuity, not as the operating dependency.'],
  ['06', 'Intelligence and safety', 'Presence, history, and routines can suggest actions, but sensitive execution requires explicit user confirmation.']
];

const stack = [
  ['Interface', 'SwiftUI'],
  ['State', 'Observation framework'],
  ['Persistence', 'SwiftData schema v3'],
  ['Sync', 'iCloud / CloudKit'],
  ['Home bridge', 'HomeKit / HMHomeManager'],
  ['Future bridge', 'Matter + local network devices'],
  ['Model', 'Rooms, zones, devices, capabilities'],
  ['Safety', 'Suggest first, confirm before action']
];

function App() {
  return (
    <main className="site-shell">
      <style>{`
        :root { color-scheme: light; --bg:#f4eee4; --ink:#1d1711; --muted:#6d5a47; --line:#ddcbb5; --card:#fffaf2; --dark:#17100b; --gold:#b8873e; --soft:#eadcc8; }
        * { box-sizing:border-box; }
        body { margin:0; font-family:-apple-system,BlinkMacSystemFont,"SF Pro Display","Inter",system-ui,sans-serif; background:var(--bg); color:var(--ink); -webkit-font-smoothing:antialiased; }
        a { color:inherit; text-decoration:none; }
        .site-shell { min-height:100vh; overflow:hidden; }
        .nav { position:fixed; inset:0 0 auto 0; z-index:20; height:72px; display:flex; align-items:center; justify-content:space-between; padding:0 44px; background:rgba(244,238,228,.74); backdrop-filter:blur(18px); border-bottom:1px solid rgba(221,203,181,.55); }
        .brand { display:flex; align-items:center; gap:10px; font-weight:650; letter-spacing:-.02em; }
        .brand-mark { width:30px; height:30px; border-radius:10px; display:grid; place-items:center; background:linear-gradient(135deg,var(--gold),#e8c989); color:#1c1209; font-size:14px; }
        .nav-links { display:flex; gap:24px; font-size:14px; color:var(--muted); }
        .hero { padding:148px 44px 88px; display:grid; grid-template-columns:minmax(0,1.05fr) minmax(360px,.95fr); gap:72px; align-items:center; max-width:1200px; margin:0 auto; }
        .eyebrow { margin:0 0 16px; color:var(--gold); text-transform:uppercase; letter-spacing:.18em; font-size:12px; font-weight:700; }
        h1 { margin:0; font-size:clamp(48px,7vw,92px); line-height:.95; letter-spacing:-.065em; font-weight:250; }
        h1 em { font-style:normal; color:var(--gold); }
        .lede { margin:26px 0 34px; color:var(--muted); font-size:20px; line-height:1.65; max-width:620px; }
        .actions { display:flex; gap:14px; flex-wrap:wrap; }
        .button { border-radius:999px; padding:13px 20px; font-weight:650; font-size:14px; border:1px solid var(--line); }
        .primary { background:var(--dark); color:var(--card); border-color:var(--dark); }
        .secondary { background:rgba(255,250,242,.5); color:var(--ink); }
        .diagram { background:var(--dark); color:var(--card); border-radius:34px; padding:28px; box-shadow:0 34px 90px rgba(54,35,15,.24); border:1px solid rgba(255,255,255,.08); }
        .diagram-title { display:flex; justify-content:space-between; gap:16px; align-items:center; margin-bottom:22px; color:#d9c5aa; font-size:13px; }
        .flow { display:grid; gap:10px; }
        .flow-row { display:grid; grid-template-columns:96px 1fr; gap:12px; align-items:center; padding:13px; border:1px solid rgba(255,255,255,.08); border-radius:16px; background:rgba(255,255,255,.035); }
        .flow-row span:first-child { color:#e7bd76; font-size:12px; text-transform:uppercase; letter-spacing:.12em; }
        .flow-row strong { font-size:15px; }
        .section { padding:86px 44px; max-width:1200px; margin:0 auto; }
        .section-head { max-width:720px; margin-bottom:36px; }
        h2 { margin:0 0 14px; font-size:clamp(34px,4.8vw,60px); line-height:1; letter-spacing:-.05em; font-weight:300; }
        .section-head p { color:var(--muted); font-size:18px; line-height:1.65; margin:0; }
        .architecture { display:grid; grid-template-columns:repeat(3,1fr); gap:16px; }
        .card { background:var(--card); border:1px solid var(--line); border-radius:24px; padding:24px; min-height:210px; }
        .num { color:var(--gold); font-weight:750; letter-spacing:.12em; font-size:12px; }
        .card h3 { margin:18px 0 10px; font-size:20px; letter-spacing:-.025em; }
        .card p { margin:0; color:var(--muted); line-height:1.62; font-size:15px; }
        .stack { background:var(--dark); color:var(--card); max-width:none; padding-left:44px; padding-right:44px; }
        .stack-inner { max-width:1200px; margin:0 auto; }
        .stack-grid { display:grid; grid-template-columns:repeat(4,1fr); border:1px solid rgba(255,255,255,.1); border-radius:28px; overflow:hidden; }
        .stack-item { padding:22px; border-right:1px solid rgba(255,255,255,.1); border-bottom:1px solid rgba(255,255,255,.1); background:rgba(255,255,255,.035); }
        .stack-item b { display:block; color:#e7bd76; margin-bottom:8px; font-size:13px; text-transform:uppercase; letter-spacing:.12em; }
        .stack-item span { color:#e8dccd; font-size:15px; }
        .access { display:grid; grid-template-columns:1fr 420px; gap:48px; align-items:start; }
        .signup { background:var(--card); border:1px solid var(--line); border-radius:24px; padding:24px; display:grid; gap:12px; }
        .signup label { font-size:13px; color:var(--muted); font-weight:650; }
        .signup input { height:48px; border:1px solid var(--line); border-radius:14px; padding:0 14px; font:inherit; background:white; }
        .signup button { height:48px; border:0; border-radius:14px; background:var(--dark); color:var(--card); font-weight:700; cursor:pointer; }
        .signup p { margin:0; color:var(--muted); font-size:13px; line-height:1.5; }
        .footer { padding:34px 44px; border-top:1px solid var(--line); display:flex; justify-content:space-between; gap:20px; color:var(--muted); font-size:14px; }
        @media (max-width:900px){ .nav{padding:0 22px}.nav-links{display:none}.hero{grid-template-columns:1fr;padding:124px 22px 64px}.section,.stack{padding:68px 22px}.architecture{grid-template-columns:1fr}.stack-grid{grid-template-columns:1fr}.access{grid-template-columns:1fr}.footer{padding:30px 22px;flex-direction:column}.diagram{border-radius:24px}.flow-row{grid-template-columns:1fr} }
      `}</style>

      <nav className="nav">
        <a className="brand" href="#top" aria-label="Illumenate home"><span className="brand-mark">L</span><span>Lumen</span></a>
        <div className="nav-links"><a href="#architecture">Architecture</a><a href="#stack">Stack</a><a href="#access">Early Access</a></div>
      </nav>

      <section id="top" className="hero">
        <div>
          <p className="eyebrow">Architecture of Lumen</p>
          <h1>The app surface for a home with <em>memory and judgment.</em></h1>
          <p className="lede">Lumen is the production-facing iPhone app. Muhome is the underlying architecture: local-first, capability-based, bridge-agnostic, and designed to propose intelligent actions without silently taking control.</p>
          <div className="actions"><a className="button primary" href="#architecture">View architecture</a><a className="button secondary" href="#access">Reserve early access</a></div>
        </div>
        <aside className="diagram" aria-label="Lumen architecture flow">
          <div className="diagram-title"><strong>Lumen system flow</strong><span>local-first</span></div>
          <div className="flow">
            <div className="flow-row"><span>User</span><strong>Intent, room context, confirmations</strong></div>
            <div className="flow-row"><span>Lumen</span><strong>SwiftUI experience layer</strong></div>
            <div className="flow-row"><span>Muhome</span><strong>Semantic model + capability graph</strong></div>
            <div className="flow-row"><span>Bridge</span><strong>HomeKit now; Matter and LAN later</strong></div>
            <div className="flow-row"><span>Devices</span><strong>Lights, sensors, scenes, routines</strong></div>
          </div>
        </aside>
      </section>

      <section id="architecture" className="section">
        <div className="section-head">
          <p className="eyebrow">System architecture</p>
          <h2>Built as layers, not a pile of controls.</h2>
          <p>The architecture separates interface, home semantics, device capability, bridge execution, storage, sync, and AI-assisted judgment. That separation is what lets Lumen feel calm while the system underneath stays extensible.</p>
        </div>
        <div className="architecture">
          {architecture.map(([num, title, text]) => <article className="card" key={title}><span className="num">{num}</span><h3>{title}</h3><p>{text}</p></article>)}
        </div>
      </section>

      <section id="stack" className="section stack">
        <div className="stack-inner">
          <div className="section-head">
            <p className="eyebrow">Technical stack</p>
            <h2>The Lumen app sits on the Muhome framework.</h2>
            <p>Each layer has a clear job: present, model, persist, sync, bridge, observe, suggest, and confirm.</p>
          </div>
          <div className="stack-grid">
            {stack.map(([k, v]) => <div className="stack-item" key={k}><b>{k}</b><span>{v}</span></div>)}
          </div>
        </div>
      </section>

      <section id="access" className="section access">
        <div>
          <p className="eyebrow">Early access</p>
          <h2>Reserve your place in the Lumen preview.</h2>
          <p className="lede">This is a preview list while the iOS product and Muhome architecture mature.</p>
        </div>
        <form className="signup" action="mailto:Muharafi@umich.edu" method="post" encType="text/plain">
          <label htmlFor="email">Email address</label>
          <input id="email" name="email" type="email" placeholder="you@example.com" required />
          <button type="submit">Join Early Access</button>
          <p>No payment required. One update when Lumen is ready.</p>
        </form>
      </section>

      <footer className="footer"><span>Lumen</span><span>Production app surface · Built on Muhome architecture</span></footer>
    </main>
  );
}

createRoot(document.getElementById('root')).render(<App />);
