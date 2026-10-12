const CACHE = 'rv-v1';
const SHELL = ['./', './index.html', './manifest.json', './config.js', './data/manifest.json'];
self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(SHELL)).catch(() => {}));
  self.skipWaiting();
});
self.addEventListener('activate', e => {
  e.waitUntil(caches.keys().then(ks => Promise.all(ks.filter(k => k !== CACHE).map(k => caches.delete(k)))));
  self.clients.claim();
});
self.addEventListener('fetch', e => {
  const r = e.request;
  if (r.method !== 'GET') return;
  e.respondWith(
    caches.match(r).then(hit => {
      if (hit) return hit;
      return fetch(r).then(res => {
        if (res.ok && new URL(r.url).origin === location.origin) {
          const cl = res.clone();
          caches.open(CACHE).then(c => c.put(r, cl));
        }
        return res;
      }).catch(() => hit);
    })
  );
});
