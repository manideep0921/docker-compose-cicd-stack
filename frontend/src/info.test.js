import { describe, it, expect } from 'vitest'
import { shortSha, buildInfo } from './info.js'

describe('build info', () => {
  it('shortens a git sha to 7 chars', () => {
    expect(shortSha('0123456789abcdef')).toBe('0123456')
  })
  it('keeps "local" for non-CI builds', () => {
    expect(shortSha('local')).toBe('local')
  })
  it('exposes the injected build sha (or "local" outside CI)', () => {
    // vite.config.js injects GITHUB_SHA in CI, so the value differs per environment
    expect(buildInfo().sha).toMatch(/^(local|[0-9a-f]{7,40})$/)
  })
})
