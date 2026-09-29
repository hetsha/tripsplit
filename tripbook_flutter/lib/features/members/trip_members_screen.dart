import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/tripsplit_widgets.dart';

class TripMembersScreen extends StatelessWidget {
  const TripMembersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final members = [
      {
        'name': 'You (Het)',
        'role': 'Creator',
        'paid': '₹ 8,540',
        'share': '₹ 6,490',
        'avatar': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=120',
        'isCreator': true,
      },
      {
        'name': 'Rahul',
        'role': 'Member',
        'paid': '₹ 8,000',
        'share': '₹ 6,490',
        'avatar': 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=120',
        'isCreator': false,
      },
      {
        'name': 'Priya',
        'role': 'Member',
        'paid': '₹ 6,200',
        'share': '₹ 6,490',
        'avatar': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=120',
        'isCreator': false,
      },
      {
        'name': 'Amit',
        'role': 'Member',
        'paid': '₹ 5,940',
        'share': '₹ 6,490',
        'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=120',
        'isCreator': false,
      },
      {
        'name': 'Neha',
        'role': 'Member',
        'paid': '₹ 4,870',
        'share': '₹ 6,490',
        'avatar': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=120',
        'isCreator': false,
      },
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header Bar
            TripSplitHeader(
              title: 'Trip Members',
              rightAction: GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Add Member dialog')),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 16, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Add Member',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              onBack: () => Navigator.of(context).maybePop(),
            ),

            const SizedBox(height: 8),

            // Members List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: members.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, index) {
                  final member = members[index];
                  final isCreator = member['isCreator'] as bool;

                  return TripSplitCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        TripSplitAvatar(
                          name: member['name'] as String,
                          imageUrl: member['avatar'] as String,
                          radius: 24,
                          isCreator: isCreator,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    member['name'] as String,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                                    ),
                                  ),
                                  if (isCreator) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Creator',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFFD97706),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Paid: ${member['paid']}   |   Share: ${member['share']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: isDark ? AppColors.textDarkMuted : Colors.grey.shade400,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Tropical Palm Leaf Illustration Footer
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Opacity(
                opacity: 0.7,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.park_rounded, color: AppColors.primary.withOpacity(0.3), size: 28),
                    const SizedBox(width: 6),
                    Text(
                      'Split smartly with your travel crew',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
