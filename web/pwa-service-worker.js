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
// (Belt-and-suspenders only — see the fetch handler below, which no longer
// depends on this being bumped for app-code files to update promptly.)
const CACHE_VERSION = 'easytrip-v5';

// Files that change on every deploy and must never be served stale: the
// compiled app itself, the loader that fetches it, and the version marker.
// A previous version of this worker cached these "cache-first" like every
// other asset, which meant a returning visitor's browser kept serving the
// *original* main.dart.js forever — no new deploy ever reached them,
// because nothing here ever told the browser a fresher copy existed.
// These are matched network-first (falling back to cache only if offline),
// same as page navigations below, so every deploy reaches every visitor
// the next time they're online — no manual cache-version bump required.
const NETWORK_FIRST_FILES = ['main.dart.js', 'flutter_bootstrap.js', 'flutter.js', 'version.json'];

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
  // Roboto (body text) and Noto Color Emoji (flags, trip icons) are
  // bundled with the app instead of fetched from Google Fonts at runtime —
  // precaching them here is what makes text and emoji still render with
  // no network at all, not just the app shell around them.
  'assets/assets/fonts/Roboto/Roboto-Thin.ttf',
  'assets/assets/fonts/Roboto/Roboto-Light.ttf',
  'assets/assets/fonts/Roboto/Roboto-Regular.ttf',
  'assets/assets/fonts/Roboto/Roboto-Medium.ttf',
  'assets/assets/fonts/Roboto/Roboto-Bold.ttf',
  'assets/assets/fonts/Roboto/Roboto-Black.ttf',
  'assets/assets/fonts/NotoColorEmoji.ttf',
  // Mirrors of the specific Google Fonts "Noto Sans Symbols" files the web
  // engine's automatic fallback mechanism reaches for (plain symbol glyphs
  // like ★, not covered by Roboto or Noto Color Emoji) — see index.html's
  // fontFallbackBaseUrl override, which points that mechanism here instead
  // of fonts.gstatic.com.
  'fallback_fonts/notosanssymbols/v43/rP2up3q65FkAtHfwd-eIS2brbDN6gxP34F9jRRCe4W3gfQ8gb_VFRkzrbQ.woff2',
  'fallback_fonts/notosanssymbols2/v24/I_uyMoGduATTei9eI8daxVHDyfisHr71-jrBWXPM4Q.woff2',
  'fallback_fonts/notosanssymbols2/v24/I_uyMoGduATTei9eI8daxVHDyfisHr71-ujgfE71.woff2',
  'fallback_fonts/notosanssymbols2/v24/I_uyMoGduATTei9eI8daxVHDyfisHr71-gTBWXPM4Q.woff2',
  'fallback_fonts/notosanssymbols2/v24/I_uyMoGduATTei9eI8daxVHDyfisHr71-vrgfE71.woff2',
  'fallback_fonts/notosanssymbols2/v24/I_uyMoGduATTei9eI8daxVHDyfisHr71-prgfE71.woff2',
  'fallback_fonts/notosanssymbols2/v24/I_uyMoGduATTei9eI8daxVHDyfisHr71-pTgfA.woff2',
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

  const isNetworkFirst =
    request.mode === 'navigate' || NETWORK_FIRST_FILES.some((name) => request.url.endsWith(name));

  // Page navigations and app-code files: prefer a fresh copy when online
  // (so a new deploy is picked up on the very next load), falling back to
  // the cached copy when offline.
  if (isNetworkFirst) {
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

  // Everything else (fonts, canvaskit, icons — large, effectively
  // immutable assets): serve from cache immediately if we have it,
  // otherwise fetch from the network and cache the result for next time
  // (including offline visits).
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
