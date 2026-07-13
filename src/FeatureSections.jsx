import {
  Activity, ArrowRight, MapPin, Shield,
  Smartphone, Sparkles, SunMedium, Tablet,
} from 'lucide-react';
import { usePhone } from './InteractivePhone.jsx';
import { FadeIn } from './components/FadeIn.jsx';

function DemoLink({ tab, label = 'Try in the phone' }) {
  const phone = usePhone();

  return (
    <button
      type="button"
      className="feature-demo-link"
      onClick={() => {
        phone.selectTab(tab);
        document.getElementById('top')?.scrollIntoView({ behavior: 'smooth', block: 'start' });
      }}
    >
      {label} <ArrowRight size={13} />
    </button>
  );
}

function FeatureBullets({ items }) {
  return (
    <ul className="feature-bullets">
      {items.map(item => (
        <li key={item}>
          <span className="feature-bullet-dot" />
          {item}
        </li>
      ))}
    </ul>
  );
}

const calmPillars = [
  {
    glyph: '◐',
    title: 'notices the moment',
    description:
      'Time of day, presence, and reachable devices are read quietly. One gentle suggestion surfaces — not a wall of toggles.',
  },
  {
    glyph: '✦',
    title: 'explains before it acts',
    description:
      'Every suggestion opens a reasoning sheet in plain language. You see the signals, read the why, and decide.',
  },
  {
    glyph: '♥',
    title: 'waits for your tap',
    description:
      'Suggestions always ask first. A second sheet lists exactly what will change. Scene taps, locks, and ambient Apply wait for your approval — only opted-in arrival or departure scenes can run on their own, with a notification.',
  },
];

export function BuiltForCalmSection() {
  return (
    <section className="built-for-calm-section" id="features">
      <FadeIn className="section-copy centered">
        <p className="eyebrow">features</p>
        <h2>built for<br /><em>calm.</em></h2>
        <p className="section-note">
          Lumen is a home companion, not a control panel. Three ideas shape every screen.
        </p>
      </FadeIn>
      <div className="calm-pillars-grid">
        {calmPillars.map(({ glyph, title, description }, i) => (
          <FadeIn key={title} delay={i * 0.07}>
            <article className="calm-pillar-card">
              <span className="calm-pillar-glyph" aria-hidden="true">{glyph}</span>
              <h3>{title}</h3>
              <p>{description}</p>
            </article>
          </FadeIn>
        ))}
      </div>
    </section>
  );
}

export function AppShowcaseSection() {
  return (
    <section className="app-showcase-section surface-alt" id="app">
      <div className="app-showcase-inner centered">
        <FadeIn className="section-copy centered">
          <p className="eyebrow">the app</p>
          <h2>simple by<br /><em>design.</em></h2>
          <p className="section-note">
            Five calm tabs — Home, Rooms, Intel, Auto, Settings — each with one job.
            The live iPhone demo above is the real beta flow: rhythm, suggestions, scenes,
            and consent sheets you can tap through right now.
          </p>
        </FadeIn>
        <FadeIn className="app-showcase-highlights">
          <div className="app-showcase-highlight">
            <SunMedium size={16} />
            <span>Daily rhythm with Now / Next transitions</span>
          </div>
          <div className="app-showcase-highlight">
            <Sparkles size={16} />
            <span>Scenes with approval before anything runs</span>
          </div>
          <div className="app-showcase-highlight">
            <Activity size={16} />
            <span>Every Apple Home device in one calm list</span>
          </div>
        </FadeIn>
        <FadeIn>
          <a className="app-showcase-cta" href="#demo">
            Try the live demo <ArrowRight size={14} />
          </a>
        </FadeIn>
      </div>
    </section>
  );
}

