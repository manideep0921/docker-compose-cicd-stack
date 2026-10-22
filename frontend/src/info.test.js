import { describe, it, expect } from 'vitest'
import { shortSha, buildInfo } from './info.js'

describe('build info', () => {
  it('shortens a git sha to 7 chars', () => {
    expect(shortSha('0123456789abcdef')).toBe('0123456')
  })
  it('keeps "local" for non-CI builds', () => {
    expect(shortSha('local')).toBe('local')
  })
  it('returns defaults when constants are not injected', () => {
    expect(buildInfo().sha).toBe('local')
  })
})
