import { useEffect, useRef } from "react";
import {
  DoorOpen,
  House,
  Maximize2,
  RotateCcw,
  Settings,
  Signal,
  Sparkle,
  Sparkles,
  X,
} from "lucide-react";
import { useDemo } from "./DemoContext.jsx";
import {
  HomeScreen,
  IntelScreen,
  RoomsScreen,
  ScenesScreen,
  SettingsScreen,
} from "./DemoScreens.jsx";
import { DemoSheets } from "./DemoSheets.jsx";
import "./simulator.css";

const tabs = [
  { label: "Home", icon: House, component: HomeScreen },
  { label: "Rooms", icon: DoorOpen, component: RoomsScreen },
  { label: "Intel", icon: Sparkle, component: IntelScreen },
  { label: "Auto", icon: Sparkles, component: ScenesScreen },
  { label: "Settings", icon: Settings, component: SettingsScreen },
];
const focusable =
  'button:not(:disabled), a[href], input:not(:disabled), [tabindex="0"]';

function useExpandedPreview(ref, expanded, dispatch, openerRef) {
  useEffect(() => {
    if (!expanded) return;
    const root = ref.current;
    // Safari does not focus buttons on pointer activation. Use the explicit
    // opener recorded by the capture handler instead of assuming activeElement.
    const previous = openerRef.current || document.activeElement;
    const overflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    const inertElements = [];
    let element = root;
    while (element.parentElement && element !== document.body) {
      for (const sibling of element.parentElement.children) {
        if (sibling !== element && !sibling.inert) {
          sibling.inert = true;
          inertElements.push(sibling);
        }
      }
      element = element.parentElement;
    }
    root.querySelector("[data-close-preview]")?.focus();
    const onKey = (event) => {
      if (document.querySelector("dialog[open]")) return;
      if (event.key === "Escape") {
        event.preventDefault();
        dispatch({ type: "COLLAPSE" });
      }
      if (event.key === "Tab") {
        const items = [...root.querySelectorAll(focusable)].filter(
          (item) =>
            item.getClientRects().length && !item.closest("dialog:not([open])"),
        );
        const first = items[0];
        const last = items.at(-1);
        if (event.shiftKey && document.activeElement === first) {
          event.preventDefault();
          last.focus();
        }
        if (!event.shiftKey && document.activeElement === last) {
          event.preventDefault();
          first.focus();
        }
      }
    };
    document.addEventListener("keydown", onKey);
    return () => {
      inertElements.forEach((item) => {
        item.inert = false;
      });
      document.body.style.overflow = overflow;
      document.removeEventListener("keydown", onKey);
      if (previous?.isConnected) previous.focus();
      openerRef.current = null;
    };
  }, [expanded, dispatch, ref, openerRef]);
}

export function InteractiveDemo() {
  const { state, dispatch, openerRef } = useDemo();
  const root = useRef(null);
  const scroll = useRef(null);
  useExpandedPreview(root, state.expanded, dispatch, openerRef);
  useEffect(() => {
    if (scroll.current) scroll.current.scrollTop = 0;
  }, [state.tab, state.roomId]);
  const Screen = tabs.find((tab) => tab.label === state.tab).component;
  return (
    <div
      ref={root}
      className={`demo-presentation ${state.expanded ? "is-expanded" : ""} ${state.reducedStimulation ? "is-quiet" : ""}`}
      role={state.expanded ? "dialog" : "region"}
      aria-modal={state.expanded || undefined}
      aria-label="Interactive Lumen preview"
    >
      <div className="demo-toolbar">
        <span>
          <span className="sample-dot" /> Simulated home
        </span>
        <div>
          <button
            className="icon-button"
            aria-label="Reset demo"
            onClick={() => dispatch({ type: "RESET" })}
          >
            <RotateCcw size={17} />
          </button>
          <button
            className="icon-button"
            data-close-preview={state.expanded ? "" : undefined}
            aria-label={state.expanded ? "Close preview" : "Expand preview"}
            onClick={(event) => {
              if (!state.expanded) openerRef.current = event.currentTarget;
              dispatch({ type: state.expanded ? "COLLAPSE" : "EXPAND" });
            }}
          >
            {state.expanded ? <X size={19} /> : <Maximize2 size={17} />}
          </button>
        </div>
      </div>
      <div className="phone-frame">
        <div className="phone-safe-area" aria-hidden="true">
          <span>9:41</span>
          <span className="phone-island" />
          <span>
            <Signal size={13} />
            <i />
          </span>
        </div>
        <div className="app-scroll" ref={scroll} data-testid="app-scroll">
          <Screen />
        </div>
        <nav className="app-tabs" aria-label="Preview navigation">
          {tabs.map(({ label, icon: Icon }) => (
            <button
              key={label}
              aria-current={state.tab === label ? "page" : undefined}
              onClick={() => dispatch({ type: "NAVIGATE", tab: label })}
            >
              <Icon size={21} strokeWidth={state.tab === label ? 2 : 1.5} />
              <span>{label}</span>
            </button>
          ))}
        </nav>
        <div className="phone-home-indicator" aria-hidden="true" />
      </div>
      <div className="demo-feedback" role="status" aria-live="polite">
        {state.notice || "Explore freely. Everything here is a simulation."}
      </div>
      {["complete", "dismissed"].includes(state.guide) && (
        <div className="guide-completion">
          <span>
            {state.guide === "complete"
              ? "Step 2 of 2 · Evening applied. Open a room to see what changed."
              : "Step 2 of 2 · Nothing changed. Saying no is part of the experience."}
          </span>
          <button
            className="text-button"
            onClick={() => dispatch({ type: "GUIDE_START" })}
          >
            Restart
          </button>
          <button
            className="text-button"
            onClick={() => dispatch({ type: "GUIDE_SKIP" })}
          >
            Finish
          </button>
        </div>
      )}
      <DemoSheets />
    </div>
  );
}
