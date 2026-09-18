import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/auth_service.dart';
import '../../services/expense_service.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../theme/app_theme.dart';
import '../expenses/add_expense_screen.dart';
import '../cashbook/cashbook_screen.dart';
import '../passbook/passbook_screen.dart';
import '../auth/trip_selector_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final expense = Provider.of<ExpenseService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tripName = (auth.activeTrip?.name ?? 'No Trip').trim();
    final displayName = _formatTripName(auth.currentUser?.name ?? 'Member');

    final dash = expense.dashboardData;
    final summary = dash?['expense_summary'] ?? {};
    final whoOwesWhom = dash?['who_owes_whom'] as List? ?? [];
    final memberBalances = dash?['member_balances'] as List? ?? [];
    final categorySpending = dash?['category_spending'] as List? ?? [];
    final recentTransactions = dash?['recent_transactions'] as List? ?? [];

    final currency = auth.activeTrip?.currencySymbol ?? '₹';
    final totalExpenses = double.tryParse((summary['total_all_expenses'] ?? 0).toString()) ?? 0.0;
    final memberCount = memberBalances.length;

    final currentUserId = auth.currentUser?.id;
    final myBalance = memberBalances.isNotEmpty
        ? memberBalances.firstWhere(
            (b) => (b['user_id'] ?? b['id']) == currentUserId,
            orElse: () => null,
          )
        : null;
    final myOwed = myBalance != null
        ? double.tryParse((myBalance['net_balance'] ?? 0).toString()) ?? 0.0
        : 0.0;
    final isPositiveBalance = myOwed >= 0;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: RefreshIndicator(
        onRefresh: () => expense.loadDashboard(),
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                    _buildHeader(context, auth, displayName, tripName, isDark),
                    const SizedBox(height: 20),

                    _buildHeroCard(context, currency, totalExpenses, memberCount, isDark, myOwed, isPositiveBalance),
                    const SizedBox(height: 20),

                    _buildQuickActions(context, expense, currency, isDark),
                    const SizedBox(height: 20),

                    _buildWhoOwesWhom(whoOwesWhom, currency, expense, context, isDark),
                    const SizedBox(height: 20),

                    if (memberBalances.isNotEmpty) ...[
                      _buildMemberSpending(memberBalances, currency, totalExpenses, isDark),
                      const SizedBox(height: 20),
                    ],

                    if (categorySpending.isNotEmpty) ...[
                      _buildSpendingOverview(currency, totalExpenses, categorySpending, isDark),
                      const SizedBox(height: 20),
                    ],

                    if (recentTransactions.isNotEmpty)
                      _buildRecentTransactions(recentTransactions, currency, isDark),
                  ]),
                ),
              ),
            ],
          ),
        ),
    );
  }

  String _formatTripName(String name) {
    if (name.isEmpty) return name;
    return name.split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }

  static final Map<String, IconData> _lucideIconMap = {
    'utensils': LucideIcons.utensils,
    'receipt': LucideIcons.receipt,
    'wallet': LucideIcons.wallet,
    'car': LucideIcons.car,
    'train': LucideIcons.train,
    'plane': LucideIcons.plane,
    'coffee': LucideIcons.coffee,
    'shopping-cart': LucideIcons.shoppingCart,
    'home': LucideIcons.home,
    'building': LucideIcons.building,
    'hotel': LucideIcons.hotel,
    'map-pin': LucideIcons.mapPin,
    'fuel': LucideIcons.fuel,
    'zap': LucideIcons.zap,
    'music': LucideIcons.music,
    'camera': LucideIcons.camera,
    'gift': LucideIcons.gift,
    'heart': LucideIcons.heart,
    'star': LucideIcons.star,
    'phone': LucideIcons.phone,
    'mail': LucideIcons.mail,
    'credit-card': LucideIcons.creditCard,
    'banknote': LucideIcons.banknote,
    'coins': LucideIcons.coins,
    'piggy-bank': LucideIcons.piggyBank,
    'store': LucideIcons.store,
    'package': LucideIcons.package,
    'ticket': LucideIcons.ticket,
    'dumbbell': LucideIcons.dumbbell,
    'baby': LucideIcons.baby,
    'heart-pulse': LucideIcons.heartPulse,
    'stethoscope': LucideIcons.stethoscope,
    'graduation-cap': LucideIcons.graduationCap,
    'book-open': LucideIcons.bookOpen,
    'bookmark': LucideIcons.bookmark,
    'film': LucideIcons.film,
    'popcorn': LucideIcons.popcorn,
    'utensils-crossed': LucideIcons.utensilsCrossed,
    'beer': LucideIcons.beer,
    'wine': LucideIcons.wine,
    'cake': LucideIcons.cake,
    'salad': LucideIcons.salad,
    'pizza': LucideIcons.pizza,
    'bus': LucideIcons.bus,
    'bicycle': LucideIcons.bike,
    'navigation': LucideIcons.navigation,
    'clock': LucideIcons.clock,
    'users': LucideIcons.users,
    'user': LucideIcons.user,
    'file-text': LucideIcons.fileText,
    'download': LucideIcons.download,
    'upload': LucideIcons.upload,
    'plus': LucideIcons.plus,
    'minus': LucideIcons.minus,
    'repeat': LucideIcons.repeat,
    'shield': LucideIcons.shield,
    'wifi': LucideIcons.wifi,
    'smartphone': LucideIcons.smartphone,
    'laptop': LucideIcons.laptop,
    'monitor': LucideIcons.monitor,
    'headphones': LucideIcons.headphones,
    'dollar-sign': LucideIcons.dollarSign,
    'indian-rupee': LucideIcons.indianRupee,
  };

  IconData _getIconFromName(String iconName) {
    if (iconName.isEmpty) return LucideIcons.receipt;
    if (_lucideIconMap.containsKey(iconName)) {
      return _lucideIconMap[iconName]!;
    }
    // Check for emoji (unicode > 0x1F000)
    if (iconName.runes.first > 0x1F000) {
      return LucideIcons.receipt;
    }
    return LucideIcons.receipt;
  }

  Widget _buildHeader(BuildContext context, AuthService auth, String displayName, String tripName, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button + Greeting row
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${_greeting()}, $displayName \u{1F44B}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _formatTripName(tripName),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.positive.withOpacity(isDark ? 0.15 : 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(backgroundColor: AppColors.positive, radius: 3),
              SizedBox(width: 6),
              Text(
                'Synced',
                style: TextStyle(
                  color: AppColors.positive,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard(BuildContext context, String currency, double totalExpenses, int memberCount, bool isDark, double myOwed, bool isPositiveBalance) {
    final trip = Provider.of<AuthService>(context, listen: false).activeTrip;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.30),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Card body — dark gradient base
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1A1040),
                    Color(0xFF0F0A2A),
                    Color(0xFF0A0818),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row — chip + trip code
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // EMV chip
                      _buildChip(),
                      if (trip != null)
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: trip.tripCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Trip code ${trip.tripCode} copied!'),
                                duration: const Duration(seconds: 1),
                                backgroundColor: AppColors.positive,
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.20),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  trip.tripCode,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.5,
                                    color: Colors.white.withOpacity(0.70),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.copy_rounded,
                                  size: 12,
                                  color: Colors.white.withOpacity(0.50),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Amount
                  Text(
                    '$currency${totalExpenses.toInt()}',
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'All expenses across the group',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.45),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Bottom row — members + balance
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildCardMetric('MEMBERS', '$memberCount', isDark),
                      _buildCardMetric(
                        isPositiveBalance ? 'YOU GET' : 'YOU OWE',
                        '$currency${myOwed.abs().toInt()}',
                        isDark,
                        valueColor: isPositiveBalance ? AppColors.positive : AppColors.negative,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Holographic shine effect — diagonal sweep (ignore pointer taps)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: const Alignment(-1.0, -1.0),
                      end: const Alignment(1.0, 1.0),
                      colors: [
                        Colors.transparent,
                        Colors.white.withOpacity(0.03),
                        Colors.white.withOpacity(0.06),
                        Colors.white.withOpacity(0.03),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // Top edge highlight
            Positioned(
              top: 0,
              left: 20,
              right: 20,
              height: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.transparent,
                      Colors.white.withOpacity(0.25),
                      Colors.white.withOpacity(0.40),
                      Colors.white.withOpacity(0.25),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                  ),
                ),
              ),
            ),

            // Border (ignore pointer taps)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.10),
                      width: 0.8,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip() {
    return Container(
      width: 40,
      height: 30,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFE8D5A3),
            const Color(0xFFD4B978),
            const Color(0xFFC9A85C),
            const Color(0xFFD4B978),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _ChipPainter(),
      ),
    );
  }

  Widget _buildCardMetric(String label, String value, bool isDark, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: Colors.white.withOpacity(0.40),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: valueColor ?? Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, ExpenseService expense, String currency, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUICK ACTIONS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // Add button
            GestureDetector(
              onTap: () => _showAddOptionsSheet(context, isDark),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withOpacity(0.15),
                      AppColors.accent.withOpacity(0.08),
                    ],
                  ),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.20),
                    width: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.add_rounded, color: AppColors.primary, size: 26),
              ),
            ),
            const SizedBox(width: 10),
            // Ledger pill
            Expanded(
              child: GestureDetector(
                onTap: () => _showLedgerOptionsSheet(context, isDark),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withOpacity(0.15),
                        AppColors.accent.withOpacity(0.08),
                      ],
                    ),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.20),
                      width: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.bookOpen, color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Ledger',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showAddOptionsSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.elevatedDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAddOption(
                  context,
                  Icons.receipt_long_rounded,
                  'Expense',
                  const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AddExpenseScreen()));
                  },
                ),
                _buildAddOption(
                  context,
                  Icons.account_balance_wallet_rounded,
                  'Add Money',
                  const [Color(0xFF10B981), Color(0xFF06B6D4)],
                  () {
                    Navigator.pop(ctx);
                    _showAddMoneyDialog(context, isDark);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showLedgerOptionsSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.elevatedDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAddOption(
                  context,
                  Icons.book_rounded,
                  'CashBook',
                  const [Color(0xFFF59E0B), Color(0xFFEF4444)],
                  () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CashBookScreen()));
                  },
                ),
                _buildAddOption(
                  context,
                  Icons.menu_book_rounded,
                  'Passbook',
                  const [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                  () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PassbookScreen()));
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showAddMoneyDialog(BuildContext context, bool isDark) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    String method = 'cash';

    final methods = [
      {'key': 'cash', 'icon': Icons.money_rounded, 'label': 'Cash'},
      {'key': 'bank', 'icon': Icons.account_balance_rounded, 'label': 'Bank'},
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Add Money to CashBook', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: methods.map((m) {
                      final isActive = method == m['key'];
                      return GestureDetector(
                        onTap: () => setDialogState(() => method = m['key'] as String),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: isActive
                                ? AppColors.primary.withOpacity(0.15)
                                : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04)),
                            border: Border.all(
                              color: isActive ? AppColors.primary : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(m['icon'] as IconData, size: 16, color: isActive ? AppColors.primary : (isDark ? AppColors.textDarkMuted : AppColors.textLightMuted)),
                              const SizedBox(width: 6),
                              Text(
                                m['label'] as String,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isActive ? AppColors.primary : (isDark ? AppColors.textDarkMuted : AppColors.textLightMuted),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    decoration: InputDecoration(
                      labelText: 'Notes (Optional)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final amt = double.tryParse(amountController.text.trim()) ?? 0.0;
                    if (amt <= 0.0) return;
                    final auth = Provider.of<AuthService>(context, listen: false);
                    Navigator.pop(context);
                    await _recordIncome(auth, context, amt, method, noteController.text.trim());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.positive,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Add Money', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _recordIncome(AuthService auth, BuildContext context, double amount, String method, String notes) async {
    final apiClient = ApiClient();
    try {
      await apiClient.post(ApiEndpoints.transactions, {
        'action': 'add_income',
        'amount': amount,
        'payment_method': method,
        'notes': notes.isNotEmpty ? notes : 'Personal income added to cashbook',
      });
      if (context.mounted) {
        Provider.of<ExpenseService>(context, listen: false).loadDashboard();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Money added to CashBook!'), backgroundColor: AppColors.positive),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.negative),
        );
      }
    }
  }

  Widget _buildAddOption(BuildContext context, IconData icon, String label, List<Color> gradient, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: gradient[0].withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPill(BuildContext context, IconData icon, String label, bool isDark, VoidCallback onTap) {
    final gradients = {
      'Add': [const Color(0xFF1A1F3D), const Color(0xFF252B4A)],
      'Ledger': [const Color(0xFF1A1F3D), const Color(0xFF252B4A)],
    };
    final colors = gradients[label] ?? [AppColors.primary, AppColors.secondary];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          boxShadow: [
            BoxShadow(
              color: colors[0].withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhoOwesWhom(List whoOwesWhom, String currency, ExpenseService expense, BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WHO OWES WHOM',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
          ),
        ),
        const SizedBox(height: 10),
        if (whoOwesWhom.isEmpty)
          GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 32,
                  color: AppColors.positive.withOpacity(0.8),
                ),
                const SizedBox(height: 10),
                Text(
                  "You're all settled!",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'No outstanding group debts.',
                  style: TextStyle(
                    color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: whoOwesWhom.map((debt) {
              final amt = double.tryParse((debt['amount'] ?? 0).toString()) ?? 0.0;
              final fromName = debt['from_user_name'] ?? 'Member';
              final toName = debt['to_user_name'] ?? 'Member';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.arrow_forward_rounded, size: 18, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                                ),
                                children: [
                                  TextSpan(text: fromName),
                                  const TextSpan(
                                    text: '  →  ',
                                    style: TextStyle(color: AppColors.primary),
                                  ),
                                  TextSpan(text: toName),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$currency${amt.toInt()}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          expense.recordSettlement(
                            fromUser: debt['from_user_id'],
                            toUser: debt['to_user_id'],
                            amount: amt,
                            paymentMethod: 'upi',
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Settlement recorded!'), backgroundColor: AppColors.positive),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Settle',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildMemberSpending(List memberBalances, String currency, double totalExpenses, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'MEMBER SPENDING',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
              ),
            ),
            Text(
              '${memberBalances.length} Members',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GlassCard(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: memberBalances.map<Widget>((member) {
              final paid = double.tryParse((member['total_paid'] ?? member['paid'] ?? 0).toString()) ?? 0.0;
              final name = member['name'] ?? member['user_name'] ?? 'Member';
              final avatarColorRaw = member['avatar_color'] ?? member['color'] ?? member['user_color'];

              Color avatarColor = AppColors.primary;
              if (avatarColorRaw != null && avatarColorRaw is String && avatarColorRaw.startsWith('#')) {
                try {
                  avatarColor = Color(int.parse('FF${avatarColorRaw.substring(1)}', radix: 16));
                } catch (_) {}
              }

              final pct = totalExpenses > 0 ? (paid / totalExpenses) : 0.0;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: avatarColor.withOpacity(0.15),
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: avatarColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                            ),
                          ),
                        ),
                        Text(
                          '$currency${paid.toInt()}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: avatarColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${(pct * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: avatarColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
                        valueColor: AlwaysStoppedAnimation<Color>(avatarColor),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSpendingOverview(String currency, double total, List categorySpending, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SPENDING OVERVIEW',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
          ),
        ),
        const SizedBox(height: 10),
        GlassCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$currency${total.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Total expenses',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                ),
              ),
              const SizedBox(height: 16),
              ...categorySpending.take(5).map<Widget>((cat) {
                final catAmount = double.tryParse((cat['amount'] ?? 0).toString()) ?? 0.0;
                final catName = cat['category_name'] ?? cat['name'] ?? 'Other';
                final catIcon = cat['category_icon'] ?? 'receipt';
                final catColor = cat['category_color'];
                final percent = total > 0 ? (catAmount / total).clamp(0.0, 1.0) : 0.0;

                Color barColor = AppColors.primary;
                if (catColor != null && catColor is String && catColor.startsWith('#')) {
                  try {
                    barColor = Color(int.parse('FF${catColor.substring(1)}', radix: 16));
                  } catch (_) {}
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_getIconFromName(catIcon), size: 14, color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    catName,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$currency${catAmount.toInt()}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percent,
                          minHeight: 5,
                          backgroundColor: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
                          valueColor: AlwaysStoppedAnimation(barColor),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions(List recentTransactions, String currency, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'RECENT TRANSACTIONS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
              ),
            ),
            Text(
              'View all →',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary.withOpacity(0.8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GlassCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: recentTransactions.take(5).map<Widget>((tx) {
              final txAmount = double.tryParse((tx['amount'] ?? 0).toString()) ?? 0.0;
              final txDesc = tx['description'] ?? tx['name'] ?? 'Transaction';
              final txPayer = tx['payer_name'] ?? tx['paid_by_name'] ?? '';
              final txCategory = tx['category_icon'] ?? tx['icon'] ?? 'receipt';

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(_getIconFromName(txCategory), size: 18, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            txDesc,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (txPayer.isNotEmpty)
                            Text(
                              txPayer,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$currency${txAmount.toInt()}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _ChipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFB8944A).withOpacity(0.40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Horizontal lines
    canvas.drawLine(
      Offset(4, size.height * 0.35),
      Offset(size.width - 4, size.height * 0.35),
      paint,
    );
    canvas.drawLine(
      Offset(4, size.height * 0.55),
      Offset(size.width - 4, size.height * 0.55),
      paint,
    );
    canvas.drawLine(
      Offset(4, size.height * 0.75),
      Offset(size.width - 4, size.height * 0.75),
      paint,
    );

    // Vertical lines
    canvas.drawLine(
      Offset(size.width * 0.35, 3),
      Offset(size.width * 0.35, size.height - 3),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.55, 3),
      Offset(size.width * 0.55, size.height - 3),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.72, 3),
      Offset(size.width * 0.72, size.height - 3),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
