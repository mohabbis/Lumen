import React from 'react';
import { createRoot } from 'react-dom/client';
import './styles.css';

const pillars = [
  ['Presence-aware', 'Lumen understands when rooms are active, idle, or empty.'],
  ['Spatially intelligent', 'Devices are organized around rooms, context, and relationships.'],
  ['Intent-driven', 'Ask for outcomes instead of tapping through device controls.']
];

function App() {
  return (
    <main className="site-shell">
      <nav className="nav">
        <a className="brand" href="#top" aria-label="Illumenate home">
          <span className="brand-mark">I</span>
          <span>Illumenate</span>
        </a>
        <div className="nav-links">
          <a href="#preview">Preview</a>
          <a href="#system">System</a>
          <a href="#access">Early Access</a>
        </div>
      </nav>

      <section id="top" className="hero grid">
        <div className="copy-block">
          <p className="eyebrow">Public preview for Lumen</p>
          <h1>Your home should understand what you mean.</h1>
          <p className="lede">
            Illumenate previews Lumen: an iPhone-first smart home interface built around rooms, presence, and intent.
          </p>
          <div className="actions">
            <a className="button primary" href="#access">Reserve Early Access</a>
            <a className="button secondary" href="#preview">View Preview</a>
          </div>
        </div>

        <section className="phone-card" id="preview" aria-label="Lumen interface preview">
          <div className="phone">
            <div className="status"><span>9:41</span><span>Home</span></div>
            <div className="assistant-card">
              <span className="spark">✦</span>
              <p>Nobody has been in the office for 47 minutes. Turn off the lights?</p>
              <div className="mini-actions"><button>Turn Off</button><button>Ignore</button></div>
            </div>
            <div className="metrics">
              <div><strong>6</strong><span>Rooms</span></div>
              <div><strong>18</strong><span>Devices</span></div>
              <div><strong>4</strong><span>Active</span></div>
            </div>
            <div className="room-list">
              <div><span>Living Room</span><em>Occupied</em></div>
              <div><span>Office</span><em>Idle</em></div>
              <div><span>Entry</span><em>Secure</em></div>
            </div>
          </div>
        </section>
      </section>

      <section id="system" className="section-intro">
        <p className="eyebrow">Built on Muhome</p>
        <h2>Lumen is the product. Muhome is the architecture underneath.</h2>
        <p>
          Muhome models devices, rooms, presence, automations, and environmental state so Lumen can present one calm interface instead of a pile of controls.
        </p>
      </section>

      <section className="pillars">
        {pillars.map(([title, text]) => (
          <article className="pillar" key={title}>
            <h3>{title}</h3>
            <p>{text}</p>
          </article>
        ))}
      </section>

      <section id="access" className="access grid">
        <div>
          <p className="eyebrow">Early access</p>
          <h2>Reserve your place in the Lumen preview.</h2>
        </div>
        <form className="signup" action="mailto:Muharafi@umich.edu" method="post" encType="text/plain">
          <label htmlFor="email">Email address</label>
          <input id="email" name="email" type="email" placeholder="you@example.com" required />
          <button type="submit">Join Early Access</button>
          <p>No payment required. This is a preview list while the iOS product is built.</p>
        </form>
      </section>

      <footer className="footer">
        <span>Illumenate</span>
        <span>Previewing Lumen · Built on Muhome</span>
      </footer>
    </main>
  );
}

createRoot(document.getElementById('root')).render(<App />);
