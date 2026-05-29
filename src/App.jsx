import React, { useMemo, useState } from 'react';
import {
  ArrowRight,
  Brain,
  CheckCircle2,
  Home,
  Infinity,
  Lightbulb,
  LockKeyhole,
  Menu,
  Microchip,
  RadioTower,
  Shield,
  Sparkles,
  SunMedium,
  Waves
} from 'lucide-react';

const screens = [
  {
    id: 'home',
    label: 'Awareness',
    title: 'Good evening, Alex',
    subtitle: 'Everything looks perfect.',
    card: 'Favorite rooms',
    icon: Home,
    rows: ['Living Room 24.0°', 'Bedroom 21.5°', 'Kitchen all off', 'Hallway quiet']
  },
  {
    id: 'room',
    label: 'Control',
    title: 'Living Room',
    subtitle: 'Comfortable · 4 devices',
    card: 'Devices',
    icon: Lightbulb,
    rows: ['Lights 70% → 40%', 'Shades open 35%', 'Temperature 22.5°', 'Air quality excellent']
  },
  {
    id: 'intelligence',
    label: 'Reasoning',
    title: 'Why Lumen dimmed the lights',
    subtitle: 'The sun set, room temperature rose, and presence stayed active.',
    card: 'Suggested automation',
    icon: Brain,
    rows: ['Presence detected', 'Sunset matched', 'Temperature +1.2°', 'Confidence high']
  },
  {
    id: 'action',
    label: 'Action',
    title: 'Evening Comfort',
    subtitle: 'Ready to apply with your approval.',
    card: 'Scene changes',
    icon: CheckCircle2,
    rows: ['Living room lights 70% → 40%', 'Temperature 22.5° → 21.5°', 'Shades 35% → 60%', 'Scene Warm Evening']
  }
];

const architecture = [
  ['Devices', 'Matter / Local'],
  ['Sensors', 'Environmental'],
  ['Presence', 'People & pets'],
  ['Automations', 'Context aware'],
  ['Scenes', 'Adaptive'],
  ['Insights', 'Private AI']
];

const stack = [
  ['SwiftUI', 'Native iPhone interface'],
  ['HomeKit', 'Secure home control'],
  ['SwiftData', 'Local home model'],
  ['CloudKit', 'Private continuity'],
  ['On-device AI', 'Reasoning without surveillance'],
  ['Matter-ready', 'Built to evolve']
];

function AppScreen({ screen, featured = false }) {
  const Icon = screen.icon;
  return (
    <div className={featured ? 'phone phone-featured' : 'phone mini-phone'}>
      <div className="phone-screen">
        <div className="phone-status"><span>9:41</span><span className="dynamic-island" /><span>⌁</span></div>
        <div className="app-brand">LUMEN</div>
        <div className="screen-header">
          <div>
            <p className="screen-kicker">{screen.label}</p>
            <h3>{screen.title}</h3>
            <p>{screen.subtitle}</p>
          </div>
          <div className="avatar-dot"><Icon size={18} /></div>
        </div>
        <div className="chip-row">
          <span>4 rooms</span><span>12 devices</span><span>3 automations</span>
        </div>
        <div className="main-card">
          <div className="main-card-head"><b>{screen.card}</b><ArrowRight size={15} /></div>
          <div className="room-grid">
            {screen.rows.map((row, index) => <div className="room-cell" key={row}><span>{row}</span><small>{index % 2 === 0 ? 'Active' : 'Ready'}</small></div>)}
          </div>
        </div>
        <div className="presence-card">
          <div><b>Lumen suggests</b><span>{screen.id === 'action' ? 'Confirm scene changes' : 'Evening comfort scene'}</span></div>
          <div className="pulse-dot" />
        </div>
        <div className="tabbar"><span className="active">Home</span><span>Rooms</span><span>Intel</span><span>Auto</span></div>
      </div>
    </div>
  );
}

