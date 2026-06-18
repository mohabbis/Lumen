import React, { useEffect, useRef, useState } from 'react';
import { AnimatePresence, motion } from 'framer-motion';
import {
  Activity, ArrowRight, BedDouble, Blinds, ChevronRight, DoorClosed, DoorOpen,
  Droplets, Home, Laptop, Lightbulb, Lock, MapPin, Menu, MessageCircle, Moon,
  MoonStar, Plus, Popcorn, Send, Settings, Sofa, Sparkle, Sparkles, SunMedium,
  Sunrise, Thermometer, Utensils, X, Zap,
} from 'lucide-react';
import './App.css';

// Data — faithful to the real Lumen app

const tabs = [
  { label: 'Home', icon: Home },
  { label: 'Rooms', icon: DoorOpen },
  { label: 'Intel', icon: Sparkle },
  { label: 'Scenes', icon: Sparkles },
  { label: 'Settings', icon: Settings },
];

const favoriteRooms = [
  { name: 'Living Room', icon: Sofa, count: '3 active' },
  { name: 'Bedroom', icon: BedDouble, count: '2 active' },
  { name: 'Kitchen', icon: Utensils, count: '1 active' },
  { name: 'Office', icon: Laptop, count: 'No devices' },
];

const scenes = [
  {
    name: 'Morning', icon: Sunrise, devices: '4 devices', mood: 'Bright & energising',
    actions: [
      { capability: 'Power', detail: 'On' },
      { capability: 'Brightness', detail: '90%' },
      { capability: 'Temperature', detail: '5000K' },
    ],
  },
  {
    name: 'Evening', icon: MoonStar, devices: '3 devices', mood: 'Warm & dim',
    actions: [
      { capability: 'Power', detail: 'On' },
      { capability: 'Brightness', detail: '40%' },
      { capability: 'Temperature', detail: '2700K' },
    ],
  },
  {
    name: 'Movie Night', icon: Popcorn, devices: '5 devices', mood: 'Dim & ambient',
    actions: [
      { capability: 'Brightness', detail: '12%' },
      { capability: 'Color', detail: 'Custom color' },
      { capability: 'Lock', detail: 'Locked' },
    ],
  },
  {
    name: 'Sleep', icon: Moon, devices: '6 devices', mood: 'All lights off',
    actions: [
      { capability: 'Power', detail: 'Off' },
      { capability: 'Lock', detail: 'Locked' },
      { capability: 'Mode', detail: 'Away' },
    ],
  },
];

const reasoningSignals = [
  { label: 'Time of day', value: 'Evening', weight: 'high' },
  { label: 'Presence', value: 'At home', weight: 'high' },
  { label: 'Reachable devices', value: '7', weight: 'medium' },
  { label: 'Matching scene', value: 'Evening', weight: 'high' },
];

const devices = [
  { name: 'Ceiling Light', room: 'Living Room', icon: Lightbulb, online: true },
  { name: 'Desk Lamp', room: 'Office', icon: Lightbulb, online: true },
  { name: 'Thermostat', room: 'Hallway', icon: Thermometer, online: true },
  { name: 'Front Door', room: 'Entryway', icon: Lock, online: false },
];

const aiCallouts = [
  { icon: Zap, label: 'Instant', sub: 'Commands sent live' },
  { icon: MessageCircle, label: 'Conversational', sub: 'Plain language control' },
  { icon: Sparkles, label: 'Suggests scenes', sub: 'Recommends, you approve' },
];

const otherCapabilities = [
  { label: 'Window blinds', icon: Blinds },
  { label: 'Door locks', icon: Lock },
  { label: 'Motion sensors', icon: Activity },
  { label: 'Door sensors', icon: DoorClosed },
  { label: 'Humidity', icon: Droplets },
];

const chapters = [
  'Try the lights',
  'Arrives home',
  'Lumen explains why',
  'One tap applies',
  'Scene is live',
];

