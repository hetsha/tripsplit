/**
 * TripBook Profile Module
 * Handles user profile view and editing
 */

const Profile = {
    userData: null,

    /**
     * Open profile modal
     */
    async open() {
        UI.openModal('modal-profile');
        const container = document.getElementById('profile-content');
        container.innerHTML = '<div style="text-align:center; padding:20px;"><span class="spinner"></span> Loading...</div>';

        try {
            const res = await API.get('api/auth.php', { action: 'me' });
            if (res.success) {
                this.userData = res.data.user;
                this.render();
            }
        } catch (e) {
            container.innerHTML = '<div style="text-align:center; color:var(--danger); padding:20px;">Failed to load profile</div>';
        }
    },

    /**
     * Render profile content
     */
    render() {
        const u = this.userData;
        if (!u) return;

        const container = document.getElementById('profile-content');
        const provider = u.auth_provider || 'phone';
        const providerLabel = { phone: 'Phone OTP', google: 'Google', email: 'Email OTP' }[provider] || provider;

        container.innerHTML = `
            <div style="text-align:center; padding:8px 0;">
                <div class="avatar-circle" style="width:72px; height:72px; font-size:28px; margin:0 auto 12px; background:${u.avatar_color || '#2563eb'};">
                    ${u.name ? u.name.charAt(0).toUpperCase() : '?'}
                </div>
                <h3 style="font-size:20px; font-weight:800; margin:0;">${this.escapeHtml(u.name)}</h3>
                <div style="font-size:13px; color:var(--text-muted); margin-top:4px;">
                    Logged in via <strong>${providerLabel}</strong>
                </div>
            </div>

            <div class="card" style="padding:14px;">
                <div style="font-size:12px; font-weight:700; color:var(--text-muted); text-transform:uppercase; margin-bottom:12px;">Personal Info</div>
                
                <div class="form-group" style="margin-bottom:12px;">
                    <label class="form-label">Name</label>
                    <div style="display:flex; gap:8px;">
                        <input type="text" class="form-control" id="profile-name" value="${this.escapeHtml(u.name)}" style="flex:1;">
                        <button type="button" class="btn-settle-action" onclick="Profile.updateName()" style="white-space:nowrap;">Save</button>
                    </div>
                </div>

                <div class="form-group" style="margin-bottom:12px;">
                    <label class="form-label">Email</label>
                    <div style="display:flex; gap:8px; align-items:center;">
                        <input type="email" class="form-control" id="profile-email" value="${this.escapeHtml(u.email || '')}" style="flex:1;" ${u.email ? 'readonly' : ''} placeholder="Not set">
                        ${u.email_verified ? '<span style="color:#10b981; font-size:12px; font-weight:600;">✓ Verified</span>' : ''}
                    </div>
                </div>

                <div class="form-group">
                    <label class="form-label">Phone</label>
                    <div style="display:flex; gap:8px; align-items:center;">
                        <input type="text" class="form-control" value="${u.phone || 'Not linked'}" style="flex:1;" readonly>
                        ${u.phone_verified ? '<span style="color:#10b981; font-size:12px; font-weight:600;">✓ Verified</span>' : ''}
                    </div>
                </div>
            </div>

            <div class="card" style="padding:14px;">
                <div style="font-size:12px; font-weight:700; color:var(--text-muted); text-transform:uppercase; margin-bottom:12px;">Account</div>
                <div style="display:flex; flex-direction:column; gap:8px;">
                    <div style="display:flex; justify-content:space-between; align-items:center; padding:8px 0; border-bottom:1px solid var(--border);">
                        <span style="font-size:14px;">Member Since</span>
                        <span style="font-size:13px; color:var(--text-muted);">${u.created_at ? new Date(u.created_at).toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' }) : 'N/A'}</span>
                    </div>
                    <div style="display:flex; justify-content:space-between; align-items:center; padding:8px 0; border-bottom:1px solid var(--border);">
                        <span style="font-size:14px;">Login Method</span>
                        <span style="font-size:13px; color:var(--text-muted);">${providerLabel}</span>
                    </div>
                    <button type="button" class="btn-settle-action" style="background:#fee2e2; color:#ef4444; width:100%; justify-content:center; margin-top:8px;" onclick="Profile.logout()">
                        <i data-lucide="log-out" style="width:16px; height:16px;"></i> Logout
                    </button>
                </div>
            </div>
        `;

        // Re-initialize lucide icons for the new content
        if (window.lucide) lucide.createIcons();
    },

    /**
     * Update user name
     */
    async updateName() {
        const nameInput = document.getElementById('profile-name');
        const name = nameInput.value.trim();

        if (!name) {
            UI.showToast('Name is required', 'error');
            return;
        }

        try {
            const res = await API.post('api/settings.php?action=update_profile', { name: name });
            if (res.success) {
                this.userData.name = name;
                // Update header
                const headerName = document.getElementById('header-user-name');
                if (headerName) headerName.textContent = name;
                UI.showToast('Name updated', 'success');
            }
        } catch (e) {
            UI.showToast('Failed to update name', 'error');
        }
    },

    /**
     * Logout user
     */
    async logout() {
        UI.closeModal('modal-profile');
        await Auth.logout();
    },

    /**
     * Escape HTML
     */
    escapeHtml(str) {
        const div = document.createElement('div');
        div.textContent = str || '';
        return div.innerHTML;
    }
};
