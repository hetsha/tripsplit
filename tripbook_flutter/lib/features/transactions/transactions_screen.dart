import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/auth_service.dart';
import '../../services/expense_service.dart';
import '../../models/transaction.dart';
import '../../theme/app_theme.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({Key? key}) : super(key: key);

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _searchController = TextEditingController();
  String _selectedType = 'all';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearch);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ExpenseService>(context, listen: false).loadTransactions();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearch);
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch() {
    final search = _searchController.text.trim();
    Provider.of<ExpenseService>(context, listen: false).loadTransactions(
      type: _selectedType,
      search: search,
    );
  }

  void _handleFilterChange(String type) {
    setState(() => _selectedType = type);
    Provider.of<ExpenseService>(context, listen: false).loadTransactions(
      type: type,
      search: _searchController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final expense = Provider.of<ExpenseService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = auth.activeTrip?.currencySymbol ?? '₹';
    final currentUserId = auth.currentUser?.id;

    final allTx = expense.transactionsList;

    final sharedExpenses = allTx.where((tx) {
      if (tx.type != 'expense') return true;
      return tx.splits.isNotEmpty;
    }).toList();

    final displayList = _selectedType == 'all'
        ? sharedExpenses
        : sharedExpenses.where((tx) => tx.type == _selectedType).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        title: const Text('Transactions', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search expenses or settlements...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Expenses', 'expense'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Settlements', 'settlement'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: expense.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : displayList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.receipt, size: 48, color: Colors.grey.withOpacity(0.3)),
                              const SizedBox(height: 12),
                              const Text('No transactions found', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => expense.loadTransactions(type: _selectedType, search: _searchController.text.trim()),
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 100),
                            itemCount: displayList.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final tx = displayList[index];
                              final isExpense = tx.type == 'expense';
                              final isSettlement = tx.type == 'settlement';
                              final isReceived = isSettlement && tx.receiverId == currentUserId;

                              final Color typeColor = isExpense
                                  ? AppColors.negative
                                  : isReceived
                                      ? AppColors.positive
                                      : AppColors.primary;

                              final String amountPrefix = isExpense ? '-' : isReceived ? '+' : '✓';

                              return Card(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => _showTransactionDetail(context, tx, currency, isDark),
                                  onLongPress: () {
                                    _showDeletePrompt(context, expense, tx.id);
                                  },
                                  child: ListTile(
                                    leading: Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: typeColor.withOpacity(0.1),
                                      ),
                                      child: Icon(
                                        isExpense
                                            ? Icons.restaurant_rounded
                                            : Icons.handshake_rounded,
                                        color: typeColor,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(tx.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text(
                                      isExpense
                                          ? 'Paid by ${tx.payerName ?? 'Member'} • ${tx.splits.length} members split'
                                          : 'Settlement complete',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '$amountPrefix$currency${tx.amount.toInt()}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 15,
                                            color: typeColor,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          tx.formattedDate,
                                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedType == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _handleFilterChange(value),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : null,
      ),
    );
  }

  void _showTransactionDetail(BuildContext context, Transaction tx, String currency, bool isDark) {
    final isExpense = tx.type == 'expense';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: (isExpense ? AppColors.negative : AppColors.primary).withOpacity(0.12),
                ),
                child: Icon(
                  isExpense ? Icons.receipt_long_rounded : Icons.handshake_rounded,
                  color: isExpense ? AppColors.negative : AppColors.primary,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: Text(
                tx.description,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                tx.formattedDate,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Amount
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
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
                    '$currency${tx.amount.toInt()}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: isExpense ? AppColors.negative : AppColors.positive,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Details
            _buildDetailRow('Transaction Type', tx.type.toUpperCase(), isDark),
            _buildDetailRow('Paid by', tx.payerName ?? 'Member', isDark),
            _buildDetailRow('Payment', tx.paymentMethodLabel, isDark),
            if (tx.categoryName != null) _buildDetailRow('Category', tx.categoryName!, isDark),
            if (tx.notes != null && tx.notes!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NOTES',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tx.notes!,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Splits
            if (isExpense && tx.splits.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'SPLIT BREAKDOWN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                ),
              ),
              const SizedBox(height: 8),
              ...tx.splits.map((split) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.primary.withOpacity(0.15),
                      child: Text(
                        split.name.isNotEmpty ? split.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        split.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                        ),
                      ),
                    ),
                    Text(
                      '$currency${split.amount.toInt()}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                      ),
                    ),
                  ],
                ),
              )),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.negative,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _showDeletePrompt(context, Provider.of<ExpenseService>(context, listen: false), tx.id);
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete_outline_rounded, size: 18, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Delete Transaction',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeletePrompt(BuildContext context, ExpenseService expense, int txId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Transaction?'),
          content: const Text('Are you sure you want to delete this transaction? All Splitwise shares will be reversed.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.negative),
              onPressed: () async {
                await expense.deleteTransaction(txId);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Transaction deleted'), backgroundColor: AppColors.positive),
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
