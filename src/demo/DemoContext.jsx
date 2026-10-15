import { createContext, useContext, useReducer, useRef } from "react";
import { createInitialState, demoReducer } from "./demoModel.js";

const DemoContext = createContext(null);
export function DemoProvider({ children }) {
  const [state, dispatch] = useReducer(
    demoReducer,
    undefined,
    createInitialState,
  );
  const openerRef = useRef(null);
  return (
    <DemoContext.Provider value={{ state, dispatch, openerRef }}>
      {children}
    </DemoContext.Provider>
  );
}
export function useDemo() {
  const value = useContext(DemoContext);
  if (!value) throw new Error("useDemo needs a DemoProvider");
  return value;
}
