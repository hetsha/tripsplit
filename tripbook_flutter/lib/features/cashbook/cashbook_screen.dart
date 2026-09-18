import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/auth_service.dart';
import '../../services/expense_service.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../theme/app_theme.dart';
import '../expenses/add_expense_screen.dart';

class CashBookScreen extends StatefulWidget {
  const CashBookScreen({Key? key}) : super(key: key);

  @override
  State<CashBookScreen> createState() => _CashBookScreenState();
}

class _CashBookScreenState extends State<CashBookScreen> {
  String _filter = 'all';

  static final Map<String, IconData> _iconMap = {
    'utensils': LucideIcons.utensils,
    'receipt': LucideIcons.receipt,
    'wallet': LucideIcons.wallet,
    'car': LucideIcons.car,
    'train': LucideIcons.train,
    'plane': LucideIcons.plane,
    'coffee': LucideIcons.coffee,
    'shopping-cart': LucideIcons.shoppingCart,
    'home': LucideIcons.home,
    'hotel': LucideIcons.hotel,
    'fuel': LucideIcons.fuel,
    'zap': LucideIcons.zap,
    'music': LucideIcons.music,
    'gift': LucideIcons.gift,
    'heart': LucideIcons.heart,
    'store': LucideIcons.store,
    'package': LucideIcons.package,
    'ticket': LucideIcons.ticket,
    'dumbbell': LucideIcons.dumbbell,
    'stethoscope': LucideIcons.stethoscope,
    'film': LucideIcons.film,
    'bus': LucideIcons.bus,
    'bicycle': LucideIcons.bike,
    'navigation': LucideIcons.navigation,
    'users': LucideIcons.users,
    'banknote': LucideIcons.banknote,
    'coins': LucideIcons.coins,
    'piggy-bank': LucideIcons.piggyBank,
    'credit-card': LucideIcons.creditCard,
    'smartphone': LucideIcons.smartphone,
    'arrow-down-left': LucideIcons.arrowDownLeft,
    'arrow-up-right': LucideIcons.arrowUpRight,
    'vault': LucideIcons.lock,
  };

  IconData _getIcon(String? name) {
    if (name == null) return Icons.receipt_rounded;
    return _iconMap[name] ?? Icons.receipt_rounded;
  }

