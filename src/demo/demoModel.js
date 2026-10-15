export const rooms = [
  {
    id: "living",
    name: "Living Room",
    subtitle: "A little room to unwind",
    icon: "sofa",
  },
  {
    id: "bedroom",
    name: "Bedroom",
    subtitle: "Rest comes naturally",
    icon: "bed",
  },
  {
    id: "kitchen",
    name: "Kitchen",
    subtitle: "The heart of the home",
    icon: "kitchen",
  },
  {
    id: "office",
    name: "Office",
    subtitle: "Ready when you are",
    icon: "office",
  },
];

const initialDevices = {
  ceiling: {
    id: "ceiling",
    name: "Ceiling Light",
    roomId: "living",
    type: "light",
    online: true,
    power: true,
    brightness: 72,
    warmth: 3500,
  },
  floor: {
    id: "floor",
    name: "Floor Lamp",
    roomId: "living",
    type: "light",
    online: true,
    power: true,
    brightness: 60,
    warmth: 3000,
  },
  bedside: {
    id: "bedside",
    name: "Bedside Lamp",
    roomId: "bedroom",
    type: "light",
    online: true,
    power: false,
    brightness: 35,
    warmth: 2700,
  },
  pendant: {
    id: "pendant",
    name: "Pendant Light",
    roomId: "kitchen",
    type: "light",
    online: true,
    power: true,
    brightness: 85,
    warmth: 4000,
  },
  thermostat: {
    id: "thermostat",
    name: "Thermostat",
    roomId: "living",
    type: "climate",
    online: true,
    temperature: 21,
  },
  sensor: {
    id: "sensor",
    name: "Window Sensor",
    roomId: "bedroom",
    type: "sensor",
    online: false,
    contact: "Closed",
  },
};

export const scenes = [
  {
    id: "evening",
    name: "Evening",
    subtitle: "Softer light. A slower pace.",
    icon: "moon",
    actions: [
      {
        deviceId: "ceiling",
        changes: { power: true, brightness: 40, warmth: 2700 },
      },
      {
        deviceId: "floor",
        changes: { power: true, brightness: 40, warmth: 2700 },
      },
      { deviceId: "pendant", changes: { power: false } },
    ],
  },
  {
    id: "morning",
    name: "Morning",
    subtitle: "A brighter beginning.",
    icon: "sun",
    actions: [
      {
        deviceId: "ceiling",
        changes: { power: true, brightness: 90, warmth: 4000 },
      },
      {
        deviceId: "pendant",
        changes: { power: true, brightness: 90, warmth: 4000 },
      },
      {
        deviceId: "bedside",
        changes: { power: true, brightness: 60, warmth: 3500 },
      },
    ],
  },
  {
    id: "sleep",
    name: "Sleep",
    subtitle: "Leave the day behind.",
    icon: "bed",
    actions: [
      ...["ceiling", "floor", "pendant", "bedside"].map((deviceId) => ({
        deviceId,
        changes: { power: false },
      })),
    ],
  },
];

export function createInitialState() {
  return {
    devices: structuredClone(initialDevices),
    tab: "Home",
    roomId: null,
    sheet: null,
    suggestion: "available",
    lastScene: null,
    history: [],
    guide: "idle",
    expanded: false,
    notice: "",
    reducedStimulation: false,
  };
}

export const devicesInRoom = (state, roomId) =>
  Object.values(state.devices).filter((device) => device.roomId === roomId);
export const activeLights = (devices) =>
  devices.filter(
    (device) => device.type === "light" && device.online && device.power,
  ).length;
export const reachableCount = (state) =>
  Object.values(state.devices).filter((device) => device.online).length;
export function deviceSummary(device) {
  if (!device.online) return "Unavailable";
  if (device.type === "light")
    return device.power ? `On · ${device.brightness}%` : "Off";
  if (device.type === "climate") return `${device.temperature}°C`;
  return device.contact;
}
export function describeChanges(changes) {
  if (changes.power === false) return "Power off";
  return [
    changes.power === true && "Power on",
    changes.brightness !== undefined && `${changes.brightness}% brightness`,
    changes.warmth && `${changes.warmth} K`,
    changes.temperature && `${changes.temperature}°C`,
  ]
    .filter(Boolean)
    .join(" · ");
}
const clamp = (value, min, max) => Math.max(min, Math.min(max, Number(value)));
function safeChanges(device, changes) {
  if (device.type === "light")
    return {
      ...(changes.power !== undefined && { power: Boolean(changes.power) }),
      ...(Number.isFinite(Number(changes.brightness)) && {
        brightness: clamp(changes.brightness, 0, 100),
      }),
      ...(Number.isFinite(Number(changes.warmth)) && {
        warmth: clamp(changes.warmth, 2200, 5000),
      }),
    };
  if (device.type === "climate" && Number.isFinite(Number(changes.temperature)))
    return { temperature: clamp(changes.temperature, 16, 28) };
  return {};
}

