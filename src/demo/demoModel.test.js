import { describe, expect, it } from 'vitest';
import { activeLights, createInitialState, demoReducer, devicesInRoom } from './demoModel.js';
const reduce = (state, ...actions) => actions.reduce(demoReducer, state);
describe('authoritative demo state', () => {
  it('starts deterministically with consistent counts', () => {
    const state = createInitialState(); expect(state.tab).toBe('Home'); expect(state.sheet).toBeNull(); expect(activeLights(devicesInRoom(state, 'living'))).toBe(2);
    state.devices.ceiling.power = false; expect(createInitialState().devices.ceiling.power).toBe(true);
  });
  it('clamps draft values, preserves off-state brightness, and requires approval', () => {
    let state = reduce(createInitialState(), { type: 'DEVICE', id: 'ceiling' }, { type: 'DRAFT', field: 'brightness', value: 200 });
    expect(state.sheet.draft.brightness).toBe(100); expect(state.devices.ceiling.brightness).toBe(72);
    state = reduce(state, { type: 'DRAFT', field: 'power', value: false }, { type: 'DRAFT', field: 'brightness', value: 0 }, { type: 'APPLY_DEVICE' });
    expect(state.devices.ceiling.power).toBe(false); expect(state.devices.ceiling.brightness).toBe(100);
  });
  it('closes incompatible state on navigation and preserves device changes', () => {
    const state = reduce(createInitialState(), { type: 'SCENE', id: 'evening' }, { type: 'APPLY_SCENE' }, { type: 'DEVICE', id: 'ceiling' }, { type: 'NAVIGATE', tab: 'Rooms' });
    expect(state.sheet).toBeNull(); expect(state.devices.ceiling.brightness).toBe(40);
  });
  it('ignores repeated approval and reports partial failures', () => {
    const initial = createInitialState(); initial.devices.floor.online = false;
    const state = reduce(initial, { type: 'SCENE', id: 'evening' }, { type: 'APPLY_SCENE' }, { type: 'APPLY_SCENE' });
    expect(state.history).toHaveLength(1); expect(state.notice).toContain('2 devices updated; 1 unavailable'); expect(state.devices.floor.brightness).toBe(60); expect(state.devices.ceiling.brightness).toBe(40);
  });
  it('handles missing scene devices without pretending success', () => {
    const initial = createInitialState(); delete initial.devices.floor; expect(reduce(initial, { type: 'SCENE', id: 'evening' }, { type: 'APPLY_SCENE' }).notice).toContain('1 unavailable');
  });
  it('resets every domain while keeping the current presentation', () => {
    const state = reduce(createInitialState(), { type: 'EXPAND' }, { type: 'GUIDE_START' }, { type: 'APPLY_SCENE' }, { type: 'STIMULATION' }, { type: 'RESET' });
    expect(state.expanded).toBe(true); expect(state.guide).toBe('idle'); expect(state.suggestion).toBe('available'); expect(state.history).toEqual([]); expect(state.devices.ceiling.brightness).toBe(72); expect(state.reducedStimulation).toBe(false);
  });
  it('supports empty rooms and ignores unknown destinations', () => {
    const state = createInitialState(); expect(devicesInRoom(state, 'office')).toEqual([]); expect(demoReducer(state, { type: 'DEVICE', id: 'missing' })).toBe(state); expect(demoReducer(state, { type: 'NAVIGATE', tab: 'Missing' })).toBe(state);
  });
});