  Color _parseColor(String? hex) {
    if (hex == null || !hex.startsWith('#')) return AppColors.primary;
    try {
      return Color(int.parse('FF${hex.substring(1)}', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final expense = Provider.of<ExpenseService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = auth.activeTrip?.currencySymbol ?? '₹';

    final dash = expense.dashboardData;
    final myCb = dash?['my_cashbook'];
    final entries = (myCb?['entries'] as List?) ?? [];
    final totalIn = double.tryParse((myCb?['total_in'] ?? 0).toString()) ?? 0.0;
    final totalOut = double.tryParse((myCb?['total_out'] ?? 0).toString()) ?? 0.0;
    final netBalance = totalIn - totalOut;

    // Compute sub-totals
    double personalExpenses = 0;
    double sharedExpenses = 0;
    double settlementsPaid = 0;
    double settlementsReceived = 0;

    for (final e in entries) {
      final amt = double.tryParse((e['amount'] ?? 0).toString()) ?? 0.0;
      final flowType = e['flow_type'] ?? '';
      final isPersonal = e['is_personal'] == true;

      if (flowType == 'expense') {
        if (isPersonal) {
          personalExpenses += amt;
        } else {
          sharedExpenses += amt;
        }
      } else if (flowType == 'settlement_sent') {
        settlementsPaid += amt;
      } else if (flowType == 'settlement_received') {
        settlementsReceived += amt;
      }
    }

    // Filter
    final filtered = _filter == 'all'
        ? entries
        : entries.where((e) {
            if (_filter == 'personal') return e['flow_type'] == 'expense' && e['is_personal'] == true;
            if (_filter == 'shared') return e['flow_type'] == 'expense' && e['is_personal'] != true;
            return true;
          }).toList();

    // Running balance (oldest first for balance calc, display newest first)
    final sortedAsc = List.from(entries)..sort((a, b) {
      final da = a['date'] ?? '';
      final db = b['date'] ?? '';
      return da.compareTo(db);
    });
    final runningBalances = <String, double>{};
    double bal = 0;
    for (final e in sortedAsc) {
      final amt = double.tryParse((e['amount'] ?? 0).toString()) ?? 0.0;
      final type = e['type'] ?? 'out';
      if (type == 'in') {
        bal += amt;
      } else {
        bal -= amt;
      }
      final key = '${e['date']}_${e['flow_type']}_${e['description']}_${e['amount']}';
      runningBalances[key] = bal;
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        title: const Text('My CashBook', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Net Balance Card ──
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [Colors.white.withOpacity(0.06), Colors.white.withOpacity(0.02)]
                          : [Colors.white, Colors.grey.shade50],
                    ),
                    border: Border.all(
                      color: isDark ? Colors.white.withOpacity(0.10) : Colors.black.withOpacity(0.06),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'NET BALANCE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$currency${netBalance.toInt()}',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: netBalance >= 0 ? AppColors.positive : AppColors.negative,
                          letterSpacing: -1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Summary Rows ──
            _buildSummaryRow('Total Income', '+$currency${totalIn.toInt()}', AppColors.positive, isDark),
            _buildSummaryRow('Personal Expenses', '-$currency${personalExpenses.toInt()}', AppColors.negative, isDark),
            _buildSummaryRow('Shared Expenses', '-$currency${sharedExpenses.toInt()}', AppColors.negative, isDark),
            _buildSummaryRow('Settlements Paid', '-$currency${settlementsPaid.toInt()}', AppColors.negative, isDark),
            _buildSummaryRow('Settlements Received', '+$currency${settlementsReceived.toInt()}', AppColors.positive, isDark),
            const SizedBox(height: 20),

            // ── Filter Tabs + Add Cash ──
            Row(
              children: [
                _buildFilterTab('All', 'all', isDark),
                const SizedBox(width: 8),
                _buildFilterTab('Personal', 'personal', isDark),
                const SizedBox(width: 8),
                _buildFilterTab('Shared', 'shared', isDark),
                const Spacer(),
                GestureDetector(
                  onTap: () => _showAddMoneySheet(context, isDark),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(colors: AppColors.brandGradient),
                    ),
                    child: const Text(
                      '+ Add Cash',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Entries ──
            if (filtered.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    'No transactions yet',
                    style: TextStyle(color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted),
                  ),
                ),
              )
            else
              ...filtered.map((entry) {
                final key = '${entry['date']}_${entry['flow_type']}_${entry['description']}_${entry['amount']}';
                final runningBal = runningBalances[key] ?? 0;
                return _buildEntryItem(entry, currency, isDark, runningBal);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color valueColor, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, String value, bool isDark) {
    final isActive = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isActive
              ? AppColors.primary
              : (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isActive
                ? Colors.white
                : (isDark ? AppColors.textDarkMuted : AppColors.textLightMuted),
          ),
        ),
      ),
    );
  }

  Widget _buildEntryItem(dynamic entry, String currency, bool isDark, double runningBal) {
    final type = entry['type'] ?? 'out';
    final amount = double.tryParse((entry['amount'] ?? 0).toString()) ?? 0.0;
    final description = entry['description'] ?? '';
    final date = entry['formatted_date'] ?? '';
    final methodName = entry['payment_method_label'] ?? entry['payment_method'] ?? '';
    final categoryName = entry['category_name'] ?? '';
    final categoryIcon = entry['category_icon'];
    final categoryColor = entry['category_color'];
    final isIncome = type == 'in';
    final amountColor = isIncome ? AppColors.positive : AppColors.negative;
    final prefix = isIncome ? '+' : '-';

    final icon = _getIcon(categoryIcon);
    final iconColor = _parseColor(categoryColor);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: iconColor.withOpacity(0.12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description.isNotEmpty ? description : (isIncome ? 'Income' : 'Expense'),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$categoryName ${methodName.isNotEmpty ? '· $methodName' : ''} $date',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$prefix$currency${amount.toInt()}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: amountColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Bal: $currency${runningBal.toInt()}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddMoneySheet(BuildContext context, bool isDark) {
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
}
