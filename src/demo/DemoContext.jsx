import { createContext, useContext, useReducer } from 'react';
import { createInitialState, demoReducer } from './demoModel.js';

const DemoContext = createContext(null);
export function DemoProvider({ children }) {
  const [state, dispatch] = useReducer(demoReducer, undefined, createInitialState);
  return <DemoContext.Provider value={{ state, dispatch }}>{children}</DemoContext.Provider>;
}
export function useDemo() {
  const value = useContext(DemoContext);
  if (!value) throw new Error('useDemo needs a DemoProvider');
  return value;
}
