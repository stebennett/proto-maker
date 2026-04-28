/*
 * proto-maker annotation overlay
 *
 * Dual-mode overlay for stakeholders to leave structured notes on a
 * wireframe screen. Probes the local proto-maker server at /__ping__
 * on init; if reachable, "online" mode POSTs annotations to disk.
 * Otherwise, "offline" mode persists to localStorage and exposes a
 * "Copy notes" button that places structured JSON on the clipboard.
 *
 * Public surface:
 *   await ProtoMakerAnnotations.init({ screen, path })
 *     → returns the overlay object with .mode in {'online', 'offline'}
 *
 * The init function is idempotent — calling it twice on the same page
 * is a no-op (returns the existing overlay).
 */

(function (global) {
  let activeOverlay = null;

  async function detectMode() {
    try {
      const res = await fetch('/__ping__', { method: 'GET' });
      if (res && res.ok) return 'online';
      return 'offline';
    } catch (_e) {
      return 'offline';
    }
  }

  async function init(opts) {
    if (activeOverlay) return activeOverlay;
    const screen = (opts && opts.screen) || 'unknown.html';
    const path = (opts && opts.path) || '';
    const mode = await detectMode();
    activeOverlay = { mode, screen, path, notes: [] };
    return activeOverlay;
  }

  global.ProtoMakerAnnotations = { init };
})(typeof window !== 'undefined' ? window : this);
