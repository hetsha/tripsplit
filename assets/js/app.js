/**
 * TripBook Main Application Coordinator
 */

const UI = {
  showToast(message, type = 'info') {
    const container = document.getElementById('toast-container');
    if (!container) return;

    const toast = document.createElement('div');
    toast.className = `toast ${type}`;
    toast.innerHTML = `<span>${this.escapeHtml(message)}</span>`;
    container.appendChild(toast);

    setTimeout(() => {
      toast.style.opacity = '0';
      toast.style.transform = 'translateY(-20px)';
      toast.style.transition = 'all 0.3s ease';
      setTimeout(() => toast.remove(), 300);
    }, 3500);
  },

  openModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
      modal.classList.add('active');
    }
  },

  closeModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
      modal.classList.remove('active');
    }
  },

  escapeHtml(str) {
    if (!str) return '';
    return String(str)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#039;');
  },

  showConfirm(title, message, onConfirm) {
    if (confirm(`${title}\n\n${message}`)) {
      onConfirm();
    }
  }
};

const App = {
  currentTab: 'home',
  lastSyncVersion: '',
  syncInterval: null,
  allUsers: [],
  pageCache: {},

  async init(csrfToken, activeTripId, urlToken) {
    this.initTheme();
    API.init(csrfToken, activeTripId);

    if (urlToken && !activeTripId) {
      try {
        const res = await API.post('api/trips.php?action=resolve_token', { url_token: urlToken });
        if (res.success && res.data.trip_id) {
          activeTripId = res.data.trip_id;
          API.activeTripId = activeTripId;
        }
      } catch (e) {
        console.error('Failed to resolve trip token');
      }
    }

    this.bindNavigation();

    if (!activeTripId) {
      document.getElementById('header-trip-name').innerText = 'TripBook';
      document.getElementById('header-trip-code').innerText = '';
      this.showMainApp();
      return;
    }

    Expenses.init();
    Transactions.init();
    Settlements.init();
    People.init();
    More.init();

    await this.refreshData();

    await this.switchTab('home');

    this.startIncrementalSync();

    document.addEventListener('visibilitychange', () => {
      if (document.hidden) {
        clearInterval(this.syncInterval);
      } else {
        this.checkSync();
        this.startIncrementalSync();
      }
    });

    if ('serviceWorker' in navigator) {
      navigator.serviceWorker.register('service-worker.js').catch(err => console.log('SW registration skipped', err));
    }
  },

  initTheme() {
    console.log('[Theme] initTheme called!');
    const savedTheme = localStorage.getItem('theme') || 'dark';
    console.log('[Theme] Saved theme from localStorage:', savedTheme);
    if (savedTheme === 'light') {
      document.body.classList.add('light-theme');
      document.documentElement.classList.add('light-theme');
      console.log('[Theme] Added light-theme class to body and root HTML element.');
    } else {
      document.body.classList.remove('light-theme');
      document.documentElement.classList.remove('light-theme');
      console.log('[Theme] Removed light-theme class from body and root HTML element.');
    }
  },

  toggleTheme() {
    console.log('[Theme] toggleTheme clicked!');
    const isLight = document.body.classList.toggle('light-theme');
    const isHtmlLight = document.documentElement.classList.toggle('light-theme', isLight);
    console.log('[Theme] Toggled light-theme class. body has light-theme:', isLight, '; html has light-theme:', isHtmlLight);
    localStorage.setItem('theme', isLight ? 'light' : 'dark');
    console.log('[Theme] Saved new preference to localStorage:', localStorage.getItem('theme'));
    UI.showToast(`Switched to ${isLight ? 'Light' : 'Dark'} Mode`, 'success');
  },

  bindNavigation() {
    const navItems = document.querySelectorAll('.nav-item, .sidebar-nav-item');
    navItems.forEach(item => {
      item.addEventListener('click', (e) => {
        const tab = item.dataset.tab;
        if (tab) {
          this.switchTab(tab);
        }
      });
    });

    document.querySelectorAll('.modal-overlay').forEach(overlay => {
      overlay.addEventListener('click', (e) => {
        if (e.target === overlay) {
          overlay.classList.remove('active');
        }
      });
    });
  },

  async switchTab(tabName) {
    if (this.currentTab === tabName && document.getElementById('tab-content')?.children.length > 0) {
      return;
    }
    this.currentTab = tabName;

    document.querySelectorAll('.nav-item, .sidebar-nav-item').forEach(item => {
      item.classList.toggle('active', item.dataset.tab === tabName);
    });

    const container = document.getElementById('tab-content');
    if (!container) return;

    container.style.opacity = '0.5';

    try {
      const html = await this.loadPage(tabName);
      container.innerHTML = html;
      container.style.opacity = '1';

      if (window.lucide) {
        lucide.createIcons();
      }

      this.initPageModules(tabName);
    } catch (err) {
      console.error('Page load error:', err);
      container.innerHTML = '<div class="empty-state"><h3 class="empty-title">Failed to load</h3><p class="empty-subtext">Please try again.</p></div>';
      container.style.opacity = '1';
    }
  },

  async loadPage(page) {
    if (this.pageCache[page]) {
      return this.pageCache[page];
    }

    const tripToken = Dashboard.data?.trip_info?.url_token || '';
    const res = await fetch(`pages/load.php?page=${page}&trip=${tripToken}`, {
      credentials: 'same-origin'
    });

    if (!res.ok) {
      const errText = await res.text();
      console.error('Page load HTTP error:', res.status, errText);
      throw new Error(`HTTP ${res.status}: ${errText}`);
    }

    const html = await res.text();
    this.pageCache[page] = html;
    return html;
  },

  invalidatePageCache(page) {
    if (page) {
      delete this.pageCache[page];
    } else {
      this.pageCache = {};
    }
  },

  initPageModules(tabName) {
    if (tabName === 'home') {
      Dashboard.load();
    } else if (tabName === 'history') {
      Transactions.bindEvents();
      Transactions.load();
    } else if (tabName === 'people') {
      People.bindEvents();
      People.load();
    } else if (tabName === 'settle') {
      Settlements.load();
    } else if (tabName === 'more') {
      More.bindEvents();
      More.render();
    }
  },

  async refreshData() {
    const dot = document.getElementById('sync-dot');
    if (dot) dot.classList.add('syncing');

    try {
      const authRes = await API.get('api/auth.php');
      const user = authRes.data.user;

      if (user) {
        if (!user.phone) {
          Auth.showPhoneLink();
          return;
        }

        const avatar = document.getElementById('header-user-avatar');
        const nameEl = document.getElementById('header-user-name');
        const sidebarAvatar = document.getElementById('sidebar-user-avatar');
        const sidebarNameEl = document.getElementById('sidebar-user-name-display');

        if (avatar) {
          avatar.innerText = user.name.charAt(0).toUpperCase();
          avatar.style.backgroundColor = user.avatar_color || 'var(--primary)';
        }
        if (nameEl) nameEl.innerText = user.name.split(' ')[0];

        if (sidebarAvatar) {
          sidebarAvatar.innerText = user.name.charAt(0).toUpperCase();
          sidebarAvatar.style.backgroundColor = user.avatar_color || 'var(--primary)';
        }
        if (sidebarNameEl) sidebarNameEl.innerText = user.name;
      }

      const dashRes = await API.get('api/dashboard.php');
      Dashboard.render(dashRes.data);

      const tripName = document.getElementById('header-trip-name');
      const tripCode = document.getElementById('header-trip-code');
      const sidebarTripName = document.getElementById('sidebar-trip-name');
      const sidebarTripCode = document.getElementById('sidebar-trip-code');

      if (tripName) tripName.innerText = dashRes.data.trip_info.name;
      if (tripCode) tripCode.innerText = dashRes.data.trip_info.trip_code;
      if (sidebarTripName) sidebarTripName.innerText = dashRes.data.trip_info.name;
      if (sidebarTripCode) sidebarTripCode.innerText = dashRes.data.trip_info.trip_code;

      this.invalidatePageCache();
      if (document.getElementById('tab-content')?.children.length > 0) {
        this.initPageModules(this.currentTab);
      }

      Notifications.load();
    } catch (e) {
      console.error('Refresh error:', e);
    } finally {
      if (dot) dot.classList.remove('syncing');
    }
  },

  startIncrementalSync() {
    clearInterval(this.syncInterval);
    this.syncInterval = setInterval(() => this.checkSync(), 6000);
  },

  async checkSync() {
    try {
      const res = await API.get('api/sync.php', { version: this.lastSyncVersion });
      if (res.data.has_changes) {
        this.lastSyncVersion = res.data.version;
        // Non-intrusive incremental update
        await this.refreshData();
      }
    } catch (e) {
      // Silent sync check error
    }
  },

  copyInviteCode(code) {
    if (navigator.clipboard) {
      navigator.clipboard.writeText(code).then(() => {
        UI.showToast(`Copied Trip Code: ${code}`, 'success');
      });
    } else {
      UI.showToast(`Trip Code: ${code}`, 'info');
    }
  },

  shareTrip() {
    const tripCode = Dashboard.data?.trip_info?.trip_code || '';
    const tripName = Dashboard.data?.trip_info?.name || 'TripBook';
    const urlToken = Dashboard.data?.trip_info?.url_token || '';
    const shareUrl = urlToken ? `${window.location.origin}${window.location.pathname}?trip=${urlToken}` : window.location.href;
    if (navigator.share) {
      navigator.share({
        title: `Join ${tripName} on TripBook`,
        text: `Join our group trip expenses on TripBook using code: ${tripCode}`,
        url: shareUrl
      }).catch(() => {});
    } else {
      this.copyInviteCode(tripCode);
    }
  },

  getPaymentMeta(method) {
    const map = {
      cash: { label: 'Cash', icon: 'banknote' },
      bank: { label: 'Bank Transfer', icon: 'building' }
    };
    return map[method] || { label: 'Cash', icon: 'banknote' };
  },

  async showTripsList() {
    clearInterval(this.syncInterval);
    document.getElementById('app-content').style.display = 'none';
    document.getElementById('trips-list-screen').style.display = 'block';

    try {
      const res = await API.get('api/auth.php');
      const trips = res.data.trips || [];
      Auth.authData = { ...Auth.authData, ...res.data };
      Auth.showTripsList(trips);
    } catch (e) {
      console.error('Failed to load trips list:', e);
    }
  },

  showMainApp() {
    document.getElementById('app-content').style.display = 'flex';
    document.querySelector('.bottom-nav').style.display = 'flex';
    this.switchTab('home');
    More.bindEvents();
  }
};