export function demoReducer(state, action) {
  switch (action.type) {
    case "NAVIGATE":
      if (!["Home", "Rooms", "Intel", "Auto", "Settings"].includes(action.tab))
        return state;
      return {
        ...state,
        tab: action.tab,
        roomId: null,
        sheet: null,
        notice: "",
        guide: state.guide === "review" ? "idle" : state.guide,
      };
    case "ROOM":
      if (!rooms.some((room) => room.id === action.id)) return state;
      return {
        ...state,
        tab: "Rooms",
        roomId: action.id,
        sheet: null,
        notice: "",
      };
    case "BACK":
      return { ...state, roomId: null, sheet: null };
    case "DEVICE": {
      const device = state.devices[action.id];
      if (!device) return state;
      return {
        ...state,
        sheet: { type: "device", deviceId: action.id, draft: { ...device } },
        notice: "",
      };
    }
    case "DRAFT": {
      if (state.sheet?.type !== "device") return state;
      const draft = state.sheet.draft;
      if (
        !draft.online ||
        (action.field !== "power" && draft.type === "light" && !draft.power)
      )
        return state;
      return {
        ...state,
        sheet: {
          ...state.sheet,
          draft: {
            ...draft,
            ...safeChanges(draft, { [action.field]: action.value }),
          },
        },
      };
    }
    case "APPLY_DEVICE": {
      if (state.sheet?.type !== "device") return state;
      const device = state.devices[state.sheet.deviceId];
      if (!device.online || device.type === "sensor") return state;
      return {
        ...state,
        devices: {
          ...state.devices,
          [device.id]: { ...device, ...safeChanges(device, state.sheet.draft) },
        },
        sheet: null,
        notice: `${device.name} updated in this simulated home.`,
      };
    }
    case "SCENE":
      if (!scenes.some((scene) => scene.id === action.id)) return state;
      return {
        ...state,
        sheet: { type: "scene", sceneId: action.id },
        notice: "",
      };
    case "SUGGESTION":
      return {
        ...state,
        sheet: { type: "suggestion", sceneId: "evening" },
        notice: "",
      };
    case "CLOSE_SHEET":
      return {
        ...state,
        sheet: null,
        guide: state.guide === "review" ? "idle" : state.guide,
      };
    case "DISMISS":
      return {
        ...state,
        sheet: null,
        suggestion: "dismissed",
        notice: "Suggestion dismissed. No devices changed.",
        guide: state.guide === "review" ? "dismissed" : state.guide,
      };
    case "APPLY_SCENE": {
      if (!["scene", "suggestion"].includes(state.sheet?.type)) return state;
      const scene = scenes.find((item) => item.id === state.sheet.sceneId);
      const devices = { ...state.devices };
      let applied = 0;
      let skipped = 0;
      for (const operation of scene.actions) {
        const device = devices[operation.deviceId];
        if (!device?.online) {
          skipped++;
          continue;
        }
        devices[device.id] = {
          ...device,
          ...safeChanges(device, operation.changes),
        };
        applied++;
      }
      const message = skipped
        ? `${scene.name}: ${applied} devices updated; ${skipped} unavailable. This is a simulation.`
        : `${scene.name} applied to ${applied} devices in this simulated home.`;
      return {
        ...state,
        devices,
        sheet: null,
        lastScene: scene.id,
        history: [{ sceneId: scene.id, message }, ...state.history].slice(0, 5),
        suggestion: scene.id === "evening" ? "applied" : state.suggestion,
        notice: message,
        guide: state.guide === "review" ? "complete" : state.guide,
      };
    }
    case "GUIDE_START":
      return {
        ...state,
        tab: "Home",
        roomId: null,
        sheet: { type: "suggestion", sceneId: "evening" },
        suggestion: "available",
        guide: "review",
        notice: "",
      };
    case "GUIDE_SKIP":
      return { ...state, guide: "idle", sheet: null };
    case "EXPAND":
      return { ...state, expanded: true };
    case "COLLAPSE":
      return { ...state, expanded: false, sheet: null };
    case "STIMULATION":
      return { ...state, reducedStimulation: !state.reducedStimulation };
    case "RESET":
      return {
        ...createInitialState(),
        expanded: state.expanded,
        notice: "Demo reset. Your sample home is back where it started.",
      };
    default:
      return state;
  }
}
