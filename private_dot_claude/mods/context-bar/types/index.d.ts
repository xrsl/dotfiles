export type Seg = { name: string; tokens: number; color: string; kind: string }

declare module 'claude-code' {
  interface PluginState {
    'context-bar': { segs: Seg[] | null; max: number; isOn: boolean }
  }
}
