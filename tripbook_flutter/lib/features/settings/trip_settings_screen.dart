import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/tripsplit_widgets.dart';
import '../../services/auth_service.dart';

class TripSettingsScreen extends StatefulWidget {
  const TripSettingsScreen({Key? key}) : super(key: key);

  @override
  State<TripSettingsScreen> createState() => _TripSettingsScreenState();
}

class _TripSettingsScreenState extends State<TripSettingsScreen> {
  final _tripNameCtrl = TextEditingController();
  final _destinationCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();

  int? _tripId;
  bool _initialized = false;
  bool _isSaving = false;
  bool _isDeleting = false;
  String _userRole = 'member';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final auth = Provider.of<AuthService>(context, listen: false);
      _tripId = args?['tripId'] ?? args?['trip']?['id'] ?? auth.activeTripId;

      if (_tripId != null && auth.detailedTrips.isNotEmpty) {
        final trip = auth.detailedTrips.firstWhere(
          (t) => t['id'] == _tripId,
          orElse: () => auth.detailedTrips.first,
        );
        _tripNameCtrl.text = trip['title'] ?? trip['name'] ?? '';
        _destinationCtrl.text = trip['destination'] ?? '';
        final startMoney = trip['starting_money'] ?? trip['total_budget'];
        if (startMoney != null && (startMoney as num) > 0) {
          _budgetCtrl.text = startMoney.toString();
        }
        _userRole = trip['role'] as String? ?? 'member';
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _tripNameCtrl.dispose();
    _destinationCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleUpdateTrip() async {
    final name = _tripNameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip name cannot be empty')),
      );
      return;
    }

    if (_tripId == null) return;

    setState(() => _isSaving = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final budget = double.tryParse(_budgetCtrl.text.replaceAll(',', '').trim()) ?? 0.0;

      await auth.updateTrip(
        tripId: _tripId!,
        name: name,
        description: _destinationCtrl.text.trim(),
        startingMoney: budget,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip settings saved successfully! 🎉'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update trip: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleDeleteTrip() async {
    if (_tripId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Trip?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text(
          'Are you sure you want to delete this trip? All recorded expenses and splits for this trip will be permanently removed from the database.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete Trip', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isDeleting = true);
      try {
        final auth = Provider.of<AuthService>(context, listen: false);
        await auth.deleteTrip(tripId: _tripId!);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Trip deleted successfully')),
          );
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not delete trip: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOwner = _userRole == 'owner' || _userRole == 'creator';

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header
            TripSplitHeader(
              title: 'Trip Settings',
              onBack: () => Navigator.of(context).maybePop(),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Column(
                  children: [
                    // Banner Photo with Change Photo Button
                    TripSplitCoverBanner(
                      height: 120,
                      onChangePhoto: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Photo updated for trip cover banner')),
                        );
                      },
                    ),

                    const SizedBox(height: 14),

                    // Inputs Card
                    TripSplitCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TripSplitTextField(
                            label: 'Trip Name',
                            controller: _tripNameCtrl,
                            prefixIcon: Icons.flight_takeoff_rounded,
                          ),
                          const SizedBox(height: 12),
                          TripSplitTextField(
                            label: 'Destination / Description',
                            controller: _destinationCtrl,
                            prefixIcon: Icons.location_on_outlined,
                          ),
                          const SizedBox(height: 12),
                          TripSplitTextField(
                            label: 'Starting Pool / Budget (₹)',
                            controller: _budgetCtrl,
                            prefixIcon: Icons.account_balance_wallet_outlined,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 18),
                          TripSplitButton(
                            label: _isSaving ? 'Saving Changes...' : 'Save Trip Changes',
                            trailingIcon: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                            onPressed: _isSaving ? () {} : _handleUpdateTrip,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Settings Menu Options Card
                    TripSplitCard(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        children: [
                          _buildMenuTile(
                            icon: Icons.group_rounded,
                            iconColor: const Color(0xFF6366F1),
                            title: 'Manage Members',
                            onTap: () => Navigator.of(context).pushNamed(
                              '/members',
                              arguments: {'tripId': _tripId},
                            ),
                            isDark: isDark,
                          ),
                          Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
                          _buildMenuTile(
                            icon: Icons.receipt_long_rounded,
                            iconColor: const Color(0xFF8B5CF6),
                            title: 'View All Expenses',
                            onTap: () => Navigator.of(context).pushNamed(
                              '/all_expenses',
                              arguments: {'tripId': _tripId},
                            ),
                            isDark: isDark,
                          ),
                          Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
                          _buildMenuTile(
                            icon: Icons.balance_rounded,
                            iconColor: const Color(0xFF10B981),
                            title: 'Settlement & Debts',
                            onTap: () => Navigator.of(context).pushNamed(
                              '/settle_up',
                              arguments: {'tripId': _tripId},
                            ),
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Delete Trip Button (Owner only or Red Outline)
                    if (isOwner)
                      TripSplitSecondaryButton(
                        label: _isDeleting ? 'Deleting Trip...' : 'Delete Trip',
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.negative, size: 20),
                        borderColor: AppColors.negative.withOpacity(0.5),
                        textColor: AppColors.negative,
                        onPressed: _isDeleting ? () {} : _handleDeleteTrip,
                      ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: isDark ? AppColors.textDarkMuted : Colors.grey.shade400,
      ),
      onTap: onTap,
    );
  }
}
