import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/tripsplit_widgets.dart';

class TripSettingsScreen extends StatefulWidget {
  const TripSettingsScreen({Key? key}) : super(key: key);

  @override
  State<TripSettingsScreen> createState() => _TripSettingsScreenState();
}

class _TripSettingsScreenState extends State<TripSettingsScreen> {
  final _tripNameCtrl = TextEditingController(text: 'Goa Trip');
  final _destinationCtrl = TextEditingController(text: 'Goa, India');
  final _startDateCtrl = TextEditingController(text: '12 Dec 2024');
  final _endDateCtrl = TextEditingController(text: '16 Dec 2024');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                          const SnackBar(content: Text('Photo selector opened')),
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
                          ),
                          const SizedBox(height: 12),
                          TripSplitTextField(
                            label: 'Destination',
                            controller: _destinationCtrl,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TripSplitTextField(
                                  label: 'Start Date',
                                  controller: _startDateCtrl,
                                  prefixIcon: Icons.calendar_today_rounded,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TripSplitTextField(
                                  label: 'End Date',
                                  controller: _endDateCtrl,
                                  prefixIcon: Icons.calendar_today_rounded,
                                ),
                              ),
                            ],
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
                            onTap: () => Navigator.of(context).pushNamed('/members'),
                            isDark: isDark,
                          ),
                          Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
                          _buildMenuTile(
                            icon: Icons.receipt_long_rounded,
                            iconColor: const Color(0xFF8B5CF6),
                            title: 'View All Expenses',
                            onTap: () => Navigator.of(context).pushNamed('/all_expenses'),
                            isDark: isDark,
                          ),
                          Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
                          _buildMenuTile(
                            icon: Icons.edit_rounded,
                            iconColor: const Color(0xFF0EA5E9),
                            title: 'Edit Trip Details',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Trip details updated')),
                              );
                            },
                            isDark: isDark,
                          ),
                          Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
                          _buildMenuTile(
                            icon: Icons.picture_as_pdf_rounded,
                            iconColor: const Color(0xFFEC4899),
                            title: 'Download Report (PDF)',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Downloading Goa Trip PDF report...')),
                              );
                            },
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Delete Trip Button (Red Outline)
                    TripSplitSecondaryButton(
                      label: 'Delete Trip',
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.negative, size: 20),
                      borderColor: AppColors.negative.withOpacity(0.5),
                      textColor: AppColors.negative,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: const Text('Delete Trip?', style: TextStyle(fontWeight: FontWeight.w700)),
                            content: const Text('Are you sure you want to delete "Goa Trip"? All expenses and balances will be removed.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.negative),
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  Navigator.of(context).pushNamed('/dashboard');
                                },
                                child: const Text('Delete', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                      },
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

  Widget _buildMenuTile({
    required IconData icon,
    required Color iconColor,
    required String title,
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
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: isDark ? AppColors.textDarkMuted : Colors.grey.shade400,
      ),
    );
  }
}