const featureOverview = [
  {
    id: 'rhythm',
    icon: SunMedium,
    label: 'Daily rhythm',
    summary: 'Morning to night blocks with gentle Now / Next transitions.',
  },
  {
    id: 'scenes',
    icon: Sparkles,
    label: 'Scenes',
    summary: 'Run, edit, and approve scenes before anything changes.',
  },
  {
    id: 'devices',
    icon: Activity,
    label: 'Devices',
    summary: 'Every Apple Home accessory in one calm Intel list.',
  },
  {
    id: 'rooms',
    icon: Shield,
    label: 'Rooms',
    summary: 'Favorite rooms and per-device controls, preview or real.',
  },
  {
    id: 'presence',
    icon: MapPin,
    label: 'Presence',
    summary: 'Arrival and departure scenes with plain notifications.',
  },
  {
    id: 'platforms',
    icon: Smartphone,
    label: 'iPhone & iPad',
    summary: 'Native SwiftUI on both form factors. Mac on the roadmap.',
  },
];

export function FeaturesOverviewSection() {
  return (
    <section className="features-overview-section" id="explore">
      <FadeIn className="section-copy centered">
        <p className="eyebrow">explore</p>
        <h2>everything your home needs.<br /><em>nothing extra.</em></h2>
        <p className="section-note">
          Each part of the app has one job. Tap a card to read more, or try it live in the phone above.
        </p>
      </FadeIn>
      <div className="features-overview-grid">
        {featureOverview.map(({ id, icon: Icon, label, summary }, i) => (
          <FadeIn key={id} delay={i * 0.05}>
            <a className="feature-overview-card" href={`#${id}`}>
              <div className="feature-overview-icon"><Icon size={18} /></div>
              <b>{label}</b>
              <p>{summary}</p>
            </a>
          </FadeIn>
        ))}
      </div>
    </section>
  );
}

export function RhythmFeatureSection() {
  return (
    <section className="feature-spotlight surface-alt" id="rhythm">
      <div className="feature-spotlight-inner">
        <FadeIn className="feature-spotlight-copy">
          <p className="eyebrow">daily rhythm</p>
          <h2>morning to night,<br /><em>without the noise.</em></h2>
          <p className="section-note">
            Lumen reads the time of day and shows where you are in the daily rhythm.
            The Now / Next card tracks the current block and the next transition calmly.
          </p>
          <FeatureBullets items={[
            'Now / Next card with progress through Evening, Night, Morning',
            'Lumen noticed suggestions tied to sunset and presence',
            'Rhythm layer works with no smart hardware connected',
          ]} />
          <DemoLink tab="Home" />
        </FadeIn>
        <FadeIn delay={0.08} className="feature-spotlight-panel">
          <div className="feature-mock-card">
            <p className="feature-mock-kicker">Now</p>
            <b>Evening</b>
            <div className="feature-mock-bar"><span style={{ width: '62%' }} /></div>
            <p className="feature-mock-next">Next · Night at 9:00 PM</p>
          </div>
        </FadeIn>
      </div>
    </section>
  );
}

export function ScenesFeatureSection() {
  return (
    <section className="feature-spotlight" id="scenes">
      <div className="feature-spotlight-inner reverse">
        <FadeIn className="feature-spotlight-copy">
          <p className="eyebrow">scenes</p>
          <h2>tap a scene.<br /><em>read it first.</em></h2>
          <p className="section-note">
            Every scene run opens an approval sheet listing exactly what will change.
            Edit scenes, add device actions, and set geofence triggers in the beta app.
          </p>
          <FeatureBullets items={[
            'Approval sheet before manual scene runs',
            'Scene editor with per-device actions',
            'Geofence automation on arrival or departure',
            'Morning, Evening, Movie Night, Sleep presets included',
          ]} />
          <DemoLink tab="Auto" label="Try scenes in the phone" />
        </FadeIn>
        <FadeIn delay={0.08} className="feature-spotlight-panel">
          <div className="feature-mock-stack">
            <div className="feature-mock-row"><span>Power</span><b>On</b></div>
            <div className="feature-mock-row"><span>Brightness</span><b>40%</b></div>
            <div className="feature-mock-row"><span>Temperature</span><b>2700K</b></div>
            <div className="feature-mock-cta">Apply Evening</div>
          </div>
        </FadeIn>
      </div>
    </section>
  );
}