const STEP_DURATIONS = [6000, 1900, 3300, 3500, 3000];
const IDLE_ADVANCE_MS = 2500;

// Rhythm card — mirrors the real app's TimeOfDay enum + RhythmTiming math
// (Lumen/Models/TimeOfDay.swift, Lumen/Components/NowNextCard.swift)

const RHYTHM_BLOCKS = [
  { name: 'Dawn', description: 'Your home is waking up.', accent: '#D4825A', startHour: 5, endHour: 7, greeting: 'Good morning' },
  { name: 'Morning', description: 'Settling into the day.', accent: '#C4956A', startHour: 7, endHour: 12, greeting: 'Good morning' },
  { name: 'Afternoon', description: 'Steady, bright, alert.', accent: '#B8A08A', startHour: 12, endHour: 17, greeting: 'Good afternoon' },
  { name: 'Evening', description: 'Winding down softly.', accent: '#D4825A', startHour: 17, endHour: 21, greeting: 'Good evening' },
  { name: 'Night', description: 'Quiet and resting.', accent: '#8B5E3C', startHour: 21, endHour: 5, greeting: 'Good night' },
];

function hexToRgb(hex) {
  const v = parseInt(hex.slice(1), 16);
  return [(v >> 16) & 255, (v >> 8) & 255, v & 255];
}

function getRhythmTiming(date) {
  const fractional = date.getHours() + date.getMinutes() / 60;
  const index = RHYTHM_BLOCKS.findIndex(({ startHour, endHour }) =>
    startHour < endHour
      ? fractional >= startHour && fractional < endHour
      : fractional >= startHour || fractional < endHour,
  );
  const block = RHYTHM_BLOCKS[index];
  const next = RHYTHM_BLOCKS[(index + 1) % RHYTHM_BLOCKS.length];

  const span = block.startHour > block.endHour
    ? (24 - block.startHour) + block.endHour
    : block.endHour - block.startHour;
  const into = fractional >= block.startHour
    ? fractional - block.startHour
    : (24 - block.startHour) + fractional;
  const progress = Math.min(1, Math.max(0, into / span));

  const nextStart = new Date(date);
  nextStart.setHours(next.startHour, 0, 0, 0);
  if (nextStart <= date) nextStart.setDate(nextStart.getDate() + 1);
  const nextStartFormatted = nextStart.toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' });

  return { block, next, progress, nextStartFormatted };
}

// Primitives

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

function StatusBar() {
  return (
    <div className="phone-status">
      <span>9:41</span>
      <span className="dynamic-island" />
      <span>5G</span>
    </div>
  );
}

function TabBar({ active }) {
  return (
    <div className="app-tabbar">
      {tabs.map(({ label, icon: Icon }) => (
        <span key={label} className={active === label ? 'active' : ''}>
          <Icon size={15} strokeWidth={active === label ? 2.2 : 1.7} />
          {label}
        </span>
      ))}
    </div>
  );
}

// Real-app screen recreations

