/**
 * TripBook People Screen Module
 */

const People = {
  init() {
    this.bindEvents();
  },

  bindEvents() {
    const form = document.getElementById('form-add-member');
    if (form) {
      form.addEventListener('submit', (e) => this.handleAddMember(e));
    }
  },

  async load() {
    try {
      const res = await API.get('api/members.php');
      this.render(res.data.members || []);
    } catch (e) {
      console.error(e);
    }
  },

  render(members) {
    const container = document.getElementById('people-members-list');
    if (!container) return;

    const currency = Dashboard.data?.trip_info?.currency_symbol || '₹';
    const currentUserId = Dashboard.data?.current_user?.id;

    container.innerHTML = members.map(m => {
      const b = m.balance_info || {};
      const isMe = m.id === currentUserId;
      const net = b.net_balance || 0;
      const isPos = net > 0.01;
      const isNeg = net < -0.01;
      const badgeClass = isPos ? 'positive' : (isNeg ? 'negative' : 'neutral');
      const sign = isPos ? '+' : '';
      const badgeText = `${sign}${currency}${Math.abs(net).toLocaleString('en-IN', {minimumFractionDigits: 2})}`;

      return `
        <div class="card" style="padding:16px; margin-bottom:12px;">
          <div style="display:flex; justify-content:space-between; align-items:flex-start;">
            <div style="display:flex; align-items:center; gap:12px;">
              <div class="member-avatar" style="background-color:${m.avatar_color || 'var(--primary)'}; width:44px; height:44px; font-size:18px;">
                ${m.name.charAt(0).toUpperCase()}
              </div>
              <div>
                <div style="font-size:16px; font-weight:800; color:var(--text-primary);">
                  ${UI.escapeHtml(m.name)} ${isMe ? '<span style="font-size:12px; color:var(--primary); font-weight:700;">(You)</span>' : ''}
                </div>
                <div style="font-size:12px; color:var(--text-secondary); text-transform:uppercase; font-weight:600; letter-spacing:0.5px; margin-top:2px;">${m.role.toUpperCase()}</div>
              </div>
            </div>
            <div style="display:flex; align-items:center; gap:10px;">
              <div class="balance-badge ${badgeClass}" style="font-size:13px; font-weight:800; padding:4px 10px;">
                ${badgeText}
              </div>
              ${!isMe ? `
                <button onclick="People.removeMember(${m.id}, '${m.name.replace(/'/g, "\\'")}')" style="background:rgba(239, 68, 68, 0.1); border:none; color:var(--danger); cursor:pointer; padding:6px; border-radius:50%; display:flex; align-items:center; justify-content:center; width:28px; height:28px; transition: all var(--transition-fast);" onmouseover="this.style.background='rgba(239, 68, 68, 0.2)'" onmouseout="this.style.background='rgba(239, 68, 68, 0.1)'">
                  <i data-lucide="user-minus" style="width:14px; height:14px;"></i>
                </button>
              ` : ''}
            </div>
          </div>

          <div style="display:grid; grid-template-columns:1fr 1fr; gap:10px; margin-top:14px; padding-top:12px; border-top:1px solid var(--border);">
            <div style="background:rgba(255,255,255,0.01); border:1px solid var(--border); padding:10px 12px; border-radius:8px;">
              <span style="font-size:11px; color:var(--text-secondary); display:block; margin-bottom:2px; font-weight:600;">Total Paid for Group</span>
              <strong style="font-size:14px; color:var(--text-primary);">${currency}${Number(b.total_paid || 0).toLocaleString('en-IN')}</strong>
            </div>
            <div style="background:rgba(255,255,255,0.01); border:1px solid var(--border); padding:10px 12px; border-radius:8px;">
              <span style="font-size:11px; color:var(--text-secondary); display:block; margin-bottom:2px; font-weight:600;">Total Share Benefited</span>
              <strong style="font-size:14px; color:var(--text-primary);">${currency}${Number(b.total_share || 0).toLocaleString('en-IN')}</strong>
            </div>
          </div>

          <button class="btn-primary-large" style="margin-top:12px; height:38px; font-size:12px; background:rgba(255,255,255,0.02); color:var(--text-primary); border:1px solid var(--border); box-shadow:none; font-weight:700;" onclick="Dashboard.openCashbookModal(${m.id})">
            <i data-lucide="book-open" style="width:12px;height:12px;"></i> View CashBook Ledger →
          </button>
        </div>
      `;
    }).join('');

    if (window.lucide) lucide.createIcons();
  },

  openAddMemberModal() {
    document.getElementById('form-add-member').reset();
    UI.openModal('modal-add-member');
  },

  async handleAddMember(e) {
    e.preventDefault();
    const name = document.getElementById('new-member-name').value.trim();
    const email = document.getElementById('new-member-email').value.trim();
    const phone = document.getElementById('new-member-phone').value.trim();

    try {
      await API.post('api/members.php', { action: 'add', name, email, phone });
      UI.showToast(`Added ${name} to the trip!`, 'success');
      UI.closeModal('modal-add-member');
      App.refreshData();
    } catch (e) {
      console.error(e);
    }
  },

  async removeMember(userId, userName) {
    if (!confirm(`Remove ${userName} from this trip?`)) return;

    try {
      await API.post('api/members.php', { action: 'remove', user_id: userId });
      UI.showToast(`${userName} removed from trip`, 'success');
      this.load();
    } catch (e) {
      console.error(e);
    }
  }
};
