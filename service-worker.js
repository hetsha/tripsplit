/**
 * TripBook Service Worker for offline static asset caching
 */

const CACHE_NAME = 'tripbook-v5';
const ASSETS_TO_CACHE = [
  'assets/css/style.css',
  'assets/css/responsive.css',
  'assets/js/api.js',
  'assets/js/app.js',
  'assets/js/auth.js',
  'assets/js/auth-email.js',
  'assets/js/profile.js',
  'assets/js/dashboard.js',
  'assets/js/expenses.js',
  'assets/js/transactions.js',
  'assets/js/settlements.js',
  'assets/js/people.js',
  'assets/js/more.js',
  'assets/js/cashbook.js',
  'assets/js/passbook.js',
  'assets/js/notifications.js',
  'manifest.json'
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(ASSETS_TO_CACHE);
    })
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) => {
      return Promise.all(
        keys.filter((key) => key !== CACHE_NAME).map((key) => caches.delete(key))
      );
    })
  );
  self.clients.claim();
});

self.addEventListener('fetch', (event) => {
  if (event.request.method !== 'GET') return;

  const url = new URL(event.request.url);
  const path = url.pathname;
  const isStatic = /\.(css|js|png|jpg|jpeg|gif|svg|ico|woff2?)$/.test(path) || path.includes('/assets/');
  const isApi = path.includes('/api/');

  if (!isApi && isStatic) {
    event.respondWith(
      caches.match(event.request).then((cached) => {
        return cached || fetch(event.request).then((response) => {
          if (response.ok) {
            const clone = response.clone();
            caches.open(CACHE_NAME).then((cache) => cache.put(event.request, clone));
          }
          return response;
        });
      })
    );
  }
});
