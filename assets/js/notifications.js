const Notifications = {
  list: [],
  unread: 0,

  async load() {
    try {
      const res = await API.get('api/notifications.php');
      this.list = res.data?.notifications || [];
      this.unread = this.list.filter(n => !n.is_read).length;
      this.updateBadge();
    } catch (e) {
      console.error('Notifications load error:', e);
    }
  },

  updateBadge() {
    const badge = document.getElementById('notif-badge');
    if (badge) {
      badge.style.display = this.unread > 0 ? 'block' : 'none';
    }
  },

  open() {
    this.render();
    UI.openModal('modal-notifications');
  },

  render() {
    const container = document.getElementById('notifications-list');
    if (!container) return;

    if (this.list.length === 0) {
      container.innerHTML = `
        <div style="text-align:center; padding:40px 20px; color:var(--text-muted);">
          <div style="font-size:32px; margin-bottom:8px;">🔔</div>
          <div style="font-size:14px; font-weight:600;">No notifications yet</div>
          <div style="font-size:12px; margin-top:4px;">You'll see updates about expenses, settlements, and trip activity here.</div>
        </div>
      `;
      return;
    }

    container.innerHTML = this.list.map(n => {
      const iconMap = {
        expense_added: 'receipt',
        expense_updated: 'edit',
        settlement_made: 'check-circle',
        member_joined: 'user-plus',
        member_removed: 'user-minus',
        trip_updated: 'settings'
      };
      const icon = iconMap[n.type] || 'bell';
      const bg = n.is_read ? 'var(--bg-subtle)' : 'var(--primary-bg)';

      return `
        <div class="tx-item" style="background:${bg}; border-radius:10px; margin-bottom:6px;" onclick="Notifications.markRead(${n.id})">
          <div class="tx-left">
            <div class="tx-icon-box" style="background:var(--bg-subtle); color:var(--text-muted);">
              <i data-lucide="${icon}"></i>
            </div>
            <div class="tx-details">
              <span class="tx-title" style="font-size:13px;">${UI.escapeHtml(n.message)}</span>
              <span class="tx-meta" style="font-size:11px;">${n.formatted_date || ''}</span>
            </div>
          </div>
        </div>
      `;
    }).join('');

    if (window.lucide) lucide.createIcons();
  },

  async markRead(id) {
    try {
      await API.post('api/notifications.php', { action: 'mark_read', id });
      const notif = this.list.find(n => n.id === id);
      if (notif && !notif.is_read) {
        notif.is_read = 1;
        this.unread--;
        this.updateBadge();
      }
    } catch (e) {
      console.error(e);
    }
  },

  async markAllRead() {
    try {
      await API.post('api/notifications.php', { action: 'mark_all_read' });
      this.list.forEach(n => n.is_read = 1);
      this.unread = 0;
      this.updateBadge();
      this.render();
    } catch (e) {
      console.error(e);
    }
  }
};