function DashboardScreen({ showWelcome = false, highlight = false, dimmed = false }) {
  const [now, setNow] = useState(() => new Date());

  useEffect(() => {
    const id = setInterval(() => setNow(new Date()), 30000);
    return () => clearInterval(id);
  }, []);

  const { block, next, progress, nextStartFormatted } = getRhythmTiming(now);
  const [r, g, b] = hexToRgb(block.accent);

  return (
    <div className={dimmed ? 'app-screen dimmed' : 'app-screen'}>
      <div className="app-topbar">
        <span className="app-wordmark">LUMEN</span>
        <span className="app-mode">
          <Home size={9} /> HOME MODE
        </span>
      </div>

      <h4 className="app-greeting">{block.greeting}, Home</h4>
      <p className="app-subtitle">7 of 8 devices online — all looking good.</p>

      <div className="app-stats">
        <span><b>4</b> rooms · <b>8</b> devices · <b>5</b> automations</span>
        <span className="app-plus"><Plus size={11} /></span>
      </div>

      <div className="nownext-card">
        <p className="app-label">Rhythm</p>
        <div className="nownext-now">
          <span
            className="nownext-tag now"
            style={{ color: block.accent, background: `rgba(${r},${g},${b},0.16)`, borderColor: `rgba(${r},${g},${b},0.22)` }}
          >
            Now
          </span>
          <div>
            <b>{block.name}</b>
            <span>{block.description}</span>
          </div>
        </div>
        <div className="nownext-bar">
          <span style={{ width: `${Math.max(4, progress * 100)}%`, background: `linear-gradient(90deg, ${block.accent}, rgba(${r},${g},${b},0.45))` }} />
        </div>
        <div className="nownext-next">
          <span className="nownext-tag next">Next</span>
          <b>{next.name}</b>
          <span>at {nextStartFormatted}</span>
        </div>
      </div>

      <div className="app-section-head">
        <p className="app-label">Favorite Rooms</p>
        <ChevronRight size={12} />
      </div>
      <div className="fav-rooms-grid">
        {favoriteRooms.map(({ name, icon: Icon, count }) => (
          <div className="fav-room-card" key={name}>
            <div className="fav-room-icon"><Icon size={15} /></div>
            <b>{name}</b>
            <span>{count}</span>
          </div>
        ))}
      </div>

      <div className={highlight ? 'noticed-card highlight' : 'noticed-card'}>
        <div className="noticed-head">
          <Sparkles size={11} /> Lumen noticed
        </div>
        <p className="noticed-msg">Sunset detected. Warm lighting mode is available.</p>
        <div className="noticed-action">
          <div>
            <b>Run Evening scene</b>
            <span>Suggested by Lumen</span>
          </div>
          <ChevronRight size={13} />
        </div>
        {highlight && <span className="tap-ripple noticed-ripple" />}
      </div>

      {showWelcome && (
        <motion.div
          className="welcome-overlay"
          initial={{ opacity: 0, scale: 0.85 }}
          animate={{ opacity: 1, scale: 1 }}
          exit={{ opacity: 0 }}
          transition={{ type: 'spring', stiffness: 220, damping: 22 }}
        >
          🏠 Welcome Home!
          <span className="welcome-caption">
            <MapPin size={9} /> Detected automatically — no tap needed
          </span>
        </motion.div>
      )}
    </div>
  );
}

function ReasoningSheet() {
  return (
    <motion.div
      className="reason-sheet"
      initial={{ y: '100%' }}
      animate={{ y: 0 }}
      exit={{ y: '100%' }}
      transition={{ type: 'spring', stiffness: 320, damping: 34 }}
    >
      <span className="sheet-handle" />
      <div className="sheet-icon"><Sparkles size={22} /></div>
      <p className="sheet-kicker">Why Lumen noticed</p>
      <h4 className="sheet-title">Sunset is moving<br />across your home.</h4>

      <p className="app-label sheet-signals-label">Signals</p>
      <div className="signal-list">
        {reasoningSignals.map(({ label, value, weight }) => (
          <div className="signal-row" key={label}>
            <span className={`signal-dot ${weight}`} />
            <span className="signal-label">{label}</span>
            <span className="signal-value">{value}</span>
          </div>
        ))}
      </div>

      <button className="sheet-apply">
        Apply Evening
        <span className="tap-ripple apply-ripple" />
      </button>
      <button className="sheet-dismiss">Not now</button>
    </motion.div>
  );
}

