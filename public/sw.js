// Wishare Service Worker
// Simple service worker to prevent 404 errors and handle basic caching

const CACHE_NAME = 'wishare-v1';

self.addEventListener('install', (event) => {
  console.log('Wishare Service Worker installed');
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  console.log('Wishare Service Worker activated');
  event.waitUntil(clients.claim());
});

// Basic fetch handler to prevent connection errors
self.addEventListener('fetch', (event) => {
  // Only handle GET requests
  if (event.request.method !== 'GET') {
    return;
  }

  // Let requests pass through normally for now
  event.respondWith(fetch(event.request));
});