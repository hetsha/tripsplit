import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_notifier.dart';
import '../../widgets/tripsplit_widgets.dart';
import '../../widgets/tripsplit_payment_card.dart';

class AllGroupsHomeScreen extends StatefulWidget {
  const AllGroupsHomeScreen({Key? key}) : super(key: key);

  @override
  State<AllGroupsHomeScreen> createState() => _AllGroupsHomeScreenState();
}

class _AllGroupsHomeScreenState extends State<AllGroupsHomeScreen> {
  int _selectedFilterIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _filters = ['All Trips (4)', 'Active (3)', 'Settled (1)'];

  final List<Map<String, dynamic>> _groups = [
    {
      'id': 1,
      'title': 'Goa Trip ✈️',
      'destination': 'Goa, India',
      'dates': '12 - 16 Dec 2024',
      'image': 'https://images.unsplash.com/photo-1512343879784-a960bf40e7f2?w=800&auto=format&fit=crop&q=80',
      'membersCount': 5,
      'totalSpent': '₹ 24,650',
      'totalBudget': '₹ 32,450',
      'spentPercent': 0.76,
      'netAmount': '+₹ 2,050',
      'netLabel': 'You Receive',
      'isPositive': true,
      'isSettled': false,
      'category': 'Beach Holiday',
      'categoryIcon': Icons.beach_access_rounded,
      'categoryColor': Color(0xFF06B6D4),
      'avatars': [
        'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
        'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=100',
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100',
      ],
    },
    {
      'id': 2,
      'title': 'Manali Winter Trip 🏔️',
      'destination': 'Manali, Himachal',
      'dates': '5 - 10 Jan 2025',
      'image': 'https://images.unsplash.com/photo-1517411032315-54ef2cb783bb?w=800&auto=format&fit=crop&q=80',
      'membersCount': 4,
      'totalSpent': '₹ 18,200',
      'totalBudget': '₹ 25,000',
      'spentPercent': 0.73,
      'netAmount': '+₹ 2,070',
      'netLabel': 'You Receive',
      'isPositive': true,
      'isSettled': false,
      'category': 'Snow Adventure',
      'categoryIcon': Icons.downhill_skiing_rounded,
      'categoryColor': Color(0xFF6366F1),
      'avatars': [
        'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
      ],
    },
    {
      'id': 3,
      'title': 'Weekend Roadtrip 🚗',
      'destination': 'Lonavala & Khandala',
      'dates': '22 - 24 Nov 2024',
      'image': 'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?w=800&auto=format&fit=crop&q=80',
      'membersCount': 3,
      'totalSpent': '₹ 6,400',
      'totalBudget': '₹ 8,000',
      'spentPercent': 0.80,
      'netAmount': '-₹ 850',
      'netLabel': 'You Owe',
      'isPositive': false,
      'isSettled': false,
      'category': 'Weekend Trip',
      'categoryIcon': Icons.directions_car_rounded,
      'categoryColor': Color(0xFFF59E0B),
      'avatars': [
        'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
        'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100',
      ],
    },
    {
      'id': 4,
      'title': 'Udaipur Heritage Tour 🏰',
      'destination': 'Udaipur, Rajasthan',
      'dates': '10 - 14 Oct 2024',
      'image': 'https://images.unsplash.com/photo-1599661046289-e31897846e41?w=800&auto=format&fit=crop&q=80',
      'membersCount': 5,
      'totalSpent': '₹ 42,000',
      'totalBudget': '₹ 42,000',
      'spentPercent': 1.0,
      'netAmount': '₹ 0',
      'netLabel': 'All Settled',
      'isPositive': true,
      'isSettled': true,
      'category': 'Heritage Tour',
      'categoryIcon': Icons.castle_rounded,
      'categoryColor': Color(0xFFEC4899),
      'avatars': [
        'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
        'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=100',
      ],
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = Provider.of<AuthService>(context);
    final currentUser = auth.currentUser;
    final loginPhone = (currentUser?.phone != null && currentUser!.phone!.isNotEmpty)
        ? currentUser.phone!
        : '9876543210';
    final cardHolder = (currentUser?.name != null && currentUser!.name.isNotEmpty)
        ? currentUser.name.toUpperCase()
        : 'HET SHAH';

    final displayedGroups = _groups.where((g) {
      if (_selectedFilterIndex == 1 && (g['isSettled'] as bool)) return false;
      if (_selectedFilterIndex == 2 && !(g['isSettled'] as bool)) return false;

      if (_searchQuery.isNotEmpty) {
        final title = (g['title'] as String).toLowerCase();
        final dest = (g['destination'] as String).toLowerCase();
        final q = _searchQuery.toLowerCase();
        if (!title.contains(q) && !dest.contains(q)) return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF090D16) : const Color(0xFFF6F8FC),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Greeting, Screens switcher & Profile
            _buildHeader(isDark, cardHolder),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Security Vault Label
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF59E0B),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'TRIPSPLIT DIGITAL VAULT',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  color: isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.lock_outline_rounded, size: 11, color: Color(0xFFF59E0B)),
                                SizedBox(width: 4),
                                Text(
                                  '256-Bit Encrypted',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFFF59E0B)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 1. PAYMENT CARD (KEPT UNCHANGED AS REQUESTED)
                    TripSplitPaymentCard(
                      cardHolder: cardHolder,
                      loginNumber: loginPhone,
                      balance: '₹ 32,450',
                      toReceive: '+₹ 4,120',
                      toPay: '-₹ 850',
                      onTap: () => Navigator.of(context).pushNamed('/dashboard'),
                    ),

                    const SizedBox(height: 18),

                    // 2. DEDICATED EXPENSE ACTION BAR (PERSONAL OR TRIP)
                    _buildExpenseActionSection(context, isDark),

                    const SizedBox(height: 18),

                    // 3. STATS STRIP
                    _buildStatsRow(isDark),

                    const SizedBox(height: 22),

                    // 4. SEARCH & FILTER PILLS
                    _buildSearchBar(isDark),

                    const SizedBox(height: 14),

                    // Section Title Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Your Travel Groups',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                            letterSpacing: -0.3,
                          ),
                        ),
                        // Filter Pills
                        Row(
                          children: List.generate(_filters.length, (index) {
                            final isSelected = index == _selectedFilterIndex;
                            final label = _filters[index].split(' ').first;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedFilterIndex = index),
                              child: Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : (isDark ? AppColors.surfaceDark : Colors.white),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : (isDark ? AppColors.borderDark : AppColors.borderLight),
                                  ),
                                ),
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark ? AppColors.textDarkMuted : AppColors.textLightMain),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // 5. REDESIGNED TRIP CARDS SECTION
                    if (displayedGroups.isEmpty)
                      _buildEmptyState(isDark)
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: displayedGroups.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (ctx, index) {
                          return _buildNewTripCardStyle(context, displayedGroups[index], isDark);
                        },
                      ),

                    const SizedBox(height: 20),

                    // Plan New Adventure Action Button
                    Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: AppColors.brandGradient,
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pushNamed('/create_trip'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_location_alt_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 10),
                            Text(
                              'Plan a New Adventure',
                              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                            SizedBox(width: 6),
                            Icon(Icons.arrow_forward_rounded, color: Colors.white70, size: 16),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom Navigation
            _buildBottomNav(context, isDark),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // ==========================================
  // BRAND NEW TRIP CARD DESIGN STYLE (LIGHT & DARK MODES)
  // ==========================================
  Widget _buildNewTripCardStyle(BuildContext context, Map<String, dynamic> group, bool isDark) {
    final isSettled = group['isSettled'] as bool;
    final isPositive = group['isPositive'] as bool;
    final categoryIcon = (group['categoryIcon'] as IconData?) ?? Icons.travel_explore_rounded;
    final avatars = (group['avatars'] as List<String>?) ?? [];

    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/dashboard'),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141A28) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? const Color(0xFF222B3D) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          boxShadow: isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: const Color(0xFF64748B).withOpacity(0.09),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: const Color(0xFF6C38FF).withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(23),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TOP PANORAMIC COVER BANNER (135px)
              Stack(
                children: [
                  Image.network(
                    group['image'] as String,
                    height: 135,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 135,
                      color: AppColors.primary,
                    ),
                  ),
                  // Rich Dark Vignette Overlay for High Legibility
                  Container(
                    height: 135,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.20),
                          Colors.black.withOpacity(0.85),
                        ],
                      ),
                    ),
                  ),

                  // Destination Chip (Top Left)
                  Positioned(
                    left: 14,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24, width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on_rounded, size: 12, color: Color(0xFFFDE047)),
                          const SizedBox(width: 4),
                          Text(
                            group['destination'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Status Badge (Top Right)
                  Positioned(
                    right: 14,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSettled
                            ? const Color(0xFF8B5CF6)
                            : const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: (isSettled ? const Color(0xFF8B5CF6) : const Color(0xFF10B981)).withOpacity(0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Text(
                        isSettled ? '★ SETTLED' : '● ACTIVE',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                  // Trip Title, Dates & Category on Banner Bottom
                  Positioned(
                    left: 14,
                    bottom: 12,
                    right: 14,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                group['title'] as String,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  shadows: [Shadow(color: Colors.black87, blurRadius: 6)],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded, size: 12, color: Colors.white70),
                                  const SizedBox(width: 4),
                                  Text(
                                    group['dates'] as String,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Category Pill
                        if (group['category'] != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.45),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white24, width: 0.8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(categoryIcon, size: 12, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  group['category'] as String,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              // 2. CARD BODY: Financial Metrics & Social
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  children: [
                    // Overall Total Trip Expense (No Budget)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(isDark ? 0.18 : 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.receipt_long_rounded,
                                size: 16,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TOTAL TRIP EXPENSE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                    color: isDark ? AppColors.textDarkMuted : const Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  group['totalSpent'] as String,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.4,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.payments_outlined,
                                size: 13,
                                color: isDark ? AppColors.textDarkMuted : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Full Trip',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.textDarkMuted : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    Divider(height: 1, color: isDark ? const Color(0xFF222B3D) : const Color(0xFFF1F5F9)),
                    const SizedBox(height: 10),

                    // Bottom Row: Friends Avatars + Financial Settlement Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Overlapping Friends Avatars
                        Row(
                          children: [
                            SizedBox(
                              height: 28,
                              width: 56,
                              child: Stack(
                                children: [
                                  for (int i = 0; i < avatars.length && i < 2; i++)
                                    Positioned(
                                      left: i * 15.0,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            if (!isDark)
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.08),
                                                blurRadius: 3,
                                                offset: const Offset(0, 1),
                                              ),
                                          ],
                                          border: Border.all(
                                            color: isDark ? const Color(0xFF141A28) : Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: CircleAvatar(
                                          radius: 12,
                                          backgroundImage: NetworkImage(avatars[i]),
                                        ),
                                      ),
                                    ),
                                  Positioned(
                                    left: 30.0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          if (!isDark)
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.08),
                                              blurRadius: 3,
                                              offset: const Offset(0, 1),
                                            ),
                                        ],
                                        border: Border.all(
                                          color: isDark ? const Color(0xFF141A28) : Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        radius: 12,
                                        backgroundColor: AppColors.primary,
                                        child: Text(
                                          '+${group['membersCount'] - 2}',
                                          style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${group['membersCount']} friends',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.textDarkMuted : const Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),

                        // Financial Settlement Badge with integrated Arrow
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                            decoration: BoxDecoration(
                              color: isSettled
                                  ? (isDark ? const Color(0xFF8B5CF6).withOpacity(0.18) : const Color(0xFFF5F3FF))
                                  : (isPositive
                                      ? (isDark ? const Color(0xFF10B981).withOpacity(0.18) : const Color(0xFFECFDF5))
                                      : (isDark ? const Color(0xFFEF4444).withOpacity(0.18) : const Color(0xFFFEF2F2))),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSettled
                                    ? (isDark ? const Color(0xFF8B5CF6).withOpacity(0.35) : const Color(0xFFDDD6FE))
                                    : (isPositive
                                        ? (isDark ? const Color(0xFF10B981).withOpacity(0.35) : const Color(0xFFA7F3D0))
                                        : (isDark ? const Color(0xFFEF4444).withOpacity(0.35) : const Color(0xFFFECACA))),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isSettled
                                      ? Icons.check_circle_rounded
                                      : (isPositive ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded),
                                  size: 12,
                                  color: isSettled
                                      ? (isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED))
                                      : (isPositive
                                          ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
                                          : (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626))),
                                ),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    isSettled
                                        ? 'All Settled'
                                        : (isPositive
                                            ? 'Receive ${group['netAmount']}'
                                            : 'Owe ${group['netAmount']}'),
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: isSettled
                                          ? (isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED))
                                          : (isPositive
                                              ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
                                              : (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626))),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 13,
                                  color: isSettled
                                      ? (isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED))
                                      : (isPositive
                                          ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
                                          : (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626))),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Header Bar
  Widget _buildHeader(bool isDark, String cardHolder) {
    final firstName = cardHolder.split(' ').first;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              gradient: const LinearGradient(
                colors: AppColors.brandGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.flight_takeoff_rounded, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Hello, $firstName',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('👋', style: TextStyle(fontSize: 15)),
                  ],
                ),
                Text(
                  '4 Active Travel Groups',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => TripSplitScreenNavigator.show(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.25), width: 1),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.dashboard_customize_rounded, size: 14, color: AppColors.primary),
                  SizedBox(width: 4),
                  Text(
                    'Screens',
                    style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Quick Theme Toggle (Sun / Moon)
          GestureDetector(
            onTap: () {
              Provider.of<ThemeNotifier>(context, listen: false).toggleTheme();
            },
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131A29) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF222F43) : const Color(0xFFE2E8F0),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                size: 15,
                color: isDark ? const Color(0xFFFDE047) : const Color(0xFF6C38FF),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.of(context).pushNamed('/profile'),
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: const CircleAvatar(
                    radius: 16,
                    backgroundImage: NetworkImage(
                      'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
                    ),
                  ),
                ),
                Positioned(
                  right: 1,
                  bottom: 1,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF090D16) : Colors.white,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Dedicated Expense Action Bar
  Widget _buildExpenseActionSection(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () => _showExpenseTypeBottomSheet(context, isDark),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131A29) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? const Color(0xFF222F43) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.25)
                  : const Color(0xFF6366F1).withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Gradient Icon Box
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_card_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            // Text Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Expense',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Record Personal or Trip Expense',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                    ),
                  ),
                ],
              ),
            ),
            // Action Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Add',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Expense Type Modal Bottom Sheet: Asks Personal or Trip
  void _showExpenseTypeBottomSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF111726) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: isDark ? const Color(0xFF222F43) : const Color(0xFFE2E8F0),
            ),
          ),
          padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(ctx).padding.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pull Handle
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What type of expense?',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Choose where to record this transaction',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 1. Personal Expense Option
              GestureDetector(
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pushNamed(
                    '/add_expense',
                    arguments: {'isPersonal': true},
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF172033) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark ? const Color(0xFF24324D) : const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.person_rounded, color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Personal Expense',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Private',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Only for you • Recorded in your personal cashbook',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primary),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // 2. Trip Expense Option
              GestureDetector(
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showSelectActiveTripBottomSheet(context, isDark);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF172033) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark ? const Color(0xFF24324D) : const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.flight_takeoff_rounded, color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Trip / Group Expense',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6366F1).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Shared',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF6366F1),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Choose active trip • Split with members',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Active Trips Selection Bottom Sheet: Shows ONLY ACTIVE TRIPS
  void _showSelectActiveTripBottomSheet(BuildContext context, bool isDark) {
    // Filter strictly for ACTIVE trips only (isSettled == false)
    final activeTrips = _groups.where((g) => !(g['isSettled'] as bool)).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF111726) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: isDark ? const Color(0xFF222F43) : const Color(0xFFE2E8F0),
            ),
          ),
          padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(ctx).padding.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Active Trip',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${activeTrips.length} Active Trips available for expenses',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...activeTrips.map((trip) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).pushNamed(
                        '/add_expense',
                        arguments: {
                          'isPersonal': false,
                          'trip': trip,
                          'activeTrips': activeTrips,
                        },
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF172033) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? const Color(0xFF24324D) : const Color(0xFFE2E8F0),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              trip['image'] as String,
                              width: 52,
                              height: 52,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 52,
                                height: 52,
                                color: AppColors.primary,
                                child: const Icon(Icons.flight_takeoff_rounded, color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        trip['title'] as String,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'ACTIVE',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF10B981),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${trip['destination']} • ${trip['membersCount']} friends',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Total Spent: ${trip['totalSpent']}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  // Stats Strip
  Widget _buildStatsRow(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131A29) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF222F43) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat('4 Trips', '3 Active', const Color(0xFF6366F1), Icons.flight_rounded, isDark),
          Container(width: 1, height: 28, color: isDark ? Colors.white12 : Colors.black12),
          _buildStat('₹ 91,250', 'Total Spent', const Color(0xFF10B981), Icons.currency_rupee_rounded, isDark),
          Container(width: 1, height: 28, color: isDark ? Colors.white12 : Colors.black12),
          _buildStat('12 Friends', 'Connected', const Color(0xFFF59E0B), Icons.group_rounded, isDark),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label, Color accentColor, IconData icon, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 13, color: accentColor),
        ),
        const SizedBox(width: 7),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Search Bar
  Widget _buildSearchBar(bool isDark) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131A29) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF222F43) : const Color(0xFFE2E8F0),
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val.trim()),
        style: TextStyle(
          fontSize: 13,
          color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
        ),
        decoration: InputDecoration(
          hintText: 'Search trips, cities, or friends...',
          hintStyle: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.textDarkMuted : Colors.grey.shade400,
          ),
          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.primary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 15),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  // Empty State
  Widget _buildEmptyState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131A29) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? const Color(0xFF222F43) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 40, color: isDark ? Colors.white38 : Colors.grey.shade400),
          const SizedBox(height: 10),
          Text(
            'No trips found',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try searching for another keyword or filter',
            style: TextStyle(fontSize: 11, color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
                _selectedFilterIndex = 0;
              });
            },
            child: const Text('Reset Filters'),
          ),
        ],
      ),
    );
  }

  // Bottom Navigation Bar
  Widget _buildBottomNav(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavItem(
                icon: Icons.travel_explore_rounded,
                label: 'Trips',
                isActive: true,
                isDark: isDark,
                onTap: () {},
              ),
              _buildBottomNavItem(
                icon: Icons.photo_library_rounded,
                label: 'Gallery',
                isActive: false,
                isDark: isDark,
                onTap: () => _showTripGallerySelectionModal(context, isDark),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pushNamed('/create_trip'),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: AppColors.brandGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.45),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
              _buildBottomNavItem(
                icon: Icons.balance_rounded,
                label: 'Settle',
                isActive: false,
                isDark: isDark,
                onTap: () => Navigator.of(context).pushNamed('/settle_up'),
              ),
              _buildBottomNavItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                isActive: false,
                isDark: isDark,
                onTap: () => Navigator.of(context).pushNamed('/profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 21,
              color: isActive
                  ? AppColors.primary
                  : (isDark ? AppColors.textDarkMuted : AppColors.textLightMuted),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                color: isActive
                    ? AppColors.primary
                    : (isDark ? AppColors.textDarkMuted : AppColors.textLightMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTripGallerySelectionModal(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF111726) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: isDark ? const Color(0xFF222F43) : const Color(0xFFE2E8F0),
            ),
          ),
          padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(ctx).padding.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.photo_library_rounded, color: AppColors.primary, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Select Trip Gallery',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Which trip\'s shared memories do you want to view?',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // List of trips with photos count
              ..._groups.map((trip) {
                final photoCount = trip['id'] == 1
                    ? 24
                    : (trip['id'] == 2 ? 18 : (trip['id'] == 3 ? 12 : 35));

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF192236) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF28364F) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        trip['image'] as String,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(
                      trip['title'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    subtitle: Row(
                      children: [
                        const Icon(Icons.photo_outlined, size: 12, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          '$photoCount Photos • ${trip['dates']}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                          ),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).pushNamed(
                        '/gallery',
                        arguments: {
                          'tripId': trip['id'],
                          'tripTitle': trip['title'],
                        },
                      );
                    },
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }
}
