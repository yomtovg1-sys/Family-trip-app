// EasyTrip offline app-shell cache.
//
// Flutter's own generated service worker in this SDK version is a no-op
// that unregisters itself on activation (its built-in PWA/offline support
// is deprecated), so this hand-written worker provides the actual offline
// behavior: once the app has been opened at least once with a network
// connection, it keeps loading — including with no signal at all — by
// serving everything it has already seen from the cache.
//
// Bump CACHE_VERSION whenever a new build is deployed so old cached
// assets from a previous release are dropped instead of lingering forever.
const CACHE_VERSION = 'easytrip-v2';

// Everything the app needs to actually boot and render, offline, from a
// cold start. This has to be precached explicitly rather than left to
// "cache it the first time it's requested": Flutter only fetches its
// engine/canvaskit/font files once, during the very first page load,
// which happens before this service worker has finished installing and
// can start intercepting anything — by the time it's active, those
// requests have already come and gone. Everything else (in-app
// navigation, screen-specific assets) is handled by the runtime,
// cache-as-you-go logic in the fetch handler below.
//
// Paths are the ones Flutter actually emits for this app today; if a
// future Flutter upgrade changes these (e.g. adds a new canvaskit
// variant), update this list to match `build/web`'s contents.
const CORE_ASSETS = [
  './',
  'index.html',
  'manifest.json',
  'favicon.png',
  'flutter_bootstrap.js',
  'flutter.js',
  'main.dart.js',
  'version.json',
  // Flutter's web renderer loads CanvasKit from different subfolders
  // depending on the browser's capabilities (Chromium-family browsers get
  // an optimized "chromium" variant; Safari and others get the default
  // build) — both are precached so the app boots offline no matter which
  // browser opens it.
  'canvaskit/canvaskit.js',
  'canvaskit/canvaskit.wasm',
  'canvaskit/chromium/canvaskit.js',
  'canvaskit/chromium/canvaskit.wasm',
  'assets/AssetManifest.bin',
  'assets/FontManifest.json',
  'assets/fonts/MaterialIcons-Regular.otf',
  'assets/packages/cupertino_icons/assets/CupertinoIcons.ttf',
  'assets/assets/images/family_hero.jpg',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_VERSION).then((cache) =>
      Promise.all(
        CORE_ASSETS.map((asset) =>
          cache.add(asset).catch((err) => {
            // One missing/renamed asset (e.g. after a Flutter upgrade)
            // shouldn't block every other asset from being cached.
            console.warn('[pwa-service-worker] failed to precache', asset, err);
          })
        )
      )
    )
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((key) => key !== CACHE_VERSION).map((key) => caches.delete(key)))
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', (event) => {
  const request = event.request;

  // Only handle same-origin GET requests. Cross-origin requests (map
  // tiles, any future API/CDN calls) are left alone — they work normally
  // online and simply fail offline, same as native would with no signal.
  if (request.method !== 'GET' || new URL(request.url).origin !== self.location.origin) {
    return;
  }

  // Page navigations: prefer a fresh copy when online (so a new deploy is
  // picked up promptly), falling back to the cached shell when offline.
  if (request.mode === 'navigate') {
    event.respondWith(
      fetch(request)
        .then((response) => {
          const copy = response.clone();
          caches.open(CACHE_VERSION).then((cache) => cache.put(request, copy));
          return response;
        })
        .catch(() => caches.match(request).then((cached) => cached || caches.match('index.html')))
    );
    return;
  }

  // Everything else: serve from cache immediately if we have it, otherwise
  // fetch from the network and cache the result for next time (including
  // offline visits).
  event.respondWith(
    caches.match(request).then((cached) => {
      if (cached) return cached;
      return fetch(request).then((response) => {
        if (response.ok) {
          const copy = response.clone();
          caches.open(CACHE_VERSION).then((cache) => cache.put(request, copy));
        }
        return response;
      });
    })
  );
});
