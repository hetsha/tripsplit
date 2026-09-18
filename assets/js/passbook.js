/**
 * TripBook Passbook Module
 * Shows all transactions in chronological order with running balance (like bank passbook)
 */

const Passbook = {
    data: null,
    currentTripId: 0,
    currentType: 'all',
    currency: '₹',

    async load() {
        try {
            const params = {
                user_id: Dashboard.data?.current_user?.id || 0,
                trip_id: this.currentTripId || API.activeTripId || 0,
                type: this.currentType
            };
            
            const res = await API.get('api/passbook.php', params);
            this.data = res.data;
            this.currency = Dashboard.data?.trip_info?.currency_symbol || '₹';
            this.render();
        } catch (err) {
            console.error('Passbook load error:', err);
        }
    },

    render() {
        const container = document.getElementById('passbook-list');
        if (!container || !this.data) return;

        const { entries, summary } = this.data;

        // Render summary
        const summaryHtml = `
            <div class="passbook-summary">
                <div class="summary-row">
                    <span>Total Credits</span>
                    <span class="positive">+${this.currency}${summary.total_credits.toFixed(2)}</span>
                </div>
                <div class="summary-row">
                    <span>Total Debits</span>
                    <span class="negative">-${this.currency}${summary.total_debits.toFixed(2)}</span>
                </div>
                <div class="summary-row final">
                    <span>Final Balance</span>
                    <span class="${summary.final_balance >= 0 ? 'positive' : 'negative'}">${this.currency}${Math.abs(summary.final_balance).toFixed(2)}</span>
                </div>
            </div>
        `;

        // Render filters
        const filterHtml = `
            <div class="passbook-filters">
                <select onchange="Passbook.setTrip(this.value)" class="form-control-sm">
                    <option value="0">All Trips</option>
                    ${this.renderTripOptions()}
                </select>
                <select onchange="Passbook.setType(this.value)" class="form-control-sm">
                    <option value="all" ${this.currentType === 'all' ? 'selected' : ''}>All Types</option>
                    <option value="expense" ${this.currentType === 'expense' ? 'selected' : ''}>Expenses</option>
                    <option value="income" ${this.currentType === 'income' ? 'selected' : ''}>Income</option>
                    <option value="settlement" ${this.currentType === 'settlement' ? 'selected' : ''}>Settlements</option>
                </select>
            </div>
        `;

        // Render entries (bank passbook style)
        let entriesHtml = '';
        if (entries.length === 0) {
            entriesHtml = '<div class="empty-state">No transactions found</div>';
        } else {
            entriesHtml = `
                <table class="passbook-table">
                    <thead>
                        <tr>
                            <th>Date</th>
                            <th>Description</th>
                            <th>Credit</th>
                            <th>Debit</th>
                            <th>Balance</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${entries.map(entry => `
                            <tr>
                                <td class="date-cell">${this.formatDate(entry.date)}</td>
                                <td class="desc-cell">
                                    <div class="desc-main">${UI.escapeHtml(entry.description)}</div>
                                    <div class="desc-meta">
                                        ${entry.trip_name ? `<span class="trip-tag">${UI.escapeHtml(entry.trip_name)}</span>` : ''}
                                        ${entry.category ? `<span class="cat-tag" style="color: ${entry.category_color}">${entry.category}</span>` : ''}
                                    </div>
                                </td>
                                <td class="credit-cell">${entry.credit > 0 ? `<span class="positive">+${this.currency}${entry.credit.toFixed(2)}</span>` : '—'}</td>
                                <td class="debit-cell">${entry.debit > 0 ? `<span class="negative">-${this.currency}${entry.debit.toFixed(2)}</span>` : '—'}</td>
                                <td class="balance-cell ${entry.balance >= 0 ? 'positive' : 'negative'}">${this.currency}${Math.abs(entry.balance).toFixed(2)}</td>
                            </tr>
                        `).join('')}
                    </tbody>
                </table>
            `;
        }

        container.innerHTML = summaryHtml + filterHtml + entriesHtml;
        
        // Re-render Lucide icons
        if (window.lucide) {
            lucide.createIcons();
        }
    },

    renderTripOptions() {
        if (!Auth.authData?.trips) return '';
        return Auth.authData.trips.map(trip => 
            `<option value="${trip.id}" ${this.currentTripId == trip.id ? 'selected' : ''}>${UI.escapeHtml(trip.name)}</option>`
        ).join('');
    },

    setTrip(tripId) {
        this.currentTripId = parseInt(tripId);
        this.load();
    },

    setType(type) {
        this.currentType = type;
        this.load();
    },

    formatDate(dateStr) {
        const date = new Date(dateStr);
        return date.toLocaleDateString('en-US', { 
            day: '2-digit', 
            month: 'short', 
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
    },

    openModal() {
        this.currentTripId = this.currentTripId || API.activeTripId || 0;
        UI.openModal('modal-passbook');
        this.load();
    }
};