function SceneApprovalSheet({ scene, onApply, onCancel }) {
  return (
    <motion.div
      className="reason-sheet"
      initial={{ y: '100%' }}
      animate={{ y: 0 }}
      exit={{ y: '100%' }}
      transition={{ type: 'spring', stiffness: 320, damping: 34 }}
    >
      <span className="sheet-handle" />
      <div className="sheet-icon"><scene.icon size={22} /></div>
      <p className="sheet-kicker">Apply scene</p>
      <h4 className="sheet-title">{scene.name}</h4>

      <p className="app-label sheet-signals-label">Lumen will</p>
      <div className="signal-list">
        {scene.actions.map(({ capability, detail }) => (
          <div className="approval-action-row" key={capability}>
            <span className="approval-action-capability">{capability}</span>
            <span className="approval-action-detail">{detail}</span>
          </div>
        ))}
      </div>

      <button className="sheet-apply" onClick={onApply}>
        Apply {scene.name}
        <span className="tap-ripple apply-ripple" />
      </button>
      <button className="sheet-dismiss" onClick={onCancel}>Cancel</button>
    </motion.div>
  );
}

function ScenesScreen({ onSelectScene }) {
  return (
    <div className="app-screen">
      <div className="app-topbar">
        <span className="app-wordmark">LUMEN</span>
      </div>
      <h4 className="app-greeting small">Scenes</h4>

      <div className="active-scene-card">
        <div className="active-scene-badge">
          <span className="active-pulse" /> ACTIVE NOW
        </div>
        <b>Evening</b>
        <span>3 devices · Warm &amp; dim</span>
      </div>

      <p className="app-label">All Scenes</p>
      <div className="scene-list">
        {scenes.map(scene => {
          const { name, icon: Icon, devices: d, mood } = scene;
          return (
            <div
              className={name === 'Evening' ? 'scene-row active' : 'scene-row'}
              key={name}
              onClick={() => onSelectScene(scene)}
            >
              <div className="scene-icon"><Icon size={16} /></div>
              <div className="scene-meta">
                <b>{name}</b>
                <span>{d} · {mood}</span>
              </div>
              <ChevronRight size={13} />
            </div>
          );
        })}
      </div>
    </div>
  );
}

function DragSlider({ value, onChange, onInteractStart, onInteractEnd, children }) {
  const trackRef = useRef(null);
  const [dragging, setDragging] = useState(false);

  const updateFromEvent = e => {
    const rect = trackRef.current.getBoundingClientRect();
    const pct = Math.min(100, Math.max(0, ((e.clientX - rect.left) / rect.width) * 100));
    onChange(Math.round(pct));
  };

  const handleDown = e => {
    e.currentTarget.setPointerCapture(e.pointerId);
    setDragging(true);
    onInteractStart();
    updateFromEvent(e);
  };
  const handleMove = e => { if (dragging) updateFromEvent(e); };
  const handleUp = () => { setDragging(false); onInteractEnd(); };

  return (
    <div
      ref={trackRef}
      className={dragging ? 'slider-track dragging' : 'slider-track'}
      onPointerDown={handleDown}
      onPointerMove={handleMove}
      onPointerUp={handleUp}
      onPointerCancel={handleUp}
    >
      <span style={{ width: `${value}%` }} />
      <i style={{ left: `${value}%` }} />
      {children}
    </div>
  );
}

