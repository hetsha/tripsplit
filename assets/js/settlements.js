/**
 * TripBook Smart Settlements Module
 */

const Settlements = {
  data: null,

  init() {
    this.bindEvents();
  },

  bindEvents() {
    const form = document.getElementById('form-settle-up');
    if (form) {
      form.addEventListener('submit', (e) => this.handleSubmitSettle(e));
    }
  },

  async load() {
    try {
      const res = await API.get('api/settlements.php');
      this.data = res.data;
      this.render();
    } catch (e) {
      console.error(e);
    }
  },

  render() {
    if (!this.data) return;
    const { suggestions, history } = this.data;
    const currency = Dashboard.data?.trip_info?.currency_symbol || '₹';
    const currentUserId = Dashboard.data?.current_user?.id;

    // Filter suggestions to only show those involving current user
    const mySuggestions = suggestions.filter(s =>
      s.from_user_id === currentUserId || s.to_user_id === currentUserId
    );

    // Filter history to only show settlements involving current user
    const myHistory = history.filter(h =>
      h.from_user_id === currentUserId || h.to_user_id === currentUserId
    );

    // 1. Render Active Suggestions (Who Owes Whom)
    const suggestionsContainer = document.getElementById('settlements-tab-suggestions');
    if (suggestionsContainer) {
      if (mySuggestions.length === 0) {
        suggestionsContainer.innerHTML = `
          <div class="card" style="text-align:center; padding:32px 16px;">
            <div style="font-size:40px; margin-bottom:12px;">🎉</div>
            <div style="font-size:16px; font-weight:800; color:var(--success-dark);">All Balances Settled!</div>
            <div style="font-size:13px; color:var(--text-secondary); margin-top:4px;">Nobody owes you anything right now.</div>
          </div>
        `;
      } else {
        const itemsHtml = mySuggestions.map(s => {
          const isDebtor = s.from_user_id == currentUserId;
          const roleBadge = isDebtor 
            ? `<span class="balance-badge negative" style="font-size:11px; padding:2px 8px; font-weight:800;">You Pay</span>`
            : `<span class="balance-badge positive" style="font-size:11px; padding:2px 8px; font-weight:800;">You Receive</span>`;

          return `
            <div class="settlement-item" style="border-left: 3px solid ${isDebtor ? 'var(--danger)' : 'var(--success)'};">
              <div style="display:flex; flex-direction:column; gap:4px; min-width:0; flex:1; padding-right:10px;">
                <div class="settle-flow">
                  <span class="settle-debtor">${isDebtor ? 'You' : UI.escapeHtml(s.from_user_name)}</span>
                  <span class="settle-arrow">→</span>
                  <span class="settle-creditor">${!isDebtor ? 'You' : UI.escapeHtml(s.to_user_name)}</span>
                </div>
                <div style="display:flex; align-items:center; gap:6px; margin-top:2px;">
                  ${roleBadge}
                </div>
              </div>
              <div class="settle-right">
                <span class="settle-amount">${currency}${Number(s.amount).toLocaleString('en-IN')}</span>
                <button class="btn-settle-action" onclick="Settlements.openSettleModal(${s.from_user_id}, ${s.to_user_id}, ${s.amount}, '${UI.escapeHtml(s.from_user_name)}', '${UI.escapeHtml(s.to_user_name)}')">
                  <i data-lucide="zap" style="width:12px;height:12px;"></i> Settle
                </button>
              </div>
            </div>
          `;
        }).join('');

        suggestionsContainer.innerHTML = `
          <div class="card">
            <div class="card-header">
              <span class="card-title"><i data-lucide="sparkles" style="width:14px;height:14px;"></i> Recommended Settlement Plan</span>
            </div>
            <div style="font-size:12px; color:var(--text-secondary); margin-bottom:14px;">
              Minimum transactions required to completely square all group debts:
            </div>
            <div class="settlements-list" style="display:flex; flex-direction:column; gap:8px;">
              ${itemsHtml}
            </div>
          </div>
        `;
      }
    }

    // 2. Render Settlement History
    const historyContainer = document.getElementById('settlements-tab-history');
    if (historyContainer) {
      if (myHistory.length === 0) {
        historyContainer.innerHTML = `
          <div class="empty-state">
            <div class="empty-icon">📜</div>
            <div class="empty-title">No settlements yet</div>
            <div class="empty-subtext">When you settle debts, the payment records will appear here.</div>
          </div>
        `;
      } else {
        const historyHtml = myHistory.map(h => `
          <div class="tx-item">
            <div class="tx-left">
              <div class="tx-icon-box" style="background:rgba(16, 185, 129, 0.1); color:#10b981; border:1px solid rgba(16, 185, 129, 0.2);">
                <i data-lucide="check-check"></i>
              </div>
              <div class="tx-details">
                <span class="tx-title" style="color:var(--text-primary); font-weight:700;">${UI.escapeHtml(h.from_name)} paid ${UI.escapeHtml(h.to_name)}</span>
                <span class="tx-meta" style="color:var(--text-secondary);">${h.payment_method_icon} ${h.payment_method_label} • ${h.formatted_date}</span>
                ${h.notes ? `<span style="font-size:11px; color:var(--text-secondary); margin-top:2px; display:block;">${UI.escapeHtml(h.notes)}</span>` : ''}
              </div>
            </div>
            <div class="tx-right">
              <span class="tx-amount settlement" style="color:var(--success); font-weight:700;">${currency}${Number(h.amount).toLocaleString('en-IN')}</span>
              <button onclick="Settlements.undoSettlement(${h.id})" style="background:transparent; border:none; color:var(--danger); font-size:11px; font-weight:700; cursor:pointer; margin-top:4px; text-transform:uppercase; letter-spacing:0.5px;">Undo</button>
            </div>
          </div>
        `).join('');

        historyContainer.innerHTML = `
          <div class="card">
            <div class="card-header">
              <span class="card-title"><i data-lucide="history" style="width:14px;height:14px;"></i> Settled History</span>
            </div>
            <div class="tx-list">
              ${historyHtml}
            </div>
          </div>
        `;
      }
    }

    if (window.lucide) lucide.createIcons();
  },

  openSettleModal(fromUserId, toUserId, amount, fromName, toName) {
    document.getElementById('settle-from-user').value = fromUserId;
    document.getElementById('settle-to-user').value = toUserId;
    document.getElementById('settle-amount').value = amount;
    document.getElementById('settle-modal-subtitle').innerHTML = `
      <strong>${fromName}</strong> paying <strong>${toName}</strong>
    `;

    UI.openModal('modal-settle-up');
  },

  async handleSubmitSettle(e) {
    e.preventDefault();
    const fromUser = parseInt(document.getElementById('settle-from-user').value);
    const toUser = parseInt(document.getElementById('settle-to-user').value);
    const amount = parseFloat(document.getElementById('settle-amount').value) || 0;
    const method = document.getElementById('settle-method').value;
    const notes = document.getElementById('settle-notes').value.trim();

    try {
      await API.post('api/settlements.php', {
        action: 'settle',
        from_user: fromUser,
        to_user: toUser,
        amount,
        payment_method: method,
        notes
      });

      UI.showToast('Debt marked as settled!', 'success');
      UI.closeModal('modal-settle-up');
      App.refreshData();
    } catch (e) {
      console.error(e);
    }
  },

  async undoSettlement(id) {
    if (!confirm('Undo this settlement record and restore the balance?')) return;

    try {
      await API.post('api/settlements.php', { action: 'undo', id });
      UI.showToast('Settlement undone', 'success');
      App.refreshData();
    } catch (e) {
      console.error(e);
    }
  }
};
