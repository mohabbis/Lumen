import { motion } from 'framer-motion';
import {
  Activity, ArrowRight, Bell, Clock, MapPin, Moon, Radio, Shield,
  Smartphone, Sparkles, SunMedium, Tablet, Thermometer, Zap,
} from 'lucide-react';
import { usePhone } from './InteractivePhone.jsx';

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
    id: 'more',
    icon: Radio,
    label: 'And more',
    summary: 'IR remotes, local preview, iPad layout, AI on the way.',
  },
];

export function FeaturesOverviewSection() {
  return (
    <section className="features-overview-section" id="features">
      <FadeIn className="section-copy centered">
        <p className="eyebrow">What Lumen does</p>
        <h2>Everything your home needs.<br /><em>Nothing extra.</em></h2>
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
          <p className="eyebrow">Daily rhythm</p>
          <h2>Morning to night,<br /><em>without the noise.</em></h2>
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
          <p className="eyebrow">Scenes</p>
          <h2>Tap a scene.<br /><em>Read it first.</em></h2>
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
          <p className="eyebrow">Intel</p>
          <h2>Every device.<br /><em>One calm list.</em></h2>
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
          <p className="eyebrow">Rooms</p>
          <h2>Your rooms,<br /><em>ready to try.</em></h2>
          <p className="section-note">
            Favorite rooms on the dashboard jump straight into room detail.
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
          <p className="eyebrow">Presence</p>
          <h2>Arrive home.<br /><em>Know what ran.</em></h2>
          <p className="section-note">
            Lumen watches your home radius and can run matching scenes when you arrive or leave.
            You get a notification and a welcome overlay, not a silent surprise.
          </p>
          <FeatureBullets items={[
            'Geofence detection within your home radius',
            'Scenes tagged for arrival or departure',
            'Notifications when automation runs or needs attention',
            'Welcome Home and Away Mode overlays on the dashboard',
          ]} />
          <DemoLink tab="Home" label="See the dashboard in the phone" />
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

const moreCapabilities = [
  { icon: Radio, label: 'IR remotes', detail: 'HTTP bridge or native Broadlink send and learn' },
  { icon: Moon, label: 'Local preview', detail: 'Full UI with planned devices, no HomeKit required' },
  { icon: Bell, label: 'Notifications', detail: 'Plain alerts when automations run' },
  { icon: Clock, label: 'Execution history', detail: 'Scenes record what succeeded or failed' },
  { icon: Thermometer, label: 'Sensor aware', detail: 'Motion and contact streams feed reasoning' },
  { icon: Zap, label: 'AI layer', detail: 'Describe a scene in plain language, coming soon' },
];

export function MoreCapabilitiesSection() {
  return (
    <section className="more-capabilities-section surface-alt" id="more">
      <FadeIn className="section-copy centered">
        <p className="eyebrow">And more</p>
        <h2>Calm details<br /><em>that add up.</em></h2>
        <p className="section-note">
          Lumen is not trying to match every power feature on day one.
          These pieces are wired or on the way in the beta app today.
        </p>
      </FadeIn>
      <div className="more-capabilities-grid">
        {moreCapabilities.map(({ icon: Icon, label, detail }, i) => (
          <FadeIn key={label} delay={i * 0.04}>
            <div className="more-capability-card">
              <Icon size={16} />
              <b>{label}</b>
              <p>{detail}</p>
            </div>
          </FadeIn>
        ))}
      </div>
    </section>
  );
}

const platforms = [
  { icon: Smartphone, label: 'iPhone', detail: 'Native SwiftUI, consent-first flows' },
  { icon: Tablet, label: 'iPad', detail: 'Sidebar navigation on the same build' },
];

export function PlatformsSection() {
  return (
    <section className="platforms-section" id="platforms">
      <FadeIn className="section-copy centered">
        <p className="eyebrow">Platforms</p>
        <h2>Built for Apple.<br /><em>Calm everywhere.</em></h2>
        <p className="section-note">
          Private beta on iPhone and iPad today. Mac is on the roadmap after the core loop is solid.
        </p>
      </FadeIn>
      <div className="platforms-row">
        {platforms.map(({ icon: Icon, label, detail }, i) => (
          <FadeIn key={label} delay={i * 0.06}>
            <div className="platform-card">
              <Icon size={22} />
              <b>{label}</b>
              <span>{detail}</span>
            </div>
          </FadeIn>
        ))}
      </div>
    </section>
  );
}
