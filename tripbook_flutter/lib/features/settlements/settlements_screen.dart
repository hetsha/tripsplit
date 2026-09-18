import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/auth_service.dart';
import '../../services/expense_service.dart';
import '../../theme/app_theme.dart';
import '../../models/transaction.dart';

class SettlementsScreen extends StatefulWidget {
  const SettlementsScreen({Key? key}) : super(key: key);

  @override
  State<SettlementsScreen> createState() => _SettlementsScreenState();
}

class _SettlementsScreenState extends State<SettlementsScreen> {
  List<Transaction> _settlementHistory = [];
  bool _isHistoryLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadHistory();
    });
  }

  Future<void> _loadHistory() async {
    setState(() => _isHistoryLoading = true);
    final expense = Provider.of<ExpenseService>(context, listen: false);
    try {
      // Query transactions endpoint for type settlement
      await expense.loadTransactions(type: 'settlement');
      setState(() {
        _settlementHistory = expense.transactionsList;
      });
    } catch (_) {} finally {
      setState(() => _isHistoryLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final expense = Provider.of<ExpenseService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final currency = auth.activeTrip?.currencySymbol ?? '₹';

    // Suggested settlements
    final dash = expense.dashboardData;
    final List whoOwesWhom = dash?['who_owes_whom'] as List? ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settlements', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await expense.loadDashboard();
          await _loadHistory();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Suggested Settlements Card list
              const Text('SUGGESTED PAYMENTS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.8)),
              const SizedBox(height: 8),
              if (whoOwesWhom.isEmpty)
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🎉 ', style: TextStyle(fontSize: 18)),
                        Text(
                          'All debts are completely settled!',
                          style: TextStyle(color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: whoOwesWhom.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final debt = whoOwesWhom[index];
                    final amt = double.tryParse((debt['amount'] ?? 0).toString()) ?? 0.0;

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const CircleAvatar(
                                      radius: 16,
                                      backgroundColor: AppColors.primary,
                                      child: Icon(Icons.person, color: Colors.white, size: 16),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(debt['from_name'] ?? 'Member', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const Icon(Icons.double_arrow_rounded, color: Colors.grey, size: 18),
                                Row(
                                  children: [
                                    Text(debt['to_name'] ?? 'Member', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 8),
                                    const CircleAvatar(
                                      radius: 16,
                                      backgroundColor: AppColors.secondary,
                                      child: Icon(Icons.person, color: Colors.white, size: 16),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$currency${amt.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () async {
                                    // Settle post call
                                    await expense.recordSettlement(
                                      fromUser: debt['from_user_id'],
                                      toUser: debt['to_user_id'],
                                      amount: amt,
                                      paymentMethod: 'upi',
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Payment registered successfully!'), backgroundColor: AppColors.positive),
                                    );
                                    await expense.loadDashboard();
                                    await _loadHistory();
                                  },
                                  child: const Text('Mark as Paid'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              // 2. Settlement History log
              const SizedBox(height: 28),
              const Text('SETTLEMENT HISTORY', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.8)),
              const SizedBox(height: 8),
              if (_isHistoryLoading)
                const Center(child: Padding(padding: EdgeInsets.all(24.0), child: CircularProgressIndicator()))
              else if (_settlementHistory.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text('No settlement logs recorded yet.', style: TextStyle(color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted)),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _settlementHistory.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final hist = _settlementHistory[index];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.transparent,
                          child: Icon(Icons.handshake_rounded, color: AppColors.positive),
                        ),
                        title: Text(hist.description),
                        subtitle: Text(hist.formattedDate, style: const TextStyle(fontSize: 11)),
                        trailing: Text(
                          '$currency${hist.amount.toInt()}',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.positive),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
