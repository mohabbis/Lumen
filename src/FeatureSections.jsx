import {
  Activity, ArrowRight, Check, MapPin, Shield,
  Smartphone, Sparkles, SunMedium, Tablet,
} from 'lucide-react';
import { usePhone } from './InteractivePhone.jsx';
import { FadeIn } from './components/FadeIn.jsx';

function DemoLink({ tab, label = 'Try in the preview' }) {
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
    icon: Activity,
    title: 'Notices the moment',
    description:
      'Time of day, presence, and which devices are answering get read in the background. '
      + 'One suggestion surfaces instead of a wall of toggles.',
  },
  {
    icon: Sparkles,
    title: 'Explains before it acts',
    description:
      'Every suggestion opens a reasoning sheet in plain language. You see the signals it '
      + 'read, why it landed on this scene, and you decide from there.',
  },
  {
    icon: Check,
    title: 'Waits for your tap',
    description:
      'Suggestions always ask first. A second sheet lists exactly what will change. Scene '
      + 'taps, locks, and ambient Apply all wait for approval. Only arrival and departure '
      + 'scenes you opt into run on their own, and they send a notification when they do.',
  },
];

export function BuiltForCalmSection() {
  return (
    <section className="built-for-calm-section" id="features">
      <FadeIn className="section-copy centered">
        <p className="eyebrow">features</p>
        <h2>Three rules behind<br /><em>every screen.</em></h2>
        <p className="section-note">
          Lumen is a home companion, not a control panel.
        </p>
      </FadeIn>
      <div className="calm-pillars-grid">
        {calmPillars.map(({ icon: Icon, title, description }) => (
          <article className="calm-pillar-card" key={title}>
            <span className="calm-pillar-icon" aria-hidden="true"><Icon size={18} /></span>
            <h3>{title}</h3>
            <p>{description}</p>
          </article>
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
          <h2>Five tabs,<br /><em>one job each.</em></h2>
          <p className="section-note">
            Home, Rooms, Intel, Auto, and Settings. The preview above runs the same loop:
            daily rhythm, one suggestion, scenes, and the consent sheets. You can tap
            through all of it right now.
          </p>
        </FadeIn>
        <div className="app-showcase-highlights">
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
        </div>
        <a className="app-showcase-cta" href="#demo">
          Try the preview <ArrowRight size={14} />
        </a>
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
        <h2>What is in the beta today.</h2>
        <p className="section-note">
          Each part of the app has one job. Tap a card to read more, or try it in the preview above.
        </p>
      </FadeIn>
      <div className="features-overview-grid">
        {featureOverview.map(({ id, icon: Icon, label, summary }) => (
          <a className="feature-overview-card" href={`#${id}`} key={id}>
            <div className="feature-overview-icon"><Icon size={18} /></div>
            <b>{label}</b>
            <p>{summary}</p>
          </a>
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
          <h2>Where you are<br /><em>in the day.</em></h2>
          <p className="section-note">
            Lumen reads the time of day and shows which block you are in. The Now / Next
            card tracks progress through it and names the next transition.
          </p>
          <FeatureBullets items={[
            'Now / Next card with progress through Evening, Night, and Morning',
            'Lumen noticed suggestions tied to sunset and presence',
            'Rhythm layer works with no smart hardware connected',
          ]} />
          <DemoLink tab="Home" />
        </FadeIn>
        <div className="feature-spotlight-panel">
          <div className="feature-mock-card">
            <p className="feature-mock-kicker">Now</p>
            <b>Evening</b>
            <div className="feature-mock-bar"><span style={{ width: '62%' }} /></div>
            <p className="feature-mock-next">Next · Night at 9:00 PM</p>
          </div>
        </div>
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
          <h2>Tap a scene,<br /><em>read it first.</em></h2>
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
          <DemoLink tab="Auto" label="Try scenes in the preview" />
        </FadeIn>
        <div className="feature-spotlight-panel">
          <div className="feature-mock-stack">
            <div className="feature-mock-row"><span>Power</span><b>On</b></div>
            <div className="feature-mock-row"><span>Brightness</span><b>40%</b></div>
            <div className="feature-mock-row"><span>Temperature</span><b>2700K</b></div>
            <div className="feature-mock-cta">Apply Evening</div>
          </div>
        </div>
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
          <h2>Every accessory<br /><em>in one list.</em></h2>
          <p className="section-note">
            The Intel tab shows your Apple Home accessories with reachability at a glance.
            Lumen only renders controls for the capabilities a device actually reports.
          </p>
          <FeatureBullets items={[
            'HomeKit and Matter accessories through Apple Home',
            'Lights, locks, thermostats, sensors, blinds, and plugs',
            'Capability-aware UI instead of generic toggle grids',
          ]} />
          <DemoLink tab="Intel" />
        </FadeIn>
        <div className="feature-spotlight-panel">
          <div className="feature-mock-list">
            <div className="feature-mock-list-row"><span>Ceiling Light</span><i className="online" /></div>
            <div className="feature-mock-list-row"><span>Desk Lamp</span><i className="online" /></div>
            <div className="feature-mock-list-row"><span>Thermostat</span><i className="online" /></div>
            <div className="feature-mock-list-row"><span>Front Door</span><i className="offline" /></div>
          </div>
        </div>
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
          <h2>Rehearse a room<br /><em>before the hardware.</em></h2>
          <p className="section-note">
            Favorite rooms on the home screen jump straight into room detail. Planned
            devices let you lay out the controls before any hardware arrives.
          </p>
          <FeatureBullets items={[
            'Room list with active device counts',
            'Brightness, color temperature, and power sliders',
            'Local preview mode enabled by default in beta',
          ]} />
          <DemoLink tab="Rooms" label="Open Living Room in the preview" />
        </FadeIn>
        <div className="feature-spotlight-panel">
          <div className="feature-mock-card warm">
            <p className="feature-mock-kicker">Living Room</p>
            <b>Ceiling Light</b>
            <div className="feature-mock-bar gold"><span style={{ width: '62%' }} /></div>
            <p className="feature-mock-next">2700K · Warm</p>
          </div>
        </div>
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
          <h2>Arrive home,<br /><em>know what ran.</em></h2>
          <p className="section-note">
            Lumen watches your home radius and can run matching scenes when you arrive or
            leave. You get a notification and a welcome overlay, never a silent surprise.
          </p>
          <FeatureBullets items={[
            'Geofence detection within your home radius',
            'Scenes tagged for arrival or departure',
            'Notifications when automation runs or needs attention',
            'Welcome Home and Away Mode overlays on the home screen',
          ]} />
          <DemoLink tab="Home" label="See the home screen in the preview" />
        </FadeIn>
        <div className="feature-spotlight-panel">
          <div className="feature-mock-card presence">
            <p className="feature-mock-kicker">Detected</p>
            <b>Welcome Home</b>
            <p className="feature-mock-next">Evening scene matched · On Arrival</p>
          </div>
        </div>
      </div>
    </section>
  );
}

export function PlatformsSection() {
  return (
    <section className="platforms-section" id="platforms">
      <FadeIn className="section-copy centered">
        <p className="eyebrow">platforms</p>
        <h2>iPhone and iPad today.</h2>
        <p className="section-note">
          Private beta on both. Mac is on the roadmap once the core loop is solid.
        </p>
      </FadeIn>
      <div className="platforms-row">
        <div className="platform-card">
          <Smartphone size={22} />
          <b>iPhone</b>
          <span>Native SwiftUI, consent-first flows</span>
        </div>
        <div className="platform-card">
          <Tablet size={22} />
          <b>iPad</b>
          <span>Sidebar navigation on the same build</span>
        </div>
      </div>
    </section>
  );
}
