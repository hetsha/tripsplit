import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/expense_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/tripsplit_widgets.dart';

class TripDashboardScreen extends StatefulWidget {
  const TripDashboardScreen({Key? key}) : super(key: key);

  @override
  State<TripDashboardScreen> createState() => _TripDashboardScreenState();
}

class _TripDashboardScreenState extends State<TripDashboardScreen> {
  int _navIndex = 0;
  bool _initialized = false;

  final List<Map<String, dynamic>> _recentExpenses = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _loadDashboard();
    }
  }

  void _loadDashboard() {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final auth = Provider.of<AuthService>(context, listen: false);
    final expense = Provider.of<ExpenseService>(context, listen: false);
    final tripId = args?['tripId'] as int? ?? auth.activeTripId;
    expense.loadDashboard(tripId: tripId);
  }

  IconData _getCategoryIcon(String cat) {
    final lower = cat.toLowerCase();
    if (lower.contains('food') || lower.contains('drink') || lower.contains('restaurant')) return Icons.restaurant_rounded;
    if (lower.contains('stay') || lower.contains('hotel')) return Icons.hotel_rounded;
    if (lower.contains('transport') || lower.contains('taxi') || lower.contains('flight')) return Icons.directions_car_rounded;
    if (lower.contains('water') || lower.contains('sport') || lower.contains('activit')) return Icons.surfing_rounded;
    if (lower.contains('ticket')) return Icons.confirmation_number_rounded;
    return Icons.receipt_rounded;
  }

  Color _getCategoryColor(String cat) {
    final lower = cat.toLowerCase();
    if (lower.contains('food') || lower.contains('drink')) return const Color(0xFFEF4444);
    if (lower.contains('stay') || lower.contains('hotel')) return const Color(0xFF8B5CF6);
    if (lower.contains('transport')) return const Color(0xFF10B981);
    if (lower.contains('water') || lower.contains('sport')) return const Color(0xFF0EA5E9);
    return const Color(0xFFF59E0B);
  }

  Color _getCategoryBg(String cat) {
    return _getCategoryColor(cat).withOpacity(0.14);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final auth = Provider.of<AuthService>(context);
    final expense = Provider.of<ExpenseService>(context);

    final tripInfo = expense.dashboardData?['trip_info'];
    final tripMoney = expense.dashboardData?['trip_money'];
    final expenseSummary = expense.dashboardData?['expense_summary'];

    final tripTitle = tripInfo?['name'] ?? args?['trip']?['title'] ?? 'Trip Dashboard';
    final tripDest = args?['trip']?['destination'] ?? 'Goa, India';
    final currency = tripMoney?['currency_symbol'] ?? '₹';
    final totalSpentNum = (tripMoney?['total_spent'] as num?)?.toDouble() ?? 0.0;
    final expenseCount = (expenseSummary?['expense_count'] as num?)?.toInt()
        ?? (expenseSummary?['total_count'] as num?)?.toInt()
        ?? (expense.dashboardData?['recent_transactions'] as List?)?.length
        ?? 0;

    final int currentUserId = auth.currentUser?.id ?? 0;
    final myBalance = expense.dashboardData?['my_balance'] as Map<String, dynamic>?;
    final whoOwesWhom = expense.dashboardData?['who_owes_whom'] as List? ?? [];

    // Payments I owe to other members
    final paymentsIOwe = whoOwesWhom.where((s) {
      final fId = s['from_user_id'] is int ? s['from_user_id'] : int.tryParse(s['from_user_id'].toString());
      return fId != null && fId == currentUserId;
    }).toList();
    final double amountIOweFromSettlements = paymentsIOwe.fold(0.0, (sum, s) => sum + ((s['amount'] as num?)?.toDouble() ?? 0.0));
    final int countIOwe = paymentsIOwe.length;

    // Payments other members owe to me (I lent)
    final paymentsILent = whoOwesWhom.where((s) {
      final tId = s['to_user_id'] is int ? s['to_user_id'] : int.tryParse(s['to_user_id'].toString());
      return tId != null && tId == currentUserId;
    }).toList();
    final double amountILentFromSettlements = paymentsILent.fold(0.0, (sum, s) => sum + ((s['amount'] as num?)?.toDouble() ?? 0.0));
    final int countILent = paymentsILent.length;

    // Authoritative Net balance fallback
    final netBalance = (myBalance?['net_balance'] as num?)?.toDouble() ?? 0.0;
    final double effectiveLent = amountILentFromSettlements > 0
        ? amountILentFromSettlements
        : (netBalance > 0 ? netBalance : 0.0);
    final double effectiveOwe = amountIOweFromSettlements > 0
        ? amountIOweFromSettlements
        : (netBalance < 0 ? netBalance.abs() : 0.0);

    final rawRecent = expense.dashboardData?['recent_transactions'] as List?;
    final displayedRecent = (rawRecent != null && rawRecent.isNotEmpty)
        ? rawRecent.map((tx) {
            final catName = tx['category_name'] as String? ?? 'General';
            final int? payerId = tx['payer_id'] is int
                ? tx['payer_id']
                : int.tryParse(tx['payer_id']?.toString() ?? '');
            final bool isPayer = payerId == currentUserId;
            final double fullAmount = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0.0;
            final String payerName = (tx['payer_name'] as String? ?? 'Member').trim();

            final rawSplits = tx['splits'] as List?;
            double mySplit = 0.0;
            bool userInSplit = false;
            if (rawSplits != null) {
              for (var s in rawSplits) {
                final sUid = s['user_id'] is int ? s['user_id'] : int.tryParse(s['user_id']?.toString() ?? '');
                if (sUid == currentUserId) {
                  mySplit = double.tryParse(s['amount']?.toString() ?? '0') ?? 0.0;
                  userInSplit = true;
                  break;
                }
              }
            }

            String userStatus = (tx['user_status'] as String? ?? '').trim();
            String userStatusLabel = (tx['user_status_label'] as String? ?? '').trim();
            String displayUserAmount = (tx['formatted_user_amount'] as String? ?? '').trim();

            if (userStatus.isEmpty) {
              final type = tx['type'] as String? ?? 'expense';
              if (type == 'expense') {
                if (isPayer) {
                  final lent = (rawSplits != null && rawSplits.isNotEmpty)
                      ? (fullAmount - mySplit).clamp(0.0, double.infinity)
                      : 0.0;
                  if (lent > 0.001) {
                    userStatus = 'lent';
                    userStatusLabel = 'You lent';
                    displayUserAmount = '+$currency ${lent.toStringAsFixed(lent.truncateToDouble() == lent ? 0 : 2)}';
                  } else {
                    userStatus = 'paid';
                    userStatusLabel = 'You paid';
                    displayUserAmount = '$currency ${fullAmount.toStringAsFixed(fullAmount.truncateToDouble() == fullAmount ? 0 : 2)}';
                  }
                } else {
                  if (userInSplit && mySplit > 0.001) {
                    userStatus = 'owe';
                    userStatusLabel = 'You owe';
                    displayUserAmount = '-$currency ${mySplit.toStringAsFixed(mySplit.truncateToDouble() == mySplit ? 0 : 2)}';
                  } else {
                    userStatus = 'none';
                    userStatusLabel = 'Not involved';
                    displayUserAmount = '$currency 0';
                  }
                }
              }
            }

            final dateStr = tx['formatted_date'] as String? ?? 'Recent';
            final payerSubtitle = isPayer
                ? 'You paid $currency ${fullAmount.toStringAsFixed(0)} • $dateStr'
                : '$payerName paid $currency ${fullAmount.toStringAsFixed(0)} • $dateStr';

            return {
              'id': tx['id'],
              'title': tx['description'] as String? ?? 'Expense',
              'payer': payerSubtitle,
              'date': dateStr,
              'amount': tx['formatted_amount'] as String? ?? '$currency ${tx['amount']}',
              'userStatus': userStatus,
              'userStatusLabel': userStatusLabel.isNotEmpty ? userStatusLabel : 'Expense',
              'userAmount': displayUserAmount.isNotEmpty ? displayUserAmount : (tx['formatted_amount'] as String? ?? '$currency ${tx['amount']}'),
              'icon': _getCategoryIcon(catName),
              'iconColor': _getCategoryColor(catName),
              'iconBg': _getCategoryBg(catName),
            };
          }).toList()
        : <Map<String, dynamic>>[];

    final tripId = args?['tripId'] as int? ?? auth.activeTripId;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header Bar
            // Top Header Bar
            TripSplitHeader(
              title: tripTitle,
              subtitle: tripDest,
              showBack: true,
              onBack: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  Navigator.of(context).pushReplacementNamed('/home');
                }
              },
              rightAction: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => TripSplitScreenNavigator.show(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withOpacity(0.1),
                      ),
                      child: const Icon(
                        Icons.grid_view_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pushNamed('/profile'),
                    child: const CircleAvatar(
                      radius: 19,
                      backgroundImage: NetworkImage(
                        'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: RefreshIndicator(
                onRefresh: () => expense.loadDashboard(tripId: tripId),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero Budget Card with Banner
                      TripSplitCard(
                        padding: EdgeInsets.zero,
                        borderRadius: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Cover Image Header
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                              child: Stack(
                                children: [
                                  Image.network(
                                    'https://images.unsplash.com/photo-1512343879784-a960bf40e7f2?w=800&auto=format&fit=crop&q=80',
                                    height: 125,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      height: 125,
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Color(0xFF38BDF8), Color(0xFF818CF8)],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: 125,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.45),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 12,
                                    top: 12,
                                    child: GestureDetector(
                                      onTap: () => Navigator.of(context).pushNamed(
                                        '/trip_settings',
                                        arguments: {'tripId': tripId},
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(7),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.4),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white24),
                                        ),
                                        child: const Icon(Icons.settings_rounded, size: 16, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: 16,
                                    bottom: 12,
                                    child: Row(
                                      children: [
                                        const Icon(Icons.location_on_rounded, size: 14, color: Colors.white70),
                                        const SizedBox(width: 4),
                                        Text(
                                          tripDest,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Total Trip Expense & Personal Balance Area
                            Padding(
                              padding: const EdgeInsets.all(18.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top Row: Total Trip Expense & Count
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Total Trip Expense',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '$currency ${totalSpentNum.toStringAsFixed(totalSpentNum % 1 == 0 ? 0 : 2)}',
                                            style: TextStyle(
                                              fontSize: 26,
                                              fontWeight: FontWeight.w800,
                                              color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                      // Total Expenses Count Badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                        decoration: BoxDecoration(
                                          color: isDark ? AppColors.elevatedDark : const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(
                                            color: isDark ? AppColors.borderDark : Colors.grey.shade200,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.receipt_long_rounded,
                                              size: 15,
                                              color: AppColors.primary,
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              '$expenseCount ${expenseCount == 1 ? 'Expense' : 'Expenses'}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 14),
                                  Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
                                  const SizedBox(height: 14),

                                  // Personal Ledger: You Lent vs You Owe
                                  Row(
                                    children: [
                                      // 1. You Lent Card
                                      Expanded(
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () => Navigator.of(context).pushNamed(
                                              '/settle_up',
                                              arguments: {'tripId': tripId},
                                            ),
                                            borderRadius: BorderRadius.circular(16),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                              decoration: BoxDecoration(
                                                color: isDark ? const Color(0xFF161F30) : const Color(0xFFF8FAFC),
                                                borderRadius: BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: isDark ? const Color(0xFF243048) : const Color(0xFFE2E8F0),
                                                  width: 1,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: isDark ? Colors.black.withOpacity(0.2) : const Color(0x0A0F172A),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Container(
                                                            width: 24,
                                                            height: 24,
                                                            decoration: BoxDecoration(
                                                              color: const Color(0xFF10B981).withOpacity(0.14),
                                                              borderRadius: BorderRadius.circular(7),
                                                            ),
                                                            child: const Icon(
                                                              Icons.south_west_rounded,
                                                              size: 13,
                                                              color: Color(0xFF059669),
                                                            ),
                                                          ),
                                                          const SizedBox(width: 8),
                                                          Text(
                                                            'You Lent',
                                                            style: TextStyle(
                                                              fontSize: 12.5,
                                                              fontWeight: FontWeight.w700,
                                                              color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      Icon(
                                                        Icons.chevron_right_rounded,
                                                        size: 16,
                                                        color: isDark ? Colors.white30 : Colors.black26,
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 10),
                                                  Text(
                                                    '+$currency ${effectiveLent.toStringAsFixed(effectiveLent % 1 == 0 ? 0 : 2)}',
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.w800,
                                                      color: Color(0xFF059669),
                                                      letterSpacing: -0.3,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    countILent > 0
                                                        ? '$countILent ${countILent == 1 ? 'payment to receive' : 'payments to receive'}'
                                                        : (effectiveLent > 0 ? 'To receive' : 'All settled'),
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w500,
                                                      color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      // 2. You Owe Card
                                      Expanded(
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () => Navigator.of(context).pushNamed(
                                              '/settle_up',
                                              arguments: {'tripId': tripId},
                                            ),
                                            borderRadius: BorderRadius.circular(16),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                              decoration: BoxDecoration(
                                                color: isDark ? const Color(0xFF161F30) : const Color(0xFFF8FAFC),
                                                borderRadius: BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: isDark ? const Color(0xFF243048) : const Color(0xFFE2E8F0),
                                                  width: 1,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: isDark ? Colors.black.withOpacity(0.2) : const Color(0x0A0F172A),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Container(
                                                            width: 24,
                                                            height: 24,
                                                            decoration: BoxDecoration(
                                                              color: const Color(0xFFEF4444).withOpacity(0.14),
                                                              borderRadius: BorderRadius.circular(7),
                                                            ),
                                                            child: const Icon(
                                                              Icons.north_east_rounded,
                                                              size: 13,
                                                              color: Color(0xFFDC2626),
                                                            ),
                                                          ),
                                                          const SizedBox(width: 8),
                                                          Text(
                                                            'You Owe',
                                                            style: TextStyle(
                                                              fontSize: 12.5,
                                                              fontWeight: FontWeight.w700,
                                                              color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      Icon(
                                                        Icons.chevron_right_rounded,
                                                        size: 16,
                                                        color: isDark ? Colors.white30 : Colors.black26,
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 10),
                                                  Text(
                                                    '-$currency ${effectiveOwe.toStringAsFixed(effectiveOwe % 1 == 0 ? 0 : 2)}',
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.w800,
                                                      color: effectiveOwe > 0.001
                                                          ? const Color(0xFFDC2626)
                                                          : (isDark ? AppColors.textDarkMuted : AppColors.textLightMuted),
                                                      letterSpacing: -0.3,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    countIOwe > 0
                                                        ? '$countIOwe ${countIOwe == 1 ? 'payment to make' : 'payments to make'}'
                                                        : (effectiveOwe > 0 ? 'To pay' : 'All settled'),
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w500,
                                                      color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
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
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Quick Actions Grid (4 Icons in a row)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildQuickAction(
                            context,
                            title: 'Expenses',
                            icon: Icons.receipt_long_rounded,
                            gradient: AppColors.expenseGradient,
                            onTap: () => Navigator.of(context).pushNamed(
                              '/all_expenses',
                              arguments: {'tripId': tripId},
                            ),
                          ),
                          _buildQuickAction(
                            context,
                            title: 'Members',
                            icon: Icons.group_rounded,
                            gradient: AppColors.membersGradient,
                            onTap: () => Navigator.of(context).pushNamed(
                              '/members',
                              arguments: {'tripId': tripId},
                            ),
                          ),
                          _buildQuickAction(
                            context,
                            title: 'Settle Up',
                            icon: Icons.balance_rounded,
                            gradient: AppColors.settleGradient,
                            onTap: () => Navigator.of(context).pushNamed(
                              '/settle_up',
                              arguments: {'tripId': tripId},
                            ),
                          ),
                          _buildQuickAction(
                            context,
                            title: 'Gallery',
                            icon: Icons.photo_library_rounded,
                            gradient: AppColors.galleryGradient,
                            onTap: () => Navigator.of(context).pushNamed(
                              '/gallery',
                              arguments: {'tripId': tripId},
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Recent Expenses Section Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Expenses',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pushNamed(
                              '/all_expenses',
                              arguments: {'tripId': tripId},
                            ),
                            child: const Row(
                              children: [
                                Text(
                                  'View All',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.primary),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Recent Expenses List from Database
                      displayedRecent.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(20),
                              alignment: Alignment.center,
                              child: Text(
                                'No expenses recorded yet',
                                style: TextStyle(
                                  color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: displayedRecent.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (ctx, index) {
                                final item = displayedRecent[index];
                                return TripSplitCard(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  onTap: () => Navigator.of(context).pushNamed(
                                    '/all_expenses',
                                    arguments: {'tripId': tripId},
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: item['iconBg'] as Color,
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Icon(
                                          item['icon'] as IconData,
                                          color: item['iconColor'] as Color,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['title'] as String,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              item['payer'] as String,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Builder(
                                        builder: (context) {
                                          final status = item['userStatus'] as String? ?? '';
                                          final isLent = status == 'lent' || status == 'settled_received';
                                          final isOwe = status == 'owe' || status == 'settled_paid';
                                          final statusColor = isLent
                                              ? const Color(0xFF10B981)
                                              : (isOwe
                                                  ? const Color(0xFFEF4444)
                                                  : (isDark ? AppColors.textDarkMain : AppColors.textLightMain));

                                          return Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                item['userAmount'] as String,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w800,
                                                  color: statusColor,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                item['userStatusLabel'] as String,
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: isLent
                                                      ? const Color(0xFF10B981)
                                                      : (isOwe
                                                          ? const Color(0xFFEF4444)
                                                          : (isDark ? AppColors.textDarkMuted : AppColors.textLightMuted)),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                      const SizedBox(height: 20),

                      // Add Expense CTA Button
                      TripSplitButton(
                        label: 'Add Expense',
                        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                        onPressed: () async {
                          await Navigator.of(context).pushNamed(
                            '/add_expense',
                            arguments: {'tripId': tripId},
                          );
                          _loadDashboard();
                        },
                      ),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Navigation Bar
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(0, Icons.home_rounded, 'Home', () {
                        Navigator.of(context).pushReplacementNamed('/home');
                      }),
                      _buildNavItem(1, Icons.photo_library_rounded, 'Gallery', () {
                        Navigator.of(context).pushNamed('/gallery', arguments: {'tripId': tripId});
                      }),
                      _buildCenterAddButton(context, tripId),
                      _buildNavItem(3, Icons.balance_rounded, 'Settle', () {
                        Navigator.of(context).pushNamed('/settle_up', arguments: {'tripId': tripId});
                      }),
                      _buildNavItem(4, Icons.person_rounded, 'Profile', () {
                        Navigator.of(context).pushNamed('/profile');
                      }),
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

  Widget _buildCenterAddButton(BuildContext context, int? tripId) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(
        '/add_expense',
        arguments: {'tripId': tripId},
      ),
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
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, VoidCallback onTap) {
    final isSelected = _navIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        setState(() => _navIndex = index);
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.textDarkMuted : AppColors.textLightMuted),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.textDarkMuted : AppColors.textLightMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: gradient.first.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
            ),
          ),
        ],
      ),
    );
  }
}
