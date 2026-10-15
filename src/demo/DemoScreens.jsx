import { BedDouble, ChevronLeft, ChevronRight, DoorOpen, Lightbulb, Moon, Monitor, ShieldCheck, Sofa, Sparkles, Sun, Thermometer, Utensils, WifiOff } from 'lucide-react';
import { useDemo } from './DemoContext.jsx';
import { activeLights, deviceSummary, devicesInRoom, reachableCount, rooms, scenes } from './demoModel.js';

const icons = { sofa: Sofa, bed: BedDouble, kitchen: Utensils, office: Monitor, moon: Moon, sun: Sun };
export function ProductIcon({ name, ...props }) { const Icon = icons[name] || Sparkles; return <Icon {...props} />; }

export function RoomCards({ limit = rooms.length }) {
  const { state, dispatch } = useDemo();
  return <div className="room-grid">{rooms.slice(0, limit).map(room => {
    const devices = devicesInRoom(state, room.id);
    const count = activeLights(devices);
    return <button className="room-card" key={room.id} aria-label={`${room.name} ${devices.length ? `${count} ${count === 1 ? 'light' : 'lights'} on` : 'No devices'}`} onClick={() => dispatch({ type: 'ROOM', id: room.id })}>
      <ProductIcon name={room.icon} size={23} /><span>{room.name}</span><small>{devices.length ? `${count} ${count === 1 ? 'light' : 'lights'} on` : 'No devices'}</small>
    </button>;
  })}</div>;
}

export function DeviceList({ devices }) {
  const { dispatch } = useDemo();
  return <div className="device-list">{devices.map(device => <button key={device.id} className={`device-row ${!device.online ? 'device-unavailable' : ''}`} onClick={() => dispatch({ type: 'DEVICE', id: device.id })}>
    <span className={`device-icon ${device.power && device.online ? 'is-on' : ''}`}>{!device.online ? <WifiOff size={20} /> : device.type === 'climate' ? <Thermometer size={20} /> : <Lightbulb size={20} />}</span>
    <span className="device-row-label"><strong>{device.name}</strong><small>{deviceSummary(device)}</small></span><ChevronRight size={16} />
  </button>)}</div>;
}

function Rhythm() {
  return <div className="rhythm-card"><div className="rhythm-top"><span><Sun size={17} /> Your daily rhythm</span><small>6:24 PM</small></div><div className="rhythm-now"><strong>Evening</strong><span>Winding down softly.</span></div><div className="rhythm-track" role="progressbar" aria-label="Progress through evening" aria-valuenow={35} aria-valuemin={0} aria-valuemax={100}><span /></div><div className="rhythm-next"><span>Next</span><span>Night at 9:00 PM</span><Moon size={14} /></div></div>;
}

export function HomeScreen() {
  const { state, dispatch } = useDemo();
  return <><div className="app-topline"><span>Lumen</span><span className="home-mode"><span /> At home</span></div><div className="screen-heading"><p>Thursday, October 15</p><h2>Good evening,<br />Maple Street.</h2><span>{reachableCount(state)} of {Object.keys(state.devices).length} devices reachable</span></div><Rhythm /><div className="app-section-title"><h3>Favorite rooms</h3><button aria-label="View all rooms" onClick={() => dispatch({ type: 'NAVIGATE', tab: 'Rooms' })}><ChevronRight size={18} /></button></div><RoomCards limit={2} />
    {state.suggestion === 'available' ? <button className="noticed-card" onClick={() => dispatch({ type: 'SUGGESTION' })}><span className="noticed-title"><Sparkles size={17} /> Lumen noticed</span><strong>A softer evening?</strong><span>You’re home. Warm, lower lighting might feel right.</span><span className="noticed-link">Review Evening <ChevronRight size={16} /></span></button> : <div className="quiet-card"><Moon size={19} /><div><strong>{state.suggestion === 'applied' ? 'A little softer now.' : 'Your home, your pace.'}</strong><p>{state.suggestion === 'applied' ? 'Evening is applied. Settle in.' : 'The suggestion is dismissed. Nothing changed.'}</p></div></div>}
  </>;
}

export function RoomsScreen() {
  const { state, dispatch } = useDemo();
  const room = rooms.find(item => item.id === state.roomId);
  if (!room) return <><div className="screen-heading"><p>Your home</p><h2>Room to feel<br />at home.</h2><span>Four spaces. One clear view.</span></div><RoomCards /></>;
  const devices = devicesInRoom(state, room.id);
  return <><button className="app-back" onClick={() => dispatch({ type: 'BACK' })}><ChevronLeft size={17} /> Rooms</button><div className="room-detail-art"><ProductIcon name={room.icon} size={60} strokeWidth={1} /><span /></div><div className="screen-heading"><h2>{room.name}</h2><span>{room.subtitle}</span></div>{devices.length ? <><div className="app-section-title"><h3>{activeLights(devices)} lights on</h3><span>{devices.length} devices</span></div><DeviceList devices={devices} /></> : <div className="empty-state"><DoorOpen size={30} /><h3>A little possibility.</h3><p>No devices in this sample room. In Lumen, you can plan a room before adding hardware.</p></div>}</>;
}

export function IntelScreen() {
  const { state } = useDemo();
  return <><div className="screen-heading"><p>Intel</p><h2>Everything,<br />accounted for.</h2><span>{reachableCount(state)} reachable · 1 unavailable</span></div><p className="app-explainer">Sample devices, with the controls each one supports.</p><DeviceList devices={Object.values(state.devices)} /></>;
}

export function ScenesScreen() {
  const { state, dispatch } = useDemo();
  return <><div className="screen-heading"><p>Auto</p><h2>A rhythm<br />of your own.</h2><span>Review a scene before it changes anything.</span></div><div className="scene-list">{scenes.map(scene => <button className="scene-card" key={scene.id} onClick={() => dispatch({ type: 'SCENE', id: scene.id })}><ProductIcon name={scene.icon} size={25} /><span><strong>{scene.name}</strong><small>{scene.subtitle}</small><small>{scene.actions.length} devices{state.lastScene === scene.id ? ' · Last applied' : ''}</small></span><ChevronRight size={17} /></button>)}</div><div className="quiet-card"><ShieldCheck size={20} /><p>This preview runs scenes only when you approve. In the app, arrival and departure scenes can also run automatically when explicitly configured.</p></div>{state.history.length > 0 && <div className="execution-history"><h3>Recent activity</h3>{state.history.map((item, index) => <p key={`${item.sceneId}-${index}`}>{item.message}</p>)}</div>}</>;
}

export function SettingsScreen() {
  const { state, dispatch } = useDemo();
  return <><div className="screen-heading"><p>Settings</p><h2>Make yourself<br />comfortable.</h2><span>This preview stays in your browser.</span></div><div className="settings-card"><div><ShieldCheck size={22} /><strong>Simulated home</strong></div><p>These controls change sample data. Nothing connects to your devices, Apple Home, or location.</p></div><div className="settings-row"><span><strong>Reduced stimulation</strong><small>Quieter visual feedback in the preview</small></span><button className="switch" role="switch" aria-label="Reduced stimulation" aria-checked={state.reducedStimulation} onClick={() => dispatch({ type: 'STIMULATION' })}><span /></button></div><button className="app-secondary" onClick={() => dispatch({ type: 'RESET' })}>Reset the demo</button><p className="app-explainer">The native app also includes sensory, permission, and home settings. This preview focuses on the core experience.</p></>;
}
