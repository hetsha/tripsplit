import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/expense_service.dart';
import '../../theme/app_theme.dart';

class PeopleScreen extends StatelessWidget {
  const PeopleScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final expense = Provider.of<ExpenseService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final currency = auth.activeTrip?.currencySymbol ?? '₹';

    // Parse members list
    final dash = expense.dashboardData;
    final List memberBalances = dash?['member_balances'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('People', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Tripwise Member Shares & Balance Summary',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Members balances cards
            Expanded(
              child: memberBalances.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      itemCount: memberBalances.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final member = memberBalances[index];
                        final netBalance = double.tryParse((member['net_balance'] ?? 0).toString()) ?? 0.0;
                        final isOwed = netBalance >= 0;

                        final Color statusColor = isOwed ? AppColors.positive : AppColors.negative;
                        final String statusText = isOwed
                            ? 'Gets back'
                            : 'Owes';

                        return GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Avatar color box
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary.withOpacity(0.12),
                                ),
                                child: Center(
                                  child: Text(
                                    member['name']?.substring(0, 1).toUpperCase() ?? 'M',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      member['name'] ?? 'Member',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$statusText $currency${netBalance.abs().toStringAsFixed(0)}',
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Right ledger status indicator
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: statusColor.withOpacity(0.08),
                                ),
                                child: Text(
                                  isOwed ? '+$currency${netBalance.toInt()}' : '-$currency${netBalance.abs().toInt()}',
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
