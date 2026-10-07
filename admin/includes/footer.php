            </div>
        </main>
    </div>
    
    <script src="https://unpkg.com/lucide@0.460.0/dist/umd/lucide.min.js"></script>
    <script>
        lucide.createIcons();

        // Toggle Profile Dropdown
        function toggleProfileDropdown(e) {
            e.stopPropagation();
            const dropdown = document.getElementById('profileDropdown');
            if (dropdown) {
                dropdown.classList.toggle('show');
            }
        }

        // Toggle Mobile Navigation Menu
        function toggleMobileNavMenu() {
            const menu = document.getElementById('consoleNavMenu');
            if (menu) {
                menu.classList.toggle('mobile-open');
            }
        }

        // Close dropdown when clicking outside
        document.addEventListener('click', function(e) {
            const dropdown = document.getElementById('profileDropdown');
            if (dropdown && dropdown.classList.contains('show')) {
                if (!e.target.closest('.profile-dropdown-container')) {
                    dropdown.classList.remove('show');
                }
            }
        });

        // Global Cmd+K / Ctrl+K search shortcut (Section 55)
        document.addEventListener('keydown', function(e) {
            if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
                e.preventDefault();
                const searchInput = document.getElementById('global-search-input');
                if (searchInput) {
                    searchInput.focus();
                    searchInput.select();
                }
            }
        });
    </script>
</body>
</html>
