import { Lightbulb, Moon, Thermometer, WifiOff } from 'lucide-react';
import { Dialog } from '../components/Dialog.jsx';
import { useDemo } from './DemoContext.jsx';
import { describeChanges, deviceSummary, reachableCount, scenes } from './demoModel.js';

export function DemoSheets() {
  const { state, dispatch } = useDemo();
  const close = () => dispatch({ type: 'CLOSE_SHEET' });
  const sheet = state.sheet;
  if (!sheet) return null;
  if (sheet.type === 'device') {
    const device = sheet.draft;
    const editable = device.online && device.type !== 'sensor';
    return <Dialog title={device.name} onClose={close} className="product-dialog"><div className="sheet-symbol">{!device.online ? <WifiOff /> : device.type === 'climate' ? <Thermometer /> : <Lightbulb />}</div><p className="sheet-intro">{!device.online ? 'This sample device is unavailable. Its last known state is shown below; no changes can be sent.' : 'Adjust, then apply when it feels right. Changes stay in this simulated home.'}</p>
      {!device.online ? <div className="change-row"><span>Last known state</span><strong>{device.contact || deviceSummary({ ...device, online: true })}</strong></div> : device.type === 'light' ? <>
        <div className="settings-row"><strong>Power</strong><button role="switch" className="switch" aria-label={`${device.name} power`} aria-checked={device.power} onClick={() => dispatch({ type: 'DRAFT', field: 'power', value: !device.power })}><span /></button></div>
        <Range label="Brightness" value={device.brightness} min={0} max={100} suffix="%" disabled={!device.power} field="brightness" />
        <Range label="Color temperature" value={device.warmth} min={2200} max={5000} step={100} suffix=" K" disabled={!device.power} field="warmth" />
        {!device.power && <p className="app-explainer">Turn power on to adjust the light. Its previous brightness is remembered.</p>}
      </> : device.type === 'climate' ? <Range label="Temperature" value={device.temperature} min={16} max={28} step={0.5} suffix="°C" field="temperature" /> : <p>{device.contact}</p>}
      <div className="sheet-actions">{editable && <button className="button button-primary" onClick={() => dispatch({ type: 'APPLY_DEVICE' })}>Apply changes</button>}<button className="button button-quiet" onClick={close}>{editable ? 'Cancel' : 'Close'}</button></div></Dialog>;
  }
  const scene = scenes.find(item => item.id === sheet.sceneId);
  const suggestion = sheet.type === 'suggestion';
  return <Dialog title={suggestion ? 'A softer evening?' : `Apply ${scene.name}?`} onClose={close} className="product-dialog"><div className="sheet-symbol"><Moon /></div>{state.guide === 'review' && <p className="guide-step">Step 1 of 2 · Review, then decide</p>}
    {suggestion && <><p className="sheet-intro">Lumen connects a few simple signals. You decide whether the suggestion fits.</p><dl className="signals"><div><dt>Time of day</dt><dd>Evening</dd></div><div><dt>Presence</dt><dd>At home</dd></div><div><dt>Reachable devices</dt><dd>{reachableCount(state)} of {Object.keys(state.devices).length}</dd></div></dl></>}
    <h3 className="sheet-subheading">{scene.name} will change</h3><div className="change-list">{scene.actions.map(operation => { const device = state.devices[operation.deviceId]; return <div className="change-row" key={operation.deviceId}><strong>{device?.name || 'Missing device'}</strong><span>{device?.online ? describeChanges(operation.changes) : 'Unavailable · will be skipped'}</span></div>; })}</div>
    <p className="simulation-note">Sample devices only. Your real home is never connected.</p><div className="sheet-actions"><button className="button button-primary" onClick={() => dispatch({ type: 'APPLY_SCENE' })}>Apply {scene.name}</button><button className="button button-quiet" onClick={() => dispatch({ type: suggestion ? 'DISMISS' : 'CLOSE_SHEET' })}>{suggestion ? 'Not now' : 'Cancel'}</button></div>
    {state.guide === 'review' && <button className="text-button guide-skip" onClick={() => dispatch({ type: 'GUIDE_SKIP' })}>Skip walkthrough</button>}
  </Dialog>;
}

function Range({ label, value, min, max, step = 1, suffix, disabled = false, field }) {
  const { dispatch } = useDemo();
  return <label className="range-control"><span>{label}<output>{value}{suffix}</output></span><input type="range" aria-label={label} aria-valuetext={`${value}${suffix}`} min={min} max={max} step={step} value={value} disabled={disabled} onChange={event => dispatch({ type: 'DRAFT', field, value: Number(event.target.value) })} /></label>;
}
