import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/expense_service.dart';
import '../../theme/app_theme.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../home_coordinator.dart';

class GroupsListScreen extends StatefulWidget {
  const GroupsListScreen({Key? key}) : super(key: key);

  @override
  State<GroupsListScreen> createState() => _GroupsListScreenState();
}

class _GroupsListScreenState extends State<GroupsListScreen> {
  bool _isLoading = false;

  static const _groupColors = [
    [Color(0xFFE74C3C), Color(0xFFC0392B)],
    [Color(0xFF3498DB), Color(0xFF2980B9)],
    [Color(0xFF2ECC71), Color(0xFF27AE60)],
    [Color(0xFF9B59B6), Color(0xFF8E44AD)],
    [Color(0xFFF39C12), Color(0xFFE67E22)],
    [Color(0xFF1ABC9C), Color(0xFF16A085)],
    [Color(0xFFE91E63), Color(0xFFC2185B)],
    [Color(0xFF00BCD4), Color(0xFF0097A7)],
  ];

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trips = auth.trips;
    final userName = auth.currentUser?.name ?? 'Member';

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: RefreshIndicator(
        onRefresh: () => auth.checkAuth(),
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Groups',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Welcome, $userName',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () async {
                          await auth.logout();
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(colors: AppColors.brandGradient),
                          ),
                          child: Center(
                            child: Text(
                              userName[0].toUpperCase(),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Groups list
                  if (trips.isEmpty)
                    _buildEmptyState(isDark)
                  else
                    ...trips.asMap().entries.map((entry) {
                      final index = entry.key;
                      final trip = entry.value;
                      final colorPair = _groupColors[index % _groupColors.length];
                      return _buildGroupCard(context, trip, colorPair, isDark);
                    }),
                ]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateJoinSheet(context, isDark),
        backgroundColor: AppColors.primary,
        elevation: 4,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Icon(Icons.group_outlined, size: 64, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text(
            'No groups yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a group or join one with an invite code',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(BuildContext context, dynamic trip, List<Color> colors, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openGroup(context, trip.id),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isDark ? AppColors.elevatedDark : AppColors.surfaceLight,
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                // Group icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: colors,
                    ),
                  ),
                  child: const Icon(Icons.flight_takeoff_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 16),
                // Group info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'tap to open',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openGroup(BuildContext context, int tripId) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    setState(() => _isLoading = true);
    try {
      await auth.switchTrip(tripId);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HomeCoordinator()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open group: $e'), backgroundColor: AppColors.negative),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showCreateJoinSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        padding: const EdgeInsets.all(20),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSheetOption(
                  context,
                  Icons.group_add_rounded,
                  'Create Group',
                  AppColors.primary,
                  () {
                    Navigator.pop(ctx);
                    _showCreateGroupDialog(context, isDark);
                  },
                ),
                _buildSheetOption(
                  context,
                  Icons.login_rounded,
                  'Join Group',
                  AppColors.secondary,
                  () {
                    Navigator.pop(ctx);
                    _showJoinGroupDialog(context, isDark);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetOption(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _showCreateGroupDialog(BuildContext context, bool isDark) {
    final nameController = TextEditingController();
    final currencyController = TextEditingController(text: '₹');
    final scaffoldContext = context;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Create Group', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Group Name',
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
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              try {
                final client = ApiClient();
                final res = await client.post(ApiEndpoints.createTrip, {
                  'action': 'create',
                  'name': name,
                  'currency_symbol': currencyController.text.trim(),
                });
                if (res['success'] == true) {
                  if (scaffoldContext.mounted) {
                    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                      const SnackBar(content: Text('Group created!'), backgroundColor: AppColors.positive),
                    );
                    Provider.of<AuthService>(scaffoldContext, listen: false).checkAuth();
                  }
                }
              } catch (e) {
                if (scaffoldContext.mounted) {
                  ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                    SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.negative),
                  );
                }
              }
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

  void _showJoinGroupDialog(BuildContext context, bool isDark) {
    final codeController = TextEditingController();
    final scaffoldContext = context;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Join Group', style: TextStyle(fontWeight: FontWeight.w800)),
        content: TextField(
          controller: codeController,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: 'Group Code',
            hintText: 'e.g. GRPX-ABCD',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = codeController.text.trim().toUpperCase();
              if (code.isEmpty) return;
              Navigator.pop(ctx);
              try {
                final client = ApiClient();
                final res = await client.post(ApiEndpoints.joinTrip, {'trip_code': code});
                if (res['success'] == true) {
                  if (scaffoldContext.mounted) {
                    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                      const SnackBar(content: Text('Joined group!'), backgroundColor: AppColors.positive),
                    );
                    Provider.of<AuthService>(scaffoldContext, listen: false).checkAuth();
                  }
                }
              } catch (e) {
                if (scaffoldContext.mounted) {
                  ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                    SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.negative),
                  );
                }
              }
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
}
