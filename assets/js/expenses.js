/**
 * TripBook Add & Edit Expense Module
 * Handles both personal and shared expenses
 */

const Expenses = {
  currentTripMembers: [],
  categories: [],
  selectedSplitType: 'equal',
  selectedPaymentMethod: 'cash',
  selectedExpenseType: 'personal', // 'personal' or 'shared'

  init() {
    this.bindEvents();
  },

  bindEvents() {
    // Expense Type Segmented Control
    const typeBtns = document.querySelectorAll('.expense-type-btn');
    typeBtns.forEach(btn => {
      btn.addEventListener('click', () => {
        typeBtns.forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        this.selectedExpenseType = btn.dataset.type;
        this.toggleExpenseTypeUI();
      });
    });

    // Split Type Segmented Control
    const splitBtns = document.querySelectorAll('.split-type-btn');
    splitBtns.forEach(btn => {
      btn.addEventListener('click', (e) => {
        splitBtns.forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        this.selectedSplitType = btn.dataset.type;
        this.recalculateSplits();
      });
    });



    // Payment Method Pills
    const payPills = document.querySelectorAll('.expense-pay-pill');
    payPills.forEach(pill => {
      pill.addEventListener('click', () => {
        payPills.forEach(p => p.classList.remove('active'));
        pill.classList.add('active');
        this.selectedPaymentMethod = pill.dataset.method;
      });
    });

    // Amount Input change
    const amountInput = document.getElementById('expense-amount');
    if (amountInput) {
      amountInput.addEventListener('input', () => this.recalculateSplits());
    }

    // Form Submit
    const form = document.getElementById('form-add-expense');
    if (form) {
      form.addEventListener('submit', (e) => this.handleSubmit(e));
    }

    // Add Category Form
    const catForm = document.getElementById('form-add-category');
    if (catForm) {
      catForm.addEventListener('submit', (e) => {
        e.preventDefault();
        this.saveNewCategory();
      });
    }
  },

  toggleExpenseTypeUI() {
    const isPersonal = this.selectedExpenseType === 'personal';
    const splitGroup = document.getElementById('expense-split-group');
    
    if (splitGroup) {
      splitGroup.style.display = isPersonal ? 'none' : 'block';
    }
  },

  openAddModal() {
    document.getElementById('expense-sheet-title').innerText = 'Add Expense';
    document.getElementById('form-add-expense').reset();
    document.getElementById('expense-id').value = '';
    this.selectedSplitType = 'equal';
    this.selectedPaymentMethod = 'cash';
    this.selectedExpenseType = 'personal';

    // Reset segmented controls
    document.querySelectorAll('.expense-type-btn').forEach(b => b.classList.toggle('active', b.dataset.type === 'personal'));
    document.querySelectorAll('.split-type-btn').forEach(b => b.classList.toggle('active', b.dataset.type === 'equal'));
    document.querySelectorAll('.expense-pay-pill').forEach(b => b.classList.toggle('active', b.dataset.method === 'cash'));

    // Toggle UI for personal expense
    this.toggleExpenseTypeUI();

    // Populate payers & categories
    this.populateMembers();
    this.populateCategories();

    this.renderMemberCheckboxes();
    this.recalculateSplits();

    UI.openModal('modal-expense-sheet');
  },

  openEditModal(expense) {
    document.getElementById('expense-sheet-title').innerText = 'Edit Expense';
    document.getElementById('expense-id').value = expense.id;
    document.getElementById('expense-amount').value = expense.amount;
    document.getElementById('expense-desc').value = expense.description;
    document.getElementById('expense-notes').value = expense.notes || '';
    
    // Set expense type
    this.selectedExpenseType = expense.trip_id ? 'shared' : 'personal';
    document.querySelectorAll('.expense-type-btn').forEach(b => b.classList.toggle('active', b.dataset.type === this.selectedExpenseType));
    this.toggleExpenseTypeUI();

    // Set payment method
    this.selectedPaymentMethod = expense.payment_method || 'cash';
    document.querySelectorAll('.expense-pay-pill').forEach(b => b.classList.toggle('active', b.dataset.method === this.selectedPaymentMethod));

    // Populate members and set payer
    this.populateMembers();
    setTimeout(() => {
      document.getElementById('expense-payer').value = expense.paid_by;
      document.getElementById('expense-category').value = expense.category_id;
    }, 100);

    this.populateCategories();

    UI.openModal('modal-expense-sheet');
  },

  populateMembers() {
    const payerSelect = document.getElementById('expense-payer');
    if (!payerSelect || !Dashboard.data) return;

    this.currentTripMembers = Dashboard.data.member_balances || [];
    const currentUserId = Dashboard.data.current_user?.id;

    payerSelect.innerHTML = this.currentTripMembers.map(m => `
      <option value="${m.user_id}" ${m.user_id === currentUserId ? 'selected' : ''}>
        ${UI.escapeHtml(m.name)} ${m.user_id === currentUserId ? '(You)' : ''}
      </option>
    `).join('');
  },

  async populateCategories() {
    const catSelect = document.getElementById('expense-category');
    if (!catSelect) return;

    try {
      const res = await API.get('api/categories.php');
      this.categories = res.data.categories || [];
      catSelect.innerHTML = this.categories.map(c => `
        <option value="${c.id}">${UI.escapeHtml(c.name)}</option>
      `).join('');
    } catch (e) {
      console.error(e);
    }
  },

  renderMemberCheckboxes() {
    const container = document.getElementById('split-members-list');
    if (!container) return;

    container.innerHTML = this.currentTripMembers.map(m => `
      <div class="split-member-row" id="split-row-${m.user_id}">
        <div class="split-member-left">
          <input type="checkbox" class="split-check" id="split-chk-${m.user_id}" value="${m.user_id}" checked onchange="Expenses.recalculateSplits()">
          <label for="split-chk-${m.user_id}" style="font-weight:700; cursor:pointer;">${UI.escapeHtml(m.name)}</label>
        </div>
        <div class="split-member-right">
          <input type="number" step="0.01" inputmode="decimal" class="form-control split-amount-input" id="split-val-${m.user_id}" value="0.00" oninput="Expenses.handleCustomSplitInput()">
        </div>
      </div>
    `).join('');
  },

  recalculateSplits() {
    const totalAmount = parseFloat(document.getElementById('expense-amount').value) || 0;
    const isCustom = this.selectedSplitType === 'custom';

    const checkedBoxes = Array.from(document.querySelectorAll('.split-check:checked'));
    const checkedCount = checkedBoxes.length;

    this.currentTripMembers.forEach(m => {
      const input = document.getElementById(`split-val-${m.user_id}`);
      const chk = document.getElementById(`split-chk-${m.user_id}`);
      if (!input || !chk) return;

      input.disabled = !chk.checked;

      if (!isCustom) {
        input.readOnly = true;
        if (chk.checked && checkedCount > 0) {
          const share = Math.floor((totalAmount / checkedCount) * 100) / 100;
          input.value = share.toFixed(2);
        } else {
          input.value = '0.00';
        }
      } else {
        input.readOnly = false;
      }
    });

    // In equal mode, distribute pennies if any rounding discrepancy exists
    if (!isCustom && checkedCount > 0 && totalAmount > 0) {
      let sum = 0;
      checkedBoxes.forEach(chk => {
        const inp = document.getElementById(`split-val-${chk.value}`);
        sum += parseFloat(inp.value) || 0;
      });
      const diff = Math.round((totalAmount - sum) * 100) / 100;
      if (diff !== 0) {
        const firstInp = document.getElementById(`split-val-${checkedBoxes[0].value}`);
        firstInp.value = (parseFloat(firstInp.value) + diff).toFixed(2);
      }
    }

    this.updateSplitStatus();
  },

  handleCustomSplitInput() {
    if (this.selectedSplitType !== 'custom') return;
    this.updateSplitStatus();
  },

  updateSplitStatus() {
    const totalAmount = parseFloat(document.getElementById('expense-amount').value) || 0;
    const statusBar = document.getElementById('split-status-bar');
    const submitBtn = document.getElementById('btn-save-expense');
    if (!statusBar) return;

    let currentSum = 0;
    document.querySelectorAll('.split-check:checked').forEach(chk => {
      const inp = document.getElementById(`split-val-${chk.value}`);
      currentSum += parseFloat(inp.value) || 0;
    });

    currentSum = Math.round(currentSum * 100) / 100;
    const diff = Math.round((totalAmount - currentSum) * 100) / 100;

    if (totalAmount <= 0) {
      statusBar.className = 'split-status-bar warning';
      statusBar.innerHTML = `<span>Enter an amount above</span> <span>₹0.00</span>`;
      if (submitBtn) submitBtn.disabled = true;
      return;
    }

    if (Math.abs(diff) === 0) {
      statusBar.className = 'split-status-bar match';
      statusBar.innerHTML = `<span>✓ Splits exact match</span> <span>₹${totalAmount.toFixed(2)}</span>`;
      if (submitBtn) submitBtn.disabled = false;
    } else if (diff > 0) {
      statusBar.className = 'split-status-bar mismatch';
      statusBar.innerHTML = `<span>₹${diff.toFixed(2)} remaining to assign</span> <span>Sum: ₹${currentSum.toFixed(2)}</span>`;
      if (submitBtn) submitBtn.disabled = (this.selectedSplitType === 'custom');
    } else {
      statusBar.className = 'split-status-bar mismatch';
      statusBar.innerHTML = `<span>Over by ₹${Math.abs(diff).toFixed(2)}</span> <span>Sum: ₹${currentSum.toFixed(2)}</span>`;
      if (submitBtn) submitBtn.disabled = true;
    }
  },

  async handleSubmit(e) {
    e.preventDefault();
    const submitBtn = document.getElementById('btn-save-expense');
    if (submitBtn) {
      submitBtn.disabled = true;
      submitBtn.innerText = 'Saving...';
    }

    const expenseId = document.getElementById('expense-id').value;
    const amount = parseFloat(document.getElementById('expense-amount').value) || 0;
    const description = document.getElementById('expense-desc').value.trim();
    const categoryId = parseInt(document.getElementById('expense-category').value) || 1;
    const paidBy = parseInt(document.getElementById('expense-payer').value);
    const notes = document.getElementById('expense-notes').value.trim();
    const isPersonal = this.selectedExpenseType === 'personal';

    // Prepare splits (only for shared expenses)
    const splits = [];
    if (!isPersonal) {
      document.querySelectorAll('.split-check:checked').forEach(chk => {
        const uid = parseInt(chk.value);
        const val = parseFloat(document.getElementById(`split-val-${uid}`).value) || 0;
        splits.push({ user_id: uid, amount: val });
      });
    }

    const payload = {
      action: expenseId ? 'update' : 'create',
      id: expenseId ? parseInt(expenseId) : undefined,
      amount,
      description,
      category_id: categoryId,
      paid_by: paidBy,
      payment_method: this.selectedPaymentMethod,
      notes,
      splits,
      is_personal: isPersonal
    };

    try {
      const res = await API.post('api/expenses.php', payload);
      UI.showToast(res.message || 'Expense saved successfully!', 'success');
      UI.closeModal('modal-expense-sheet');
      App.refreshData();
    } catch (err) {
      console.error(err);
    } finally {
      if (submitBtn) {
        submitBtn.disabled = false;
        submitBtn.innerText = 'Save Expense';
      }
    }
  },

  openAddCategoryModal() {
    document.getElementById('new-category-name').value = '';
    document.getElementById('new-category-icon').value = 'folder';
    document.getElementById('new-category-color').value = '#6366f1';
    UI.openModal('modal-add-category');
  },

  async saveNewCategory() {
    const name = document.getElementById('new-category-name').value.trim();
    const icon = document.getElementById('new-category-icon').value.trim() || 'folder';
    const color = document.getElementById('new-category-color').value;

    if (!name) {
      UI.showToast('Category name is required', 'error');
      return;
    }

    try {
      const res = await API.post('api/categories.php', { action: 'create', name, icon, color });
      UI.showToast('Category added!', 'success');
      UI.closeModal('modal-add-category');
      await this.loadCategories();
      // Select the new category
      if (res.data && (res.data.category_id || res.data.id)) {
        document.getElementById('expense-category').value = res.data.category_id || res.data.id;
      }
    } catch (e) {
      UI.showToast('Failed to add category', 'error');
    }
  }
};
