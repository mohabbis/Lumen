import React, { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react';
import { AnimatePresence, motion, useReducedMotion } from 'framer-motion';
import {
  Activity, BedDouble, ChevronRight, Home, Laptop, Lightbulb, Lock, Settings, Sofa, Sparkle, Sparkles, SunMedium, Thermometer, Utensils,
} from 'lucide-react';
import {
  Moon, MoonStar, Popcorn, Sunrise,
} from 'lucide-react';

// Shared demo data (mirrors the iOS app seed content)

export const phoneTabs = [
  { label: 'Home', icon: Home },
  { label: 'Rooms', icon: Sofa },
  { label: 'Intel', icon: Sparkle },
  { label: 'Auto', icon: Sparkles },
  { label: 'Settings', icon: Settings },
];

export const favoriteRooms = [
  { name: 'Living Room', icon: Sofa, count: '3 active' },
  { name: 'Bedroom', icon: BedDouble, count: '2 active' },
  { name: 'Kitchen', icon: Utensils, count: '1 active' },
  { name: 'Office', icon: Laptop, count: 'No devices' },
];

export const scenes = [
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
  Home: 'Home shows rhythm, rooms, and gentle suggestions. Tap Lumen noticed to begin.',
  Rooms: 'Open Living Room to try planned-device controls before hardware arrives.',
  Intel: 'Every Apple Home device in one calm list.',
  Auto: 'Tap a scene to preview the approval sheet before anything runs.',
  Settings: 'Remotes, homes, and calm preferences live here in the beta.',
  reasoning: 'Reasoning shows the signals behind a suggestion.',
  action: 'Action confirms exactly what Lumen will change.',
  approval: 'Manual scene runs use the same approval pattern.',
  applied: 'Evening is live. Lights and locks updated after your tap.',
};

const PhoneContext = createContext(null);

export function usePhone() {
  const ctx = useContext(PhoneContext);
  if (!ctx) throw new Error('usePhone requires PhoneProvider');
  return ctx;
}

export function PhoneProvider({ children, onAmbientChange, onFlowModeChange }) {
  const [tab, setTab] = useState('Home');
  const [sheet, setSheet] = useState(null);
  const [approvalScene, setApprovalScene] = useState(null);
  const [activeScene, setActiveScene] = useState(null);
  const [selectedRoom, setSelectedRoom] = useState(null);
  const [lightOn, setLightOn] = useState(true);
  const [brightness, setBrightness] = useState(62);
  const [colorTemp, setColorTemp] = useState(40);
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
    return PHONE_HINTS[tab] ?? PHONE_HINTS.idle;
  }, [tab, sheet, toast]);

  const markTouched = useCallback(() => setTouched(true), []);

  const selectTab = useCallback(label => {
    markTouched();
    setTab(label);
    setSheet(null);
    setApprovalScene(null);
    setSelectedRoom(null);
    setToast(null);
  }, [markTouched]);

  const openReasoning = useCallback(() => {
    markTouched();
    setSheet('reasoning');
  }, [markTouched]);

  const openAction = useCallback(() => {
    markTouched();
    setSheet('action');
  }, [markTouched]);

  const dismissSheet = useCallback(() => {
    markTouched();
    setSheet(null);
    setApprovalScene(null);
  }, [markTouched]);

  const applySuggestion = useCallback(() => {
    markTouched();
    setSheet(null);
    setActiveScene(eveningScene.name);
    setLightOn(true);
    setBrightness(40);
    setColorTemp(25);
    setToast('Evening scene applied');
    setTimeout(() => setToast(null), 2800);
  }, [eveningScene.name, markTouched]);

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
  }, [markTouched]);

  const runGuidedStep = useCallback(stepId => {
    markTouched();
    setToast(null);
    switch (stepId) {
      case 'home':
        setTab('Home');
        setSheet(null);
        setApprovalScene(null);
        setSelectedRoom(null);
        break;
      case 'noticed':
        setTab('Home');
        setSheet('reasoning');
        setApprovalScene(null);
        break;
      case 'reasoning':
        setTab('Home');
        setSheet('reasoning');
        setApprovalScene(null);
        break;
      case 'action':
        setTab('Home');
        setSheet('action');
        setApprovalScene(null);
        break;
      case 'scenes':
        setTab('Auto');
        setApprovalScene(eveningScene);
        setSheet('approval');
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
    tab,
    sheet,
    approvalScene,
    activeScene,
    selectedRoom,
    lightOn,
    brightness,
    colorTemp,
    toast,
    touched,
    flowMode,
    hint,
    eveningScene,
    selectTab,
    openReasoning,
    openAction,
    dismissSheet,
    applySuggestion,
    openSceneApproval,
    confirmScene,
    openRoom,
    setLightOn,
    setBrightness,
    setColorTemp,
    markTouched,
    runGuidedStep,
  };

  return <PhoneContext.Provider value={value}>{children}</PhoneContext.Provider>;
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

function DashboardScreen() {
  const phone = usePhone();

  return (
    <div className={phone.sheet ? 'app-screen dimmed' : 'app-screen'}>
      <div className="app-topbar">
        <span className="app-wordmark">LUMEN</span>
        <span className="app-mode"><Home size={9} /> HOME MODE</span>
      </div>
      <h4 className="app-greeting serif">Good evening,</h4>
      <h4 className="app-greeting serif home-name">Home</h4>
      <p className="app-subtitle">7 of 8 devices online. All looking good.</p>

      <p className="app-label noticed-section-label">Lumen noticed</p>
      <button type="button" className="noticed-card interactive-card" onClick={phone.openReasoning}>
        <div className="noticed-head"><Sparkles size={11} /> Lumen noticed</div>
        <p className="noticed-msg">Sunset detected. Warm lighting mode is available.</p>
        <div className="noticed-action">
          <div>
            <b>Run Evening scene</b>
            <span>Suggested by Lumen</span>
          </div>
          <ChevronRight size={13} />
        </div>
      </button>

      <div className="app-section-head">
        <p className="app-label">Favorite Rooms</p>
      </div>
      <div className="fav-rooms-grid">
        {favoriteRooms.map(({ name, icon: Icon, count }) => (
          <button type="button" className="fav-room-card interactive-card" key={name} onClick={() => { phone.selectTab('Rooms'); phone.openRoom(name); }}>
            <div className="fav-room-icon"><Icon size={15} /></div>
            <b>{name}</b>
            <span>{count}</span>
          </button>
        ))}
      </div>
    </div>
  );
}

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
      <div className="sheet-icon"><scene.icon size={22} /></div>
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
      <button type="button" className="sheet-apply" onClick={phone.confirmScene}>Apply {scene.name}</button>
      <button type="button" className="sheet-dismiss" onClick={phone.dismissSheet}>Cancel</button>
    </SheetMotion>
  );
}

