/**
 * TripBook Email OTP Authentication Module
 * Handles email-based OTP login flow
 */

const AuthEmail = {
    currentEmail: '',
    otpTimer: null,
    otpExpiry: 0,

    /**
     * Send OTP to email address
     */
    async handleSendEmailOtp() {
        const emailInput = document.getElementById('email-address');
        const email = emailInput.value.trim().toLowerCase();

        if (!email) {
            UI.showToast('Please enter your email address', 'error');
            return;
        }

        if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
            UI.showToast('Please enter a valid email address', 'error');
            return;
        }

        const btn = document.getElementById('btn-send-email-otp');
        btn.disabled = true;
        btn.innerHTML = '<span class="spinner"></span> Sending...';

        try {
            const res = await API.post('api/email-otp.php?action=send_email_otp', {
                email: email
            });

            if (res.success) {
                this.currentEmail = email;
                this.otpExpiry = res.data.expires_in;

                // Show OTP screen
                document.getElementById('email-input-screen').style.display = 'none';
                document.getElementById('email-otp-screen').style.display = 'block';

                // Update email display
                document.getElementById('email-otp-display').textContent = this.maskEmail(email);

                // Start countdown
                this.startEmailOtpCountdown();

                UI.showToast('OTP sent to your email', 'success');

                // Focus OTP input
                document.getElementById('email-otp-code').focus();
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
     * Verify email OTP code
     */
    async handleVerifyEmailOtp() {
        const otpInput = document.getElementById('email-otp-code');
        const otpCode = otpInput.value.trim();

        if (!otpCode || otpCode.length !== 6) {
            UI.showToast('Please enter 6-digit OTP', 'error');
            return;
        }

        const btn = document.getElementById('btn-verify-email-otp');
        btn.disabled = true;
        btn.innerHTML = '<span class="spinner"></span> Verifying...';

        try {
            const res = await API.post('api/email-otp.php?action=verify_email_otp', {
                email: this.currentEmail,
                otp_code: otpCode
            });

            if (res.success) {
                clearInterval(this.otpTimer);

                // Store auth data
                Auth.authData = res.data;

                // Check if phone is needed
                if (res.data.needs_phone) {
                    Auth.showPhoneLink();
                } else {
                    window.location.reload();
                }
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
     * Start OTP countdown timer
     */
    startEmailOtpCountdown() {
        let remaining = this.otpExpiry;
        const timerEl = document.getElementById('email-otp-timer');
        const resendBtn = document.getElementById('btn-resend-email-otp');

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
     * Resend email OTP
     */
    async resendEmailOtp() {
        const email = this.currentEmail;
        if (!email) {
            document.getElementById('email-otp-screen').style.display = 'none';
            document.getElementById('email-input-screen').style.display = 'block';
            return;
        }

        const btn = document.getElementById('btn-resend-email-otp');
        if (btn) { btn.disabled = true; btn.innerHTML = '<span class="spinner"></span> Sending...'; }

        try {
            const res = await API.post('api/email-otp.php?action=send_email_otp', { email });
            if (res.success) {
                this.otpExpiry = res.data.expires_in;
                this.startEmailOtpCountdown();
                UI.showToast('OTP resent to ' + this.maskEmail(email), 'success');
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
     * Mask email for display
     */
    maskEmail(email) {
        const [name, domain] = email.split('@');
        if (!name || !domain) return email;
        const maskedName = name.length > 2 
            ? name[0] + '*'.repeat(name.length - 2) + name[name.length - 1]
            : name[0] + '*';
        return maskedName + '@' + domain;
    },

    /**
     * Switch to email login tab
     */
    showEmailLogin() {
        document.getElementById('phone-screen').style.display = 'none';
        document.getElementById('email-input-screen').style.display = 'flex';
        document.getElementById('email-otp-screen').style.display = 'none';
        document.getElementById('google-login-section').style.display = 'none';

        // Update tab states
        document.querySelectorAll('.auth-tab').forEach(tab => tab.classList.remove('active'));
        document.querySelector('[data-auth-tab="email"]')?.classList.add('active');
    },

    /**
     * Reset email login state
     */
    reset() {
        this.currentEmail = '';
        if (this.otpTimer) clearInterval(this.otpTimer);
        const emailInput = document.getElementById('email-address');
        if (emailInput) emailInput.value = '';
        const otpInput = document.getElementById('email-otp-code');
        if (otpInput) otpInput.value = '';
        document.getElementById('email-input-screen').style.display = 'flex';
        document.getElementById('email-otp-screen').style.display = 'none';
    }
};
