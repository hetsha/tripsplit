/**
 * TripBook Transactions Screen Module
 */

const Transactions = {
  list: [],
  selectedFilter: 'all',

  init() {
    this.bindEvents();
  },

  bindEvents() {
    const searchInput = document.getElementById('tx-search-input');
    if (searchInput && !searchInput._bound) {
      searchInput._bound = true;
      searchInput.addEventListener('input', () => this.filterAndRender());
    }
  },

  async load() {
    try {
      const res = await API.get('api/transactions.php');
      this.list = res.data.transactions || [];
      this.filterAndRender();
    } catch (e) {
      console.error(e);
    }
  },

  setFilter(type, btn) {
    this.selectedFilter = type;
    document.querySelectorAll('.tx-filter-chip').forEach(c => c.classList.remove('active'));
    if (btn) btn.classList.add('active');
    this.filterAndRender();
  },

  filterAndRender() {
    const container = document.getElementById('transactions-full-list');
    if (!container) return;

    const searchTerm = (document.getElementById('tx-search-input')?.value || '').toLowerCase();
    const filtered = this.list.filter(tx => {
      // Type filter
      if (this.selectedFilter !== 'all' && tx.type !== this.selectedFilter) return false;
      // Search
      if (searchTerm && !tx.description.toLowerCase().includes(searchTerm) && !(tx.notes || '').toLowerCase().includes(searchTerm)) return false;
      return true;
    });

    if (filtered.length === 0) {
      container.innerHTML = `
        <div class="empty-state">
          <div class="empty-icon">🔍</div>
          <div class="empty-title">No matching transactions</div>
        <div style="text-align:center; padding:48px 24px; color:var(--text-secondary);">
          <i data-lucide="receipt" style="width:48px; height:48px; margin-bottom:16px; opacity:0.3; stroke-width:1.5;"></i>
          <p style="font-size:14px; font-weight:600; margin:0;">No transactions found</p>
        </div>
      `;
      lucide.createIcons();
      return;
    }

    const currency = Dashboard.data?.trip_info?.currency_symbol || '₹';
    container.innerHTML = filtered.map(tx => this.renderTransactionItem(tx, currency)).join('');
    lucide.createIcons();
  },

  renderTransactionItem(tx, currency) {
    let iconName = 'receipt';
    let iconBg = 'rgba(239, 68, 68, 0.1)';
    let iconColor = '#475569';
    let amountSign = '-';
    let amountClass = 'expense';
    let subtext = '';

    if (tx.type === 'expense') {
      iconName = tx.category_icon || 'utensils';
      iconBg = (tx.category_color || '#ef4444') + '15';
      iconColor = tx.category_color || '#ef4444';
      amountSign = '-';
      amountClass = 'expense';
      subtext = `Paid by <strong>${UI.escapeHtml(tx.payer_name || 'Member')}</strong> • ${tx.payment_method_icon || 'banknote'} ${tx.payment_method_label}`;
    } else if (tx.type === 'income') {
      iconName = 'wallet';
      iconBg = 'rgba(16, 185, 129, 0.1)';
      iconColor = '#10b981';
      amountSign = '+';
      amountClass = 'income';
      subtext = `Received by <strong>${UI.escapeHtml(tx.receiver_name || 'Pool')}</strong> • ${tx.payment_method_icon || 'banknote'} ${tx.payment_method_label}`;
    } else if (tx.type === 'settlement') {
      iconName = 'arrow-left-right';
      iconBg = 'rgba(91, 92, 255, 0.1)';
      iconColor = '#2563eb';
      amountSign = '✓ ';
      amountClass = 'settlement';
      subtext = `Settlement • ${tx.payment_method_icon || 'smartphone'} ${tx.payment_method_label}`;
    }

    const isOwner = tx.created_by === Dashboard.data?.current_user?.id;
    const isExpense = tx.type === 'expense';

    return `
      <div class="tx-item" onclick="Transactions.showDetails(${tx.id})">
        <div class="tx-left">
          <div class="tx-icon-box" style="background-color: ${iconBg}; color: ${iconColor}; border-color: ${iconColor}20;">
            <i data-lucide="${iconName}"></i>
          </div>
          <div class="tx-details">
            <span class="tx-title">${UI.escapeHtml(tx.description)}</span>
            <span class="tx-meta">${subtext}</span>
            <span style="font-size:11px; color:var(--text-secondary); margin-top:2px;">${tx.formatted_date}</span>
          </div>
        </div>
        <div class="tx-right">
          <span class="tx-amount ${amountClass}">${amountSign}${currency}${Number(tx.amount).toLocaleString('en-IN')}</span>
          ${isExpense && isOwner ? `<button onclick="event.stopPropagation(); Expenses.openEditModal({id:${tx.id}, amount:${tx.amount}, description:'${tx.description.replace(/'/g, "\\'")}', trip_id:${tx.trip_id || 'null'}, payment_method:'${tx.payment_method}', paid_by:${tx.payer_id}, category_id:${tx.category_id || 1}, notes:'${(tx.notes || '').replace(/'/g, "\\'")}'})" style="background:none; border:none; color:var(--primary); font-size:11px; font-weight:700; cursor:pointer; margin-top:4px; text-transform:uppercase; letter-spacing:0.5px;">Edit</button>` : ''}
        </div>
      </div>
    `;
  },

  showDetails(txId) {
    const tx = this.list.find(t => t.id === txId);
    if (!tx) return;

    const modalBody = document.getElementById('tx-details-body');
    const currency = Dashboard.data?.trip_info?.currency_symbol || '₹';

    let splitsHtml = '';
    if (tx.splits && tx.splits.length > 0) {
      splitsHtml = `
        <div style="margin-top:16px; padding-top:14px; border-top:1px solid var(--border);">
          <div style="font-size:11px; font-weight:800; color:var(--text-secondary); text-transform:uppercase; letter-spacing:0.5px; margin-bottom:10px;">Split Breakdown</div>
          <div style="display:flex; flex-direction:column; gap:8px;">
            ${tx.splits.map(s => `
              <div style="display:flex; justify-content:space-between; align-items:center; font-size:13px; background:rgba(255, 255, 255, 0.01); padding:8px 12px; border-radius:8px; border:1px solid var(--border);">
                <span style="font-weight:600;">${UI.escapeHtml(s.name)}</span>
                <strong style="color:var(--text-primary); font-size:14px;">${currency}${Number(s.amount).toLocaleString('en-IN')}</strong>
              </div>
            `).join('')}
          </div>
        </div>
      `;
    }

    modalBody.innerHTML = `
      <div style="text-align:center; padding-bottom:18px; border-bottom:1px solid var(--border);">
        <div style="font-size:36px; font-weight:800; color:var(--text-primary); margin-bottom:6px; background:var(--brand-gradient); -webkit-background-clip:text; -webkit-text-fill-color:transparent; display:inline-block;">
          ${currency}${Number(tx.amount).toLocaleString('en-IN')}
        </div>
        <div style="font-size:18px; font-weight:800; color:var(--text-primary); letter-spacing:-0.3px;">
          ${UI.escapeHtml(tx.description)}
        </div>
        <div style="font-size:12px; color:var(--text-secondary); margin-top:6px; font-weight:500;">
          ${tx.formatted_date}
        </div>
      </div>

      <div style="display:flex; flex-direction:column; gap:12px; margin-top:18px;">
        <div style="display:flex; justify-content:space-between; align-items:center; font-size:13px; padding:6px 0; border-bottom:1px solid rgba(255,255,255,0.02);">
          <span style="color:var(--text-secondary); font-weight:600;">Transaction Type</span>
          <strong style="text-transform:uppercase; font-size:12px; letter-spacing:0.5px; color:var(--text-primary);">${tx.type}</strong>
        </div>
        <div style="display:flex; justify-content:space-between; align-items:center; font-size:13px; padding:6px 0; border-bottom:1px solid rgba(255,255,255,0.02);">
          <span style="color:var(--text-secondary); font-weight:600;">Paid By</span>
          <strong style="color:var(--text-primary);">${UI.escapeHtml(tx.payer_name || tx.receiver_name || '-')}</strong>
        </div>
        <div style="display:flex; justify-content:space-between; align-items:center; font-size:13px; padding:6px 0; border-bottom:1px solid rgba(255,255,255,0.02);">
          <span style="color:var(--text-secondary); font-weight:600;">Payment Method</span>
          <strong style="color:var(--text-primary);">${tx.payment_method_icon} ${tx.payment_method_label}</strong>
        </div>
        ${tx.notes ? `
          <div style="font-size:13px; background:rgba(255,255,255,0.02); border:1px solid var(--border); padding:12px; border-radius:10px; margin-top:6px;">
            <span style="color:var(--text-secondary); font-size:11px; font-weight:700; text-transform:uppercase; letter-spacing:0.5px; display:block; margin-bottom:4px;">Notes</span>
            <div style="color:var(--text-primary); line-height:1.5;">${UI.escapeHtml(tx.notes)}</div>
          </div>
        ` : ''}
      </div>

      ${splitsHtml}

      <div style="margin-top:24px; display:flex; gap:10px;">
        <button class="btn-primary-large" style="background:#f87171; box-shadow:none; height:48px; font-size:14px; color:#ffffff; font-weight:700;" onclick="Transactions.deleteTransaction(${tx.id})">
          <i data-lucide="trash-2" style="width:16px;height:16px;"></i> Delete Transaction
        </button>
      </div>
    `;

    UI.openModal('modal-tx-details');
    if (window.lucide) lucide.createIcons();
  },

  async deleteTransaction(txId) {
    if (!confirm('Are you sure you want to delete this transaction? All associated splits will be removed.')) {
      return;
    }

    try {
      await API.post('api/transactions.php', { action: 'delete', id: txId });
      UI.showToast('Transaction deleted', 'success');
      UI.closeModal('modal-tx-details');
      App.refreshData();
    } catch (e) {
      console.error(e);
    }
  },

  openAddMoneyModal() {
    document.getElementById('form-add-money').reset();
    UI.openModal('modal-add-money');
  },

  async handleAddMoney(e) {
    e.preventDefault();
    const amount = parseFloat(document.getElementById('add-money-amount').value) || 0;
    const method = document.getElementById('add-money-method').value;
    const notes = document.getElementById('add-money-notes').value.trim();

    try {
      await API.post('api/transactions.php', {
        action: 'add_money',
        amount,
        payment_method: method,
        notes
      });
      UI.showToast('Money added to shared pool!', 'success');
      UI.closeModal('modal-add-money');
      App.refreshData();
    } catch (e) {
      console.error(e);
    }
  }
};
