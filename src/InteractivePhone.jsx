import React, { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react';
import { AnimatePresence, motion, useReducedMotion } from 'framer-motion';
import {
  Activity, BedDouble, Blinds, ChevronRight, DoorOpen, Flame, Home, Laptop, Lightbulb, Lock,
  LogOut, Moon, MoonStar, Popcorn, Settings, SlidersHorizontal, Snowflake, Sofa, Sparkle, Sparkles,
  Sunrise, SunMedium, Thermometer, Utensils,
} from 'lucide-react';

// Shared demo data. This mirrors the native iOS app (Lumen/) as closely as a
// web mockup can — same tab set, seeded scenes, dark palette (#0E0819 / accent
// #C49A6C), consent-first flow (Awareness → Reasoning → Action → Execution),
// and the calm surfaces (rhythm card, sensory profile) that distinguish Lumen
// from a generic HomeKit controller.

export const phoneTabs = [
  { label: 'Home', icon: Home },
  { label: 'Rooms', icon: DoorOpen },
  { label: 'Intel', icon: Sparkle },
  { label: 'Auto', icon: Sparkles },
  { label: 'Settings', icon: Settings },
];

// Seeded scenes match SceneService.seedDefaultScenesIfNeeded (first three favorited).
export const scenes = [
  {
    name: 'Morning', icon: Sunrise, favorite: true, mood: 'Bright & cool',
    actions: [
      { capability: 'Power', detail: 'On' },
      { capability: 'Brightness', detail: '90%' },
      { capability: 'Color Temperature', detail: '5000K' },
    ],
  },
  {
    name: 'Evening', icon: MoonStar, favorite: true, mood: 'Warm & dim',
    actions: [
      { capability: 'Power', detail: 'On' },
      { capability: 'Brightness', detail: '40%' },
      { capability: 'Color Temperature', detail: '2700K' },
    ],
  },
  {
    name: 'Movie Night', icon: Popcorn, favorite: true, mood: 'Dim & ambient',
    actions: [
      { capability: 'Brightness', detail: '12%' },
      { capability: 'Color', detail: 'Custom color' },
      { capability: 'Lock', detail: 'Locked' },
    ],
  },
  {
    name: 'Sleep', icon: Moon, favorite: false, mood: 'All lights off',
    actions: [
      { capability: 'Power', detail: 'Off' },
      { capability: 'Lock', detail: 'Locked' },
      { capability: 'Mode', detail: 'Away' },
    ],
  },
  {
    name: 'Away', icon: LogOut, favorite: false, mood: 'Away mode',
    actions: [
      { capability: 'Power', detail: 'Off' },
      { capability: 'Lock', detail: 'Locked' },
      { capability: 'Mode', detail: 'Away' },
    ],
  },
];

// Rooms shown on the dashboard + Rooms tab. Each drills into a room detail
// that lists its devices, and each device drills into a capability-driven
// control screen (mirrors RoomDetailView → DeviceDetailView).
export const rooms = [
  { name: 'Living Room', type: 'Living Room', icon: Sofa, devices: ['ceiling', 'floorlamp', 'thermostat'] },
  { name: 'Bedroom', type: 'Bedroom', icon: BedDouble, devices: ['bedside', 'blind'] },
  { name: 'Kitchen', type: 'Kitchen', icon: Utensils, devices: ['undercab'] },
  { name: 'Office', type: 'Office', icon: Laptop, devices: [] },
];

const deviceCatalog = {
  ceiling: { name: 'Ceiling Light', room: 'Living Room', category: 'Lighting', icon: Lightbulb, kind: 'light', online: true },
  floorlamp: { name: 'Floor Lamp', room: 'Living Room', category: 'Lighting', icon: Lightbulb, kind: 'light', online: true },
  thermostat: { name: 'Thermostat', room: 'Living Room', category: 'Climate', icon: Thermometer, kind: 'climate', online: true },
  bedside: { name: 'Bedside Lamp', room: 'Bedroom', category: 'Lighting', icon: Lightbulb, kind: 'light', online: true },
  blind: { name: 'Blackout Blind', room: 'Bedroom', category: 'Other', icon: Blinds, kind: 'blind', online: true },
  undercab: { name: 'Under-cabinet Light', room: 'Kitchen', category: 'Lighting', icon: Lightbulb, kind: 'light', online: true },
  desklamp: { name: 'Desk Lamp', room: 'Office', category: 'Lighting', icon: Lightbulb, kind: 'light', online: true },
  frontdoor: { name: 'Front Door', room: 'Entryway', category: 'Security', icon: Lock, kind: 'lock', online: false },
  motion: { name: 'Living Room Motion', room: 'Living Room', category: 'Sensors', icon: Activity, kind: 'sensor', online: true },
};

// Global device list for the Intel tab, grouped by category (8 devices, 7 online),
// matching the discovery banner "HomeKit · 8 devices discovered · 7 online".
const intelCategories = [
  { category: 'Lighting', ids: ['ceiling', 'floorlamp', 'bedside', 'undercab', 'desklamp'] },
  { category: 'Climate', ids: ['thermostat'] },
  { category: 'Security', ids: ['frontdoor'] },
  { category: 'Sensors', ids: ['motion'] },
];

// Evening reasoning — mirrors ReasoningCalculator + SuggestionEngine output.
const reasoningHeadline = 'Sunset is moving across your home.';

const reasoningFactors = [
  { label: 'Fits the evening', detail: 'Warm, low light suits winding down.' },
  { label: 'Your usual routine', detail: 'You’ve run Evening 3× around this hour.' },
  { label: 'Devices are ready', detail: '7 reachable right now.' },
];

const reasoningSignals = [
  { label: 'Time of day', value: 'Evening', weight: 'high' },
  { label: 'Presence', value: 'At home', weight: 'high' },
  { label: 'Reachable devices', value: '7', weight: 'medium' },
  { label: 'Matching scene', value: 'Evening', weight: 'high' },
  { label: 'Usual routine', value: '3× around now', weight: 'medium' },
  { label: 'Confidence', value: '72%', weight: 'high' },
];

const TAB_AMBIENT = {
  Home: '212,130,90',
  Rooms: '111,219,168',
  Intel: '120,170,230',
  Auto: '138,180,248',
  Settings: '160,108,240',
};

const SHEET_AMBIENT = {
  reasoning: '160,108,240',
  action: '232,160,32',
  approval: '212,130,90',
};

export const PHONE_HINTS = {
  idle: 'Tap through the phone like the real app. Calm tabs, gentle suggestions, and consent before anything runs.',
  Home: 'Home shows rhythm, rooms, and one gentle suggestion. Tap “Lumen noticed” to begin.',
  Rooms: 'Open a room, then a device, to try the capability controls before hardware arrives.',
  Intel: 'Every Apple Home device in one calm list, grouped by type.',
  Auto: 'Tap a scene to preview its approval sheet before anything runs.',
  Settings: 'Sensory profile, bridges, and calm preferences live here in the beta.',
  room: 'Tap a device to open its controls.',
  device: 'Drag the sliders — brightness and warmth respond live.',
  reasoning: 'Reasoning shows the signals and the “why this scene”.',
  action: 'Action confirms exactly what Lumen will change.',
  approval: 'Manual scene runs use the same approval pattern.',
  applied: 'Evening is live. Lights updated only after your tap.',
};

const PhoneContext = createContext(null);

export function usePhone() {
  const ctx = useContext(PhoneContext);
  if (!ctx) throw new Error('usePhone requires PhoneProvider');
  return ctx;
}

const DEFAULT_LIGHT = { power: true, brightness: 62, temp: 40 };

export function PhoneProvider({ children, onAmbientChange, onFlowModeChange }) {
  const [tab, setTab] = useState('Home');
  const [sheet, setSheet] = useState(null);
  const [approvalScene, setApprovalScene] = useState(null);
  const [activeScene, setActiveScene] = useState(null);
  const [selectedRoom, setSelectedRoom] = useState(null);
  const [selectedDevice, setSelectedDevice] = useState(null);
  const [deviceStates, setDeviceStates] = useState({ ceiling: { ...DEFAULT_LIGHT } });
  const [toast, setToast] = useState(null);
  const [touched, setTouched] = useState(false);

  const eveningScene = scenes.find(s => s.name === 'Evening') ?? scenes[1];

  const flowMode = useMemo(() => {
    if (toast) return 3;
    if (sheet === 'action' || sheet === 'approval') return 2;
    if (sheet === 'reasoning') return 1;
    return 0;
  }, [sheet, toast]);

  const hint = useMemo(() => {
    if (toast) return PHONE_HINTS.applied;
    if (sheet) return PHONE_HINTS[sheet];
    if (selectedDevice) return PHONE_HINTS.device;
    if (selectedRoom) return PHONE_HINTS.room;
    return PHONE_HINTS[tab] ?? PHONE_HINTS.idle;
  }, [tab, sheet, toast, selectedRoom, selectedDevice]);

  const markTouched = useCallback(() => setTouched(true), []);

  const lightState = useCallback(id => deviceStates[id] ?? DEFAULT_LIGHT, [deviceStates]);

  const setLight = useCallback((id, patch) => {
    setDeviceStates(prev => ({ ...prev, [id]: { ...DEFAULT_LIGHT, ...prev[id], ...patch } }));
  }, []);

  const selectTab = useCallback(label => {
    markTouched();
    setTab(label);
    setSheet(null);
    setApprovalScene(null);
    setSelectedRoom(null);
    setSelectedDevice(null);
    setToast(null);
  }, [markTouched]);

  const openReasoning = useCallback(() => { markTouched(); setSheet('reasoning'); }, [markTouched]);
  const openAction = useCallback(() => { markTouched(); setSheet('action'); }, [markTouched]);

  const dismissSheet = useCallback(() => {
    markTouched();
    setSheet(null);
    setApprovalScene(null);
  }, [markTouched]);

  const applySuggestion = useCallback(() => {
    markTouched();
    setSheet(null);
    setActiveScene(eveningScene.name);
    setLight('ceiling', { power: true, brightness: 40, temp: 19 });
    setToast('Evening scene applied');
    setTimeout(() => setToast(null), 2800);
  }, [eveningScene.name, markTouched, setLight]);

  const openSceneApproval = useCallback(scene => {
    markTouched();
    setApprovalScene(scene);
    setSheet('approval');
  }, [markTouched]);

  const confirmScene = useCallback(() => {
    if (!approvalScene) return;
    markTouched();
    setActiveScene(approvalScene.name);
    setSheet(null);
    setApprovalScene(null);
    setToast(`${approvalScene.name} scene applied`);
    setTimeout(() => setToast(null), 2800);
  }, [approvalScene, markTouched]);

  const openRoom = useCallback(name => {
    markTouched();
    setSelectedRoom(name);
    setSelectedDevice(null);
  }, [markTouched]);

  const openDevice = useCallback(id => { markTouched(); setSelectedDevice(id); }, [markTouched]);

  const runGuidedStep = useCallback(stepId => {
    markTouched();
    setToast(null);
    setSelectedRoom(null);
    setSelectedDevice(null);
    switch (stepId) {
      case 'home':
        setTab('Home'); setSheet(null); setApprovalScene(null);
        break;
      case 'noticed':
      case 'reasoning':
        setTab('Home'); setSheet('reasoning'); setApprovalScene(null);
        break;
      case 'action':
        setTab('Home'); setSheet('action'); setApprovalScene(null);
        break;
      case 'scenes':
        setTab('Auto'); setApprovalScene(eveningScene); setSheet('approval');
        break;
      default:
        break;
    }
    document.getElementById('demo')?.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
  }, [eveningScene, markTouched]);

  useEffect(() => {
    const ambient = sheet ? SHEET_AMBIENT[sheet] : TAB_AMBIENT[tab];
    onAmbientChange?.(ambient);
  }, [tab, sheet, onAmbientChange]);

  useEffect(() => {
    onFlowModeChange?.(flowMode, touched);
  }, [flowMode, touched, onFlowModeChange]);

  const value = {
    tab, sheet, approvalScene, activeScene, selectedRoom, selectedDevice,
    toast, touched, flowMode, hint, eveningScene,
    lightState, setLight,
    selectTab, openReasoning, openAction, dismissSheet, applySuggestion,
    openSceneApproval, confirmScene, openRoom, openDevice, markTouched, runGuidedStep,
  };

  return <PhoneContext.Provider value={value}>{children}</PhoneContext.Provider>;
}

// ===== Chrome =====

function StatusBar() {
  return (
    <div className="phone-status">
      <span>9:41</span>
      <span className="dynamic-island" />
      <span>5G</span>
    </div>
  );
}

function TabBar({ active, onSelect }) {
  return (
    <div className="app-tabbar interactive-tabbar">
      {phoneTabs.map(({ label, icon: Icon }) => (
        <button
          type="button"
          key={label}
          className={active === label ? 'active' : ''}
          onClick={() => onSelect(label)}
          aria-label={`${label} tab`}
          aria-current={active === label ? 'page' : undefined}
        >
          <Icon size={15} strokeWidth={active === label ? 2.2 : 1.7} />
          {label}
        </button>
      ))}
    </div>
  );
}

// Large-title header used by the secondary screens (Rooms / Intel / Auto /
// Settings and the detail views), matching the app's eyebrow + big title.
function SimHeader({ eyebrow, title, back, onBack, action }) {
  return (
    <div className="sim-head">
      <div className="sim-head-text">
        {back ? (
          <button type="button" className="room-back" onClick={onBack}>{back}</button>
        ) : (
          <span className="sim-eyebrow">{eyebrow}</span>
        )}
        <h4 className="sim-title">{title}</h4>
      </div>
      {action ? <span className="sim-round" aria-hidden="true">{action}</span> : null}
    </div>
  );
}

function DragSlider({ value, onChange, children }) {
  const trackRef = React.useRef(null);
  const [dragging, setDragging] = useState(false);

  const updateFromEvent = e => {
    const rect = trackRef.current.getBoundingClientRect();
    const pct = Math.min(100, Math.max(0, ((e.clientX - rect.left) / rect.width) * 100));
    onChange(Math.round(pct));
  };

  return (
    <div
      ref={trackRef}
      className={dragging ? 'slider-track dragging' : 'slider-track'}
      onPointerDown={e => {
        e.currentTarget.setPointerCapture(e.pointerId);
        setDragging(true);
        updateFromEvent(e);
      }}
      onPointerMove={e => { if (dragging) updateFromEvent(e); }}
      onPointerUp={() => setDragging(false)}
      onPointerCancel={() => setDragging(false)}
    >
      <span style={{ width: `${value}%` }} />
      <i style={{ left: `${value}%` }} />
      {children}
    </div>
  );
}

// ===== Home (dashboard) =====

function RhythmCard() {
  return (
    <div className="nownext-card">
      <p className="app-label">Rhythm</p>
      <div className="nownext-now">
        <span className="nownext-tag now">Now</span>
        <div>
          <b>Evening</b>
          <span>Winding down softly.</span>
        </div>
      </div>
      <div className="nownext-bar"><span style={{ width: '62%' }} /></div>
      <div className="nownext-next">
        <span className="nownext-tag next">Next</span>
        <b>Night</b>
        <span>at 9:00 PM</span>
      </div>
    </div>
  );
}

function DashboardScreen() {
  const phone = usePhone();

  return (
    <div className={phone.sheet ? 'app-screen dimmed' : 'app-screen'}>
      <div className="app-topbar">
        <span className="app-wordmark">LUMEN</span>
        <span className="app-mode"><Home size={9} /> HOME MODE</span>
      </div>
      <h4 className="app-greeting serif">Welcome Home,</h4>
      <h4 className="app-greeting serif home-name">Home</h4>
      <p className="app-subtitle">7 of 8 devices online — all looking good.</p>

      <div className="app-cstats">
        <span><b>4</b> rooms</span>
        <i>·</i>
        <span><b>8</b> devices</span>
        <i>·</i>
        <span><b>5</b> automations</span>
        <span className="app-plus" aria-hidden="true">+</span>
      </div>

      <RhythmCard />

      <div className="app-section-head">
        <p className="app-label">Favorite Rooms</p>
      </div>
      <div className="fav-rooms-grid">
        {rooms.map(({ name, icon: Icon, devices }) => (
          <button type="button" className="fav-room-card interactive-card" key={name} onClick={() => { phone.selectTab('Rooms'); phone.openRoom(name); }}>
            <div className="fav-room-icon"><Icon size={15} /></div>
            <b>{name}</b>
            <span>{devices.length === 0 ? 'No devices' : `${devices.length} active`}</span>
          </button>
        ))}
      </div>

      <p className="app-label noticed-section-label">Lumen noticed</p>
      <button type="button" className="noticed-card interactive-card" onClick={phone.openReasoning}>
        <div className="noticed-head"><Sparkles size={11} /> Lumen noticed</div>
        <p className="noticed-msg">Sunset detected. Warm lighting may fit this moment.</p>
        <div className="noticed-action">
          <div>
            <b>Review Evening scene</b>
            <span>Confirm before anything changes</span>
          </div>
          <ChevronRight size={13} />
        </div>
      </button>
    </div>
  );
}

// ===== Consent sheets =====

function SheetMotion({ children, className }) {
  const reducedMotion = useReducedMotion();
  return (
    <motion.div
      className={className}
      initial={reducedMotion ? false : { y: '100%' }}
      animate={{ y: 0 }}
      exit={reducedMotion ? { opacity: 0 } : { y: '100%' }}
      transition={reducedMotion ? { duration: 0.15 } : { type: 'spring', stiffness: 320, damping: 34 }}
    >
      {children}
    </motion.div>
  );
}

function ReasoningSheet() {
  const phone = usePhone();
  return (
    <SheetMotion className="reason-sheet">
      <span className="sheet-handle" />
      <div className="sheet-icon"><Sparkles size={20} /></div>
      <p className="sheet-kicker">Why Lumen noticed</p>
      <h4 className="sheet-title">{reasoningHeadline}</h4>

      <p className="app-label sheet-signals-label">Why this scene</p>
      <div className="signal-list">
        {reasoningFactors.map(({ label, detail }) => (
          <div className="factor-row" key={label}>
            <span className="factor-dot" />
            <div>
              <b>{label}</b>
              <span>{detail}</span>
            </div>
          </div>
        ))}
      </div>

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

      <button type="button" className="sheet-apply" onClick={phone.openAction}>Apply Evening</button>
      <button type="button" className="sheet-dismiss" onClick={phone.dismissSheet}>Not now</button>
    </SheetMotion>
  );
}

function ActionConfirmationSheet({ scene }) {
  const phone = usePhone();
  return (
    <SheetMotion className="reason-sheet">
      <span className="sheet-handle" />
      <div className="sheet-icon"><scene.icon size={20} /></div>
      <p className="sheet-kicker">Apply suggested scene</p>
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
      <button type="button" className="sheet-apply" onClick={phone.applySuggestion}>Apply</button>
      <button type="button" className="sheet-dismiss" onClick={phone.dismissSheet}>Not now</button>
    </SheetMotion>
  );
}

function SceneApprovalSheet({ scene }) {
  const phone = usePhone();
  return (
    <SheetMotion className="reason-sheet">
      <span className="sheet-handle" />
      <div className="sheet-icon"><scene.icon size={20} /></div>
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
      <button type="button" className="sheet-apply" onClick={phone.confirmScene}>Apply</button>
      <button type="button" className="sheet-dismiss" onClick={phone.dismissSheet}>Cancel</button>
    </SheetMotion>
  );
}

// ===== Auto (Scenes) =====

function AutoScreen() {
  const phone = usePhone();
  const running = phone.activeScene;
  const runningScene = scenes.find(s => s.name === running);

  return (
    <div className={phone.sheet ? 'app-screen dimmed' : 'app-screen'}>
      <SimHeader eyebrow="LUMEN" title="Scenes" action="+" />
      {runningScene && (
        <div className="active-scene-card">
          <div className="active-scene-badge"><span className="active-pulse" /> ACTIVE NOW</div>
          <b>{running}</b>
          <span>{runningScene.actions.length} devices · {runningScene.mood}</span>
        </div>
      )}
      <p className="app-label">All Scenes</p>
      <div className="scene-list">
        {scenes.map(scene => {
          const { name, icon: Icon, actions, mood } = scene;
          return (
            <button type="button" className={`scene-row interactive-card ${running === name ? 'active' : ''}`} key={name} onClick={() => phone.openSceneApproval(scene)}>
              <div className="scene-icon"><Icon size={16} /></div>
              <div className="scene-meta"><b>{name}</b><span>{actions.length} devices · {mood}</span></div>
              <SlidersHorizontal size={11} className="scene-edit" />
              <ChevronRight size={13} />
            </button>
          );
        })}
      </div>
    </div>
  );
}

// ===== Rooms =====

function DeviceControlScreen({ deviceId }) {
  const phone = usePhone();
  const device = deviceCatalog[deviceId];
  const state = phone.lightState(deviceId);

  const warm = [212, 130, 90];
  const cool = [120, 170, 230];
  const t = state.temp / 100;
  const rgb = warm.map((w, i) => Math.round(w + (cool[i] - w) * t));
  const glowOpacity = device.kind === 'light' && state.power ? 0.14 + (state.brightness / 100) * 0.5 : 0.04;
  const kelvin = Math.round(1800 + (state.temp / 100) * 4700);

  return (
    <div className="app-screen device-screen">
      {device.kind === 'light' && (
        <div className="room-glow" style={{ background: `radial-gradient(ellipse at 50% 0%, rgba(${rgb.join(',')}, ${glowOpacity}) 0%, transparent 70%)` }} />
      )}
      <SimHeader
        back={device.room}
        title={device.name}
        onBack={() => phone.openDevice(null)}
      />

      <p className="app-label">Status</p>
      <div className="control-card">
        <div className="control-row"><span>Status</span><span className="stat-online"><span className={device.online ? 'online-dot' : 'offline-dot'} /> {device.online ? 'Online' : 'Offline'}</span></div>
        <div className="control-row"><span>Room</span><span>{device.room}</span></div>
        <div className="control-row"><span>Category</span><span>{device.category}</span></div>
      </div>

      {device.kind === 'light' && (
        <>
          <p className="app-label">Controls</p>
          <div className="control-card">
            <div className="control-row">
              <span>Power</span>
              <button type="button" className={state.power ? 'toggle on' : 'toggle'} onClick={() => phone.setLight(deviceId, { power: !state.power })} aria-label="Toggle power"><span /></button>
            </div>
            <div className="control-slider">
              <SunMedium size={11} className="dim" />
              <DragSlider value={state.brightness} onChange={v => { phone.markTouched(); phone.setLight(deviceId, { brightness: v }); }} />
              <SunMedium size={13} />
              <small>{state.brightness}%</small>
            </div>
            <div className="control-slider">
              <Flame size={10} className="warm" />
              <DragSlider value={state.temp} onChange={v => { phone.markTouched(); phone.setLight(deviceId, { temp: v }); }} />
              <Snowflake size={10} className="cool" />
              <small>{kelvin}K</small>
            </div>
          </div>
        </>
      )}

      {device.kind === 'climate' && (
        <>
          <p className="app-label">Temperature</p>
          <div className="control-card">
            <div className="control-row"><span>Current</span><span className="climate-temp">21.0 °C</span></div>
          </div>
        </>
      )}

      {device.kind === 'lock' && (
        <>
          <p className="app-label">Lock</p>
          <div className="control-card">
            <div className="control-row"><span><Lock size={10} /> Locked</span><span>Tap to unlock</span></div>
          </div>
        </>
      )}

      {device.kind === 'blind' && (
        <>
          <p className="app-label">Position</p>
          <div className="control-card">
            <div className="control-row"><span>Open</span><span>100%</span></div>
          </div>
        </>
      )}
    </div>
  );
}

function RoomDetailScreen({ roomName }) {
  const phone = usePhone();
  const room = rooms.find(r => r.name === roomName);

  if (phone.selectedDevice) {
    return <DeviceControlScreen deviceId={phone.selectedDevice} />;
  }

  return (
    <div className="app-screen">
      <SimHeader back="Rooms" title={room.name} onBack={() => phone.openRoom(null)} action="+" />
      {room.devices.length === 0 ? (
        <div className="room-empty">
          <p className="app-label">Plan this room</p>
          <p className="room-empty-msg">Add the devices you expect here first. They stay as preview controls until real hardware is linked.</p>
        </div>
      ) : (
        <>
          <p className="app-label">Active Devices</p>
          <div className="device-list">
            {room.devices.map(id => {
              const d = deviceCatalog[id];
              const Icon = d.icon;
              return (
                <button type="button" className="device-row interactive-card" key={id} onClick={() => phone.openDevice(id)}>
                  <div className="device-icon"><Icon size={13} /></div>
                  <div className="device-meta"><b>{d.name}</b><span>{d.category}</span></div>
                  <span className={d.online ? 'online-dot' : 'offline-dot'} />
                  <ChevronRight size={12} />
                </button>
              );
            })}
          </div>
        </>
      )}
    </div>
  );
}

function RoomsScreen() {
  const phone = usePhone();

  if (phone.selectedRoom) {
    return <RoomDetailScreen roomName={phone.selectedRoom} />;
  }

  return (
    <div className="app-screen">
      <SimHeader eyebrow="LUMEN" title="Rooms" action="+" />
      <p className="app-label">All Rooms</p>
      <div className="fav-rooms-grid">
        {rooms.map(({ name, icon: Icon, devices }) => (
          <button type="button" className="fav-room-card interactive-card" key={name} onClick={() => phone.openRoom(name)}>
            <div className="fav-room-icon"><Icon size={15} /></div>
            <b>{name}</b>
            <span>{devices.length === 0 ? 'No devices' : `${devices.length} active`}</span>
          </button>
        ))}
      </div>
    </div>
  );
}

// ===== Intel (Devices) =====

function IntelScreen() {
  return (
    <div className="app-screen">
      <SimHeader eyebrow="LUMEN" title="Intel" action="⟳" />
      <div className="intel-banner">
        <span className="online-dot" /> HomeKit · 8 devices discovered
        <span className="intel-online">7 online</span>
      </div>
      {intelCategories.map(({ category, ids }) => (
        <div className="intel-group" key={category}>
          <p className="app-label">{category}</p>
          <div className="device-list">
            {ids.map(id => {
              const d = deviceCatalog[id];
              const Icon = d.icon;
              return (
                <div className="device-row" key={id}>
                  <div className="device-icon"><Icon size={13} /></div>
                  <div className="device-meta"><b>{d.name}</b><span>{d.room}</span></div>
                  <span className={d.online ? 'online-dot' : 'offline-dot'} />
                </div>
              );
            })}
          </div>
        </div>
      ))}
    </div>
  );
}

// ===== Settings =====

const cadenceOptions = ['Quiet', 'Balanced', 'Supportive'];
const motionOptions = ['Reduced', 'Balanced'];
const contrastOptions = ['Soft', 'Balanced', 'Clear'];

function Segmented({ options, value, onChange }) {
  return (
    <div className="seg">
      {options.map(opt => (
        <button
          type="button"
          key={opt}
          className={value === opt ? 'seg-opt active' : 'seg-opt'}
          onClick={() => onChange(opt)}
        >
          {opt}
        </button>
      ))}
    </div>
  );
}

function SettingsScreen() {
  const phone = usePhone();
  const [calm, setCalm] = useState(false);
  const [cadence, setCadence] = useState('Balanced');
  const [motionPref, setMotionPref] = useState('Balanced');
  const [contrast, setContrast] = useState('Balanced');
  const [transitions, setTransitions] = useState(10);

  // Enabling Calm Mode applies the calm defaults (mirrors applyCalmModeDefaults).
  const toggleCalm = () => {
    phone.markTouched();
    setCalm(prev => {
      const next = !prev;
      if (next) {
        setCadence('Quiet');
        setMotionPref('Reduced');
        setContrast('Soft');
        setTransitions(t => Math.max(t, 15));
      }
      return next;
    });
  };

  return (
    <div className="app-screen settings-screen">
      <SimHeader eyebrow="LUMEN" title="Settings" />

      <p className="app-label">Home</p>
      <div className="settings-card">
        <div className="settings-row2"><span>Name</span><span>Home</span></div>
        <div className="settings-row2"><span>Rooms</span><span>4</span></div>
        <div className="settings-row2"><span>Devices</span><span>8</span></div>
        <div className="settings-row2"><span>Home location</span><span>Set</span></div>
      </div>

      <p className="app-label">Bridges</p>
      <div className="settings-card">
        <div className="settings-row2"><span>Homekit</span><span className="settings-on">Connected</span></div>
        <div className="settings-row2"><span>Local network</span><span className="settings-on">Connected</span></div>
      </div>

      <p className="app-label">Connections</p>
      <div className="settings-card">
        <div className="settings-row2"><span>IR Remotes</span><ChevronRight size={11} /></div>
        <div className="settings-row2"><span>Wi-Fi Devices</span><ChevronRight size={11} /></div>
      </div>

      <p className="app-label">Sensory Profile</p>
      <div className="settings-card">
        <div className="settings-row2"><span>Profile</span><span className="settings-on">{calm ? 'Calm Mode' : 'Balanced'}</span></div>
        <div className="settings-row2">
          <span>Calm Mode</span>
          <button type="button" className={calm ? 'toggle on' : 'toggle'} onClick={toggleCalm} aria-label="Toggle Calm Mode"><span /></button>
        </div>
        <div className="settings-stack"><span>Suggestions</span><Segmented options={cadenceOptions} value={cadence} onChange={v => { phone.markTouched(); setCadence(v); }} /></div>
        <div className="settings-stack"><span>Motion</span><Segmented options={motionOptions} value={motionPref} onChange={v => { phone.markTouched(); setMotionPref(v); }} /></div>
        <div className="settings-stack"><span>Contrast</span><Segmented options={contrastOptions} value={contrast} onChange={v => { phone.markTouched(); setContrast(v); }} /></div>
        <div className="settings-row2"><span>Transitions</span><span>{transitions === 0 ? 'Off' : `${transitions} min`}</span></div>
      </div>

      <p className="app-label">About</p>
      <div className="settings-card">
        <div className="settings-row2"><span>Version</span><span>1.0</span></div>
        <div className="settings-row2"><span>Build</span><span>1</span></div>
      </div>
    </div>
  );
}

// ===== Toast + stage =====

function PhoneToast({ message }) {
  if (!message) return null;
  return (
    <motion.div className="phone-toast" initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -6 }}>
      <Activity size={11} /> {message}
    </motion.div>
  );
}

