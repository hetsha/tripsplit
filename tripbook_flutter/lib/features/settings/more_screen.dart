import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_notifier.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trip = auth.activeTrip;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        title: const Text('More', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Trip Card
            _buildTripCard(context, trip, isDark),
            const SizedBox(height: 24),

            // Quick Trip Actions
            Text(
              'QUICK TRIP ACTIONS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
              ),
            ),
            const SizedBox(height: 12),
            _buildActionTile(
              context,
              icon: Icons.person_outline_rounded,
              iconColor: AppColors.primary,
              title: 'My Profile',
              subtitle: 'View and edit your profile details',
              onTap: () => _showProfileSheet(context, auth, isDark),
            ),
            _buildActionTile(
              context,
              icon: Icons.add_circle_outline_rounded,
              iconColor: AppColors.positive,
              title: 'Create New Group',
              subtitle: 'Start tracking another group',
              onTap: () => _showCreateTripSheet(context, isDark),
            ),
            _buildActionTile(
              context,
              icon: Icons.login_rounded,
              iconColor: AppColors.secondary,
              title: 'Join Existing Group',
              subtitle: 'Enter a shared code to join a group',
              onTap: () => _showJoinTripSheet(context, isDark),
            ),
            _buildActionTile(
              context,
              icon: Icons.settings_outlined,
              iconColor: AppColors.warning,
              title: 'Group Settings',
              subtitle: 'Edit name, currency, description',
              onTap: () {},
            ),
            _buildActionTile(
              context,
              icon: Icons.delete_outline_rounded,
              iconColor: AppColors.negative,
              title: 'Delete This Group',
              subtitle: 'Permanently remove group and all data',
              onTap: () => _confirmDeleteTrip(context, auth),
            ),
            _buildActionTile(
              context,
              icon: Icons.person_remove_outlined,
              iconColor: AppColors.negative,
              title: 'Delete Account',
              subtitle: 'Permanently delete your profile account',
              onTap: () {},
            ),
            _buildActionTile(
              context,
              icon: Icons.logout_rounded,
              iconColor: AppColors.negative,
              title: 'Logout',
              subtitle: 'Sign out of your profile',
              onTap: () async {
                await auth.logout();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripCard(BuildContext context, dynamic trip, bool isDark) {
    final tripName = trip?.name ?? 'No Group';
    final tripCode = trip?.tripCode ?? 'N/A';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.15),
            AppColors.accent.withOpacity(0.08),
          ],
        ),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.20),
          width: 0.8,
        ),
      ),
      child: Column(
        children: [
          // Suitcase icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: AppColors.primary.withOpacity(0.15),
            ),
            child: const Icon(
              Icons.luggage_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          // Trip name
          Text(
            tripName,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          // Trip code
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Group Code: ',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: tripCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Trip code $tripCode copied!'),
                      duration: const Duration(seconds: 1),
                      backgroundColor: AppColors.positive,
                    ),
                  );
                },
                child: Text(
                  tripCode,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTripButton(
                context,
                icon: Icons.share_rounded,
                label: 'Share Invite',
                isPrimary: true,
                onTap: () {
                  Clipboard.setData(ClipboardData(text: tripCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Invite code copied!'),
                      backgroundColor: AppColors.positive,
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              _buildTripButton(
                context,
                icon: Icons.download_rounded,
                label: 'CSV',
                isPrimary: false,
                onTap: () {},
              ),
              const SizedBox(width: 8),
              _buildTripButton(
                context,
                icon: Icons.picture_as_pdf_rounded,
                label: 'PDF',
                isPrimary: false,
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTripButton(BuildContext context, {required IconData icon, required String label, required bool isPrimary, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: isPrimary
              ? const LinearGradient(
                  colors: AppColors.brandGradient,
                )
              : null,
          color: isPrimary ? null : Colors.white.withOpacity(0.08),
          border: Border.all(
            color: isPrimary ? Colors.transparent : Colors.white.withOpacity(0.15),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: iconColor.withOpacity(0.12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showProfileSheet(BuildContext context, AuthService auth, bool isDark) {
    final user = auth.currentUser;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.elevatedDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: AppColors.brandGradient),
              ),
              child: Center(
                child: Text(
                  (user?.name ?? 'M')[0].toUpperCase(),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user?.name ?? 'Member',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              user?.phone ?? 'No phone',
              style: TextStyle(fontSize: 13, color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted),
            ),
            Text(
              user?.email ?? 'No email',
              style: TextStyle(fontSize: 13, color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showCreateTripSheet(BuildContext context, bool isDark) {
    final nameController = TextEditingController();
    final currencyController = TextEditingController(text: '₹');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Create New Group', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Trip Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: currencyController,
              decoration: InputDecoration(
                labelText: 'Currency Symbol',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Create', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showJoinTripSheet(BuildContext context, bool isDark) {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Join Group', style: TextStyle(fontWeight: FontWeight.w800)),
        content: TextField(
          controller: codeController,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: 'Trip Code',
            hintText: 'e.g. TRIP-ABCD',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Join', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTrip(BuildContext context, AuthService auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Group?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('This will permanently remove the group and all its data. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.negative,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
