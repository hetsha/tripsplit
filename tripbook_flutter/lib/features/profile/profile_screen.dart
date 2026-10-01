import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_notifier.dart';
import '../../services/auth_service.dart';
import '../../widgets/tripsplit_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final auth = Provider.of<AuthService>(context);
    final user = auth.currentUser;
    final userName = user?.name ?? 'Guest User';
    final userEmail = user?.email ?? (user?.phone ?? 'trip.splitter@example.com');
    final initials = userName.trim().isNotEmpty
        ? userName.trim().split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join().toUpperCase()
        : 'U';

    Color userColor;
    try {
      final colorHex = (user?.avatarColor ?? '#6366F1').replaceAll('#', '');
      userColor = Color(int.parse('FF$colorHex', radix: 16));
    } catch (_) {
      userColor = const Color(0xFF6366F1);
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header
            TripSplitHeader(
              title: 'Profile',
              onBack: () => Navigator.of(context).maybePop(),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Column(
                  children: [
                    // Profile Card with Backdrop
                    TripSplitCard(
                      padding: EdgeInsets.zero,
                      borderRadius: 22,
                      child: Column(
                        children: [
                          // Tropical Backdrop
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  height: 85,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        userColor.withOpacity(0.85),
                                        const Color(0xFF3B82F6),
                                        const Color(0xFF06B6D4),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                ),
                                Container(
                                  height: 85,
                                  color: Colors.black.withOpacity(0.15),
                                ),
                              ],
                            ),
                          ),

                          // Avatar overlapping
                          Transform.translate(
                            offset: const Offset(0, -32),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.surfaceDark : Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.12),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 36,
                                    backgroundColor: userColor,
                                    child: Text(
                                      initials,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      userName,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                                      ),
                                    ),
                                    if (user?.isAdmin == true) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'ADMIN',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  userEmail,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 0),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Profile Navigation Menu
                    TripSplitCard(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        children: [
                          _buildTile(
                            icon: Icons.flight_takeoff_rounded,
                            iconColor: const Color(0xFF6366F1),
                            title: 'My Trips',
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => Navigator.of(context).pushNamed('/dashboard'),
                            isDark: isDark,
                          ),
                          Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
                          _buildTile(
                            icon: Icons.credit_card_rounded,
                            iconColor: const Color(0xFF8B5CF6),
                            title: 'Payment Methods',
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => Navigator.of(context).pushNamed('/settle_up'),
                            isDark: isDark,
                          ),
                          Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
                          // Notifications Toggle
                          ListTile(
                            dense: true,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0EA5E9).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.notifications_outlined, size: 18, color: Color(0xFF0EA5E9)),
                            ),
                            title: Text(
                              'Notifications',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                              ),
                            ),
                            trailing: Switch(
                              value: _notificationsEnabled,
                              activeColor: AppColors.primary,
                              onChanged: (val) => setState(() => _notificationsEnabled = val),
                            ),
                          ),
                          Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
                          // Dark Mode Toggle
                          ListTile(
                            dense: true,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF475569).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.dark_mode_outlined, size: 18, color: Color(0xFF475569)),
                            ),
                            title: Text(
                              'Dark Mode',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                              ),
                            ),
                            trailing: Switch(
                              value: themeNotifier.themeMode == ThemeMode.dark,
                              activeColor: AppColors.primary,
                              onChanged: (val) {
                                themeNotifier.toggleTheme();
                              },
                            ),
                          ),
                          Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),

                          _buildTile(
                            icon: Icons.help_outline_rounded,
                            iconColor: const Color(0xFFF59E0B),
                            title: 'Help & Support',
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () {},
                            isDark: isDark,
                          ),
                          Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
                          _buildTile(
                            icon: Icons.info_outline_rounded,
                            iconColor: const Color(0xFF10B981),
                            title: 'About TripSplit',
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () {},
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Logout Button
                    TripSplitSecondaryButton(
                      label: 'Logout',
                      borderColor: AppColors.negative.withOpacity(0.4),
                      textColor: AppColors.negative,
                      onPressed: () async {
                        try {
                          await Provider.of<AuthService>(context, listen: false).logout();
                        } catch (_) {}
                        if (context.mounted) {
                          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                        }
                      },
                    ),

                    const SizedBox(height: 14),

                    // Version Note
                    Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget trailing,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return ListTile(
      dense: true,
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: iconColor),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
        ),
      ),
      trailing: trailing,
    );
  }
}
