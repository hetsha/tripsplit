/**
 * TripBook CashBook Module
 * Shows all expenses (personal + shared) with running balance
 * Also handles adding personal cash/income
 */

const CashBook = {
    data: null,
    currentFilter: 'all',
    currency: '₹',

    async load() {
        try {
            const params = {
                user_id: Dashboard.data?.current_user?.id || 0,
                trip_id: API.activeTripId || 0,
                type: this.currentFilter
            };
            
            const res = await API.get('api/cashbook.php', params);
            this.data = res.data;
            this.currency = Dashboard.data?.trip_info?.currency_symbol || '₹';
            this.render();
        } catch (err) {
            console.error('CashBook load error:', err);
        }
    },

    render() {
        const container = document.getElementById('cashbook-list');
        if (!container || !this.data) return;

        const { entries, summary } = this.data;

        // Render summary card
        const summaryHtml = `
            <div class="card cashbook-summary">
                <div class="cashbook-balance">
                    <div class="balance-label">Net Balance</div>
                    <div class="balance-amount ${summary.net_balance >= 0 ? 'positive' : 'negative'}">
                        ${this.currency}${Math.abs(summary.net_balance).toFixed(2)}
                    </div>
                </div>
                <div class="cashbook-stats">
                    <div class="stat-item">
                        <span class="stat-label">Total Income</span>
                        <span class="stat-value positive">+${this.currency}${summary.total_income.toFixed(2)}</span>
                    </div>
                    <div class="stat-item">
                        <span class="stat-label">Personal Expenses</span>
                        <span class="stat-value negative">-${this.currency}${summary.total_personal.toFixed(2)}</span>
                    </div>
                    <div class="stat-item">
                        <span class="stat-label">Shared Expenses</span>
                        <span class="stat-value negative">-${this.currency}${summary.total_shared.toFixed(2)}</span>
                    </div>
                    <div class="stat-item">
                        <span class="stat-label">Settlements Paid</span>
                        <span class="stat-value negative">-${this.currency}${summary.total_settlements_paid.toFixed(2)}</span>
                    </div>
                    <div class="stat-item">
                        <span class="stat-label">Settlements Received</span>
                        <span class="stat-value positive">+${this.currency}${summary.total_settlements_received.toFixed(2)}</span>
                    </div>
                </div>
            </div>
        `;

        // Render filter buttons + Add Cash button
        const filterHtml = `
            <div style="display:flex; gap:8px; align-items:center; margin-bottom:12px;">
                <div class="cashbook-filters" style="flex:1;">
                    <button class="filter-btn ${this.currentFilter === 'all' ? 'active' : ''}" onclick="CashBook.setFilter('all')">All</button>
                    <button class="filter-btn ${this.currentFilter === 'personal' ? 'active' : ''}" onclick="CashBook.setFilter('personal')">Personal</button>
                    <button class="filter-btn ${this.currentFilter === 'shared' ? 'active' : ''}" onclick="CashBook.setFilter('shared')">Shared</button>
                </div>
                <button class="btn-settle-action" onclick="CashBook.openAddCash()" style="white-space:nowrap; font-size:13px;">
                    + Add Cash
                </button>
            </div>
        `;

        // Render entries
        let entriesHtml = '';
        if (entries.length === 0) {
            entriesHtml = '<div class="empty-state">No transactions found</div>';
        } else {
            entriesHtml = entries.map(entry => {
                const isIncome = entry.type === 'income' || entry.type === 'settlement_received';
                const typeLabels = {
                    'income': 'Income',
                    'shared': 'Shared',
                    'personal': 'Personal',
                    'settlement_paid': 'Settlement',
                    'settlement_received': 'Settlement'
                };
                const badgeLabel = typeLabels[entry.type] || 'Personal';
                const badgeClass = isIncome ? 'badge-income' : (entry.type === 'shared' ? 'badge-shared' : (entry.type === 'settlement_paid' ? 'badge-shared' : (entry.type === 'settlement_received' ? 'badge-income' : 'badge-personal')));
                return `
                <div class="cashbook-entry">
                    <div class="entry-left">
                        <div class="entry-icon" style="background: ${entry.category_color || (isIncome ? '#10b981' : '#ef4444')}20; color: ${entry.category_color || (isIncome ? '#10b981' : '#ef4444')}">
                            <i data-lucide="${entry.category_icon || (isIncome ? 'trending-up' : 'trending-down')}"></i>
                        </div>
                        <div class="entry-info">
                            <div class="entry-desc">${UI.escapeHtml(entry.description)}</div>
                            <div class="entry-meta">
                                <span class="badge ${badgeClass}">${badgeLabel}</span>
                                ${entry.trip_name ? `<span class="entry-trip">${UI.escapeHtml(entry.trip_name)}</span>` : ''}
                                <span class="entry-date">${this.formatDate(entry.date)}</span>
                            </div>
                        </div>
                    </div>
                    <div class="entry-right">
                        <div class="entry-amount ${isIncome ? 'positive' : 'negative'}">${isIncome ? '+' : '-'}${this.currency}${Math.abs(entry.amount).toFixed(2)}</div>
                        <div class="entry-balance">Bal: ${this.currency}${entry.balance.toFixed(2)}</div>
                    </div>
                </div>
            `}).join('');
        }

        container.innerHTML = summaryHtml + filterHtml + `<div class="cashbook-entries">${entriesHtml}</div>`;
        
        // Re-render Lucide icons
        if (window.lucide) {
            lucide.createIcons();
        }
    },

    setFilter(filter) {
        this.currentFilter = filter;
        this.load();
    },

    formatDate(dateStr) {
        const date = new Date(dateStr);
        const now = new Date();
        const diff = now - date;
        
        // Less than 24 hours ago
        if (diff < 86400000) {
            return date.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' });
        }
        
        // Less than 7 days ago
        if (diff < 604800000) {
            return date.toLocaleDateString('en-US', { weekday: 'short' });
        }
        
        // Otherwise show date
        return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
    },

    openModal() {
        UI.openModal('modal-cashbook');
        this.load();
    },

    /**
     * Open Add Cash/Income modal
     */
    openAddCash() {
        document.getElementById('add-cash-type').value = 'income';
        document.getElementById('add-cash-amount').value = '';
        document.getElementById('add-cash-desc').value = '';
        document.getElementById('add-cash-method').value = 'cash';
        UI.closeModal('modal-cashbook');
        UI.openModal('modal-add-cash');
    },

    /**
     * Submit add cash/income form
     */
    async handleAddCash(e) {
        e.preventDefault();

        const type = document.getElementById('add-cash-type').value;
        const amount = parseFloat(document.getElementById('add-cash-amount').value);
        const description = document.getElementById('add-cash-desc').value.trim();
        const paymentMethod = document.getElementById('add-cash-method').value;

        if (!amount || amount <= 0) {
            UI.showToast('Please enter a valid amount', 'error');
            return;
        }

        if (!description) {
            UI.showToast('Please enter a description', 'error');
            return;
        }

        try {
            const res = await API.post('api/cashbook.php?action=add', {
                type: type,
                amount: amount,
                description: description,
                payment_method: paymentMethod
            });

            if (res.success) {
                UI.closeModal('modal-add-cash');
                UI.showToast(`${type === 'income' ? 'Income' : 'Expense'} added successfully`, 'success');
                this.load();
                UI.openModal('modal-cashbook');
            }
        } catch (err) {
            UI.showToast('Failed to add entry', 'error');
        }
    }
};
