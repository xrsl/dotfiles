import { atom, read, update } from 'claude-code'
import type { Register } from 'claude-code'

import type { Seg } from '../types'

const segs = atom({ plugin: 'context-bar', key: 'segs' } as const, null)
const max = atom({ plugin: 'context-bar', key: 'max' } as const, 0)
const isOn = atom({ plugin: 'context-bar', key: 'isOn' } as const, false)  // off until /context-bar

// theme keys, so the bar follows light and dark themes; used rows take them in order
const PALETTE = ['suggestion', 'success', 'claude', 'remember', 'ide', 'permission', 'merged', 'planMode']

const refresh = async ($: any) => {
  const { context } = await $.session.usage({ breakdown: 'summary' })
  const b = context.breakdown
  if (!b) return
  // deferred rows sit outside the window; free/buffer are drawn like /context does
  const rows: Seg[] = b.categories
    .filter((c: any) => c.kind !== 'deferred' && c.tokens > 0)
    .map((c: any) => ({ name: c.name, tokens: c.tokens, color: c.color, kind: c.kind }))
  await update($, segs, () => rows)
  await update($, max, () => b.rawMaxTokens)
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({ name: 'context-bar', description: 'Toggle the context window bar' })
    await refresh($)
    return next(e)
  })

  on('turn.complete', async ($, e, next) => {
    await refresh($)
    return next(e)
  })

  on('command.run', { command: 'context-bar' }, async $ => {
    const now = !(await read($, isOn))
    await update($, isOn, () => now)
    if (now) await refresh($)
    return { text: `Context bar ${now ? 'on' : 'off'}.` }
  })

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    const rows = await read($, segs)
    if (!rows || !(await read($, isOn))) return next(e)

    const total = (await read($, max)) || rows.reduce((n, r) => n + r.tokens, 0)
    const { Box, Text } = $.ui.resolve(e)
    const width = e.props.bodyColumns
    // cumulative rounding so the segments sum to exactly `width`
    let used = 0
    let acc = 0
    const cells = rows.map(r => {
      acc += r.tokens
      const n = Math.round((acc / total) * width) - used
      used += n
      return n
    })
    // free space and the buffer get their own glyph so they never blend into used rows
    const glyph = (kind: string) => (kind === 'free' ? '░' : kind === 'buffer' ? '▒' : '█')
    const k = (n: number) => (n >= 1000 ? `${(n / 1000).toFixed(1)}k` : `${n}`)
    // used rows each get their own colour; free and buffer keep the engine's
    const tint = (r: Seg, i: number) => (r.kind === 'used' ? PALETTE[i % PALETTE.length] : r.color)

    return (
      <Box flexDirection="column">
        <Box>
          {rows.map((r, i) => (
            <Text key={r.name} color={tint(r, i)} dimColor={r.kind === 'free'}>
              {glyph(r.kind).repeat(Math.max(0, cells[i]))}
            </Text>
          ))}
        </Box>
        <Box>
          {rows.map((r, i) => (
            <Text key={r.name} color={tint(r, i)} dimColor={r.kind === 'free'}>
              {r.name} {k(r.tokens)}{'  '}
            </Text>
          ))}
        </Box>
      </Box>
    )
  })
}
