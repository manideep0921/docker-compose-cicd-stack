import React, { useEffect, useState } from 'react'
import { buildInfo, shortSha } from './info.js'

export default function App() {
  const info = buildInfo()
  const [health, setHealth] = useState('checking...')

  useEffect(() => {
    fetch('/healthz')
      .then((r) => (r.ok ? r.text() : Promise.reject(r.status)))
      .then((t) => setHealth(t.trim()))
      .catch(() => setHealth('unreachable'))
  }, [])

  return (
    <main style={{ fontFamily: 'system-ui', maxWidth: 560, margin: '4rem auto' }}>
      <h1>Deploy Status</h1>
      <p>Commit: <code>{shortSha(info.sha)}</code></p>
      <p>Built at: <code>{info.builtAt}</code></p>
      <p>Server health (<code>/healthz</code>): <strong>{health}</strong></p>
    </main>
  )
}
