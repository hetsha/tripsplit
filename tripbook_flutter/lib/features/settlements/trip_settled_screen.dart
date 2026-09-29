import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/tripsplit_widgets.dart';

class TripSettledScreen extends StatelessWidget {
  const TripSettledScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final membersStatus = [
      {
        'name': 'You (Het)',
        'paid': '₹ 8,540',
        'share': '₹ 6,490',
        'status': '+₹ 2,050',
        'statusLabel': 'You received',
        'isPositive': true,
        'avatar': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
      },
      {
        'name': 'Rahul',
        'paid': '₹ 8,500',
        'share': '₹ 6,490',
        'status': '-₹ 2,050',
        'statusLabel': 'You paid',
        'isPositive': false,
        'avatar': 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=100',
      },
      {
        'name': 'Priya',
        'paid': '₹ 6,200',
        'share': '₹ 6,490',
        'status': '-₹ 290',
        'statusLabel': 'You paid',
        'isPositive': false,
        'avatar': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100',
      },
      {
        'name': 'Amit',
        'paid': '₹ 5,940',
        'share': '₹ 6,490',
        'status': '-₹ 550',
        'statusLabel': 'You paid',
        'isPositive': false,
        'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
      },
      {
        'name': 'Neha',
        'paid': '₹ 4,870',
        'share': '₹ 6,490',
        'status': '-₹ 1,620',
        'statusLabel': 'You paid',
        'isPositive': false,
        'avatar': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100',
      },
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header
            TripSplitHeader(
              title: '',
              showBack: true,
              onBack: () => Navigator.of(context).maybePop(),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
                child: Column(
                  children: [
                    // Glowing Green Checkmark Circle
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF10B981),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.4),
                            blurRadius: 24,
                            spreadRadius: 4,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.check_rounded, color: Colors.white, size: 48),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Success Headline
                    Text(
                      'Trip Successfully Settled!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'All expenses have been settled among 5 members.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Trip Summary Card
                    TripSplitCard(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              'https://images.unsplash.com/photo-1512343879784-a960bf40e7f2?w=200',
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Goa Trip ✈️',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '12 - 16 Dec 2024 • Goa, India',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.brandLavender,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.star_rounded, size: 12, color: AppColors.primary),
                                SizedBox(width: 4),
                                Text(
                                  'Settled',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Settlement Details Stat Card
                    TripSplitCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMiniStat('5', 'Members', isDark),
                          _buildMiniStat('₹ 8,540', 'You Paid', isDark),
                          _buildMiniStat('₹ 6,490', 'Your Share', isDark),
                          _buildMiniStat('₹ 2,050', 'You Received', isDark, isHighlight: true),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Final Status Header
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Final Status',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Final Status Member Cards
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: membersStatus.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, index) {
                        final item = membersStatus[index];
                        final isPositive = item['isPositive'] as bool;

                        return TripSplitCard(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundImage: NetworkImage(item['avatar'] as String),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'] as String,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Paid: ${item['paid']} • Share: ${item['share']}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    item['status'] as String,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: isPositive ? AppColors.positiveText : AppColors.negativeText,
                                    ),
                                  ),
                                  Text(
                                    item['statusLabel'] as String,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: isPositive ? AppColors.positiveText : AppColors.negativeText,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Two Buttons: View Trip & Back to Home
                    Row(
                      children: [
                        Expanded(
                          child: TripSplitSecondaryButton(
                            label: 'View Trip',
                            icon: const Icon(Icons.remove_red_eye_outlined, size: 18, color: AppColors.primary),
                            onPressed: () => Navigator.of(context).pushNamed('/dashboard'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TripSplitButton(
                            label: 'Back to Home',
                            icon: const Icon(Icons.home_rounded, color: Colors.white, size: 18),
                            onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false),
                          ),
                        ),
                      ],
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

  Widget _buildMiniStat(String value, String label, bool isDark, {bool isHighlight = false}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: isHighlight
                ? AppColors.positiveText
                : (isDark ? AppColors.textDarkMain : AppColors.textLightMain),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
          ),
        ),
      ],
    );
  }
}