function ProductGallery() {
  const [active, setActive] = useState(0);
  return (
    <section className="section gallery" id="product">
      <div className="section-copy centered">
        <p className="eyebrow">The Lumen experience</p>
        <h2>From awareness to action. All in one calm flow.</h2>
      </div>
      <div className="story-steps">
        {screens.map((screen, index) => {
          const Icon = screen.icon;
          return <button key={screen.id} className={active === index ? 'active' : ''} onClick={() => setActive(index)}><Icon size={18} /><b>{screen.label}</b><span>{index === 0 ? 'See your home.' : index === 1 ? 'Understand every detail.' : index === 2 ? 'AI that reasons.' : 'One tap. Done.'}</span></button>;
        })}
      </div>
      <div className="screen-gallery">
        {screens.map((screen, index) => <div className={active === index ? 'selected' : ''} key={screen.id}><AppScreen screen={screen} /></div>)}
      </div>
    </section>
  );
}

function Architecture() {
  return (
    <section className="deep-section" id="architecture">
      <div className="architecture-card">
        <div>
          <p className="eyebrow">Muhome architecture</p>
          <h2>The foundation behind Lumen.</h2>
          <p>Muhome is the local brain. It unifies devices, sensors, presence, routines, and room semantics into a single model your home can understand.</p>
          <a href="#access">Learn more <ArrowRight size={15} /></a>
        </div>
        <div className="muhome-diagram">
          <div className="cube">Muhome</div>
          {architecture.map(([name, meta]) => <div className="node" key={name}><b>{name}</b><span>{meta}</span></div>)}
        </div>
        <div>
          <p className="eyebrow">Technical stack</p>
          <h2>Modern. Private. Built to last.</h2>
          <div className="stack-list">{stack.map(([name, meta]) => <div key={name}><Sparkles size={15} /><span><b>{name}</b><small>{meta}</small></span></div>)}</div>
        </div>
      </div>
    </section>
  );
}

export function App() {
  const featureStrip = useMemo(() => [
    ['Private by design', 'Your home. Your data.', LockKeyhole],
    ['On-device intelligence', 'Fast, local, secure.', Microchip],
    ['HomeKit native', 'Deep integration that works.', Home],
    ['Future ready', 'Built to evolve with your home.', Infinity]
  ], []);

  return (
    <main className="site-shell">
      <style>{styles}</style>
      <div className="grain" />
      <nav className="nav">
        <a className="logo" href="#top"><SunMedium size={25} /><span>LUMEN</span></a>
        <div className="links"><a href="#product">Product</a><a href="#intelligence">Intelligence</a><a href="#architecture">Architecture</a><a href="#design">Design</a><a href="#access">Early Access</a></div>
        <div className="nav-actions"><a href="#access">Join Waitlist</a><button><Menu size={19} /></button></div>
      </nav>

      <section className="hero" id="top">
        <div className="hero-bg" />
        <div className="hero-copy">
          <div className="pill"><span /> Coming soon</div>
          <h1>Your home, <em>understood.</em></h1>
          <p>Lumen is a new kind of home intelligence. It understands presence, context, and intent so your home can respond beautifully.</p>
          <div className="hero-chips"><span><LockKeyhole size={14} /> Private by design</span><span><Microchip size={14} /> On-device intelligence</span><span><Home size={14} /> Built for HomeKit</span></div>
          <div className="hero-actions"><a className="primary" href="#access">Join Early Access <ArrowRight size={16} /></a><a href="#product">Watch film <span>▶</span></a></div>
        </div>
        <div className="hero-device"><AppScreen screen={screens[0]} featured /></div>
        <div className="hero-points" id="intelligence">
          <div><Waves /><b>Understands</b><span>Presence & context</span></div>
          <div><Brain /><b>Thinks</b><span>On-device intelligence</span></div>
          <div><Sparkles /><b>Acts</b><span>Beautifully, automatically</span></div>
          <div><Shield /><b>Respects</b><span>Privacy always</span></div>
        </div>
      </section>

      <section className="detail-band" id="design">
        <div><p className="eyebrow">Every detail</p><h2>In every room.</h2><p>See what matters. Control what counts. Effortlessly.</p></div>
        <AppScreen screen={screens[0]} />
        <AppScreen screen={screens[1]} />
        <AppScreen screen={screens[2]} />
        <AppScreen screen={screens[3]} />
        <div><p className="eyebrow">Intelligence</p><h2>Meets intention.</h2><p>Lumen explains, suggests, and acts with your approval.</p><a href="#product">Explore the experience <ArrowRight size={15} /></a></div>
      </section>

      <ProductGallery />
      <div className="feature-strip">{featureStrip.map(([title, text, Icon]) => <div key={title}><Icon size={23} /><span><b>{title}</b><small>{text}</small></span></div>)}</div>
      <Architecture />

      <section className="access" id="access">
        <div>
          <p className="eyebrow">Private early access</p>
          <h2>Be the first to bring intelligence home.</h2>
          <p>Join the private waitlist and help shape the future of Lumen.</p>
          <form action="mailto:Muharafi@umich.edu" method="post" encType="text/plain"><input name="email" type="email" placeholder="Your email address" required /><button>Join Early Access <ArrowRight size={16} /></button></form>
          <div className="checks"><span>✓ No spam</span><span>✓ Private</span><span>✓ Invite only</span></div>
        </div>
        <div className="launch-card"><SunMedium size={36} /><b>Launching 2026</b><span>Built on Muhome · HomeKit native · Matter ready</span></div>
      </section>
    </main>
  );
}

