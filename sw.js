// Offline cache for The Machinist's Bench.
// BUMP this version whenever app.html (or any shipped file) changes — the app
// shell is served cache-first, so a stale cache only refreshes when this
// version string changes and the browser reinstalls the worker.
const CACHE = 'machinist-v4.32';

// Same-origin app shell — must cache successfully or install fails.
const CORE = ['./app.html', './manifest.webmanifest', './icon.png'];

// Cross-origin React (the first CDN the loader tries). Precached best-effort so
// the app works fully offline after one online visit, without needing a reload.
// Opaque responses can't go through addAll, so they're fetched + put by hand.
const CDN = [
  'https://unpkg.com/react@18.3.1/umd/react.production.min.js',
  'https://unpkg.com/react-dom@18.3.1/umd/react-dom.production.min.js'
];

self.addEventListener('install', (e) => {
  e.waitUntil((async () => {
    const c = await caches.open(CACHE);
    await c.addAll(CORE);
    await Promise.all(CDN.map(async (url) => {
      try { await c.put(url, await fetch(url, { mode: 'no-cors' })); } catch (_) { /* CDN down — runtime cache will catch it */ }
    }));
    self.skipWaiting();
  })());
});

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

// Cache-first, fall back to network and cache what comes back — including
// opaque cross-origin responses (CDN, fonts) so the next load is offline.
self.addEventListener('fetch', (e) => {
  const req = e.request;
  if (req.method !== 'GET') return;
  e.respondWith(
    caches.match(req).then((hit) => {
      if (hit) return hit;
      return fetch(req).then((res) => {
        if (res && (res.ok || res.type === 'opaque')) {
          const copy = res.clone();
          caches.open(CACHE).then((c) => c.put(req, copy));
        }
        return res;
      }).catch(() => (req.mode === 'navigate' ? caches.match('./app.html') : undefined));
    })
  );
});
