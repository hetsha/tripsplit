import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/tripsplit_widgets.dart';

class SettleUpScreen extends StatefulWidget {
  final int? initialTripId;

  const SettleUpScreen({Key? key, this.initialTripId}) : super(key: key);

  @override
  State<SettleUpScreen> createState() => _SettleUpScreenState();
}

class _SettleUpScreenState extends State<SettleUpScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTripIndex = 0;
  int _selectedPaymentMethod = 0;

  final List<Map<String, dynamic>> _paymentMethods = [
    {'title': 'UPI', 'icon': Icons.qr_code_scanner_rounded},
    {'title': 'Bank Transfer', 'icon': Icons.account_balance_rounded},
    {'title': 'Cash', 'icon': Icons.payments_rounded},
    {'title': 'Other', 'icon': Icons.more_horiz_rounded},
  ];

  // Comprehensive Trip-by-Trip Settlement Data
  late List<Map<String, dynamic>> _trips;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeTripData();
  }

  void _initializeTripData() {
    _trips = [
      {
        'id': 1,
        'title': 'Goa Trip ✈️',
        'destination': 'Goa, India',
        'dates': '12 - 16 Dec 2024',
        'image': 'https://images.unsplash.com/photo-1512343879784-a960bf40e7f2?w=800&auto=format&fit=crop&q=80',
        'membersCount': 5,
        'totalExpenses': 32450,
        'fairShare': 6490,
        'youPaid': 8540,
        'netBalance': 2050, // +2050
        'isSettled': false,
        'debts': [
          {
            'id': 101,
            'name': 'Neha',
            'avatar': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100',
            'amount': 1580,
            'type': 'owes_you', // owes_you or you_owe
            'status': 'pending', // pending or settled
            'subtitle': 'Share of Beach Shack & Hotel Stay',
            'upiId': 'neha.verma@oksbi',
          },
          {
            'id': 102,
            'name': 'Amit',
            'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
            'amount': 470,
            'type': 'owes_you',
            'status': 'pending',
            'subtitle': 'Share of Water Sports & Fuel',
            'upiId': 'amit.p@okhdfcbank',
          },
        ],
        'ledger': [
          {
            'name': 'You (Het)',
            'isUser': true,
            'paid': 8540,
            'share': 6490,
            'balance': 2050,
            'status': 'Gets back',
            'avatar': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
          },
          {
            'name': 'Rahul',
            'isUser': false,
            'paid': 7500,
            'share': 6490,
            'balance': 1010,
            'status': 'Gets back',
            'avatar': 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=100',
          },
          {
            'name': 'Priya',
            'isUser': false,
            'paid': 6000,
            'share': 6490,
            'balance': -490,
            'status': 'Owes',
            'avatar': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100',
          },
          {
            'name': 'Amit',
            'isUser': false,
            'paid': 5500,
            'share': 6490,
            'balance': -990,
            'status': 'Owes',
            'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
          },
          {
            'name': 'Neha',
            'isUser': false,
            'paid': 4910,
            'share': 6490,
            'balance': -1580,
            'status': 'Owes',
            'avatar': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100',
          },
        ],
      },
      {
        'id': 2,
        'title': 'Manali Winter Trip 🏔️',
        'destination': 'Manali, Himachal',
        'dates': '5 - 10 Jan 2025',
        'image': 'https://images.unsplash.com/photo-1517411032315-54ef2cb783bb?w=800&auto=format&fit=crop&q=80',
        'membersCount': 4,
        'totalExpenses': 18200,
        'fairShare': 4550,
        'youPaid': 6620,
        'netBalance': 2070, // +2070
        'isSettled': false,
        'debts': [
          {
            'id': 201,
            'name': 'Rahul',
            'avatar': 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=100',
            'amount': 1200,
            'type': 'owes_you',
            'status': 'pending',
            'subtitle': 'Snow Cab & Ski Gear Rental',
            'upiId': 'rahul.sharma@okaxis',
          },
          {
            'id': 202,
            'name': 'Rohan',
            'avatar': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100',
            'amount': 870,
            'type': 'owes_you',
            'status': 'pending',
            'subtitle': 'Bonfire Dinner & Cafe Bill',
            'upiId': 'rohan.k@okicici',
          },
        ],
        'ledger': [
          {
            'name': 'You (Het)',
            'isUser': true,
            'paid': 6620,
            'share': 4550,
            'balance': 2070,
            'status': 'Gets back',
            'avatar': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
          },
          {
            'name': 'Pooja',
            'isUser': false,
            'paid': 5000,
            'share': 4550,
            'balance': 450,
            'status': 'Gets back',
            'avatar': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=100',
          },
          {
            'name': 'Rohan',
            'isUser': false,
            'paid': 3680,
            'share': 4550,
            'balance': -870,
            'status': 'Owes',
            'avatar': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100',
          },
          {
            'name': 'Rahul',
            'isUser': false,
            'paid': 2900,
            'share': 4550,
            'balance': -1650,
            'status': 'Owes',
            'avatar': 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=100',
          },
        ],
      },
      {
        'id': 3,
        'title': 'Weekend Roadtrip 🚗',
        'destination': 'Lonavala & Khandala',
        'dates': '22 - 24 Nov 2024',
        'image': 'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?w=800&auto=format&fit=crop&q=80',
        'membersCount': 3,
        'totalExpenses': 6400,
        'fairShare': 2133,
        'youPaid': 1283,
        'netBalance': -850, // You owe 850
        'isSettled': false,
        'debts': [
          {
            'id': 301,
            'name': 'Neha',
            'avatar': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100',
            'amount': 850,
            'type': 'you_owe', // YOU OWE NEHA
            'status': 'pending',
            'subtitle': 'Fuel & Highway Expressway Tolls',
            'upiId': 'neha.v@okaxis',
          },
        ],
        'ledger': [
          {
            'name': 'Neha',
            'isUser': false,
            'paid': 3500,
            'share': 2133,
            'balance': 1367,
            'status': 'Gets back',
            'avatar': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100',
          },
          {
            'name': 'Siddharth',
            'isUser': false,
            'paid': 1617,
            'share': 2133,
            'balance': -516,
            'status': 'Owes',
            'avatar': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100',
          },
          {
            'name': 'You (Het)',
            'isUser': true,
            'paid': 1283,
            'share': 2133,
            'balance': -850,
            'status': 'Owes',
            'avatar': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
          },
        ],
      },
      {
        'id': 4,
        'title': 'Udaipur Heritage Tour 🏰',
        'destination': 'Udaipur, Rajasthan',
        'dates': '10 - 14 Oct 2024',
        'image': 'https://images.unsplash.com/photo-1599661046289-e31897846e41?w=800&auto=format&fit=crop&q=80',
        'membersCount': 5,
        'totalExpenses': 42000,
        'fairShare': 8400,
        'youPaid': 8400,
        'netBalance': 0, // Fully settled
        'isSettled': true,
        'debts': [],
        'ledger': [
          {
            'name': 'You (Het)',
            'isUser': true,
            'paid': 8400,
            'share': 8400,
            'balance': 0,
            'status': 'Settled',
            'avatar': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
          },
          {
            'name': 'Rahul',
            'isUser': false,
            'paid': 8400,
            'share': 8400,
            'balance': 0,
            'status': 'Settled',
            'avatar': 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=100',
          },
          {
            'name': 'Priya',
            'isUser': false,
            'paid': 8400,
            'share': 8400,
            'balance': 0,
            'status': 'Settled',
            'avatar': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100',
          },
        ],
      },
    ];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Map<String, dynamic> get _currentTrip => _trips[_selectedTripIndex];

  int get _currentTripPendingAmount {
    int sum = 0;
    final debts = (_currentTrip['debts'] as List<Map<String, dynamic>>?) ?? [];
    for (final d in debts) {
      if (d['status'] == 'pending') {
        sum += (d['amount'] as int);
      }
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentTrip = _currentTrip;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            TripSplitHeader(
              title: 'Trip Settle Up',
              subtitle: 'Settle balances trip by trip 💸',
              onBack: () => Navigator.of(context).maybePop(),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. TRIP-BY-TRIP SELECTOR CAROUSEL
                    _buildTripSelectorHeader(isDark),

                    const SizedBox(height: 16),

                    // 2. HERO NET BALANCE CARD FOR SELECTED TRIP
                    _buildHeroNetCard(isDark, currentTrip),

                    const SizedBox(height: 16),

                    // 3. TRIP SNAPSHOT CARD (Cover, Total Spent, Fair Share)
                    _buildTripSnapshotCard(isDark, currentTrip),

                    const SizedBox(height: 20),

                    // 4. SEGMENTED TABS: [Direct Settlements] & [Full Trip Ledger]
                    _buildSegmentedTabBar(isDark, currentTrip),

                    const SizedBox(height: 14),

                    // Tab View Content
                    _tabController.index == 0
                        ? _buildDirectSettlementsSection(isDark, currentTrip)
                        : _buildGroupLedgerSection(isDark, currentTrip),

                    const SizedBox(height: 22),

                    // 5. UPI PAYMENT / QR CODE SECTION
                    _buildUpiActionCard(isDark, currentTrip),

                    const SizedBox(height: 16),

                    // Info Note
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF172033) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_user_rounded, size: 16, color: Color(0xFF10B981)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Settlements for ${currentTrip['title']} are calculated using minimum transaction algorithms to eliminate redundant transfers.',
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.3,
                                color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 6. ACTION BUTTON: MARK THIS TRIP AS SETTLED
                    TripSplitButton(
                      label: currentTrip['isSettled'] == true || _currentTripPendingAmount == 0
                          ? 'Trip Fully Settled 🎉'
                          : 'Mark Trip as Settled',
                      trailingIcon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                      onPressed: () {
                        setState(() {
                          currentTrip['isSettled'] = true;
                          final debts = (currentTrip['debts'] as List<Map<String, dynamic>>?) ?? [];
                          for (final d in debts) {
                            d['status'] = 'settled';
                          }
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${currentTrip['title']} has been marked as fully settled! 🎉'),
                            backgroundColor: const Color(0xFF10B981),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. Horizontal Trip-by-Trip Selector Header
  Widget _buildTripSelectorHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Select Trip to Settle',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_trips.length} Trips Available',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 76,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _trips.length,
            itemBuilder: (context, index) {
              final trip = _trips[index];
              final isSelected = index == _selectedTripIndex;
              final net = trip['netBalance'] as int;
              final isPositive = net > 0;
              final isSettled = trip['isSettled'] == true || net == 0;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTripIndex = index;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 170,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? const Color(0xFF1E283D) : Colors.white)
                        : (isDark ? const Color(0xFF131A29) : const Color(0xFFF8FAFC)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? const Color(0xFF222F43) : const Color(0xFFE2E8F0)),
                      width: isSelected ? 2.0 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          trip['image'] as String,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              trip['title'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: isSelected
                                    ? (isDark ? Colors.white : AppColors.primary)
                                    : (isDark ? AppColors.textDarkMain : AppColors.textLightMain),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: isSettled
                                    ? Colors.blue.withOpacity(0.15)
                                    : (isPositive
                                        ? const Color(0xFF10B981).withOpacity(0.15)
                                        : const Color(0xFFEF4444).withOpacity(0.15)),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                isSettled
                                    ? 'Settled'
                                    : (isPositive ? '+₹ $net' : '-₹ ${net.abs()}'),
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  color: isSettled
                                      ? Colors.blue
                                      : (isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // 2. Hero Net Balance Card tailored to the selected trip
  Widget _buildHeroNetCard(bool isDark, Map<String, dynamic> trip) {
    final net = trip['netBalance'] as int;
    final isPositive = net > 0;
    final isSettled = trip['isSettled'] == true || net == 0;
    final debts = (trip['debts'] as List<Map<String, dynamic>>?) ?? [];
    final pendingDebts = debts.where((d) => d['status'] == 'pending').toList();

    List<Color> gradientColors;
    if (isSettled) {
      gradientColors = [const Color(0xFF4F46E5), const Color(0xFF7C3AED)];
    } else if (isPositive) {
      gradientColors = [const Color(0xFF059669), const Color(0xFF10B981)];
    } else {
      gradientColors = [const Color(0xFFDC2626), const Color(0xFFF97316)];
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withOpacity(0.32),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSettled
                            ? Icons.check_circle_rounded
                            : (isPositive ? Icons.south_west_rounded : Icons.north_east_rounded),
                        color: Colors.white,
                        size: 13,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          isSettled
                              ? 'TRIP FULLY SETTLED'
                              : (isPositive ? 'YOU WILL RECEIVE' : 'YOU NEED TO PAY'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isSettled ? '0 Pending' : '${pendingDebts.length} Pending',
                  style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isSettled
                ? '₹ 0'
                : (isPositive ? '+₹ $net' : '-₹ ${net.abs()}'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isSettled
                ? 'All accounts in ${trip['title']} are completely balanced.'
                : (isPositive
                    ? 'You spent more than your share in this trip. Friends owe you ₹ $net in total.'
                    : 'You owe ₹ ${net.abs()} to members in this trip to balance your fair share.'),
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  // 3. Trip Snapshot Card
  Widget _buildTripSnapshotCard(bool isDark, Map<String, dynamic> trip) {
    final net = trip['netBalance'] as int;
    final isPositive = net > 0;
    final isSettled = trip['isSettled'] == true || net == 0;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131A29) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF222F43) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          // Panoramic Photo Strip
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
            child: Stack(
              children: [
                Image.network(
                  trip['image'] as String,
                  height: 84,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Container(
                  height: 84,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black.withOpacity(0.2), Colors.black.withOpacity(0.8)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  bottom: 10,
                  right: 14,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TOTAL EXPENSES • ${trip['title']}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  '₹ ${trip['totalExpenses']}',
                                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    '• ${trip['membersCount']} Members',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Text(
                          trip['dates'] as String,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3 Columns: Fair Share, You Paid, Net Position
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                _buildStatPill('₹ ${trip['fairShare']}', 'Your Fair Share', Icons.pie_chart_outline_rounded, AppColors.primary, isDark),
                Container(height: 32, width: 1, color: isDark ? const Color(0xFF222F43) : const Color(0xFFE2E8F0)),
                _buildStatPill('₹ ${trip['youPaid']}', 'You Paid', Icons.credit_card_rounded, const Color(0xFF10B981), isDark),
                Container(height: 32, width: 1, color: isDark ? const Color(0xFF222F43) : const Color(0xFFE2E8F0)),
                _buildStatPill(
                  isSettled ? '₹ 0' : (isPositive ? '+₹ $net' : '-₹ ${net.abs()}'),
                  isSettled ? 'Settled' : (isPositive ? 'To Receive' : 'To Pay'),
                  isPositive ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                  isSettled ? Colors.blue : (isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                  isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String title, String subtitle, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
            ),
          ),
        ],
      ),
    );
  }

  // 4. Segmented Tab Bar for the Active Trip
  Widget _buildSegmentedTabBar(bool isDark, Map<String, dynamic> trip) {
    final debts = (trip['debts'] as List<Map<String, dynamic>>?) ?? [];
    final ledger = (trip['ledger'] as List<Map<String, dynamic>>?) ?? [];
    final pendingCount = debts.where((d) => d['status'] == 'pending').length;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131A29) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tabController.index = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _tabController.index == 0
                      ? (isDark ? const Color(0xFF1E283D) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _tabController.index == 0
                      ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 2))]
                      : null,
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.handshake_rounded,
                        size: 15,
                        color: _tabController.index == 0 ? AppColors.primary : (isDark ? Colors.white54 : Colors.black54),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Direct Debts ($pendingCount)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: _tabController.index == 0
                                ? (isDark ? Colors.white : AppColors.primary)
                                : (isDark ? Colors.white54 : Colors.black54),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tabController.index = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _tabController.index == 1
                      ? (isDark ? const Color(0xFF1E283D) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _tabController.index == 1
                      ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 2))]
                      : null,
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.groups_rounded,
                        size: 16,
                        color: _tabController.index == 1 ? AppColors.primary : (isDark ? Colors.white54 : Colors.black54),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Trip Ledger (${ledger.length})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: _tabController.index == 1
                                ? (isDark ? Colors.white : AppColors.primary)
                                : (isDark ? Colors.white54 : Colors.black54),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tab 1: Direct Settlements for this Trip
  Widget _buildDirectSettlementsSection(bool isDark, Map<String, dynamic> trip) {
    final debts = (trip['debts'] as List<Map<String, dynamic>>?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Trip Settlements',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Minimum Transfers',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (debts.isEmpty || debts.every((d) => d['status'] == 'settled'))
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131A29) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
            ),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 40),
                  const SizedBox(height: 8),
                  Text(
                    'All direct debts for ${trip['title']} are settled!',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'No pending transfers remaining.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...debts.map((debt) {
            final isSettled = debt['status'] == 'settled';
            final isOwesYou = debt['type'] == 'owes_you';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131A29) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSettled
                      ? Colors.grey.withOpacity(0.3)
                      : (isDark ? const Color(0xFF222F43) : const Color(0xFFE2E8F0)),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundImage: NetworkImage(debt['avatar'] as String),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  debt['name'] as String,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                                    decoration: isSettled ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isSettled
                                        ? Colors.grey.withOpacity(0.15)
                                        : (isOwesYou
                                            ? const Color(0xFF10B981).withOpacity(0.15)
                                            : const Color(0xFFEF4444).withOpacity(0.15)),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isSettled
                                        ? 'PAID'
                                        : (isOwesYou ? 'OWES YOU' : 'YOU OWE'),
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w900,
                                      color: isSettled
                                          ? Colors.grey
                                          : (isOwesYou ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              debt['subtitle'] as String,
                              style: TextStyle(
                                fontSize: 11.5,
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
                            '₹ ${debt['amount']}',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: isSettled
                                  ? Colors.grey
                                  : (isOwesYou ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                              decoration: isSettled ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isSettled ? 'Completed' : (isOwesYou ? 'To Receive' : 'To Pay'),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isSettled
                                  ? Colors.grey
                                  : (isOwesYou ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (!isSettled) ...[
                    const SizedBox(height: 12),
                    Divider(height: 1, color: isDark ? const Color(0xFF222F43) : const Color(0xFFF1F5F9)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (isOwesYou) ...[
                          // WhatsApp Remind Button
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                side: BorderSide(
                                  color: const Color(0xFF25D366).withOpacity(0.6),
                                  width: 1.2,
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                backgroundColor: const Color(0xFF25D366).withOpacity(isDark ? 0.1 : 0.06),
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('WhatsApp reminder sent to ${debt['name']} for ₹ ${debt['amount']}! 📱'),
                                    backgroundColor: const Color(0xFF25D366),
                                  ),
                                );
                              },
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.message_rounded, size: 14, color: Color(0xFF25D366)),
                                  SizedBox(width: 6),
                                  Text(
                                    'Remind',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF25D366),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Record Payment Received
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              onPressed: () => _showRecordPaymentModal(context, isDark, debt, true),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_rounded, size: 15, color: Colors.white),
                                  SizedBox(width: 6),
                                  Text(
                                    'Record Paid',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ] else ...[
                          // Direct Pay via UPI Button
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                backgroundColor: const Color(0xFF0284C7),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              onPressed: () => _showUpiPayModal(context, isDark, debt),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.payment_rounded, size: 15, color: Colors.white),
                                  SizedBox(width: 6),
                                  Text(
                                    'Pay via UPI',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Mark as Paid
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                side: const BorderSide(color: AppColors.primary),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => _showRecordPaymentModal(context, isDark, debt, false),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_rounded, size: 15, color: AppColors.primary),
                                  SizedBox(width: 6),
                                  Text(
                                    'Mark Paid',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
      ],
    );
  }

  // Tab 2: All Group Members Ledger for Active Trip
  Widget _buildGroupLedgerSection(bool isDark, Map<String, dynamic> trip) {
    final ledger = (trip['ledger'] as List<Map<String, dynamic>>?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                '${trip['title']} Ledger',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Share: ₹ ${trip['fairShare']}/person',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...ledger.map((member) {
          final balance = member['balance'] as int;
          final isPositive = balance > 0;
          final isZero = balance == 0;
          final isUser = member['isUser'] == true;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isUser
                  ? (isDark ? const Color(0xFF1E283D) : const Color(0xFFF8FAFC))
                  : (isDark ? const Color(0xFF131A29) : Colors.white),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isUser
                    ? AppColors.primary.withOpacity(0.5)
                    : (isDark ? const Color(0xFF222F43) : const Color(0xFFE2E8F0)),
                width: isUser ? 1.6 : 1.0,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundImage: NetworkImage(member['avatar'] as String),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            member['name'] as String,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                            ),
                          ),
                          if (isUser) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'YOU',
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Paid: ₹ ${member['paid']}  •  Share: ₹ ${member['share']}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
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
                      isZero
                          ? '₹ 0'
                          : (isPositive ? '+₹ $balance' : '-₹ ${balance.abs()}'),
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: isZero
                            ? Colors.blue
                            : (isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isZero
                          ? 'Settled'
                          : (isPositive ? 'Gets back' : 'Owes'),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: isZero
                            ? Colors.blue
                            : (isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  // 5. Smart UPI Action Card: Adapts if You Receive vs You Owe
  Widget _buildUpiActionCard(bool isDark, Map<String, dynamic> trip) {
    final net = trip['netBalance'] as int;
    final isReceiving = net > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131A29) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF222F43) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: (isReceiving ? const Color(0xFF10B981) : const Color(0xFF0284C7)).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isReceiving ? Icons.qr_code_2_rounded : Icons.account_balance_wallet_rounded,
                  size: 20,
                  color: isReceiving ? const Color(0xFF10B981) : const Color(0xFF0284C7),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isReceiving ? 'Your Settlement UPI QR Code' : 'Quick Settle with UPI Apps',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      isReceiving
                          ? 'Trip friends can scan and pay your balance instantly'
                          : 'Send payment directly to members you owe',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (isReceiving)
            Row(
              children: [
                // QR Box
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Icon(Icons.qr_code_rounded, size: 68, color: Colors.black87),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1C2436) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? const Color(0xFF2B3752) : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'hetshah@okaxis',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                            GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('UPI ID copied to clipboard!')),
                                );
                              },
                              child: const Icon(Icons.copy_rounded, size: 15, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('QR Code shared!')),
                          );
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.share_rounded, size: 13, color: AppColors.primary),
                            SizedBox(width: 5),
                            Text(
                              'Share QR Code',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildAppIconPill('GPay', 'https://upload.wikimedia.org/wikipedia/commons/f/f2/Google_Pay_Logo.svg', isDark),
                _buildAppIconPill('PhonePe', '', isDark, icon: Icons.bolt_rounded, color: const Color(0xFF5F259F)),
                _buildAppIconPill('Paytm', '', isDark, icon: Icons.account_balance_wallet_rounded, color: const Color(0xFF002E6E)),
                _buildAppIconPill('BHIM UPI', '', isDark, icon: Icons.payments_rounded, color: const Color(0xFF10B981)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildAppIconPill(String label, String url, bool isDark, {IconData? icon, Color? color}) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Launching $label for UPI settlement... 🚀')),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C2436) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF2B3752) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            children: [
              Icon(icon ?? Icons.payment_rounded, size: 22, color: color ?? AppColors.primary),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Modal: Record Payment Received or Made
  void _showRecordPaymentModal(BuildContext context, bool isDark, Map<String, dynamic> debt, bool isReceiving) {
    int selectedMethod = _selectedPaymentMethod;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
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
                            isReceiving ? 'Record Payment Received' : 'Record Payment Made',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isReceiving ? 'From ${debt['name']}' : 'Paid to ${debt['name']}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
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

                  // Amount Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF172033) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: (isReceiving ? const Color(0xFF10B981) : AppColors.primary).withOpacity(0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isReceiving ? 'RECEIVED AMOUNT' : 'SETTLEMENT AMOUNT',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: isReceiving ? const Color(0xFF10B981) : AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '₹ ${debt['amount']}',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: NetworkImage(debt['avatar'] as String),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  Text(
                    'Payment Mode',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Payment method chips
                  Row(
                    children: List.generate(_paymentMethods.length, (index) {
                      final method = _paymentMethods[index];
                      final isSelected = index == selectedMethod;

                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setModalState(() => selectedMethod = index);
                            setState(() => _selectedPaymentMethod = index);
                          },
                          child: Container(
                            margin: EdgeInsets.only(right: index < _paymentMethods.length - 1 ? 8 : 0),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : (isDark ? const Color(0xFF1E283D) : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : Colors.transparent,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  method['icon'] as IconData,
                                  size: 18,
                                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  method['title'] as String,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 20),

                  // Confirm button
                  TripSplitButton(
                    label: isReceiving ? 'Confirm Payment Received' : 'Confirm Payment Recorded',
                    trailingIcon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                    onPressed: () {
                      setState(() {
                        debt['status'] = 'settled';
                      });
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Payment of ₹ ${debt['amount']} marked as settled!'),
                          backgroundColor: const Color(0xFF10B981),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Modal: UPI Pay Modal
  void _showUpiPayModal(BuildContext context, bool isDark, Map<String, dynamic> debt) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF111726) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(ctx).padding.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Pay ${debt['name']} via UPI',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                'UPI ID: ${debt['upiId'] ?? 'member@okaxis'}',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A2338) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Amount to Pay:', style: TextStyle(fontWeight: FontWeight.w700)),
                    Text(
                      '₹ ${debt['amount']}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0284C7)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TripSplitButton(
                label: 'Open UPI App (GPay / PhonePe)',
                trailingIcon: const Icon(Icons.open_in_new_rounded, color: Colors.white, size: 18),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  setState(() {
                    debt['status'] = 'settled';
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Payment of ₹ ${debt['amount']} initiated to ${debt['name']}!'),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
