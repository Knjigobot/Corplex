/**
 * Cordis Meta-Framework Dynamic Context & Observable Store
 */

export class CordisContext {
  constructor() {
    this.bindings = new Map();
    this.listeners = new Map();
  }

  set(key, value) {
    this.bindings.set(key, value);
    if (this.listeners.has(key)) {
      this.listeners.get(key).forEach(cb => {
        try { cb(value); } catch (e) { console.error('Context listener error:', e); }
      });
    }
  }

  get(key, defaultValue = undefined) {
    return this.bindings.has(key) ? this.bindings.get(key) : defaultValue;
  }

  subscribe(key, callback) {
    if (!this.listeners.has(key)) {
      this.listeners.set(key, new Set());
    }
    this.listeners.get(key).add(callback);
    return () => this.listeners.get(key).delete(callback);
  }
}
