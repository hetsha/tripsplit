import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/tripsplit_widgets.dart';
import '../../services/auth_service.dart';
import '../../services/expense_service.dart';

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
  bool _initialized = false;
  bool _isProcessing = false;

  final List<Map<String, dynamic>> _paymentMethods = [
    {'id': 'upi', 'title': 'UPI', 'icon': Icons.qr_code_scanner_rounded},
    {'id': 'bank', 'title': 'Bank Transfer', 'icon': Icons.account_balance_rounded},
    {'id': 'cash', 'title': 'Cash', 'icon': Icons.payments_rounded},
    {'id': 'other', 'title': 'Other', 'icon': Icons.more_horiz_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final auth = Provider.of<AuthService>(context, listen: false);
      final targetTripId = widget.initialTripId ?? args?['tripId'] ?? args?['trip']?['id'] ?? auth.activeTripId;

      if (auth.detailedTrips.isNotEmpty && targetTripId != null) {
        final idx = auth.detailedTrips.indexWhere((t) => t['id'] == targetTripId);
        if (idx != -1) {
          _selectedTripIndex = idx;
        }
      }

      _loadData();
      _initialized = true;
    }
  }

  Future<void> _loadData() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final expense = Provider.of<ExpenseService>(context, listen: false);

    if (auth.detailedTrips.isEmpty) {
      await auth.fetchTripsList();
    }

    final currentTrip = _getCurrentTrip(auth);
    final tripId = currentTrip?['id'] as int?;

    if (tripId != null) {
      await Future.wait([
        expense.loadSettlements(tripId: tripId),
        expense.loadDashboard(tripId: tripId),
      ]);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Map<String, dynamic>? _getCurrentTrip(AuthService auth) {
    if (auth.detailedTrips.isEmpty) return null;
    if (_selectedTripIndex >= auth.detailedTrips.length) {
      _selectedTripIndex = 0;
    }
    return auth.detailedTrips[_selectedTripIndex];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = Provider.of<AuthService>(context);
    final expense = Provider.of<ExpenseService>(context);
    final currentUserId = auth.currentUser?.id ?? 0;

    final trips = auth.detailedTrips;
    final currentTrip = _getCurrentTrip(auth);
    final settlementData = expense.settlementData;

    final List rawSuggestions = settlementData?['suggestions'] ?? [];
    final List rawBalances = settlementData?['all_balances'] ?? [];
    final List rawHistory = settlementData?['history'] ?? [];
    final Map<String, dynamic>? myBalance = settlementData?['my_balance'];

    // Map current trip metrics
    final double totalSpent = (currentTrip?['total_spent'] as num?)?.toDouble() ?? 0.0;
    final int membersCount = (currentTrip?['members_count'] as num?)?.toInt() ?? (currentTrip?['members'] as List?)?.length ?? 1;
    final double fairShare = membersCount > 0 ? (totalSpent / membersCount) : 0.0;
    final double youPaid = (myBalance?['total_paid'] as num?)?.toDouble() ?? 0.0;
    final double netBalance = (myBalance?['net_balance'] as num?)?.toDouble() ?? (currentTrip?['my_net_balance'] as num?)?.toDouble() ?? 0.0;
    final bool isSettled = rawSuggestions.isEmpty && netBalance.abs() < 0.01;

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
              child: RefreshIndicator(
                onRefresh: _loadData,
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. TRIP-BY-TRIP SELECTOR CAROUSEL
                      if (trips.isNotEmpty)
                        _buildTripSelectorHeader(isDark, trips),

                      const SizedBox(height: 16),

                      // 2. HERO NET BALANCE CARD FOR SELECTED TRIP
                      _buildHeroNetCard(
                        isDark: isDark,
                        tripTitle: currentTrip?['title'] ?? currentTrip?['name'] ?? 'Trip',
                        net: netBalance,
                        isSettled: isSettled,
                        pendingCount: rawSuggestions.length,
                      ),

                      const SizedBox(height: 16),

                      // 3. TRIP SNAPSHOT CARD
                      _buildTripSnapshotCard(
                        isDark: isDark,
                        title: currentTrip?['title'] ?? currentTrip?['name'] ?? 'Trip',
                        totalSpent: totalSpent,
                        membersCount: membersCount,
                        fairShare: fairShare,
                        youPaid: youPaid,
                        net: netBalance,
                        isSettled: isSettled,
                      ),

                      const SizedBox(height: 20),

                      // 4. SEGMENTED TABS: [Direct Debts] & [Trip Ledger]
                      _buildSegmentedTabBar(isDark, rawSuggestions.length, rawBalances.length),

                      const SizedBox(height: 14),

                      // Tab View Content
                      _tabController.index == 0
                          ? _buildDirectSettlementsSection(
                              isDark: isDark,
                              tripId: currentTrip?['id'] as int? ?? 0,
                              suggestions: rawSuggestions,
                              currentUserId: currentUserId,
                              isSettled: isSettled,
                            )
                          : _buildGroupLedgerSection(
                              isDark: isDark,
                              tripTitle: currentTrip?['title'] ?? currentTrip?['name'] ?? 'Trip',
                              fairShare: fairShare,
                              balances: rawBalances,
                              currentUserId: currentUserId,
                            ),

                      const SizedBox(height: 22),

                      // 5. UPI PAYMENT / QR CODE SECTION
                      _buildUpiActionCard(
                        isDark: isDark,
                        net: netBalance,
                        currentUserName: auth.currentUser?.name ?? 'User',
                      ),

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
                                'Settlements are calculated using greedy debt minimization algorithms to clear balances with minimal transactions.',
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
                        label: isSettled
                            ? 'Trip Fully Settled 🎉'
                            : (_isProcessing ? 'Settling Debts...' : 'Mark Trip as Settled'),
                        trailingIcon: _isProcessing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                        onPressed: isSettled
                            ? () {
                                Navigator.of(context).pushNamed('/trip_settled', arguments: {
                                  'trip': currentTrip,
                                  'tripId': currentTrip?['id'],
                                });
                              }
                            : (_isProcessing ? () {} : () => _confirmSettleAllDebts(context, currentTrip?['id'] as int? ?? 0)),
                      ),

                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. Horizontal Trip-by-Trip Selector Header
  Widget _buildTripSelectorHeader(bool isDark, List<Map<String, dynamic>> trips) {
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
                '${trips.length} Trips',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: trips.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (ctx, index) {
              final isSelected = index == _selectedTripIndex;
              final trip = trips[index];
              final title = trip['title'] ?? trip['name'] ?? 'Trip';

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTripIndex = index;
                  });
                  _loadData();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? const Color(0xFF131A29) : Colors.white),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? const Color(0xFF222F43) : const Color(0xFFE2E8F0)),
                      width: 1.2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.flight_takeoff_rounded,
                        size: 16,
                        color: isSelected ? Colors.white : AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? AppColors.textDarkMain : AppColors.textLightMain),
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

  // 2. Hero Net Balance Card
  Widget _buildHeroNetCard({
    required bool isDark,
    required String tripTitle,
    required double net,
    required bool isSettled,
    required int pendingCount,
  }) {
    final isPositive = net >= 0;
    final gradientColors = isSettled
        ? [const Color(0xFF0284C7), const Color(0xFF0369A1)]
        : (isPositive
            ? [const Color(0xFF059669), const Color(0xFF10B981)]
            : [const Color(0xFFDC2626), const Color(0xFFEF4444)]);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
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
                  isSettled ? '0 Pending' : '$pendingCount Pending',
                  style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isSettled
                ? '₹ 0'
                : (isPositive ? '+₹ ${net.toStringAsFixed(0)}' : '-₹ ${net.abs().toStringAsFixed(0)}'),
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
                ? 'All accounts in $tripTitle are completely balanced.'
                : (isPositive
                    ? 'You spent more than your share. Friends owe you ₹ ${net.toStringAsFixed(0)} in total.'
                    : 'You owe ₹ ${net.abs().toStringAsFixed(0)} to balance your fair share.'),
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
  Widget _buildTripSnapshotCard({
    required bool isDark,
    required String title,
    required double totalSpent,
    required int membersCount,
    required double fairShare,
    required double youPaid,
    required double net,
    required bool isSettled,
  }) {
    final isPositive = net >= 0;

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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C2436) : const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL EXPENSES • $title',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹ ${totalSpent.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$membersCount Members',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                _buildStatPill('₹ ${fairShare.toStringAsFixed(0)}', 'Your Fair Share', Icons.pie_chart_outline_rounded, AppColors.primary, isDark),
                Container(height: 32, width: 1, color: isDark ? const Color(0xFF222F43) : const Color(0xFFE2E8F0)),
                _buildStatPill('₹ ${youPaid.toStringAsFixed(0)}', 'You Paid', Icons.credit_card_rounded, const Color(0xFF10B981), isDark),
                Container(height: 32, width: 1, color: isDark ? const Color(0xFF222F43) : const Color(0xFFE2E8F0)),
                _buildStatPill(
                  isSettled ? '₹ 0' : (isPositive ? '+₹ ${net.toStringAsFixed(0)}' : '-₹ ${net.abs().toStringAsFixed(0)}'),
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

  // 4. Segmented Tab Bar
  Widget _buildSegmentedTabBar(bool isDark, int directDebtsCount, int ledgerCount) {
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
                      Text(
                        'Direct Debts ($directDebtsCount)',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: _tabController.index == 0
                              ? (isDark ? Colors.white : AppColors.primary)
                              : (isDark ? Colors.white54 : Colors.black54),
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
                      Text(
                        'Trip Ledger ($ledgerCount)',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: _tabController.index == 1
                              ? (isDark ? Colors.white : AppColors.primary)
                              : (isDark ? Colors.white54 : Colors.black54),
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

  // Tab 1: Direct Settlements
  Widget _buildDirectSettlementsSection({
    required bool isDark,
    required int tripId,
    required List suggestions,
    required int currentUserId,
    required bool isSettled,
  }) {
    if (suggestions.isEmpty || isSettled) {
      return Container(
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
              const Text(
                'All direct debts for this trip are settled!',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
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
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Trip Settlements (${suggestions.length})',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
              ),
            ),
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
        ...suggestions.map((s) {
          final fromUserId = s['from_user_id'] is int ? s['from_user_id'] : int.parse(s['from_user_id'].toString());
          final toUserId = s['to_user_id'] is int ? s['to_user_id'] : int.parse(s['to_user_id'].toString());
          final fromName = s['from_user_name'] as String? ?? 'Member';
          final toName = s['to_user_name'] as String? ?? 'Member';
          final double amount = (s['amount'] as num).toDouble();

          final bool isYouDebtor = fromUserId == currentUserId;
          final bool isYouCreditor = toUserId == currentUserId;

          String statusLabel = 'DIRECT DEBT';
          Color badgeColor = AppColors.primary;
          if (isYouCreditor) {
            statusLabel = 'OWES YOU';
            badgeColor = const Color(0xFF10B981);
          } else if (isYouDebtor) {
            statusLabel = 'YOU OWE';
            badgeColor = const Color(0xFFEF4444);
          }

          final peerName = isYouCreditor ? fromName : (isYouDebtor ? toName : '$fromName ➔ $toName');

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131A29) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? const Color(0xFF222F43) : const Color(0xFFE2E8F0),
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
                      radius: 20,
                      backgroundColor: badgeColor.withOpacity(0.2),
                      child: Text(
                        peerName.isNotEmpty ? peerName[0].toUpperCase() : 'M',
                        style: TextStyle(fontWeight: FontWeight.w800, color: badgeColor),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  peerName,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: badgeColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                    color: badgeColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isYouCreditor
                                ? '$fromName owes you to balance trip expenses'
                                : (isYouDebtor ? 'Pay $toName to clear your fair share' : '$fromName pays $toName'),
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹ ${amount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: badgeColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isYouCreditor ? 'To Collect' : (isYouDebtor ? 'To Pay' : 'Transfer'),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: isDark ? const Color(0xFF222F43) : const Color(0xFFF1F5F9)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (isYouCreditor) ...[
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
                                content: Text('Reminder queued for $fromName for ₹ ${amount.toStringAsFixed(0)}! 📱'),
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
                          onPressed: () => _showRecordPaymentModal(
                            context: context,
                            isDark: isDark,
                            tripId: tripId,
                            fromUserId: fromUserId,
                            toUserId: toUserId,
                            counterpartName: fromName,
                            amount: amount,
                            isReceiving: true,
                          ),
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
                          onPressed: () => _showUpiPayModal(
                            context: context,
                            isDark: isDark,
                            tripId: tripId,
                            fromUserId: fromUserId,
                            toUserId: toUserId,
                            receiverName: toName,
                            amount: amount,
                          ),
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
                          onPressed: () => _showRecordPaymentModal(
                            context: context,
                            isDark: isDark,
                            tripId: tripId,
                            fromUserId: fromUserId,
                            toUserId: toUserId,
                            counterpartName: toName,
                            amount: amount,
                            isReceiving: false,
                          ),
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
            ),
          );
        }).toList(),
      ],
    );
  }

  // Tab 2: Group Members Ledger
  Widget _buildGroupLedgerSection({
    required bool isDark,
    required String tripTitle,
    required double fairShare,
    required List balances,
    required int currentUserId,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$tripTitle Ledger',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
              ),
            ),
            Text(
              'Share: ₹ ${fairShare.toStringAsFixed(0)}/person',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...balances.map((member) {
          final uid = member['user_id'] is int ? member['user_id'] : int.parse(member['user_id'].toString());
          final name = member['name'] as String? ?? 'Member';
          final double paid = (member['total_paid'] as num?)?.toDouble() ?? 0.0;
          final double share = (member['total_share'] as num?)?.toDouble() ?? 0.0;
          final double balance = (member['net_balance'] as num?)?.toDouble() ?? 0.0;

          final bool isPositive = balance > 0.01;
          final bool isZero = balance.abs() <= 0.01;
          final bool isUser = uid == currentUserId;

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
                  radius: 18,
                  backgroundColor: isPositive
                      ? const Color(0xFF10B981).withOpacity(0.2)
                      : (isZero ? Colors.blue.withOpacity(0.2) : const Color(0xFFEF4444).withOpacity(0.2)),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'M',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: isPositive ? const Color(0xFF10B981) : (isZero ? Colors.blue : const Color(0xFFEF4444)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                              ),
                              overflow: TextOverflow.ellipsis,
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
                        'Paid: ₹ ${paid.toStringAsFixed(0)}  •  Share: ₹ ${share.toStringAsFixed(0)}',
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
                          : (isPositive ? '+₹ ${balance.toStringAsFixed(0)}' : '-₹ ${balance.abs().toStringAsFixed(0)}'),
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
                      isZero ? 'Settled' : (isPositive ? 'Gets back' : 'Owes'),
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

  // 5. Smart UPI Action Card
  Widget _buildUpiActionCard({
    required bool isDark,
    required double net,
    required String currentUserName,
  }) {
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
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Icon(Icons.qr_code_rounded, size: 64, color: Colors.black87),
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
                            Text(
                              '${currentUserName.toLowerCase().replaceAll(' ', '')}@okaxis',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
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
                _buildAppIconPill('GPay', isDark, icon: Icons.payment_rounded, color: const Color(0xFF4285F4)),
                _buildAppIconPill('PhonePe', isDark, icon: Icons.bolt_rounded, color: const Color(0xFF5F259F)),
                _buildAppIconPill('Paytm', isDark, icon: Icons.account_balance_wallet_rounded, color: const Color(0xFF002E6E)),
                _buildAppIconPill('BHIM UPI', isDark, icon: Icons.payments_rounded, color: const Color(0xFF10B981)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildAppIconPill(String label, bool isDark, {required IconData icon, required Color color}) {
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
              Icon(icon, size: 22, color: color),
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

  // Modal: Record Payment
  void _showRecordPaymentModal({
    required BuildContext context,
    required bool isDark,
    required int tripId,
    required int fromUserId,
    required int toUserId,
    required String counterpartName,
    required double amount,
    required bool isReceiving,
  }) {
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
                            isReceiving ? 'From $counterpartName' : 'Paid to $counterpartName',
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
                              '₹ ${amount.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            counterpartName.isNotEmpty ? counterpartName[0].toUpperCase() : 'M',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
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
                  TripSplitButton(
                    label: isReceiving ? 'Confirm Payment Received' : 'Confirm Payment Recorded',
                    trailingIcon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      final expense = Provider.of<ExpenseService>(context, listen: false);
                      final methodStr = _paymentMethods[selectedMethod]['id'] as String;

                      try {
                        await expense.recordSettlement(
                          tripId: tripId,
                          fromUser: fromUserId,
                          toUser: toUserId,
                          amount: amount,
                          paymentMethod: methodStr,
                          notes: 'Settled via TripSplit App',
                        );
                        _loadData();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Payment of ₹ ${amount.toStringAsFixed(0)} recorded successfully!'),
                              backgroundColor: const Color(0xFF10B981),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to record settlement: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
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
  void _showUpiPayModal({
    required BuildContext context,
    required bool isDark,
    required int tripId,
    required int fromUserId,
    required int toUserId,
    required String receiverName,
    required double amount,
  }) {
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
                'Pay $receiverName via UPI',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                'UPI ID: ${receiverName.toLowerCase().replaceAll(' ', '')}@okaxis',
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
                      '₹ ${amount.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0284C7)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TripSplitButton(
                label: 'Confirm Payment to $receiverName',
                trailingIcon: const Icon(Icons.open_in_new_rounded, color: Colors.white, size: 18),
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  final expense = Provider.of<ExpenseService>(context, listen: false);

                  try {
                    await expense.recordSettlement(
                      tripId: tripId,
                      fromUser: fromUserId,
                      toUser: toUserId,
                      amount: amount,
                      paymentMethod: 'upi',
                      notes: 'Paid via UPI App',
                    );
                    _loadData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Payment of ₹ ${amount.toStringAsFixed(0)} confirmed!'),
                          backgroundColor: const Color(0xFF10B981),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Payment record error: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Dialog: Settle all outstanding debts for the trip
  Future<void> _confirmSettleAllDebts(BuildContext context, int tripId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Settle All Debts?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text(
          'This will mark all remaining balances in this trip as fully settled and clear all outstanding debts in the database.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Mark All Settled', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isProcessing = true);
      try {
        final expense = Provider.of<ExpenseService>(context, listen: false);
        final auth = Provider.of<AuthService>(context, listen: false);

        await expense.settleAllDebts(tripId: tripId);
        await auth.fetchTripsList();
        await _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Trip marked as fully settled! 🎉'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
          Navigator.of(context).pushNamed('/trip_settled', arguments: {
            'tripId': tripId,
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error settling debts: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      }
    }
  }
}
