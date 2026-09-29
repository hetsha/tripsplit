import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/tripsplit_widgets.dart';

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

  final List<Map<String, dynamic>> _categories = [
    {'title': 'All', 'count': 7, 'icon': Icons.tune_rounded},
    {'title': 'Food', 'count': 2, 'icon': Icons.restaurant_rounded},
    {'title': 'Stay', 'count': 1, 'icon': Icons.hotel_rounded},
    {'title': 'Transport', 'count': 2, 'icon': Icons.directions_car_rounded},
    {'title': 'Activities', 'count': 2, 'icon': Icons.surfing_rounded},
  ];

  final List<Map<String, dynamic>> _allExpenses = [
    {
      'id': 1,
      'title': 'Dinner at Beach Shack',
      'payer': 'You (Het)',
      'isUser': true,
      'payerAvatar': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
      'date': '12 Dec 2024',
      'time': '8:30 PM',
      'amount': 2450,
      'userNet': 1960, // Het paid 2450, fair share is 490 -> lent 1960
      'splitText': 'Split equally between 5 members',
      'membersCount': 5,
      'icon': Icons.restaurant_rounded,
      'color': const Color(0xFFEF4444),
      'bg': const Color(0xFFFEE2E2),
      'category': 'Food',
      'paymentMode': 'UPI (Google Pay)',
      'note': 'Seafood platter and fresh lime sodas by the beach.',
    },
    {
      'id': 2,
      'title': 'Water Sports & Scuba',
      'payer': 'Rahul',
      'isUser': false,
      'payerAvatar': 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=100',
      'date': '12 Dec 2024',
      'time': '11:15 AM',
      'amount': 5000,
      'userNet': -1000, // Rahul paid 5000, Het owes 1000
      'splitText': 'Split equally between 5 members',
      'membersCount': 5,
      'icon': Icons.surfing_rounded,
      'color': const Color(0xFF0EA5E9),
      'bg': const Color(0xFFE0F2FE),
      'category': 'Activities',
      'paymentMode': 'Credit Card',
      'note': 'Parasailing, jet ski, and scuba briefing package.',
    },
    {
      'id': 3,
      'title': 'Luxury Beach Villa Stay',
      'payer': 'Priya',
      'isUser': false,
      'payerAvatar': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100',
      'date': '13 Dec 2024',
      'time': '2:00 PM',
      'amount': 8000,
      'userNet': -1600, // Priya paid 8000, Het owes 1600
      'splitText': 'Split equally between 5 members',
      'membersCount': 5,
      'icon': Icons.hotel_rounded,
      'color': const Color(0xFF8B5CF6),
      'bg': const Color(0xFFF3E8FF),
      'category': 'Stay',
      'paymentMode': 'Bank Transfer (NEFT)',
      'note': '2 nights stay at North Goa Seaside Villa.',
    },
    {
      'id': 4,
      'title': 'Airport Cab & Tolls',
      'payer': 'Amit',
      'isUser': false,
      'payerAvatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
      'date': '12 Dec 2024',
      'time': '9:00 AM',
      'amount': 1200,
      'userNet': -240, // Amit paid 1200, Het owes 240
      'splitText': 'Split equally between 5 members',
      'membersCount': 5,
      'icon': Icons.local_taxi_rounded,
      'color': const Color(0xFF10B981),
      'bg': const Color(0xFFD1FAE5),
      'category': 'Transport',
      'paymentMode': 'Cash',
      'note': 'Goa Dabolim Airport to Calangute resort.',
    },
    {
      'id': 5,
      'title': 'Lunch at Seaside Café',
      'payer': 'Neha',
      'isUser': false,
      'payerAvatar': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100',
      'date': '13 Dec 2024',
      'time': '1:30 PM',
      'amount': 1050,
      'userNet': -210, // Neha paid 1050, Het owes 210
      'splitText': 'Split equally between 5 members',
      'membersCount': 5,
      'icon': Icons.coffee_rounded,
      'color': const Color(0xFFF59E0B),
      'bg': const Color(0xFFFEF3C7),
      'category': 'Food',
      'paymentMode': 'UPI (PhonePe)',
      'note': 'Woodfire pizzas, shakes, and cold coffee.',
    },
    {
      'id': 6,
      'title': 'Fort Aguada & Beach Entry',
      'payer': 'You (Het)',
      'isUser': true,
      'payerAvatar': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
      'date': '14 Dec 2024',
      'time': '4:45 PM',
      'amount': 600,
      'userNet': 480, // Het paid 600, fair share is 120 -> lent 480
      'splitText': 'Split equally between 5 members',
      'membersCount': 5,
      'icon': Icons.confirmation_number_rounded,
      'color': const Color(0xFF06B6D4),
      'bg': const Color(0xFFCFFAFE),
      'category': 'Activities',
      'paymentMode': 'UPI (Paytm)',
      'note': 'Entry pass tickets for all 5 group members.',
    },
    {
      'id': 7,
      'title': 'Scooter Rental (2 Days)',
      'payer': 'Rahul',
      'isUser': false,
      'payerAvatar': 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=100',
      'date': '14 Dec 2024',
      'time': '10:00 AM',
      'amount': 2000,
      'userNet': -400, // Rahul paid 2000, Het owes 400
      'splitText': 'Split equally between 5 members',
      'membersCount': 5,
      'icon': Icons.two_wheeler_rounded,
      'color': const Color(0xFFF97316),
      'bg': const Color(0xFFFFEDD5),
      'category': 'Transport',
      'paymentMode': 'Cash',
      'note': 'Activa rentals with helmets for local commuting.',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredExpenses {
    return _allExpenses.where((item) {
      // Category filter
      final selectedCategory = _categories[_selectedCategoryIndex]['title'] as String;
      final matchesCategory = selectedCategory == 'All' || item['category'] == selectedCategory;

      // Payer filter
      bool matchesPayer = true;
      if (_selectedPayerFilter == 'You') {
        matchesPayer = item['isUser'] == true;
      } else if (_selectedPayerFilter == 'Others') {
        matchesPayer = item['isUser'] == false;
      }

      // Search query
      final query = _searchQuery.toLowerCase().trim();
      final matchesSearch = query.isEmpty ||
          (item['title'] as String).toLowerCase().contains(query) ||
          (item['payer'] as String).toLowerCase().contains(query) ||
          (item['category'] as String).toLowerCase().contains(query) ||
          (item['note'] as String).toLowerCase().contains(query);

      return matchesCategory && matchesPayer && matchesSearch;
    }).toList();
  }

  int get _totalTripExpenses => _allExpenses.fold(0, (sum, item) => sum + (item['amount'] as int));
  int get _totalYouPaid => _allExpenses.where((i) => i['isUser'] == true).fold(0, (sum, item) => sum + (item['amount'] as int));
  int get _netBalance => _totalYouPaid - (_totalTripExpenses ~/ 5);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredList = _filteredExpenses;

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
                  subtitle: 'Goa Trip 🏖️ • ${_allExpenses.length} Records',
                  onBack: () => Navigator.of(context).maybePop(),
                ),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    children: [
                      // 1. FINANCIAL SUMMARY HERO CARD
                      _buildSummaryHeroCard(isDark),

                      const SizedBox(height: 14),

                      // 2. SEARCH BAR
                      _buildSearchField(isDark),

                      const SizedBox(height: 12),

                      // 3. CATEGORY PILLS BAR
                      _buildCategoryFilterBar(isDark),

                      const SizedBox(height: 10),

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
                      if (filteredList.isEmpty)
                        _buildEmptyState(isDark)
                      else
                        ...filteredList.map((item) => _buildExpenseCard(context, isDark, item)),
                    ],
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
                onPressed: () => Navigator.of(context).pushNamed('/add_expense'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. Summary Hero Card: Total Spent, Your Share, Net Position
  Widget _buildSummaryHeroCard(bool isDark) {
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
                    '₹ $_totalTripExpenses',
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
                  color: const Color(0xFF10B981).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_downward_rounded, size: 13, color: Color(0xFF10B981)),
                    const SizedBox(width: 4),
                    Text(
                      '+₹ $_netBalance Lent',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF10B981),
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
              _buildMiniMetric('₹ $_totalYouPaid', 'You Paid', isDark, const Color(0xFF10B981)),
              Container(height: 26, width: 1, color: isDark ? const Color(0xFF253248) : const Color(0xFFE2E8F0)),
              _buildMiniMetric('₹ ${_totalTripExpenses ~/ 5}', 'Your Fair Share', isDark, AppColors.primary),
              Container(height: 26, width: 1, color: isDark ? const Color(0xFF253248) : const Color(0xFFE2E8F0)),
              _buildMiniMetric('5 Members', 'Equal Split', isDark, const Color(0xFFF59E0B)),
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
  Widget _buildCategoryFilterBar(bool isDark) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, index) {
          final isSelected = index == _selectedCategoryIndex;
          final cat = _categories[index];

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
  Widget _buildExpenseCard(BuildContext context, bool isDark, Map<String, dynamic> item) {
    final isUser = item['isUser'] == true;
    final userNet = item['userNet'] as int;
    final isPositive = userNet > 0;

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
          onTap: () => _showExpenseDetailsSheet(context, isDark, item),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Category Icon with soft background
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: item['bg'] as Color,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    color: item['color'] as Color,
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
                        item['title'] as String,
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
                            backgroundImage: NetworkImage(item['payerAvatar'] as String),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              '${item['payer']} paid',
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
                            '• ${item['date']}',
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
                      '₹ ${item['amount']}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isPositive ? '+₹ $userNet you lent' : '-₹ ${userNet.abs()} you owe',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
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
  void _showExpenseDetailsSheet(BuildContext context, bool isDark, Map<String, dynamic> item) {
    final isUser = item['isUser'] == true;
    final int amount = item['amount'] as int;
    final int sharePerPerson = amount ~/ 5;

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
                      color: item['bg'] as Color,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] as String,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item['category']} • ${item['date']} at ${item['time']}',
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
                      '₹ $amount',
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
                        'Paid by ${item['payer']} via ${item['paymentMode']}',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Split Breakdown List
              Text(
                'Split Breakdown (5 Members)',
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
                    _buildSplitMemberRow('You (Het)', sharePerPerson, isUser, isDark),
                    Divider(height: 1, color: isDark ? const Color(0xFF222F43) : const Color(0xFFE2E8F0)),
                    _buildSplitMemberRow('Rahul', sharePerPerson, item['payer'] == 'Rahul', isDark),
                    Divider(height: 1, color: isDark ? const Color(0xFF222F43) : const Color(0xFFE2E8F0)),
                    _buildSplitMemberRow('Priya', sharePerPerson, item['payer'] == 'Priya', isDark),
                    Divider(height: 1, color: isDark ? const Color(0xFF222F43) : const Color(0xFFE2E8F0)),
                    _buildSplitMemberRow('Amit', sharePerPerson, item['payer'] == 'Amit', isDark),
                    Divider(height: 1, color: isDark ? const Color(0xFF222F43) : const Color(0xFFE2E8F0)),
                    _buildSplitMemberRow('Neha', sharePerPerson, item['payer'] == 'Neha', isDark),
                  ],
                ),
              ),

              if (item['note'] != null && (item['note'] as String).isNotEmpty) ...[
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
                          item['note'] as String,
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
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        setState(() {
                          _allExpenses.removeWhere((e) => e['id'] == item['id']);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Expense deleted successfully')),
                        );
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 17),
                          SizedBox(width: 6),
                          Text(
                            'Delete',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFEF4444)),
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
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.of(context).pushNamed('/add_expense');
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit_rounded, color: Colors.white, size: 17),
                          SizedBox(width: 6),
                          Text(
                            'Edit Expense',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ],
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

  Widget _buildSplitMemberRow(String name, int share, bool isPayer, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isPayer ? FontWeight.w800 : FontWeight.w500,
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
                    'PAID',
                    style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
                  ),
                ),
              ],
            ],
          ),
          Text(
            '₹ $share',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
            ),
          ),
        ],
      ),
    );
  }
}
