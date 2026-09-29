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
                    // Profile Card with Beach Backdrop
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
                                Image.network(
                                  'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800',
                                  height: 80,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                                Container(
                                  height: 80,
                                  color: Colors.black.withOpacity(0.3),
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
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: const CircleAvatar(
                                    radius: 36,
                                    backgroundImage: NetworkImage(
                                      'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200',
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Het Shah',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'het@example.com',
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
