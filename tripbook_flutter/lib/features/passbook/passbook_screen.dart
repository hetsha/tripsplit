import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/expense_service.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../theme/app_theme.dart';

class PassbookScreen extends StatefulWidget {
  const PassbookScreen({Key? key}) : super(key: key);

  @override
  State<PassbookScreen> createState() => _PassbookScreenState();
}

class _PassbookScreenState extends State<PassbookScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final expense = Provider.of<ExpenseService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = auth.activeTrip?.currencySymbol ?? '₹';
    final tripName = auth.activeTrip?.name ?? 'Trip';

    final dash = expense.dashboardData;
    final myCb = dash?['my_cashbook'];
    final entries = (myCb?['entries'] as List?) ?? [];
    final totalIn = double.tryParse((myCb?['total_in'] ?? 0).toString()) ?? 0.0;
    final totalOut = double.tryParse((myCb?['total_out'] ?? 0).toString()) ?? 0.0;
    final netBalance = totalIn - totalOut;

    // Running balance (oldest first)
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
        title: const Text('Passbook', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Passbook Header Card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
                border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06)),
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
                    tripName.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'PERSONAL PASSBOOK',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    auth.currentUser?.name ?? 'Member',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(color: isDark ? Colors.white.withOpacity(0.10) : Colors.black.withOpacity(0.08)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildPassbookStat('CREDIT', '+$currency${totalIn.toInt()}', AppColors.positive, isDark),
                      Container(width: 1, height: 30, color: isDark ? Colors.white.withOpacity(0.10) : Colors.black.withOpacity(0.08)),
                      _buildPassbookStat('DEBIT', '-$currency${totalOut.toInt()}', AppColors.negative, isDark),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(color: isDark ? Colors.white.withOpacity(0.10) : Colors.black.withOpacity(0.08)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'BALANCE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                        ),
                      ),
                      Text(
                        '${netBalance >= 0 ? '+' : ''}$currency${netBalance.toInt()}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: netBalance >= 0 ? AppColors.positive : AppColors.negative,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Add Cash Button ──
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
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
            ),
            const SizedBox(height: 16),

            // ── Table Header ──
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 50,
                    child: Text('DATE', style: _headerStyle(isDark)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: Text('DESCRIPTION', style: _headerStyle(isDark)),
                  ),
                  SizedBox(
                    width: 62,
                    child: Text('CREDIT', style: _headerStyle(isDark), textAlign: TextAlign.right),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 62,
                    child: Text('DEBIT', style: _headerStyle(isDark), textAlign: TextAlign.right),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 70,
                    child: Text('BALANCE', style: _headerStyle(isDark), textAlign: TextAlign.right),
                  ),
                ],
              ),
            ),
            Divider(color: isDark ? Colors.white.withOpacity(0.10) : Colors.black.withOpacity(0.08)),

            // ── Transaction Rows ──
            if (entries.isEmpty)
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
              ...entries.map((entry) {
                final isIncome = entry['type'] == 'in';
                final amount = double.tryParse((entry['amount'] ?? 0).toString()) ?? 0.0;
                final description = entry['description'] ?? '';
                final date = _formatDate(entry['formatted_date'] ?? entry['date'] ?? '');
                final key = '${entry['date']}_${entry['flow_type']}_${entry['description']}_${entry['amount']}';
                final runningBal = runningBalances[key] ?? 0;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 50,
                        child: Text(
                          date,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: Text(
                          description.isNotEmpty ? description : (isIncome ? 'Income' : 'Expense'),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(
                        width: 62,
                        child: isIncome
                            ? Text(
                                '$currency${amount.toInt()}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.positive,
                                ),
                                textAlign: TextAlign.right,
                              )
                            : const Text('-', style: TextStyle(color: Colors.transparent)),
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 62,
                        child: !isIncome
                            ? Text(
                                '$currency${amount.toInt()}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.negative,
                                ),
                                textAlign: TextAlign.right,
                              )
                            : const Text('-', style: TextStyle(color: Colors.transparent)),
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 70,
                        child: Text(
                          '$currency${runningBal.toInt()}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: runningBal >= 0 ? AppColors.positive : AppColors.negative,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildPassbookStat(String label, String value, Color valueColor, bool isDark) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  TextStyle _headerStyle(bool isDark) {
    return TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.8,
      color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
    );
  }

  String _formatDate(String date) {
    if (date.isEmpty) return '';
    try {
      final dt = DateTime.parse(date);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dt.month - 1]} ${dt.day}';
    } catch (_) {
      return date;
    }
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
