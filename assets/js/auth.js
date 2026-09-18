/**
 * TripBook Authentication Module
 * Handles multi-method login: Phone OTP, Email OTP, Google
 */

const Auth = {
    currentPhone: '',
    otpTimer: null,
    otpExpiry: 0,
    authData: null,
    authMethods: { phone_enabled: true, google_enabled: false, email_enabled: false },
    linkPhone: '',

    /**
     * Initialize auth module
     */
    init() {
        this.loadAuthMethods();
        this.bindEvents();
    },

    /**
     * Load available auth methods from server
     */
    async loadAuthMethods() {
        try {
            const res = await API.get('api/otp.php?action=get_auth_methods');
            if (res.success) {
                this.authMethods = res.data;
                this.applyAuthMethods();
            }
        } catch (e) {
            // Default: show phone only
            this.applyAuthMethods();
        }
    },

    /**
     * Show/hide login methods based on admin settings
     */
    applyAuthMethods() {
        const methods = this.authMethods;
        
        // Show/hide phone tab
        const phoneTab = document.querySelector('[data-auth-tab="phone"]');
        if (phoneTab) phoneTab.style.display = methods.phone_enabled ? '' : 'none';
        
        // Show/hide email tab
        const emailTab = document.querySelector('[data-auth-tab="email"]');
        if (emailTab) emailTab.style.display = methods.email_enabled ? '' : 'none';
        
        // Show/hide Google section
        const googleSection = document.getElementById('google-login-section');
        if (googleSection) googleSection.style.display = methods.google_enabled ? '' : 'none';

        // Show/hide dividers
        const dividers = document.querySelectorAll('.auth-divider');
        const enabledCount = [methods.phone_enabled, methods.email_enabled, methods.google_enabled].filter(Boolean).length;
        dividers.forEach(d => d.style.display = enabledCount > 1 ? '' : 'none');

        // Initialize Google Sign-In if enabled
        if (methods.google_enabled && methods.google_client_id) {
            this.initGoogleSignIn(methods.google_client_id);
        }

        // Default to first enabled tab
        if (methods.phone_enabled) {
            this.switchTab('phone');
        } else if (methods.email_enabled) {
            this.switchTab('email');
        }
    },

    /**
     * Initialize Google Identity Services
     */
    initGoogleSignIn(clientId) {
        // Load Google GIS script if not loaded
        if (!document.getElementById('google-gis-script')) {
            const script = document.createElement('script');
            script.id = 'google-gis-script';
            script.src = 'https://accounts.google.com/gsi/client';
            script.async = true;
            script.defer = true;
            script.onload = () => this.renderGoogleButton(clientId);
            document.head.appendChild(script);
        } else if (window.google) {
            this.renderGoogleButton(clientId);
        }
    },

    /**
     * Render Google Sign-In button
     */
    renderGoogleButton(clientId) {
        const container = document.getElementById('google-signin-btn');
        if (!container || !window.google) return;

        container.innerHTML = '';

        google.accounts.id.initialize({
            client_id: clientId,
            callback: this.handleGoogleCredential.bind(this)
        });

        google.accounts.id.renderButton(container, {
            theme: 'outline',
            size: 'large',
            width: container.offsetWidth || 332,
            text: 'continue_with'
        });
    },

    /**
     * Handle Google credential response
     */
    async handleGoogleCredential(response) {
        const btn = document.getElementById('google-login-btn');
        if (btn) { btn.disabled = true; btn.innerHTML = '<span class="spinner"></span> Signing in...'; }

        try {
            const res = await API.post('api/google-auth.php?action=google_login', {
                credential: response.credential
            });

            if (res.success) {
                this.authData = res.data;

                // Check if phone is needed
                if (res.data.needs_phone) {
                    this.showPhoneLink();
                } else {
                    window.location.reload();
                }
            } else {
                UI.showToast(res.message || 'Google login failed', 'error');
            }
        } catch (err) {
            UI.showToast('Network error. Please try again.', 'error');
        } finally {
            if (btn) { btn.disabled = false; btn.innerHTML = 'Sign in with Google'; }
        }
    },

    /**
     * Bind form events
     */
    bindEvents() {
        // Phone form submission
        const phoneForm = document.getElementById('form-send-otp');
        if (phoneForm) {
            phoneForm.addEventListener('submit', (e) => {
                e.preventDefault();
                this.handleSendOtp();
            });
        }

        // OTP form submission
        const otpForm = document.getElementById('form-verify-otp');
        if (otpForm) {
            otpForm.addEventListener('submit', (e) => {
                e.preventDefault();
                this.handleVerifyOtp();
            });
        }

        // OTP input auto-focus
        const otpInput = document.getElementById('otp-code');
        if (otpInput) {
            otpInput.addEventListener('input', (e) => {
                const value = e.target.value.replace(/\D/g, '');
                e.target.value = value;
                if (value.length === 6) {
                    this.handleVerifyOtp();
                }
            });
        }

        // Email form events
        const emailForm = document.getElementById('form-send-email-otp');
        if (emailForm) {
            emailForm.addEventListener('submit', (e) => {
                e.preventDefault();
                AuthEmail.handleSendEmailOtp();
            });
        }

        const emailOtpForm = document.getElementById('form-verify-email-otp');
        if (emailOtpForm) {
            emailOtpForm.addEventListener('submit', (e) => {
                e.preventDefault();
                AuthEmail.handleVerifyEmailOtp();
            });
        }

        // Email OTP auto-verify
        const emailOtpInput = document.getElementById('email-otp-code');
        if (emailOtpInput) {
            emailOtpInput.addEventListener('input', (e) => {
                const value = e.target.value.replace(/\D/g, '');
                e.target.value = value;
                if (value.length === 6) {
                    AuthEmail.handleVerifyEmailOtp();
                }
            });
        }

        // Link phone OTP auto-verify
        const linkOtpInput = document.getElementById('link-otp-code');
        if (linkOtpInput) {
            linkOtpInput.addEventListener('input', (e) => {
                const value = e.target.value.replace(/\D/g, '');
                e.target.value = value;
                if (value.length === 6) {
                    Auth.handleLinkVerifyOtp();
                }
            });
        }
    },

    /**
     * Switch between auth tabs
     */
    switchTab(method) {
        // Reset all screens
        document.getElementById('phone-screen').style.display = 'none';
        document.getElementById('otp-screen').style.display = 'none';
        document.getElementById('email-input-screen').style.display = 'none';
        document.getElementById('email-otp-screen').style.display = 'none';
        document.getElementById('google-login-section').style.display = 'none';

        // Update tab active state
        document.querySelectorAll('.auth-tab').forEach(t => t.classList.remove('active'));
        document.querySelector(`[data-auth-tab="${method}"]`)?.classList.add('active');

        // Show appropriate section
        if (method === 'phone') {
            document.getElementById('phone-screen').style.display = 'flex';
        } else if (method === 'email') {
            AuthEmail.reset();
            document.getElementById('email-input-screen').style.display = 'flex';
        } else if (method === 'google') {
            document.getElementById('google-login-section').style.display = 'flex';
        }
    },

    /**
     * Send OTP to phone number
     */
    async handleSendOtp() {
        const phoneInput = document.getElementById('phone-number');
        const phone = phoneInput.value.trim();

        if (!phone) {
            UI.showToast('Please enter your phone number', 'error');
            return;
        }

        // Normalize phone
        let normalizedPhone = phone.replace(/[\s\-\(\)]/g, '');
        if (normalizedPhone.length === 10) {
            normalizedPhone = '+91' + normalizedPhone;
        } else if (normalizedPhone.length === 12 && normalizedPhone.startsWith('91')) {
            normalizedPhone = '+' + normalizedPhone;
        }

        if (!/^\+[1-9]\d{6,14}$/.test(normalizedPhone)) {
            UI.showToast('Invalid phone number format', 'error');
            return;
        }

        const btn = document.getElementById('btn-send-otp');
        btn.disabled = true;
        btn.innerHTML = '<span class="spinner"></span> Sending...';

        try {
            const res = await API.post('api/otp.php?action=send_otp', {
                phone: normalizedPhone
            });

            if (res.success) {
                this.currentPhone = normalizedPhone;
                this.otpExpiry = res.data.expires_in;
                
                // Show OTP screen
                document.getElementById('phone-screen').style.display = 'none';
                document.getElementById('otp-screen').style.display = 'block';
                
                // Update phone display
                document.getElementById('otp-phone-display').textContent = this.maskPhone(normalizedPhone);
                
                // Start countdown
                this.startOtpCountdown();
                
                // Show simulation notice if applicable
                if (res.data.simulated) {
                    UI.showToast('OTP simulated - check console for code', 'info');
                } else {
                    UI.showToast('OTP sent to your phone', 'success');
                }
                
                // Focus OTP input
                document.getElementById('otp-code').focus();
            } else {
                UI.showToast(res.message || 'Failed to send OTP', 'error');
            }
        } catch (err) {
            UI.showToast('Network error. Please try again.', 'error');
        } finally {
            btn.disabled = false;
            btn.innerHTML = 'Send OTP';
        }
    },

    /**
     * Verify OTP code
     */
    async handleVerifyOtp() {
        const otpInput = document.getElementById('otp-code');
        const otpCode = otpInput.value.trim();

        if (!otpCode || otpCode.length !== 6) {
            UI.showToast('Please enter 6-digit OTP', 'error');
            return;
        }

        const btn = document.getElementById('btn-verify-otp');
        btn.disabled = true;
        btn.innerHTML = '<span class="spinner"></span> Verifying...';

        try {
            const res = await API.post('api/otp.php?action=verify_otp', {
                phone: this.currentPhone,
                otp_code: otpCode
            });

            if (res.success) {
                clearInterval(this.otpTimer);
                
                // Store auth data
                this.authData = res.data;
                
                window.location.reload();
            } else {
                UI.showToast(res.message || 'Invalid OTP', 'error');
                otpInput.value = '';
                otpInput.focus();
            }
        } catch (err) {
            UI.showToast('Network error. Please try again.', 'error');
        } finally {
            btn.disabled = false;
            btn.innerHTML = 'Verify OTP';
        }
    },

    /**
     * Show phone linking screen (after Google/Email login)
     */
    showPhoneLink() {
        document.getElementById('login-screen').style.display = 'none';
        document.getElementById('phone-link-screen').style.display = 'flex';
        document.getElementById('link-phone-input').style.display = 'flex';
        document.getElementById('link-otp-input').style.display = 'none';
    },

    /**
     * Send OTP for phone linking
     */
    async handleLinkSendOtp() {
        const phoneInput = document.getElementById('link-phone-number');
        const phone = phoneInput.value.trim();

        if (!phone) {
            UI.showToast('Please enter your phone number', 'error');
            return;
        }

        let normalizedPhone = phone.replace(/[\s\-\(\)]/g, '');
        if (normalizedPhone.length === 10) {
            normalizedPhone = '+91' + normalizedPhone;
        } else if (normalizedPhone.length === 12 && normalizedPhone.startsWith('91')) {
            normalizedPhone = '+' + normalizedPhone;
        }

        if (!/^\+[1-9]\d{6,14}$/.test(normalizedPhone)) {
            UI.showToast('Invalid phone number format', 'error');
            return;
        }

        const btn = document.getElementById('btn-link-send-otp');
        btn.disabled = true;
        btn.innerHTML = '<span class="spinner"></span> Sending...';

        try {
            const res = await API.post('api/otp.php?action=send_otp', {
                phone: normalizedPhone
            });

            if (res.success) {
                this.linkPhone = normalizedPhone;
                this.otpExpiry = res.data.expires_in;

                document.getElementById('link-phone-input').style.display = 'none';
                document.getElementById('link-otp-input').style.display = 'block';
                document.getElementById('link-otp-phone-display').textContent = this.maskPhone(normalizedPhone);

                this.startLinkOtpCountdown();

                if (res.data.simulated) {
                    UI.showToast('OTP simulated - check console for code', 'info');
                } else {
                    UI.showToast('OTP sent to your phone', 'success');
                }

                document.getElementById('link-otp-code').focus();
            } else {
                UI.showToast(res.message || 'Failed to send OTP', 'error');
            }
        } catch (err) {
            UI.showToast('Network error. Please try again.', 'error');
        } finally {
            btn.disabled = false;
            btn.innerHTML = 'Send OTP';
        }
    },

    /**
     * Verify OTP for phone linking
     */
    async handleLinkVerifyOtp() {
        const otpInput = document.getElementById('link-otp-code');
        const otpCode = otpInput.value.trim();

        if (!otpCode || otpCode.length !== 6) {
            UI.showToast('Please enter 6-digit OTP', 'error');
            return;
        }

        const btn = document.getElementById('btn-link-verify-otp');
        btn.disabled = true;
        btn.innerHTML = '<span class="spinner"></span> Linking...';

        try {
            const res = await API.post('api/otp.php?action=link_phone', {
                phone: this.linkPhone,
                otp_code: otpCode
            });

            if (res.success) {
                clearInterval(this.otpTimer);
                UI.showToast('Phone number linked successfully!', 'success');

                // Update auth data with new user info
                this.authData.user = res.data.user;

                window.location.reload();
            } else {
                UI.showToast(res.message || 'Failed to link phone', 'error');
                otpInput.value = '';
                otpInput.focus();
            }
        } catch (err) {
            UI.showToast('Network error. Please try again.', 'error');
        } finally {
            btn.disabled = false;
            btn.innerHTML = 'Verify & Link';
        }
    },

    /**
     * Resend OTP for phone linking
     */
    async handleLinkResendOtp() {
        const phone = this.linkPhone;
        if (!phone) return;

        const btn = document.getElementById('btn-link-resend-otp');
        if (btn) { btn.disabled = true; btn.innerHTML = '<span class="spinner"></span> Sending...'; }

        try {
            const res = await API.post('api/otp.php?action=send_otp', { phone });
            if (res.success) {
                this.otpExpiry = res.data.expires_in;
                this.startLinkOtpCountdown();
                UI.showToast('OTP resent to ' + this.maskPhone(phone), 'success');
            } else {
                UI.showToast(res.message || 'Failed to resend OTP', 'error');
            }
        } catch (e) {
            UI.showToast('Network error. Please try again.', 'error');
        } finally {
            if (btn) { btn.disabled = false; btn.innerHTML = 'Resend OTP'; }
        }
    },

    /**
     * Start OTP countdown for phone linking
     */
    startLinkOtpCountdown() {
        let remaining = this.otpExpiry;
        const timerEl = document.getElementById('link-otp-timer');
        const resendBtn = document.getElementById('btn-link-resend-otp');

        if (this.otpTimer) clearInterval(this.otpTimer);
        resendBtn.style.display = 'none';

        this.otpTimer = setInterval(() => {
            remaining--;
            if (remaining <= 0) {
                clearInterval(this.otpTimer);
                timerEl.textContent = '';
                resendBtn.style.display = 'inline-block';
                return;
            }
            const mins = Math.floor(remaining / 60);
            const secs = remaining % 60;
            timerEl.textContent = `OTP expires in ${mins}:${secs.toString().padStart(2, '0')}`;
        }, 1000);
    },

    /**
     * Skip phone linking
     */
    skipPhoneLink() {
        if (this.authData.is_new_user || (this.authData.trips && this.authData.trips.length === 0)) {
            this.showOnboarding();
        } else {
            this.showTripsList(this.authData.trips);
        }
    },

    /**
     * Show onboarding screen for new users
     */
    showOnboarding() {
        document.getElementById('login-screen').style.display = 'none';
        document.getElementById('onboarding-screen').style.display = 'block';
        
        const userName = this.authData.user?.name || 'there';
        document.getElementById('onboarding-user-name').textContent = userName;
    },

    /**
     * Show trips list screen with all joined trips
     */
    showTripsList(trips) {
        document.getElementById('login-screen').style.display = 'none';
        document.getElementById('trips-list-screen').style.display = 'block';

        const container = document.getElementById('trips-list-container');
        if (!container) return;

        const userName = this.authData.user?.name || 'there';
        document.getElementById('trips-list-screen').querySelector('.onboarding-title').textContent = `${userName}'s Trips`;

        container.innerHTML = trips.map(trip => `
            <div class="trip-list-card" onclick="Auth.selectTrip('${UI.escapeHtml(trip.url_token || '')}')">
                <div class="trip-list-icon">🧳</div>
                <div class="trip-list-info">
                    <div class="trip-list-name">${UI.escapeHtml(trip.name)}</div>
                    <div class="trip-list-code">${trip.trip_code} • ${trip.role}</div>
                </div>
                <div class="trip-list-arrow">→</div>
            </div>
        `).join('');
    },

    /**
     * Select a trip from the list and load the dashboard
     */
    async selectTrip(urlToken) {
        document.getElementById('trips-list-screen').style.display = 'none';
        document.getElementById('app-content').style.display = 'flex';

        const csrfToken = this.authData.csrf_token || '';
        App.init(csrfToken, 0, urlToken);
    },

    /**
     * Skip onboarding and use CashBook only
     */
    skipOnboarding() {
        this.initMainApp();
    },

    /**
     * Initialize main application after auth
     */
    initMainApp() {
        document.getElementById('login-screen').style.display = 'none';
        document.getElementById('onboarding-screen').style.display = 'none';
        document.getElementById('trips-list-screen').style.display = 'none';
        document.getElementById('app-content').style.display = 'flex';
        
        const csrfToken = this.authData.csrf_token || '';
        const activeTripId = this.authData.active_trip || 0;
        
        App.init(csrfToken, activeTripId);
    },

    /**
     * Show app-content for modal access (without re-init)
     */
    initMainAppForTripsList() {
        document.getElementById('trips-list-screen').style.display = 'none';
        document.getElementById('app-content').style.display = 'flex';
        
        const csrfToken = this.authData.csrf_token || '';
        const activeTripId = this.authData.active_trip || 0;
        
        if (!activeTripId) {
          App.showMainApp();
        } else {
          App.init(csrfToken, activeTripId);
        }
    },

    /**
     * Start OTP countdown timer
     */
    startOtpCountdown() {
        let remaining = this.otpExpiry;
        const timerEl = document.getElementById('otp-timer');
        const resendBtn = document.getElementById('btn-resend-otp');
        
        if (this.otpTimer) clearInterval(this.otpTimer);
        
        resendBtn.style.display = 'none';
        
        this.otpTimer = setInterval(() => {
            remaining--;
            
            if (remaining <= 0) {
                clearInterval(this.otpTimer);
                timerEl.textContent = '';
                resendBtn.style.display = 'inline-block';
                return;
            }
            
            const mins = Math.floor(remaining / 60);
            const secs = remaining % 60;
            timerEl.textContent = `OTP expires in ${mins}:${secs.toString().padStart(2, '0')}`;
        }, 1000);
    },

    /**
     * Resend OTP
     */
    async resendOtp() {
        const phone = this.currentPhone;
        if (!phone) {
            document.getElementById('otp-screen').style.display = 'none';
            document.getElementById('phone-screen').style.display = 'block';
            return;
        }

        const btn = document.getElementById('btn-resend-otp');
        if (btn) { btn.disabled = true; btn.innerHTML = '<span class="spinner"></span> Sending...'; }

        try {
            const res = await API.post('api/otp.php?action=send_otp', { phone });
            if (res.success) {
                this.otpExpiry = res.data.expires_in;
                this.startOtpCountdown();
                UI.showToast('OTP resent to ' + this.maskPhone(phone), 'success');
            } else {
                UI.showToast(res.message || 'Failed to resend OTP', 'error');
            }
        } catch (e) {
            UI.showToast('Network error. Please try again.', 'error');
        } finally {
            if (btn) { btn.disabled = false; btn.innerHTML = 'Resend OTP'; }
        }
    },

    /**
     * Mask phone number for display
     */
    maskPhone(phone) {
        if (phone.length < 6) return phone;
        const visible = phone.slice(0, -4);
        const masked = phone.slice(-4);
        return visible.replace(/./g, '*') + masked;
    },

    /**
     * Logout user
     */
    async logout() {
        try {
            await API.get('api/otp.php?action=logout');
        } catch (e) {}
        
        window.location.reload();
    }
};
