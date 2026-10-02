import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/tripsplit_widgets.dart';
import 'create_trip_screen.dart';

class GroupTypeItem {
  final String key;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final List<String> tags;
  final String defaultName;
  final String defaultDestination;
  final String coverUrl;

  const GroupTypeItem({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.tags,
    required this.defaultName,
    required this.defaultDestination,
    required this.coverUrl,
  });
}

class SelectGroupTypeScreen extends StatelessWidget {
  const SelectGroupTypeScreen({Key? key}) : super(key: key);

  static const List<GroupTypeItem> groupTypes = [
    GroupTypeItem(
      key: 'home',
      title: 'Home',
      subtitle: 'Flatmates, rent, wifi, electricity, groceries & household bills',
      icon: Icons.home_rounded,
      gradient: [Color(0xFF10B981), Color(0xFF059669)],
      tags: ['Apartment', 'Housemates', 'Rent & Bills'],
      defaultName: 'Apartment 302',
      defaultDestination: 'Home, Sweet Home',
      coverUrl: 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800',
    ),
    GroupTypeItem(
      key: 'trip',
      title: 'Trip',
      subtitle: 'Vacations, weekend road trips, flights, hotels & adventures',
      icon: Icons.flight_takeoff_rounded,
      gradient: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
      tags: ['Vacations', 'Road Trips', 'Flights & Hotels'],
      defaultName: 'Goa Trip 2025',
      defaultDestination: 'Goa, India',
      coverUrl: 'https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?w=800',
    ),
    GroupTypeItem(
      key: 'couple',
      title: 'Couple',
      subtitle: 'Dates, dinners, movies, groceries & daily life with your partner',
      icon: Icons.favorite_rounded,
      gradient: [Color(0xFFEC4899), Color(0xFFF43F5E)],
      tags: ['Partners', 'Dates & Dinners', 'Shared Life'],
      defaultName: 'Us ❤️',
      defaultDestination: 'Everyday Moments',
      coverUrl: 'https://images.unsplash.com/photo-1516589178581-6cd7833ae3b2?w=800',
    ),
    GroupTypeItem(
      key: 'personal',
      title: 'Personal',
      subtitle: 'Solo budget tracking, pocketbook, daily expenses & cash log',
      icon: Icons.person_rounded,
      gradient: [Color(0xFF06B6D4), Color(0xFF0284C7)],
      tags: ['Solo Spending', 'Personal Budget', 'Pocketbook'],
      defaultName: 'Personal Wallet',
      defaultDestination: 'Daily Spending',
      coverUrl: 'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?w=800',
    ),
    GroupTypeItem(
      key: 'business',
      title: 'Business / Office',
      subtitle: 'Coworkers, office lunches, client dinners & team project expenses',
      icon: Icons.business_center_rounded,
      gradient: [Color(0xFFF59E0B), Color(0xFFD97706)],
      tags: ['Work Team', 'Office Lunches', 'Client Projects'],
      defaultName: 'Office & Projects',
      defaultDestination: 'Tech Hub Office',
      coverUrl: 'https://images.unsplash.com/photo-1497366216548-37526070297c?w=800',
    ),
  ];

  void _onSelectType(BuildContext context, GroupTypeItem item) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CreateTripScreen(initialType: item.key),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header Bar
            TripSplitHeader(
              title: 'Create Group / Vault',
              subtitle: 'Select category to get started',
              onBack: () => Navigator.of(context).maybePop(),
            ),

            // Category Cards List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                itemCount: groupTypes.length,
                itemBuilder: (ctx, index) {
                  final item = groupTypes[index];
                  return _buildTypeCard(context, item, isDark);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeCard(BuildContext context, GroupTypeItem item, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151D2F) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF222F43) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : item.gradient.first.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => _onSelectType(context, item),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Avatar with Gradient Background
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: item.gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: item.gradient.first.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    item.icon,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),

                // Card Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: item.gradient.first.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 13,
                              color: item.gradient.first,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Pills / Tags
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: item.tags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.06)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.textDarkMuted
                                    : Colors.grey.shade700,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
