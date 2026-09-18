/**
 * TripBook Dashboard Module
 */

const Dashboard = {
  data: null,

  async load() {
    try {
      const res = await API.get('api/dashboard.php');
      this.render(res.data);
    } catch (e) {
      console.error('Dashboard load error:', e);
    }
  },

  render(data) {
    this.data = data;
    const { expense_summary, who_owes_whom, member_balances, recent_transactions, current_user } = data;
    const currency = data.trip_info?.currency_symbol || '₹';
    const totalExpenses = Number(expense_summary?.total_all_expenses || 0);

    // 1. Render Hero Card — Total Trip Expenses
    const heroContainer = document.getElementById('dashboard-hero-money');
    if (heroContainer) {
      const myBalance = member_balances.find(b => b.user_id == current_user.id);
      const myOwed = myBalance ? Number(myBalance.net_balance) : 0;
      const isPositive = myOwed >= 0;
      const memberCount = member_balances.length;

      heroContainer.innerHTML = `
        <div class="card hero-money-card">
          <div class="card-header">
            <span class="card-title" style="color:rgba(255,255,255,0.75);">
              <i data-lucide="receipt" style="width:14px;height:14px;"></i> Total Trip Expenses
            </span>
            <span class="trip-code-pill" onclick="App.copyInviteCode('${data.trip_info.trip_code}')">
              ${data.trip_info.trip_code} <i data-lucide="copy" style="width:11px;height:11px;"></i>
            </span>
          </div>

          <div class="hero-amount">
            ${currency}${totalExpenses.toLocaleString('en-IN')}
          </div>
          <div class="hero-subtitle" style="color:rgba(255,255,255,0.55); margin-bottom:18px;">
            <span>All expenses across the trip</span>
          </div>

          <div class="hero-stats-row">
            <div class="hero-stat-col">
              <span class="hero-stat-label">Members</span>
              <span class="hero-stat-val">${memberCount}</span>
            </div>
            <div class="hero-stat-col">
              <span class="hero-stat-label">You ${isPositive ? 'Get' : 'Owe'}</span>
              <span class="hero-stat-val" style="color: ${isPositive ? 'var(--success-dark)' : 'var(--danger-dark)'}">
                ${currency}${Math.abs(myOwed).toLocaleString('en-IN')}
              </span>
            </div>
          </div>
        </div>
      `;
    }

    // 2. Render Expense Breakdown Summary SVG Donut Chart
    const categoryContainer = document.getElementById('dashboard-category-spending');
    if (categoryContainer) {
      if (!data.category_spending || data.category_spending.length === 0) {
        categoryContainer.innerHTML = `
          <div class="card">
            <div class="card-header">
              <span class="card-title"><i data-lucide="pie-chart" style="width:14px;height:14px;"></i> Spending Overview</span>
            </div>
            <div style="text-align:center; padding:32px; color:var(--text-secondary);">No spending tracked yet</div>
          </div>
        `;
      } else {
        const totalSpend = data.category_spending.reduce((sum, c) => sum + Number(c.amount), 0);
        let accumulatedPercent = 0;
        let paths = '';
        const circumference = 376.99;
        
        data.category_spending.forEach((c, idx) => {
          const amt = Number(c.amount);
          if (amt <= 0) return;
          const pct = (amt / totalSpend) * 100;
          const strokeDashArray = `${(pct / 100) * circumference} ${circumference}`;
          const strokeDashOffset = -((accumulatedPercent / 100) * circumference);
          
          paths += `
            <circle class="donut-segment" id="donut-seg-${idx}" cx="80" cy="80" r="60" 
                    fill="transparent" stroke="${c.color}" stroke-width="12" 
                    stroke-dasharray="${strokeDashArray}" stroke-dashoffset="${strokeDashOffset}" 
                    transform="rotate(-90 80 80)" 
                    style="transition: all 0.2s ease; cursor: pointer;"
                    onmouseover="document.getElementById('legend-item-${idx}').classList.add('highlighted'); this.setAttribute('stroke-width', '16');"
                    onmouseout="document.getElementById('legend-item-${idx}').classList.remove('highlighted'); this.setAttribute('stroke-width', '12');"
                    title="${c.name}: ${currency}${amt.toLocaleString('en-IN')}">
            </circle>
          `;
          accumulatedPercent += pct;
        });

        if (paths === '') {
          paths = `<circle cx="80" cy="80" r="60" fill="transparent" stroke="rgba(255,255,255,0.06)" stroke-width="12"></circle>`;
        }

        const legendHtml = data.category_spending.map((c, idx) => {
          const amt = Number(c.amount);
          const pct = totalSpend > 0 ? ((amt / totalSpend) * 100).toFixed(0) : '0';
          return `
            <div class="legend-item" id="legend-item-${idx}" 
                 onmouseover="document.getElementById('donut-seg-${idx}')?.setAttribute('stroke-width', '16');" 
                 onmouseout="document.getElementById('donut-seg-${idx}')?.setAttribute('stroke-width', '12');">
              <span class="legend-dot" style="background:${c.color}"></span>
              <span class="legend-icon">${c.icon || '📁'}</span>
              <span class="legend-name">${UI.escapeHtml(c.name)}</span>
              <span class="legend-pct">${pct}%</span>
              <span class="legend-amount">${currency}${amt.toLocaleString('en-IN')}</span>
            </div>
          `;
        }).join('');

        categoryContainer.innerHTML = `
          <div class="card">
            <div class="card-header">
              <span class="card-title"><i data-lucide="pie-chart" style="width:14px;height:14px;"></i> Spending Overview</span>
              <span style="font-size:12px; color:var(--text-secondary); font-weight:700;">${currency}${totalSpend.toLocaleString('en-IN')}</span>
            </div>
            
            <div class="donut-chart-wrapper">
              <div class="donut-svg-container">
                <svg width="160" height="160" viewBox="0 0 160 160">
                  ${paths}
                </svg>
                <div class="donut-inner-text">
                  <span class="inner-val">${currency}${totalSpend.toLocaleString('en-IN', {maximumFractionDigits:0})}</span>
                  <span class="inner-lbl">Spent</span>
                </div>
              </div>
              
              <div class="donut-legend">
                ${legendHtml}
              </div>
            </div>
          </div>
        `;
      }
    }

    // 3. Render Who Owes Whom (Settlements)
    const settleContainer = document.getElementById('dashboard-settlements');
    if (settleContainer) {
      const mySettlements = who_owes_whom.filter(s =>
        s.from_user_id == current_user.id || s.to_user_id == current_user.id
      );

      if (mySettlements.length === 0) {
        settleContainer.innerHTML = `
          <div class="card" style="height: 100%; display: flex; flex-direction: column;">
            <div class="card-header">
              <span class="card-title"><i data-lucide="check-circle-2" style="width:14px;height:14px;"></i> Who Owes Whom</span>
            </div>
            <div style="display:flex; flex-direction:column; align-items:center; justify-content:center; flex:1; padding:32px 16px; text-align:center;">
              <span style="font-size:40px; margin-bottom:12px;">🎉</span>
              <div style="color:var(--success-dark); font-weight:800; font-size:15px; margin-bottom:4px;">You're all settled up!</div>
              <div style="font-size:12px; color:var(--text-secondary);">No outstanding debts in this trip group.</div>
            </div>
          </div>
        `;
      } else {
        const itemsHtml = mySettlements.map(s => {
          const isDebtor = s.from_user_id == current_user.id;
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

        settleContainer.innerHTML = `
          <div class="card" style="height: 100%; display: flex; flex-direction: column;">
            <div class="card-header">
              <span class="card-title"><i data-lucide="arrow-left-right" style="width:14px;height:14px;"></i> Who Owes Whom</span>
            </div>
            <div class="settlements-list" style="display:flex; flex-direction:column; gap:8px;">
              ${itemsHtml}
            </div>
          </div>
        `;
      }
    }

    // 4. Render Member Balances
    const balancesContainer = document.getElementById('dashboard-member-balances');
    if (balancesContainer && member_balances) {
      const itemsHtml = member_balances.map(b => {
        const net = Number(b.net_balance);
        const isPositive = net >= 0;
        const colorClass = net === 0 ? 'neutral' : (isPositive ? 'positive' : 'negative');
        const sign = net > 0 ? '+' : '';
        
        return `
          <div class="member-balance-item">
            <div class="member-info-left">
              <div class="member-avatar" style="background:${b.avatar_color || 'var(--primary)'}">
                ${b.name.charAt(0).toUpperCase()}
              </div>
              <div class="member-name-wrap">
                <span class="member-name">${UI.escapeHtml(b.name)}</span>
                <span class="member-subtext">Paid: ${currency}${Number(b.total_paid).toLocaleString('en-IN')} • Share: ${currency}${Number(b.total_share).toLocaleString('en-IN')}</span>
              </div>
            </div>
            <div class="balance-badge ${colorClass}">
              ${sign}${currency}${net.toLocaleString('en-IN')}
            </div>
          </div>
        `;
      }).join('');

      balancesContainer.innerHTML = `
        <div class="card">
          <div class="card-header">
            <span class="card-title"><i data-lucide="users" style="width:14px;height:14px;"></i> Member Balances</span>
            <span style="font-size:12px; color:var(--text-secondary); font-weight:700;">${member_balances.length} Members</span>
          </div>
          <div style="display:flex; flex-direction:column; gap:2px;">
            ${itemsHtml}
          </div>
        </div>
      `;
    }

    // 6. Render Recent Transactions
    const recentTxContainer = document.getElementById('dashboard-recent-transactions');
    if (recentTxContainer) {
      if (recent_transactions.length === 0) {
        recentTxContainer.innerHTML = `
          <div class="empty-state">
            <div class="empty-icon">🧾</div>
            <div class="empty-title">No expenses yet</div>
            <div class="empty-subtext">Tap + Expense below to record your first trip expense!</div>
          </div>
        `;
      } else {
        const txHtml = recent_transactions.map(tx => Transactions.renderTransactionItem(tx, currency)).join('');
        recentTxContainer.innerHTML = `
          <div class="card">
            <div class="card-header">
              <span class="card-title"><i data-lucide="receipt"></i> Recent Transactions</span>
              <a href="javascript:void(0)" onclick="App.switchTab('history')" style="font-size:12px; font-weight:700; color:var(--primary); text-decoration:none;">View All →</a>
            </div>
            <div class="tx-list">
              ${txHtml}
            </div>
          </div>
        `;
      }
    }

    // Re-initialize lucide icons
    if (window.lucide) {
      lucide.createIcons();
    }
  },

  async openCashbookModal(userId) {
    const currentUserId = Dashboard.data?.current_user?.id;
    if (userId !== currentUserId) {
      UI.showToast('You can only view your own CashBook', 'error');
      return;
    }

    const modalBody = document.getElementById('cashbook-details-body');
    const modalTitle = document.getElementById('cashbook-modal-title');
    const currency = Dashboard.data?.trip_info?.currency_symbol || '₹';

    if (!modalBody) return;

    modalBody.innerHTML = `<div style="text-align:center; padding:30px; color:var(--text-muted);">Loading CashBook ledger...</div>`;
    UI.openModal('modal-cashbook-ledger');

    try {
      const res = await API.get('api/members.php', { action: 'cashbook' });
      const { user, cashbook } = res.data;

      if (modalTitle) {
        modalTitle.innerText = `${user.name}'s CashBook Ledger`;
      }

      const entries = cashbook.entries || [];
      const entriesHtml = entries.length === 0 ? `
        <div class="empty-state" style="padding:20px 0;">
          <div class="empty-icon"><i data-lucide="book-open" style="width:48px;height:48px;"></i></div>
          <div class="empty-title">No cash transactions yet</div>
          <div class="empty-subtext">Expenses, pool contributions, and settlements will appear here.</div>
        </div>
      ` : entries.map(e => {
        const isIn = e.type === 'in';
        const sign = isIn ? '+' : '-';
        const color = isIn ? 'var(--success-dark)' : 'var(--danger-dark)';
        const bg = isIn ? '#ecfdf5' : '#fef2f2';

        return `
          <div class="tx-item" style="background:#ffffff; margin-bottom:8px;">
            <div class="tx-left">
              <div class="tx-icon-box" style="background:${bg}; color:${color};">
                <i data-lucide="${isIn ? 'arrow-down-left' : 'arrow-up-right'}"></i>
              </div>
              <div class="tx-details">
                <span class="tx-title">${UI.escapeHtml(e.description)}</span>
                <span class="tx-meta">${e.payment_method_icon} ${e.payment_method_label} • ${e.category_name}</span>
                <span style="font-size:11px; color:var(--text-light); margin-top:2px;">${e.formatted_date}</span>
              </div>
            </div>
            <div class="tx-right">
              <span class="tx-amount" style="color:${color}; font-size:15px; font-weight:800;">
                ${sign}${currency}${Number(e.amount).toLocaleString('en-IN')}
              </span>
              <span style="font-size:10px; font-weight:700; text-transform:uppercase; color:${color}; background:${bg}; padding:1px 4px; border-radius:4px; margin-top:2px;">
                ${isIn ? 'IN / ADDED' : 'OUT / PAID'}
              </span>
            </div>
          </div>
        `;
      }).join('');

      modalBody.innerHTML = `
        <div class="expense-summary-grid" style="margin-bottom:14px;">
          <div class="summary-stat-box" style="background:#ecfdf5; border:1px solid #a7f3d0;">
            <div class="summary-stat-label" style="color:#047857; font-weight:700;">🟢 Total Money In</div>
            <div class="summary-stat-val" style="color:#047857;">+${currency}${Number(cashbook.total_in).toLocaleString('en-IN')}</div>
          </div>
          <div class="summary-stat-box" style="background:#fef2f2; border:1px solid #fecaca;">
            <div class="summary-stat-label" style="color:#b91c1c; font-weight:700;">🔴 Total Money Out</div>
            <div class="summary-stat-val" style="color:#b91c1c;">-${currency}${Number(cashbook.total_out).toLocaleString('en-IN')}</div>
          </div>
        </div>

        <div style="display:flex; justify-content:space-between; align-items:center; background:#f8fafc; padding:10px 14px; border-radius:10px; font-size:13px; margin-bottom:14px;">
          <span style="color:var(--text-muted); font-weight:600;">Net Personal Outflow</span>
          <strong style="font-size:16px; color:var(--text-main);">${currency}${Number(cashbook.net_outflow).toLocaleString('en-IN')}</strong>
        </div>

        <div style="font-size:12px; font-weight:700; color:var(--text-muted); text-transform:uppercase; margin-bottom:8px;">
          Itemized CashBook Entries (${entries.length})
        </div>
        <div class="tx-list">
          ${entriesHtml}
        </div>
      `;

      if (window.lucide) lucide.createIcons();
    } catch (e) {
      console.error(e);
      modalBody.innerHTML = `<div style="text-align:center; color:var(--danger); padding:20px;">Failed to load CashBook ledger.</div>`;
    }
  }
};