function InteractiveRoomScreen({
  lightOn, onToggle, brightness, onBrightness, colorTemp, onColorTemp,
  onInteractStart, onInteractEnd,
}) {
  const warm = [212, 130, 90];
  const cool = [120, 170, 230];
  const t = colorTemp / 100;
  const rgb = warm.map((w, i) => Math.round(w + (cool[i] - w) * t));
  const glowOpacity = lightOn ? 0.15 + (brightness / 100) * 0.55 : 0.04;

  return (
    <div className="app-screen">
      <div
        className="room-glow"
        style={{
          background: `radial-gradient(ellipse at 50% 0%, rgba(${rgb.join(',')}, ${glowOpacity}) 0%, transparent 70%)`,
        }}
      />
      <div className="app-topbar">
        <span className="app-wordmark">LIVING ROOM</span>
        <span className="try-it-pill">Try it</span>
      </div>
      <h4 className="app-greeting small">Living Room</h4>
      <p className="app-label">Ceiling Light</p>

      <div className="control-card">
        <div className="control-row">
          <span>Power</span>
          <span
            className={lightOn ? 'toggle on' : 'toggle'}
            onClick={() => { onInteractStart(); onToggle(); onInteractEnd(); }}
          >
            <span />
          </span>
        </div>

        <div className="control-slider">
          <SunMedium size={11} className="dim" />
          <DragSlider
            value={brightness}
            onChange={onBrightness}
            onInteractStart={onInteractStart}
            onInteractEnd={onInteractEnd}
          />
          <SunMedium size={13} />
          <small>{brightness}%</small>
        </div>

        <div className="control-slider">
          <span className="warm">Warm</span>
          <DragSlider
            value={colorTemp}
            onChange={onColorTemp}
            onInteractStart={onInteractStart}
            onInteractEnd={onInteractEnd}
          />
          <span className="cool">Cool</span>
          <small>{Math.round(1800 + (colorTemp / 100) * 4700)}K</small>
        </div>
      </div>
    </div>
  );
}

// The live demo — auto-playing recreation of the real app