const styles = `
  :root{--night:#050505;--ink:#0a0806;--cream:#fff3dc;--muted:#b8a995;--gold:#f0c987;--gold2:#f7dfae;--line:rgba(255,243,220,.14);--glass:rgba(255,255,255,.06)}*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:#050505;color:var(--cream);font-family:-apple-system,BlinkMacSystemFont,'SF Pro Display',Inter,system-ui,sans-serif}a{color:inherit;text-decoration:none}.site-shell{min-height:100vh;overflow:hidden;background:radial-gradient(circle at 58% 20%,rgba(222,153,70,.22),transparent 24%),radial-gradient(circle at 88% 38%,rgba(46,94,130,.16),transparent 28%),#050505}.grain{position:fixed;inset:0;pointer-events:none;opacity:.16;background-image:linear-gradient(rgba(255,255,255,.04) 1px,transparent 1px),linear-gradient(90deg,rgba(255,255,255,.035) 1px,transparent 1px);background-size:76px 76px;mask-image:radial-gradient(circle,black,transparent 76%)}.nav{height:76px;padding:0 38px;display:flex;align-items:center;justify-content:space-between;position:fixed;inset:0 0 auto;z-index:20;background:rgba(5,5,5,.72);border-bottom:1px solid var(--line);backdrop-filter:blur(20px)}.logo,.links,.nav-actions,.hero-actions,.hero-chips,.feature-strip div,.stack-list div{display:flex;align-items:center}.logo{gap:15px;font-size:22px;letter-spacing:.28em}.logo svg{color:var(--gold)}.links{gap:42px;color:#d5c7b3;font-size:14px}.nav-actions{gap:16px}.nav-actions a,.nav-actions button{border:1px solid var(--line);border-radius:999px;background:rgba(255,255,255,.05);color:var(--cream);padding:13px 21px}.nav-actions button{width:46px;height:46px;padding:0;justify-content:center}.hero{min-height:100vh;padding:120px 5vw 60px;display:grid;grid-template-columns:1fr 430px 360px;gap:50px;align-items:center;position:relative}.hero-bg{position:absolute;inset:76px 0 0;background:linear-gradient(90deg,rgba(0,0,0,.92),rgba(0,0,0,.28),rgba(0,0,0,.88)),radial-gradient(circle at 65% 44%,rgba(240,201,135,.22),transparent 26%),linear-gradient(135deg,#0a0705,#1f140d 45%,#071018);opacity:.95}.hero>*:not(.hero-bg){position:relative;z-index:1}.pill{display:inline-flex;gap:10px;align-items:center;border:1px solid var(--line);border-radius:999px;padding:10px 15px;color:var(--gold2);text-transform:uppercase;letter-spacing:.14em;font-size:12px;background:rgba(255,255,255,.04)}.pill span{width:7px;height:7px;border-radius:999px;background:var(--gold);box-shadow:0 0 16px var(--gold)}h1{font-family:Georgia,serif;font-weight:400;font-size:clamp(70px,8vw,140px);line-height:.88;letter-spacing:-.065em;margin:30px 0 24px}h1 em{display:block;color:var(--gold2)}.hero-copy p,.section-copy p,.access p,.deep-section p,.detail-band p{color:#d7c7b2;font-size:19px;line-height:1.65;max-width:620px}.hero-chips{gap:12px;flex-wrap:wrap;margin:28px 0}.hero-chips span{display:inline-flex;gap:8px;align-items:center;border:1px solid var(--line);border-radius:999px;padding:10px 14px;color:#d8cab8;background:rgba(255,255,255,.045)}.hero-actions{gap:22px}.hero-actions .primary,.access button{display:inline-flex;gap:10px;align-items:center;border:0;border-radius:999px;background:linear-gradient(135deg,#ffe2a7,#f0c987);color:#130d08;padding:17px 28px;font-weight:800}.hero-actions a:last-child{color:#e6d6c1}.hero-points{display:grid;gap:34px;border-left:1px solid var(--line);padding-left:34px}.hero-points div{display:grid;grid-template-columns:32px 1fr;column-gap:18px}.hero-points svg{color:var(--gold);grid-row:span 2}.hero-points b{text-transform:uppercase;letter-spacing:.14em;font-size:13px;color:var(--gold2)}.hero-points span{color:#d2c2ad}.phone{background:linear-gradient(145deg,#2d241e,#050505 54%,#8d633a);border:1px solid rgba(255,255,255,.28);border-radius:42px;padding:10px;box-shadow:0 34px 90px rgba(0,0,0,.55)}.phone-featured{width:390px;transform:rotate(-5deg)}.mini-phone{width:230px}.phone-screen{min-height:520px;border-radius:34px;padding:18px;background:radial-gradient(circle at 55% 18%,rgba(240,201,135,.16),transparent 30%),linear-gradient(180deg,#090b0f,#090706);overflow:hidden;border:1px solid rgba(255,255,255,.08)}.mini-phone .phone-screen{min-height:380px;border-radius:28px;padding:14px}.phone-status,.screen-header,.main-card-head,.presence-card,.tabbar{display:flex;align-items:center;justify-content:space-between}.dynamic-island{width:84px;height:24px;border-radius:999px;background:#000}.app-brand{letter-spacing:.42em;color:#e8d6bc;font-size:12px;margin:20px 0}.screen-kicker,.eyebrow{text-transform:uppercase;letter-spacing:.18em;color:var(--gold);font-size:12px}.screen-header h3{font-size:25px;line-height:1.05;margin:5px 0 4px}.screen-header p,.main-card small,.presence-card span{color:#b5a895;margin:0}.avatar-dot,.pulse-dot{display:grid;place-items:center;width:40px;height:40px;border-radius:50%;background:rgba(240,201,135,.14);color:var(--gold)}.chip-row{display:flex;gap:7px;flex-wrap:wrap;margin:16px 0}.chip-row span{font-size:11px;padding:7px 10px;border-radius:999px;background:rgba(255,255,255,.08);color:#d7c7b2}.main-card,.presence-card{padding:14px;border-radius:18px;background:rgba(255,255,255,.065);border:1px solid rgba(255,255,255,.08);margin-top:12px}.room-grid{display:grid;grid-template-columns:1fr 1fr;gap:9px;margin-top:12px}.room-cell{min-height:70px;border-radius:14px;padding:11px;background:linear-gradient(135deg,rgba(240,201,135,.2),rgba(255,255,255,.045))}.room-cell span{display:block;font-size:13px}.tabbar{margin-top:18px;border-radius:18px;padding:9px;background:rgba(0,0,0,.32);font-size:11px;color:#a99982}.tabbar .active{color:var(--gold)}.detail-band{margin:0 3vw 20px;padding:34px;display:grid;grid-template-columns:1.1fr repeat(4,230px) 1.1fr;gap:24px;align-items:center;border:1px solid var(--line);border-radius:28px;background:rgba(255,255,255,.045);backdrop-filter:blur(18px)}.detail-band h2,.section-copy h2,.access h2,.deep-section h2{font-family:Georgia,serif;font-weight:400;font-size:44px;line-height:1;margin:12px 0}.detail-band a,.architecture-card a{display:inline-flex;align-items:center;gap:8px;color:var(--gold)}.section{padding:110px 5vw}.centered{text-align:center;margin:0 auto 45px}.story-steps{display:grid;grid-template-columns:repeat(4,1fr);gap:18px;margin:0 auto 40px;max-width:1120px}.story-steps button{text-align:left;border:1px solid var(--line);border-radius:22px;background:rgba(255,255,255,.04);color:var(--cream);padding:18px}.story-steps button.active{background:rgba(240,201,135,.13);border-color:rgba(240,201,135,.4)}.story-steps svg{color:var(--gold)}.story-steps b,.story-steps span{display:block}.story-steps b{margin:12px 0 7px}.story-steps span{color:#c8b7a2}.screen-gallery{display:flex;justify-content:center;gap:26px;flex-wrap:wrap}.screen-gallery>div{opacity:.58;transform:scale(.94);transition:.25s}.screen-gallery>.selected{opacity:1;transform:scale(1)}.feature-strip{padding:26px 5vw;display:grid;grid-template-columns:repeat(4,1fr);gap:24px;border-block:1px solid var(--line);background:rgba(255,255,255,.035)}.feature-strip div{gap:16px}.feature-strip svg{color:var(--gold)}.feature-strip b,.feature-strip small{display:block}.feature-strip small{color:#b9aa95}.deep-section{padding:60px 3vw}.architecture-card{display:grid;grid-template-columns:1fr 1.6fr 1fr;gap:46px;padding:40px;border-radius:28px;border:1px solid var(--line);background:rgba(255,255,255,.04)}.muhome-diagram{position:relative;min-height:330px;border:1px solid var(--line);border-radius:24px;background:radial-gradient(circle,rgba(240,201,135,.13),transparent 48%)}.cube{position:absolute;left:50%;top:50%;transform:translate(-50%,-50%);display:grid;place-items:center;width:120px;height:120px;border:1px solid rgba(240,201,135,.5);border-radius:28px;color:var(--gold2);box-shadow:0 0 70px rgba(240,201,135,.18)}.node{position:relative;display:inline-block;margin:18px;width:145px;padding:13px;border-radius:15px;background:rgba(255,255,255,.06)}.node b,.node span{display:block}.node span{color:#a99982;font-size:12px}.stack-list{display:grid;gap:13px}.stack-list div{gap:12px}.stack-list svg{color:var(--gold)}.stack-list b,.stack-list small{display:block}.stack-list small{color:#b9aa95}.access{margin:20px 3vw 50px;padding:44px;display:grid;grid-template-columns:1.2fr .8fr;gap:40px;border-radius:28px;border:1px solid var(--line);background:linear-gradient(135deg,rgba(255,255,255,.06),rgba(240,201,135,.08))}.access form{display:grid;grid-template-columns:1fr auto;gap:12px;max-width:620px}.access input{height:56px;border:1px solid var(--line);border-radius:16px;background:rgba(255,255,255,.07);color:var(--cream);padding:0 18px}.checks{display:flex;gap:18px;flex-wrap:wrap;margin-top:16px;color:#c7b9a5}.launch-card{display:grid;place-content:center;gap:12px;text-align:center;border:1px solid var(--line);border-radius:24px;background:rgba(0,0,0,.22);padding:30px}.launch-card svg{color:var(--gold);margin:auto}.launch-card b{font-size:24px}.launch-card span{color:#c5b5a0}@media(max-width:1120px){.hero,.architecture-card,.access{grid-template-columns:1fr}.hero-points{border-left:0;padding-left:0}.detail-band{grid-template-columns:1fr 1fr}.feature-strip,.story-steps{grid-template-columns:1fr 1fr}.phone-featured{transform:none}}@media(max-width:720px){.links{display:none}.nav{padding:0 20px}.hero{padding-top:120px;grid-template-columns:1fr}h1{font-size:66px}.phone-featured,.mini-phone{width:min(100%,350px)}.detail-band,.feature-strip,.story-steps{grid-template-columns:1fr}.access form{grid-template-columns:1fr}.hero-actions{flex-direction:column;align-items:flex-start}}
`;
