# 23 — Frontend Architecture

This document specifies the web application architecture: folder structure, routing, state management, API layer, and component patterns.

---

## 1. Technology Stack

| Component | Technology |
|-----------|-----------|
| Language | Vanilla JavaScript (ES6+) |
| Styling | CSS3 with custom properties |
| Icons | Lucide Icons (SVG) |
| Font | Plus Jakarta Sans |
| PWA | Service Worker |
| Build | None (vanilla, no bundler) |

---

## 2. Directory Structure

```
tripsplit/
├── index.php                 # SPA entry point
├── pages/
│   ├── home.php              # Dashboard page fragment
│   ├── history.php           # Transaction list
│   ├── people.php            # Member list
│   ├── settle.php            # Settlement screen
│   ├── more.php              # More/settings
│   └── load.php              # AJAX page loader
├── assets/
│   ├── css/
│   │   ├── style.css         # Main styles (design system)
│   │   └── responsive.css    # Media queries
│   └── js/
│       ├── api.js            # API client
│       ├── app.js            # Main app controller
│       ├── auth.js           # Authentication
│       ├── auth-email.js     # Email OTP
│       ├── dashboard.js      # Dashboard logic
│       ├── expenses.js       # Expense creation
│       ├── cashbook.js       # Personal finance (LEGACY — will be replaced)
│       ├── passbook.js       # Passbook view
│       ├── settlements.js    # Settlement logic
│       ├── transactions.js   # Transaction list
│       ├── people.js         # People list
│       ├── notifications.js  # Notifications
│       ├── more.js           # Settings/more
│       └── profile.js        # Profile management
├── admin/                    # Admin panel
├── api/                      # Backend API
├── config/                   # Database config
├── includes/                 # PHP helpers
└── service-worker.js         # PWA caching
```

---

## 3. SPA Routing

### Page Loading

The app is a single-page application using AJAX to load page fragments:

```javascript
// load.php resolves page requests
async function loadPage(page) {
    const response = await fetch(`pages/${page}.php`);
    const html = await response.text();
    document.getElementById('app-content').innerHTML = html;
    // Initialize page-specific JS
    initPage(page);
}
```

### Navigation

Bottom nav tabs trigger page loads:
- Home → `loadPage('home')`
- Transactions → `loadPage('history')`
- People → `loadPage('people')`
- Settle → `loadPage('settle')`
- More → `loadPage('more')`

---

## 4. API Layer

### `api.js`

```javascript
const API = {
    baseURL: '/api/',
    
    async request(endpoint, method = 'GET', data = null) {
        const options = {
            method,
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-Token': this.csrfToken
            },
            credentials: 'same-origin'
        };
        if (data) options.body = JSON.stringify(data);
        
        const response = await fetch(this.baseURL + endpoint, options);
        return response.json();
    },
    
    get(endpoint) { return this.request(endpoint); },
    post(endpoint, data) { return this.request(endpoint, 'POST', data); }
};
```

### CSRF Token Management

```javascript
// Fetch CSRF token from session
async function initCSRF() {
    const res = await API.get('auth.php?action=me');
    API.csrfToken = res.data.csrf_token;
}
```

---

## 5. State Management

### Global State

```javascript
const AppState = {
    user: null,
    activeTrip: null,
    trips: [],
    csrfToken: null,
    lastSyncVersion: null
};
```

### Page State

Each page manages its own state:

```javascript
const DashboardState = {
    balances: null,
    recentTransactions: [],
    categorySpending: [],
    whoOwesWhom: []
};
```

---

## 6. Live Sync

### Polling

```javascript
// Check for updates every 6 seconds
setInterval(async () => {
    const res = await API.get(`sync.php?trip_id=${AppState.activeTrip.id}&version=${AppState.lastSyncVersion}`);
    if (res.data.has_changes) {
        refreshCurrentPage();
        AppState.lastSyncVersion = res.data.version;
    }
}, 6000);
```

---

## 7. Component Patterns

### Bottom Sheet

```html
<div class="bottom-sheet-overlay" id="overlay">
    <div class="bottom-sheet" id="sheet">
        <div class="bottom-sheet-handle"></div>
        <div class="bottom-sheet-content">
            <!-- Content -->
        </div>
    </div>
</div>
```

### Modal

```html
<div class="modal-overlay" id="modal-overlay">
    <div class="modal">
        <h3 class="modal-title">Title</h3>
        <p class="modal-body">Content</p>
        <div class="modal-actions">
            <button class="btn btn-secondary">Cancel</button>
            <button class="btn btn-primary">Confirm</button>
        </div>
    </div>
</div>
```

### Toast Notification

```javascript
function showToast(message, type = 'success') {
    const toast = document.createElement('div');
    toast.className = `toast toast-${type}`;
    toast.textContent = message;
    document.getElementById('toast-container').appendChild(toast);
    setTimeout(() => toast.remove(), 3000);
}
```

---

## 8. Offline Support

### Service Worker

```javascript
// service-worker.js
const CACHE_NAME = 'tripbook-v1';
const ASSETS = ['/assets/css/style.css', '/assets/js/api.js', ...];

self.addEventListener('install', e => {
    e.waitUntil(caches.open(CACHE_NAME).then(c => c.addAll(ASSETS)));
});

self.addEventListener('fetch', e => {
    e.respondWith(
        caches.match(e.request).then(r => r || fetch(e.request))
    );
});
```

---

## 9. Responsive Behavior

| Breakpoint | Behavior |
|-----------|----------|
| < 768px | Single column, bottom nav |
| 768px-1023px | Single column, max-width 540px centered |
| ≥ 1024px | Sidebar navigation, max-width 960px content |

---

## Open Questions

| # | Question | Impact |
|---|----------|--------|
| OQ-1 | Should we introduce a build step (Vite) for optimization? | Performance |
| OQ-2 | Should we migrate to a lightweight framework (Preact, Alpine.js)? | Maintainability |
| OQ-3 | Should we implement Web Push notifications? | Feature scope |

---

## Dependencies

- `04-DESIGN-SYSTEM.md` — CSS tokens and components
- `21-API-SPECIFICATION.md` — API endpoints
- `22-BACKEND-ARCHITECTURE.md` — Backend integration

## Related Documents

- `04-DESIGN-SYSTEM.md` — Design tokens
- `22-BACKEND-ARCHITECTURE.md` — Backend
- `24-FLUTTER-ARCHITECTURE.md` — Flutter counterpart
- `27-SYNC-OFFLINE.md` — Sync implementation