function AutoScreen() {
  const phone = usePhone();
  const running = phone.activeScene;

  return (
    <div className={phone.sheet ? 'app-screen dimmed' : 'app-screen'}>
      <div className="app-topbar"><span className="app-wordmark">LUMEN</span></div>
      <h4 className="app-greeting small">Scenes</h4>
      {running && (
        <div className="active-scene-card">
          <div className="active-scene-badge"><span className="active-pulse" /> ACTIVE NOW</div>
          <b>{running}</b>
          <span>{scenes.find(s => s.name === running)?.devices ?? ''} · {scenes.find(s => s.name === running)?.mood ?? ''}</span>
        </div>
      )}
      <p className="app-label">All Scenes</p>
      <div className="scene-list">
        {scenes.map(scene => {
          const { name, icon: Icon, devices: d, mood } = scene;
          return (
            <button type="button" className={`scene-row interactive-card ${running === name ? 'active' : ''}`} key={name} onClick={() => phone.openSceneApproval(scene)}>
              <div className="scene-icon"><Icon size={16} /></div>
              <div className="scene-meta"><b>{name}</b><span>{d} · {mood}</span></div>
              <ChevronRight size={13} />
            </button>
          );
        })}
      </div>
    </div>
  );
}

function RoomsScreen() {
  const phone = usePhone();

  if (phone.selectedRoom === 'Living Room') {
    const warm = [212, 130, 90];
    const cool = [120, 170, 230];
    const t = phone.colorTemp / 100;
    const rgb = warm.map((w, i) => Math.round(w + (cool[i] - w) * t));
    const glowOpacity = phone.lightOn ? 0.15 + (phone.brightness / 100) * 0.55 : 0.04;

    return (
      <div className="app-screen">
        <div className="room-glow" style={{ background: `radial-gradient(ellipse at 50% 0%, rgba(${rgb.join(',')}, ${glowOpacity}) 0%, transparent 70%)` }} />
        <div className="app-topbar">
          <button type="button" className="room-back" onClick={() => phone.openRoom(null)}>Rooms</button>
          <span className="try-it-pill">Try it</span>
        </div>
        <h4 className="app-greeting small">Living Room</h4>
        <p className="app-label">Ceiling Light</p>
        <div className="control-card">
          <div className="control-row">
            <span>Power</span>
            <button type="button" className={phone.lightOn ? 'toggle on' : 'toggle'} onClick={() => phone.setLightOn(!phone.lightOn)} aria-label="Toggle power"><span /></button>
          </div>
          <div className="control-slider">
            <SunMedium size={11} className="dim" />
            <DragSlider value={phone.brightness} onChange={v => { phone.markTouched(); phone.setBrightness(v); }} />
            <SunMedium size={13} />
            <small>{phone.brightness}%</small>
          </div>
          <div className="control-slider">
            <span className="warm">Warm</span>
            <DragSlider value={phone.colorTemp} onChange={v => { phone.markTouched(); phone.setColorTemp(v); }} />
            <span className="cool">Cool</span>
            <small>{Math.round(1800 + (phone.colorTemp / 100) * 4700)}K</small>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="app-screen">
      <div className="app-topbar"><span className="app-wordmark">LUMEN</span></div>
      <h4 className="app-greeting small">Rooms</h4>
      <p className="app-label">All Rooms</p>
      <div className="fav-rooms-grid">
        {favoriteRooms.map(({ name, icon: Icon, count }) => (
          <button type="button" className="fav-room-card interactive-card" key={name} onClick={() => phone.openRoom(name)}>
            <div className="fav-room-icon"><Icon size={15} /></div>
            <b>{name}</b>
            <span>{count}</span>
          </button>
        ))}
      </div>
    </div>
  );
}

function IntelScreen() {
  return (
    <div className="app-screen">
      <div className="app-topbar"><span className="app-wordmark">LUMEN</span></div>
      <h4 className="app-greeting small">Intel</h4>
      <div className="intel-banner"><span className="online-dot" /> Apple Home · 8 devices · 7 online</div>
      <div className="device-list">
        {devices.map(({ name, room, icon: Icon, online }) => (
          <div className="device-row" key={name}>
            <div className="device-icon"><Icon size={15} /></div>
            <div className="device-meta"><b>{name}</b><span>{room}</span></div>
            <span className={online ? 'online-dot' : 'offline-dot'} />
          </div>
        ))}
      </div>
    </div>
  );
}

function SettingsScreen() {
  return (
    <div className="app-screen">
      <div className="app-topbar"><span className="app-wordmark">LUMEN</span></div>
      <h4 className="app-greeting small">Settings</h4>
      <div className="settings-list">
        <div className="settings-row"><span>Home</span><ChevronRight size={12} /></div>
        <div className="settings-row"><span>Remotes</span><ChevronRight size={12} /></div>
        <div className="settings-row"><span>Location &amp; arrival</span><ChevronRight size={12} /></div>
        <div className="settings-row"><span>Local preview devices</span><span className="settings-on">On</span></div>
      </div>
    </div>
  );
}

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
