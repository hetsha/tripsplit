/**
 * TripBook API Client Wrapper
 */

const API = {
  csrfToken: '',
  activeTripId: 1,

  init(csrfToken, activeTripId) {
    this.csrfToken = csrfToken;
    this.activeTripId = activeTripId;
  },

  async request(url, options = {}) {
    const headers = options.headers || {};
    if (this.csrfToken) {
      headers['X-CSRF-Token'] = this.csrfToken;
    }

    if (options.body && typeof options.body === 'object' && !(options.body instanceof FormData)) {
      headers['Content-Type'] = 'application/json';
      options.body = JSON.stringify(options.body);
    }

    options.headers = headers;

    try {
      const response = await fetch(url, options);
      const data = await response.json();

      if (!response.ok || data.success === false) {
        throw new Error(data.message || 'An error occurred');
      }

      return data;
    } catch (err) {
      console.error('API Error:', err);
      UI.showToast(err.message, 'error');
      throw err;
    }
  },

  get(url, params = {}) {
    const query = new URLSearchParams(params).toString();
    const fullUrl = query ? `${url}?${query}` : url;
    return this.request(fullUrl, { method: 'GET' });
  },

  post(url, body = {}) {
    if (!body.trip_id && this.activeTripId) {
      body.trip_id = this.activeTripId;
    }
    return this.request(url, {
      method: 'POST',
      body
    });
  }
};
