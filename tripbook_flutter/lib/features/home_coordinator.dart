import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/expense_service.dart';
import '../services/sync_service.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../theme/app_theme.dart';
import '../widgets/floating_bottom_nav.dart';
import 'dashboard/dashboard_screen.dart';
import 'transactions/transactions_screen.dart';
import 'people/people_screen.dart';
import 'settlements/settlements_screen.dart';
import 'settings/more_screen.dart';
import '../features/expenses/add_expense_screen.dart';
import '../features/cashbook/cashbook_screen.dart';
import '../features/passbook/passbook_screen.dart';

class HomeCoordinator extends StatefulWidget {
  const HomeCoordinator({Key? key}) : super(key: key);

  @override
  State<HomeCoordinator> createState() => _HomeCoordinatorState();
}

class _HomeCoordinatorState extends State<HomeCoordinator> with WidgetsBindingObserver {
  int _currentIndex = 0;
  int _previousIndex = 0;
  late final SyncService _syncService;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const TransactionsScreen(),
    const PeopleScreen(),
    const SettlementsScreen(),
    const MoreScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final auth = Provider.of<AuthService>(context, listen: false);
    final expense = Provider.of<ExpenseService>(context, listen: false);

    _syncService = SyncService();
    _syncService.registerCallback(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        expense.loadDashboard();
        if (_currentIndex == 1) {
          expense.loadTransactions();
        }
      });
    });

    _syncService.startPolling(auth.activeTripId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) expense.loadDashboard();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _syncService.stopPolling();
    _syncService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _syncService.stopPolling();
    } else if (state == AppLifecycleState.resumed) {
      final auth = Provider.of<AuthService>(context, listen: false);
      _syncService.startPolling(auth.activeTripId);
    }
  }

  void _showFABMenu(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                _buildFABOption(context, Icons.receipt_long_rounded, 'Expense', const [Color(0xFF6366F1), Color(0xFF8B5CF6)], () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AddExpenseScreen()));
                }),
                _buildFABOption(context, Icons.account_balance_wallet_rounded, 'Add Money', const [Color(0xFF10B981), Color(0xFF06B6D4)], () {
                  Navigator.pop(ctx);
                  _showAddMoneyDialog(context);
                }),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showAddMoneyDialog(BuildContext context) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    String method = 'cash';
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                    Navigator.pop(context);
                    await _recordIncome(context, amt, method, noteController.text.trim());
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

  Future<void> _recordIncome(BuildContext context, double amount, String method, String notes) async {
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

  Widget _buildFABOption(BuildContext context, IconData icon, String label, List<Color> gradient, VoidCallback onTap) {
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

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SyncService>.value(
      value: _syncService,
      child: Scaffold(
        body: Stack(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (Widget child, Animation<double> animation) {
                final isNewPage = _screens.indexOf(child) >= _currentIndex;
                final isForward = _currentIndex > _previousIndex;
                final offset = isForward ? 0.08 : -0.08;

                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(offset, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _screens[_currentIndex],
            ),

            // FAB
            Positioned(
              right: 20,
              bottom: MediaQuery.of(context).padding.bottom + 80,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _showFABMenu(context);
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1A1F3D), Color(0xFF252B4A)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.25),
                      width: 0.8,
                    ),
                  ),
                  child: const Icon(Icons.add_rounded, color: AppColors.primary, size: 28),
                ),
              ),
            ),

            // Bottom nav
            Positioned(
              bottom: 16 + MediaQuery.of(context).padding.bottom,
              left: 16,
              right: 16,
              child: FloatingBottomNav(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _previousIndex = _currentIndex;
                    _currentIndex = index;
                  });
                  if (index == 0) {
                    Provider.of<ExpenseService>(context, listen: false).loadDashboard();
                  } else if (index == 1) {
                    Provider.of<ExpenseService>(context, listen: false).loadTransactions();
                  }
                },
              ),
            ),

            // Offline banner
            Consumer<SyncService>(
              builder: (context, sync, _) {
                if (!sync.isOffline) return const SizedBox.shrink();
                return Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade900.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text(
                          "You're offline. Visualizing cached ledger.",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
