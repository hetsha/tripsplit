/**
 * TripBook More / Settings Screen Module
 */

const More = {
  init() {
    this.bindEvents();
  },

  bindEvents() {
    // Create Trip Form
    const createForm = document.getElementById('form-create-trip');
    if (createForm) {
      createForm.addEventListener('submit', (e) => this.handleCreateTrip(e));
    }

    // Join Trip Form
    const joinForm = document.getElementById('form-join-trip');
    if (joinForm) {
      joinForm.addEventListener('submit', (e) => this.handleJoinTrip(e));
    }

    const tripSettingsForm = document.getElementById('form-trip-settings');
    if (tripSettingsForm) {
      tripSettingsForm.addEventListener('submit', (e) => {
        e.preventDefault();
        this.saveTripSettings();
      });
    }
  },

  bindForms() {
    this.bindEvents();
  },

  render() {
    if (!Dashboard.data) return;
    const { trip_info, current_user } = Dashboard.data;

    document.getElementById('more-trip-name').innerText = trip_info.name;
    document.getElementById('more-trip-code').innerText = trip_info.trip_code;
  },

  openCreateTripModal() {
    document.getElementById('form-create-trip').reset();
    UI.openModal('modal-create-trip');
  },

  async handleCreateTrip(e) {
    e.preventDefault();
    const name = document.getElementById('new-trip-name').value.trim();
    const currencySymbol = document.getElementById('new-trip-currency')?.value?.trim() || '₹';

    try {
      const res = await API.post('api/trips.php', {
        action: 'create',
        name,
        starting_money: 0,
        starting_payment_method: 'cash',
        currency_symbol: currencySymbol
      });

      UI.showToast('Trip created!', 'success');
      UI.closeModal('modal-create-trip');
      window.location.href = '?trip=' + res.data.url_token;
    } catch (e) {
      console.error(e);
    }
  },

  openJoinTripModal() {
    document.getElementById('form-join-trip').reset();
    UI.openModal('modal-join-trip');
  },

  async handleJoinTrip(e) {
    e.preventDefault();
    const code = document.getElementById('join-trip-code').value.trim();

    try {
      const res = await API.post('api/trips.php', { action: 'join', trip_code: code });
      UI.showToast(res.message, 'success');
      UI.closeModal('modal-join-trip');
      window.location.href = '?trip=' + res.data.url_token;
    } catch (e) {
      console.error(e);
    }
  },

  exportCSV() {
    const tripId = API.activeTripId || 1;
    window.location.href = `api/export.php?format=csv&trip_id=${tripId}`;
  },

  async deleteTrip() {
    if (!confirm('Are you sure you want to delete this trip? This will also delete all associated transactions and splits.')) return;

    try {
      const res = await API.post('api/trips.php', { action: 'delete' });
      UI.showToast('Trip deleted', 'success');
      window.location.href = 'index.php';
    } catch (e) {
      console.error(e);
    }
  },

  openTripSettings() {
    const trip = Dashboard.data?.trip_info;
    if (!trip) return;
    document.getElementById('settings-trip-name').value = trip.name || '';
    document.getElementById('settings-trip-currency').value = trip.currency_symbol || '₹';
    document.getElementById('settings-trip-desc').value = trip.description || '';
    UI.openModal('modal-trip-settings');
  },

  async saveTripSettings() {
    const name = document.getElementById('settings-trip-name').value.trim();
    const currency = document.getElementById('settings-trip-currency').value.trim() || '₹';
    const description = document.getElementById('settings-trip-desc').value.trim();

    if (!name) {
      UI.showToast('Trip name is required', 'error');
      return;
    }

    try {
      await API.post('api/trips.php', { action: 'update', name, currency_symbol: currency, description });
      UI.showToast('Trip settings saved', 'success');
      UI.closeModal('modal-trip-settings');
      App.refreshData();
    } catch (e) {
      UI.showToast('Failed to save settings', 'error');
    }
  },

  exportPDF() {
    const tripId = API.activeTripId || 1;
    window.location.href = `api/export.php?format=pdf&trip_id=${tripId}`;
  },

  deleteAccount() {
    UI.showConfirm(
      'Delete Account',
      'This will permanently delete your account and all your data across all trips. This cannot be undone.',
      async () => {
        try {
          await API.post('api/auth.php', { action: 'delete_account' });
          UI.showToast('Account deleted', 'success');
          Auth.logout();
        } catch (e) {
          UI.showToast('Failed to delete account', 'error');
        }
      }
    );
  }
};