export function DevicesFeatureSection() {
  return (
    <section className="feature-spotlight surface-alt" id="devices">
      <div className="feature-spotlight-inner">
        <FadeIn className="feature-spotlight-copy">
          <p className="eyebrow">intel</p>
          <h2>every device.<br /><em>one calm list.</em></h2>
          <p className="section-note">
            The Intel tab shows your Apple Home accessories with reachability at a glance.
            Lumen only renders controls for capabilities each device actually reports.
          </p>
          <FeatureBullets items={[
            'HomeKit and Matter accessories through Apple Home',
            'Lights, locks, thermostats, sensors, blinds, and plugs',
            'Capability-aware UI instead of generic toggle grids',
          ]} />
          <DemoLink tab="Intel" />
        </FadeIn>
        <FadeIn delay={0.08} className="feature-spotlight-panel">
          <div className="feature-mock-list">
            <div className="feature-mock-list-row"><span>Ceiling Light</span><i className="online" /></div>
            <div className="feature-mock-list-row"><span>Desk Lamp</span><i className="online" /></div>
            <div className="feature-mock-list-row"><span>Thermostat</span><i className="online" /></div>
            <div className="feature-mock-list-row"><span>Front Door</span><i className="offline" /></div>
          </div>
        </FadeIn>
      </div>
    </section>
  );
}

export function RoomsFeatureSection() {
  return (
    <section className="feature-spotlight" id="rooms">
      <div className="feature-spotlight-inner reverse">
        <FadeIn className="feature-spotlight-copy">
          <p className="eyebrow">rooms</p>
          <h2>your rooms,<br /><em>ready to try.</em></h2>
          <p className="section-note">
            Favorite rooms on the home screen jump straight into room detail.
            Planned devices let you rehearse controls before hardware arrives.
          </p>
          <FeatureBullets items={[
            'Room list with active device counts',
            'Brightness, color temperature, and power sliders',
            'Local preview mode enabled by default in beta',
          ]} />
          <DemoLink tab="Rooms" label="Open Living Room in the phone" />
        </FadeIn>
        <FadeIn delay={0.08} className="feature-spotlight-panel">
          <div className="feature-mock-card warm">
            <p className="feature-mock-kicker">Living Room</p>
            <b>Ceiling Light</b>
            <div className="feature-mock-bar gold"><span style={{ width: '62%' }} /></div>
            <p className="feature-mock-next">2700K · Warm</p>
          </div>
        </FadeIn>
      </div>
    </section>
  );
}

export function PresenceFeatureSection() {
  return (
    <section className="feature-spotlight surface-alt" id="presence">
      <div className="feature-spotlight-inner">
        <FadeIn className="feature-spotlight-copy">
          <p className="eyebrow">presence</p>
          <h2>arrive home.<br /><em>know what ran.</em></h2>
          <p className="section-note">
            Lumen watches your home radius and can run matching scenes when you arrive or leave.
            You get a notification and a welcome overlay, not a silent surprise.
          </p>
          <FeatureBullets items={[
            'Geofence detection within your home radius',
            'Scenes tagged for arrival or departure',
            'Notifications when automation runs or needs attention',
            'Welcome Home and Away Mode overlays on the home screen',
          ]} />
          <DemoLink tab="Home" label="See the home screen in the phone" />
        </FadeIn>
        <FadeIn delay={0.08} className="feature-spotlight-panel">
          <div className="feature-mock-card presence">
            <p className="feature-mock-kicker">Detected</p>
            <b>Welcome Home</b>
            <p className="feature-mock-next">Evening scene matched · On Arrival</p>
          </div>
        </FadeIn>
      </div>
    </section>
  );
}

export function PlatformsSection() {
  return (
    <section className="platforms-section" id="platforms">
      <FadeIn className="section-copy centered">
        <p className="eyebrow">platforms</p>
        <h2>built for Apple.<br /><em>calm everywhere.</em></h2>
        <p className="section-note">
          Private beta on iPhone and iPad today. Mac is on the roadmap after the core loop is solid.
        </p>
      </FadeIn>
      <div className="platforms-row">
        <FadeIn delay={0.04}>
          <div className="platform-card">
            <Smartphone size={22} />
            <b>iPhone</b>
            <span>Native SwiftUI, consent-first flows</span>
          </div>
        </FadeIn>
        <FadeIn delay={0.08}>
          <div className="platform-card">
            <Tablet size={22} />
            <b>iPad</b>
            <span>Sidebar navigation on the same build</span>
          </div>
        </FadeIn>
      </div>
    </section>
  );
}
