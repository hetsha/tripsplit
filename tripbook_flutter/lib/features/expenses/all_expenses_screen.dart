import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/tripsplit_widgets.dart';
import '../../services/auth_service.dart';
import '../../services/expense_service.dart';
import '../../models/transaction.dart';

class AllExpensesScreen extends StatefulWidget {
  const AllExpensesScreen({Key? key}) : super(key: key);

  @override
  State<AllExpensesScreen> createState() => _AllExpensesScreenState();
}

class _AllExpensesScreenState extends State<AllExpensesScreen> {
  int _selectedCategoryIndex = 0;
  String _selectedPayerFilter = 'All'; // 'All', 'You', 'Others'
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _initialized = false;
  int? _tripId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final auth = Provider.of<AuthService>(context, listen: false);
      _tripId = args?['tripId'] ?? args?['trip']?['id'] ?? auth.activeTripId;
      _loadData();
      _initialized = true;
    }
  }

  Future<void> _loadData() async {
    final expense = Provider.of<ExpenseService>(context, listen: false);
    await Future.wait([
      expense.loadTransactions(tripId: _tripId, type: 'expense'),
      expense.loadCategories(tripId: _tripId),
      expense.loadDashboard(tripId: _tripId),
    ]);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Helper to map category names to icons and colors
  Map<String, dynamic> _getCategoryMeta(String? catName) {
    final name = (catName ?? 'General').toLowerCase();
    if (name.contains('food') || name.contains('dining') || name.contains('restaurant') || name.contains('cafe')) {
      return {'icon': Icons.restaurant_rounded, 'color': const Color(0xFFEF4444), 'bg': const Color(0xFFFEE2E2)};
    } else if (name.contains('stay') || name.contains('hotel') || name.contains('villa') || name.contains('resort')) {
      return {'icon': Icons.hotel_rounded, 'color': const Color(0xFF8B5CF6), 'bg': const Color(0xFFF3E8FF)};
    } else if (name.contains('transport') || name.contains('cab') || name.contains('flight') || name.contains('rental') || name.contains('fuel')) {
      return {'icon': Icons.directions_car_rounded, 'color': const Color(0xFF10B981), 'bg': const Color(0xFFD1FAE5)};
    } else if (name.contains('activit') || name.contains('sport') || name.contains('tour') || name.contains('ticket')) {
      return {'icon': Icons.surfing_rounded, 'color': const Color(0xFF0EA5E9), 'bg': const Color(0xFFE0F2FE)};
    } else if (name.contains('shop')) {
      return {'icon': Icons.shopping_bag_rounded, 'color': const Color(0xFFEC4899), 'bg': const Color(0xFFFCE7F3)};
    }
    return {'icon': Icons.receipt_long_rounded, 'color': const Color(0xFFF59E0B), 'bg': const Color(0xFFFEF3C7)};
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = Provider.of<AuthService>(context);
    final expense = Provider.of<ExpenseService>(context);
    final currentUserId = auth.currentUser?.id ?? 0;
    final transactions = expense.transactionsList.where((t) => t.type == 'expense').toList();

    // Calculate aggregated amounts
    final double totalTripExpenses = transactions.fold(0.0, (sum, t) => sum + t.amount);
    final double totalYouPaid = transactions
        .where((t) => t.payerId == currentUserId)
        .fold(0.0, (sum, t) => sum + t.amount);

    double totalYourShare = 0.0;
    for (var t in transactions) {
      for (var s in t.splits) {
        if (s.userId == currentUserId) {
          totalYourShare += s.amount;
        }
      }
    }
    final double netBalance = totalYouPaid - totalYourShare;

    // Build dynamic categories list
    final Map<String, int> catCounts = {};
    for (var t in transactions) {
      final cName = t.categoryName ?? 'Other';
      catCounts[cName] = (catCounts[cName] ?? 0) + 1;
    }

    final List<Map<String, dynamic>> categoryChips = [
      {'title': 'All', 'count': transactions.length, 'icon': Icons.tune_rounded},
      ...catCounts.entries.map((e) => {
            'title': e.key,
            'count': e.value,
            'icon': _getCategoryMeta(e.key)['icon'] as IconData,
          }),
    ];

    if (_selectedCategoryIndex >= categoryChips.length) {
      _selectedCategoryIndex = 0;
    }

    // Filter transactions
    final selectedCategory = categoryChips[_selectedCategoryIndex]['title'] as String;
    final filteredList = transactions.where((t) {
      // Category filter
      if (selectedCategory != 'All' && (t.categoryName ?? 'Other') != selectedCategory) {
        return false;
      }

      // Payer filter
      final isUser = t.payerId == currentUserId;
      if (_selectedPayerFilter == 'You' && !isUser) return false;
      if (_selectedPayerFilter == 'Others' && isUser) return false;

      // Search filter
      final q = _searchQuery.toLowerCase().trim();
      if (q.isNotEmpty) {
        final matchesDesc = t.description.toLowerCase().contains(q);
        final matchesPayer = (t.payerName ?? '').toLowerCase().contains(q);
        final matchesCat = (t.categoryName ?? '').toLowerCase().contains(q);
        final matchesNote = (t.notes ?? '').toLowerCase().contains(q);
        if (!matchesDesc && !matchesPayer && !matchesCat && !matchesNote) {
          return false;
        }
      }

      return true;
    }).toList();

    final activeTripName = auth.activeTrip?.name ?? 'Trip Expenses';

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Top App Bar
                TripSplitHeader(
                  title: 'All Expenses',
                  subtitle: '$activeTripName • ${transactions.length} Records',
                  onBack: () => Navigator.of(context).maybePop(),
                ),

                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadData,
                    color: AppColors.primary,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                      children: [
                        // 1. FINANCIAL SUMMARY HERO CARD
                        _buildSummaryHeroCard(
                          isDark: isDark,
                          totalTripExpenses: totalTripExpenses,
                          totalYouPaid: totalYouPaid,
                          totalYourShare: totalYourShare,
                          netBalance: netBalance,
                        ),

                        const SizedBox(height: 14),

                        // 2. SEARCH BAR
                        _buildSearchField(isDark),

                        const SizedBox(height: 12),

                        // 3. CATEGORY PILLS BAR
                        if (categoryChips.length > 1) ...[
                          _buildCategoryFilterBar(isDark, categoryChips),
                          const SizedBox(height: 10),
                        ],

                        // 4. PAYER QUICK TOGGLES (All, Paid by You, Paid by Friends)
                        _buildPayerToggleRow(isDark),

                        const SizedBox(height: 14),

                        // 5. EXPENSES LIST HEADER
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Expenses (${filteredList.length})',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                              ),
                            ),
                            Text(
                              'Tap item for split details',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // 6. EXPENSE CARDS LIST
                        if (expense.isLoading && transactions.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (filteredList.isEmpty)
                          _buildEmptyState(isDark)
                        else
                          ...filteredList.map((item) => _buildExpenseCard(
                                context: context,
                                isDark: isDark,
                                tx: item,
                                currentUserId: currentUserId,
                              )),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Bottom Floating Add Expense Pill Button
            Positioned(
              left: 20,
              right: 20,
              bottom: 16,
              child: TripSplitButton(
                label: 'Add New Expense',
                icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                onPressed: () async {
                  await Navigator.of(context).pushNamed('/add_expense', arguments: {
                    'tripId': _tripId,
                  });
                  _loadData();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. Summary Hero Card: Total Spent, Your Share, Net Position
  Widget _buildSummaryHeroCard({
    required bool isDark,
    required double totalTripExpenses,
    required double totalYouPaid,
    required double totalYourShare,
    required double netBalance,
  }) {
    final isLent = netBalance >= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E283D), const Color(0xFF151C2C)]
              : [const Color(0xFFF8FAFC), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isDark ? const Color(0xFF28364F) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL TRIP EXPENSES',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹ ${totalTripExpenses.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (isLent ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (isLent ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isLent ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                      size: 13,
                      color: isLent ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isLent
                          ? '+₹ ${netBalance.toStringAsFixed(0)} Lent'
                          : '-₹ ${netBalance.abs().toStringAsFixed(0)} Owe',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: isLent ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: isDark ? const Color(0xFF253248) : const Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMiniMetric('₹ ${totalYouPaid.toStringAsFixed(0)}', 'You Paid', isDark, const Color(0xFF10B981)),
              Container(height: 26, width: 1, color: isDark ? const Color(0xFF253248) : const Color(0xFFE2E8F0)),
              _buildMiniMetric('₹ ${totalYourShare.toStringAsFixed(0)}', 'Your Fair Share', isDark, AppColors.primary),
              Container(height: 26, width: 1, color: isDark ? const Color(0xFF253248) : const Color(0xFFE2E8F0)),
              _buildMiniMetric(
                isLent ? 'Net Positive' : 'Net Due',
                'Status',
                isDark,
                isLent ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(String value, String label, bool isDark, Color accentColor) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 1),
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
    );
  }

  // 2. Search Field
  Widget _buildSearchField(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131A29) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF222F43) : const Color(0xFFE2E8F0),
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        style: TextStyle(
          fontSize: 13.5,
          color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
        ),
        decoration: InputDecoration(
          hintText: 'Search expenses, payers, food...',
          hintStyle: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
          ),
          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.primary),
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  child: const Icon(Icons.close_rounded, size: 18),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  // 3. Category Filter Chips
  Widget _buildCategoryFilterBar(bool isDark, List<Map<String, dynamic>> categoryChips) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categoryChips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, index) {
          final isSelected = index == _selectedCategoryIndex;
          final cat = categoryChips[index];

          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? const Color(0xFF131A29) : Colors.white),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? const Color(0xFF222F43) : const Color(0xFFE2E8F0)),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    cat['icon'] as IconData,
                    size: 14,
                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${cat['title']} (${cat['count']})',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? AppColors.textDarkMuted : AppColors.textLightMain),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 4. Payer Filter Toggle Row
  Widget _buildPayerToggleRow(bool isDark) {
    final options = ['All', 'You', 'Others'];

    return Row(
      children: options.map((opt) {
        final isSelected = _selectedPayerFilter == opt;

        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedPayerFilter = opt),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 7),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? const Color(0xFF243048) : const Color(0xFFF1F5F9))
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.5)
                      : Colors.transparent,
                  width: 1.2,
                ),
              ),
              child: Center(
                child: Text(
                  opt == 'All' ? 'All Payers' : (opt == 'You' ? 'Paid by You' : 'Paid by Friends'),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? AppColors.textDarkMuted : AppColors.textLightMuted),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // 5. Individual Expense Card
  Widget _buildExpenseCard({
    required BuildContext context,
    required bool isDark,
    required Transaction tx,
    required int currentUserId,
  }) {
    final isUser = tx.payerId == currentUserId;
    final catMeta = _getCategoryMeta(tx.categoryName);

    // Calculate user's net position for this transaction
    double mySplitAmt = 0.0;
    for (var s in tx.splits) {
      if (s.userId == currentUserId) {
        mySplitAmt = s.amount;
        break;
      }
    }

    final double userNet = isUser ? (tx.amount - mySplitAmt) : -mySplitAmt;
    final isPositive = userNet >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131A29) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF222F43) : const Color(0xFFE2E8F0),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.18 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showExpenseDetailsSheet(context, isDark, tx, currentUserId, catMeta),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Category Icon with soft background
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: catMeta['bg'] as Color,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    catMeta['icon'] as IconData,
                    color: catMeta['color'] as Color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),

                // Title & Payer Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 8,
                            backgroundColor: isUser ? const Color(0xFF10B981) : AppColors.primary,
                            child: Text(
                              (tx.payerName ?? 'U').isNotEmpty ? (tx.payerName ?? 'U')[0].toUpperCase() : 'U',
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              '${isUser ? 'You' : (tx.payerName ?? 'Friend')} paid ₹${tx.amount.toStringAsFixed(0)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: isUser
                                    ? const Color(0xFF10B981)
                                    : (isDark ? AppColors.textDarkMuted : AppColors.textLightMuted),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '• ${tx.formattedDate.isNotEmpty ? tx.formattedDate : tx.date}',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Amount & Lent / Borrowed Tag
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      userNet > 0.001
                          ? '+₹ ${userNet.toStringAsFixed(0)}'
                          : (userNet < -0.001
                              ? '-₹ ${userNet.abs().toStringAsFixed(0)}'
                              : (isUser ? '₹ ${tx.amount.toStringAsFixed(0)}' : '₹ 0')),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: userNet > 0.001
                            ? const Color(0xFF10B981)
                            : (userNet < -0.001
                                ? const Color(0xFFEF4444)
                                : (isDark ? AppColors.textDarkMain : AppColors.textLightMain)),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (userNet > 0.001
                                ? const Color(0xFF10B981)
                                : (userNet < -0.001
                                    ? const Color(0xFFEF4444)
                                    : (isDark ? Colors.white10 : Colors.black12)))
                            .withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        userNet > 0.001
                            ? 'You lent'
                            : (userNet < -0.001
                                ? 'You owe'
                                : (isUser ? 'You paid' : 'Not involved')),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: userNet > 0.001
                              ? const Color(0xFF10B981)
                              : (userNet < -0.001
                                  ? const Color(0xFFEF4444)
                                  : (isDark ? AppColors.textDarkMuted : AppColors.textLightMuted)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 6. Empty State when search returns 0 results
  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long_rounded, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 14),
            Text(
              'No expenses found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try changing your search keywords or active filter.',
              textAlign: TextAlign.center,
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

  // Detailed Expense Bottom Sheet Modal
  void _showExpenseDetailsSheet(
    BuildContext context,
    bool isDark,
    Transaction tx,
    int currentUserId,
    Map<String, dynamic> catMeta,
  ) {
    final isUser = tx.payerId == currentUserId;
    final expense = Provider.of<ExpenseService>(context, listen: false);

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
              // Sheet Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title Row
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: catMeta['bg'] as Color,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(catMeta['icon'] as IconData, color: catMeta['color'] as Color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx.description,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${tx.categoryName ?? 'Expense'} • ${tx.formattedDate.isNotEmpty ? tx.formattedDate : tx.date}',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Big Amount Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF172033) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? const Color(0xFF28364F) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'TOTAL AMOUNT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹ ${tx.amount.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Paid by ${isUser ? 'You' : (tx.payerName ?? 'Friend')} via ${tx.paymentMethodLabel}',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Split Breakdown List
              Text(
                'Split Breakdown (${tx.splits.length} Members)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                ),
              ),
              const SizedBox(height: 8),

              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF172033) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF222F43) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < tx.splits.length; i++) ...[
                      _buildSplitMemberRow(
                        tx.splits[i].name,
                        tx.splits[i].amount,
                        tx.splits[i].userId == tx.payerId,
                        isDark,
                      ),
                      if (i < tx.splits.length - 1)
                        Divider(height: 1, color: isDark ? const Color(0xFF222F43) : const Color(0xFFE2E8F0)),
                    ]
                  ],
                ),
              ),

              if (tx.notes != null && tx.notes!.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A2338) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.sticky_note_2_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tx.notes!,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Action Buttons: Edit / Delete
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFFEF4444)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        try {
                          await expense.deleteTransaction(tx.id);
                          _loadData();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Expense deleted successfully')),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to delete expense: $e')),
                            );
                          }
                        }
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 17),
                          SizedBox(width: 6),
                          Text(
                            'Delete',
                            style: TextStyle(
                              color: Color(0xFFEF4444),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text(
                        'Done',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSplitMemberRow(String name, double amount, bool isPayer, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: isPayer ? const Color(0xFF10B981) : AppColors.primary.withOpacity(0.2),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'M',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isPayer ? Colors.white : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                ),
              ),
              if (isPayer) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Payer',
                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF10B981)),
                  ),
                ),
              ],
            ],
          ),
          Text(
            '₹ ${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
            ),
          ),
        ],
      ),
    );
  }
}