function LiveDemo() {
  const [step, setStep] = useState(0);
  const [paused, setPaused] = useState(false);
  const reducedRef = useRef(false);
  const lastInteractionRef = useRef(Date.now());
  const stepStartRef = useRef(Date.now());

  const [lightOn, setLightOn] = useState(true);
  const [brightness, setBrightness] = useState(62);
  const [colorTemp, setColorTemp] = useState(40);
  const [selectedScene, setSelectedScene] = useState(null);

  const markInteraction = () => { lastInteractionRef.current = Date.now(); };

  const closeApproval = () => {
    setSelectedScene(null);
    markInteraction();
  };

  useEffect(() => {
    reducedRef.current =
      typeof window !== 'undefined' &&
      window.matchMedia &&
      window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  }, []);

  useEffect(() => {
    stepStartRef.current = Date.now();
  }, [step]);

  useEffect(() => {
    if (paused || reducedRef.current || selectedScene) return undefined;

    if (step === 0) {
      const id = setInterval(() => {
        const idleEnough = Date.now() - lastInteractionRef.current >= IDLE_ADVANCE_MS;
        const dwelledEnough = Date.now() - stepStartRef.current >= STEP_DURATIONS[0];
        if (idleEnough && dwelledEnough) setStep(1);
      }, 250);
      return () => clearInterval(id);
    }

    const id = setTimeout(
      () => setStep(s => (s + 1) % STEP_DURATIONS.length),
      STEP_DURATIONS[step],
    );
    return () => clearTimeout(id);
  }, [step, paused, selectedScene]);

  const activeTab = step === 4 ? 'Scenes' : 'Home';

  return (
    <div className="live-demo">
      <div
        className="phone phone-featured phone-app"
        onMouseEnter={() => setPaused(true)}
        onMouseLeave={() => setPaused(false)}
      >
        <div className="phone-screen">
          <StatusBar />
          <div className="app-stage">
            {step === 0 ? (
              <InteractiveRoomScreen
                lightOn={lightOn}
                onToggle={() => setLightOn(o => !o)}
                brightness={brightness}
                onBrightness={setBrightness}
                colorTemp={colorTemp}
                onColorTemp={setColorTemp}
                onInteractStart={markInteraction}
                onInteractEnd={markInteraction}
              />
            ) : step <= 3 ? (
              <DashboardScreen
                showWelcome={step === 1}
                highlight={step === 2}
                dimmed={step === 3}
              />
            ) : (
              <ScenesScreen onSelectScene={setSelectedScene} />
            )}
            <AnimatePresence>
              {step === 3 && <ReasoningSheet key="sheet" />}
              {selectedScene && (
                <SceneApprovalSheet
                  key="approval"
                  scene={selectedScene}
                  onApply={closeApproval}
                  onCancel={closeApproval}
                />
              )}
            </AnimatePresence>
          </div>
          <TabBar active={activeTab} />
        </div>
      </div>

      <div className="demo-chapters">
        <span className="demo-live"><span className="demo-live-dot" />Auto-playing</span>
        <div className="chapter-strip">
          {chapters.map((label, i) => (
            <button
              key={label}
              className={step === i ? 'active' : ''}
              onClick={() => { setStep(i); setPaused(false); }}
            >
              <span className="chapter-num">0{i + 1}</span>
              {label}
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}

// App tour — real screens beyond the demo flow

function RoomsTourScreen() {
  return (
    <div className="phone mini-phone tour-phone">
      <div className="phone-screen">
        <StatusBar />
        <div className="app-screen">
          <div className="app-topbar"><span className="app-wordmark">LUMEN</span></div>
          <h4 className="app-greeting small">Rooms</h4>
          <p className="app-label">All Rooms</p>
          <div className="fav-rooms-grid">
            {favoriteRooms.map(({ name, icon: Icon, count }) => (
              <div className="fav-room-card" key={name}>
                <div className="fav-room-icon"><Icon size={15} /></div>
                <b>{name}</b>
                <span>{count}</span>
              </div>
            ))}
          </div>
        </div>
        <TabBar active="Rooms" />
      </div>
    </div>
  );
}

function IntelTourScreen() {
  return (
    <div className="phone mini-phone tour-phone">
      <div className="phone-screen">
        <StatusBar />
        <div className="app-screen">
          <div className="app-topbar"><span className="app-wordmark">LUMEN</span></div>
          <h4 className="app-greeting small">Intel</h4>
          <div className="intel-banner">
            <span className="online-dot" /> HomeKit · 8 devices · 7 online
          </div>
          <div className="device-list">
            {devices.map(({ name, room, icon: Icon, online }) => (
              <div className="device-row" key={name}>
                <div className="device-icon"><Icon size={15} /></div>
                <div className="device-meta">
                  <b>{name}</b>
                  <span>{room}</span>
                </div>
                <span className={online ? 'online-dot' : 'offline-dot'} />
              </div>
            ))}
          </div>
        </div>
        <TabBar active="Intel" />
      </div>
    </div>
  );
}

function RoomDetailTourScreen() {
  return (
    <div className="phone mini-phone tour-phone">
      <div className="phone-screen">
        <StatusBar />
        <div className="app-screen">
          <div className="app-topbar"><span className="app-wordmark">LIVING ROOM</span></div>
          <h4 className="app-greeting small">Living Room</h4>
          <p className="app-label">Ceiling Light</p>
          <div className="control-card">
            <div className="control-row">
              <span>Power</span>
              <span className="toggle on"><span /></span>
            </div>
            <div className="control-slider">
              <SunMedium size={11} className="dim" />
              <div className="slider-track"><span style={{ width: '62%' }} /><i style={{ left: '62%' }} /></div>
              <SunMedium size={13} />
              <small>62%</small>
            </div>
            <div className="control-slider">
              <span className="warm">Warm</span>
              <div className="slider-track"><span style={{ width: '40%' }} /><i style={{ left: '40%' }} /></div>
              <span className="cool">Cool</span>
              <small>3200K</small>
            </div>
          </div>
        </div>
        <TabBar active="Rooms" />
      </div>
    </div>
  );
}

function AppTourSection() {
  const tour = [
    { screen: <RoomsTourScreen />, label: 'Rooms' },
    { screen: <IntelTourScreen />, label: 'Devices' },
    { screen: <RoomDetailTourScreen />, label: 'Controls' },
  ];
  return (
    <section className="app-tour-section" id="product">
      <FadeIn className="section-copy centered">
        <p className="eyebrow">The whole app</p>
        <h2>More than<br />a dashboard.</h2>
      </FadeIn>
      <div className="tour-row">
        {tour.map(({ screen, label }, i) => (
          <FadeIn key={label} delay={i * 0.1} className="tour-item">
            {screen}
            <div className="tour-label">{label}</div>
          </FadeIn>
        ))}
      </div>
      <FadeIn className="capability-chips-wrap">
        <p className="eyebrow">Also speaks to</p>
        <div className="capability-chips">
          {otherCapabilities.map(({ label, icon: Icon }) => (
            <span className="capability-chip" key={label}>
              <Icon size={11} />
              {label}
            </span>
          ))}
        </div>
      </FadeIn>
    </section>
  );
}

function RoomShowcaseSection() {
  return (
    <section className="room-show-section" id="showcase">
      <FadeIn className="section-copy centered">
        <p className="eyebrow">Your home at a glance</p>
        <h2>Every room,<br /><em>one glance.</em></h2>
        <p className="section-note">Works the moment you open it — no smart hardware required.</p>
      </FadeIn>
      <div className="room-show-grid">
        {favoriteRooms.map(({ name, icon: Icon, count }, i) => (
          <FadeIn key={name} delay={i * 0.06}>
            <div className="room-show-card">
              <div className="room-show-icon"><Icon size={18} /></div>
              <b>{name}</b>
              <span>{count}</span>
            </div>
          </FadeIn>
        ))}
      </div>
    </section>
  );
}

function AIChatScreen() {
  return (
    <div className="phone phone-featured phone-app">
      <div className="phone-screen">
        <StatusBar />
        <div className="chat-header">
          <div className="chat-avatar"><MessageCircle size={14} /></div>
          <div>
            <b>Lumen</b>
            <small>AI assistant</small>
          </div>
          <span className="coming-pill">Soon</span>
        </div>
        <div className="chat-thread">
          <div className="chat-msg user">Make the bedroom cozy</div>
          <div className="chat-msg ai">
            Dimming to 30%, warming colour to 2700K.
            <div className="chat-chips">
              <button className="chat-chip apply">Apply</button>
              <button className="chat-chip">Edit</button>
            </div>
          </div>
          <div className="chat-msg user">Also turn off the hallway</div>
          <div className="chat-msg ai">
            Hallway off. Ready when you are.
            <div className="chat-chips">
              <button className="chat-chip apply">Apply</button>
            </div>
          </div>
        </div>
        <div className="chat-input-bar">
          <span className="chat-input-placeholder">Ask Lumen...</span>
          <button className="chat-send-btn"><Send size={12} /></button>
        </div>
        <TabBar active="Home" />
      </div>
    </div>
  );
}

function AIChatSection() {
  return (
    <section className="ai-chat-section" id="ai">
      <div className="ai-chat-inner">
        <FadeIn className="ai-chat-phone-wrap">
          <AIChatScreen />
        </FadeIn>
        <FadeIn delay={0.1} className="ai-chat-copy">
          <p className="eyebrow">Coming soon · Built-in AI</p>
          <h2>Just say it.<br /><em>Lumen handles it.</em></h2>
          <p className="ai-chat-lede">
            A conversational layer is on the way — describe what you want and
            Lumen recommends the scene, then sends it once you approve.
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

  async function handleSubmit(e) {
    e.preventDefault();
    const email = new FormData(e.currentTarget).get('email');
    setStatus('loading');
    try {
      const endpoint = import.meta.env.VITE_WAITLIST_ENDPOINT;
      const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
      const supabaseKey = import.meta.env.VITE_SUPABASE_ANON_KEY;
      if (endpoint) {
        await fetch(endpoint, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ email, source: 'lumen-site' }),
        });
      } else if (supabaseUrl && supabaseKey) {
        await fetch(`${supabaseUrl}/rest/v1/lumen_waitlist`, {
          method: 'POST',
          headers: {
            apikey: supabaseKey,
            Authorization: `Bearer ${supabaseKey}`,
            'Content-Type': 'application/json',
            Prefer: 'return=minimal',
          },
          body: JSON.stringify({ email, source: 'lumen-site', user_agent: navigator.userAgent }),
        });
      } else {
        window.location.href = `mailto:m.rafiq2006@icloud.com?subject=Lumen%20Early%20Access&body=${encodeURIComponent(`Please add me to the Lumen waitlist: ${email}`)}`;
      }
      setStatus('success');
      e.target.reset();
    } catch {
      setStatus('error');
    }
  }

  return (
    <section className="waitlist-section" id="access">
      <div className="waitlist-inner">
        <FadeIn className="waitlist-copy">
          <p className="eyebrow">Early access</p>
          <h2>Try the calmer<br />smart-home layer.</h2>
          <p>
            A private iPhone beta. No spam, no fake urgency.
          </p>
        </FadeIn>
        <FadeIn delay={0.1} className="waitlist-form-wrap">
          <form className="waitlist-form" onSubmit={handleSubmit}>
            <input
              name="email"
              type="email"
              placeholder="Your email address"
              required
            />
            <button disabled={status === 'loading'}>
              {status === 'loading' ? 'Joining...' : 'Request access'}
              <ArrowRight size={15} />
            </button>
          </form>
          <div className="waitlist-checks">
            <span>iOS first</span>
            <span>Private beta</span>
            <span>No spam</span>
          </div>
          {status === 'success' && (
            <p className="form-note">
              You're on the list. We'll reach out when Lumen is ready.
            </p>
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

// App shell

export function App() {
  const [menuOpen, setMenuOpen] = useState(false);
  const close = () => setMenuOpen(false);

  return (
    <main className="site-shell">
      <div className="grain" />

      <nav className="nav">
        <a className="logo" href="#top">
          <SunMedium size={22} />
          <span>LUMEN</span>
        </a>
        <div className="links">
          <a href="#product">The App</a>
          <a href="#ai">AI</a>
          <a href="/privacy">Privacy</a>
        </div>
        <div className="nav-actions">
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
            <a href="#product" onClick={close}><span>01</span>The App</a>
            <a href="#ai" onClick={close}><span>02</span>AI</a>
            <a href="/privacy" onClick={close} className="privacy-link"><span>03</span>Privacy</a>
            <a href="#access" onClick={close} className="mobile-cta">
              Request Access <ArrowRight size={14} />
            </a>
          </div>
        </div>
      )}

      <section className="hero" id="top">
        <div className="hero-bg" />

        <FadeIn className="hero-copy">
          <div className="pill">
            <span />
            Coming soon — iOS private beta
          </div>
          <h1>Your home,<br /><em>understood.</em></h1>
          <p>
            Watch it work — Lumen notices the moment, explains why,<br />
            and waits for your tap before anything changes.
          </p>
          <div className="hero-actions">
            <a className="primary" href="#access">
              Request Early Access <ArrowRight size={15} />
            </a>
            <a className="ghost" href="#product">See the whole app</a>
          </div>
        </FadeIn>

        <div className="hero-demo">
          <div className="hero-glow" />
          <LiveDemo />
        </div>
      </section>

      <AppTourSection />
      <RoomShowcaseSection />
      <AIChatSection />
      <Waitlist />

      <footer className="site-footer">
        <a className="logo" href="#top">
          <SunMedium size={17} /><span>LUMEN</span>
        </a>
        <p>Native iOS · On-device reasoning · AI assistant soon · Private beta</p>
        <div className="footer-links">
          <a href="/privacy">Privacy</a>
          <a
            href="https://github.com/mohabbis/lumen"
            target="_blank"
            rel="noopener noreferrer"
          >
            GitHub
          </a>
          <a href="mailto:m.rafiq2006@icloud.com">Contact</a>
        </div>
      </footer>
    </main>
  );
}