function PhoneScreen() {
  const phone = usePhone();

  const body = (() => {
    switch (phone.tab) {
      case 'Home': return <DashboardScreen />;
      case 'Rooms': return <RoomsScreen />;
      case 'Intel': return <IntelScreen />;
      case 'Auto': return <AutoScreen />;
      case 'Settings': return <SettingsScreen />;
      default: return <DashboardScreen />;
    }
  })();

  return (
    <>
      {body}
      <AnimatePresence>
        {phone.sheet === 'reasoning' && <ReasoningSheet key="reasoning" />}
        {phone.sheet === 'action' && <ActionConfirmationSheet key="action" scene={phone.eveningScene} />}
        {phone.sheet === 'approval' && phone.approvalScene && (
          <SceneApprovalSheet key="approval" scene={phone.approvalScene} />
        )}
      </AnimatePresence>
      <AnimatePresence>
        {phone.toast && <PhoneToast key="toast" message={phone.toast} />}
      </AnimatePresence>
    </>
  );
}

export function InteractivePhone() {
  const phone = usePhone();

  return (
    <div className="live-demo interactive-demo">
      <div className="phone phone-featured phone-app">
        <div className="phone-screen">
          <StatusBar />
          <div className="app-stage">
            <PhoneScreen />
          </div>
          <TabBar active={phone.tab} onSelect={phone.selectTab} />
        </div>
      </div>
      <p className="demo-caption live-hint">{phone.hint}</p>
    </div>
  );
}
