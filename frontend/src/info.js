// Build metadata injected by Vite at build time (see vite.config.js).
export function buildInfo() {
  return {
    sha: typeof __BUILD_SHA__ !== 'undefined' ? __BUILD_SHA__ : 'local',
    builtAt: typeof __BUILD_TIME__ !== 'undefined' ? __BUILD_TIME__ : 'unknown',
  }
}

export function shortSha(sha) {
  return sha && sha !== 'local' ? sha.slice(0, 7) : 'local'
}
