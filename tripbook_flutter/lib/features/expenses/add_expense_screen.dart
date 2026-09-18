import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/auth_service.dart';
import '../../services/expense_service.dart';
import '../../theme/app_theme.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({Key? key}) : super(key: key);

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isPersonal = false;
  String _paymentMethod = 'cash';
  int? _paidById;
  int? _categoryId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthService>(context, listen: false);
    final expense = Provider.of<ExpenseService>(context, listen: false);
    _paidById = auth.currentUser?.id;

    expense.loadCategories().then((_) {
      if (mounted && expense.categories.isNotEmpty) {
        setState(() {
          _categoryId = int.parse(expense.categories[0]['id'].toString());
        });
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveExpense() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final expense = Provider.of<ExpenseService>(context, listen: false);

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final desc = _descController.text.trim();

    if (amount <= 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount')));
      return;
    }
    if (desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a description')));
      return;
    }
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    setState(() => _isLoading = true);

    final clientRequestId = 'req-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(10000)}';

    try {
      await expense.saveExpense(
        amount: amount,
        description: desc,
        categoryId: _categoryId!,
        paidBy: _paidById ?? auth.currentUser!.id,
        paymentMethod: _paymentMethod,
        isPersonal: _isPersonal,
        clientRequestId: clientRequestId,
        splits: [],
        notes: _notesController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense saved successfully!'), backgroundColor: AppColors.positive),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.negative),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final expense = Provider.of<ExpenseService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = auth.activeTrip?.currencySymbol ?? '₹';

    final List rawMembers = expense.dashboardData?['member_balances'] ?? [];

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        title: const Text('Add Expense', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Expense Type Toggle ──
                  Text('Expense Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isPersonal = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: !_isPersonal ? const LinearGradient(colors: AppColors.brandGradient) : null,
                              ),
                              child: Text(
                                'Personal',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: !_isPersonal ? Colors.white : (isDark ? AppColors.textDarkMuted : AppColors.textLightMuted),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isPersonal = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: _isPersonal ? const LinearGradient(colors: AppColors.brandGradient) : null,
                              ),
                              child: Text(
                                'Shared with Trip',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: _isPersonal ? Colors.white : (isDark ? AppColors.textDarkMuted : AppColors.textLightMuted),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Amount ──
                  Text('Expense Amount', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: isDark ? AppColors.textDarkMain : AppColors.textLightMain),
                    decoration: InputDecoration(
                      prefixText: '$currency ',
                      prefixStyle: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.primary),
                      hintText: '0.00',
                      hintStyle: TextStyle(color: Colors.grey.withOpacity(0.4), fontSize: 36, fontWeight: FontWeight.w900),
                      filled: true,
                      fillColor: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.10) : Colors.black.withOpacity(0.08)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.10) : Colors.black.withOpacity(0.08)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Description ──
                  Text('Description', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Dinner, Auto, Tickets',
                      hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
                      filled: true,
                      fillColor: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.10) : Colors.black.withOpacity(0.08)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.10) : Colors.black.withOpacity(0.08)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Payment Method ──
                  Text('Payment Method', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildPaymentPill('cash', 'Cash', LucideIcons.banknote, isDark),
                      const SizedBox(width: 10),
                      _buildPaymentPill('bank', 'Bank', LucideIcons.landmark, isDark),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Paid By & Category ──
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Paid By', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
                                border: Border.all(color: isDark ? Colors.white.withOpacity(0.10) : Colors.black.withOpacity(0.08)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: _paidById,
                                  isExpanded: true,
                                  dropdownColor: isDark ? AppColors.elevatedDark : Colors.white,
                                  style: TextStyle(fontSize: 14, color: isDark ? AppColors.textDarkMain : AppColors.textLightMain),
                                  items: rawMembers.map<DropdownMenuItem<int>>((m) {
                                    return DropdownMenuItem<int>(
                                      value: int.parse(m['user_id'].toString()),
                                      child: Text(m['name'], overflow: TextOverflow.ellipsis),
                                    );
                                  }).toList(),
                                  onChanged: (val) => setState(() => _paidById = val),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Category', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
                                border: Border.all(color: isDark ? Colors.white.withOpacity(0.10) : Colors.black.withOpacity(0.08)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: _categoryId,
                                  isExpanded: true,
                                  dropdownColor: isDark ? AppColors.elevatedDark : Colors.white,
                                  style: TextStyle(fontSize: 14, color: isDark ? AppColors.textDarkMain : AppColors.textLightMain),
                                  items: expense.categories.map<DropdownMenuItem<int>>((c) {
                                    return DropdownMenuItem<int>(
                                      value: int.parse(c['id'].toString()),
                                      child: Text(c['name'], overflow: TextOverflow.ellipsis),
                                    );
                                  }).toList(),
                                  onChanged: (val) => setState(() => _categoryId = val),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Notes ──
                  Text('Notes (Optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Additional notes...',
                      hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
                      filled: true,
                      fillColor: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.10) : Colors.black.withOpacity(0.08)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.10) : Colors.black.withOpacity(0.08)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Save Button ──
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(colors: AppColors.brandGradient),
                      ),
                      child: ElevatedButton(
                        onPressed: _handleSaveExpense,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text(
                          'Save Expense',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPaymentPill(String value, String label, IconData icon, bool isDark) {
    final isSel = _paymentMethod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _paymentMethod = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: isSel
                ? AppColors.primary.withOpacity(0.12)
                : isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
            border: Border.all(
              color: isSel ? AppColors.primary.withOpacity(0.5) : (isDark ? Colors.white.withOpacity(0.10) : Colors.black.withOpacity(0.08)),
              width: isSel ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSel ? AppColors.primary : (isDark ? AppColors.textDarkMuted : AppColors.textLightMuted)),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: isSel ? AppColors.primary : (isDark ? AppColors.textDarkMuted : AppColors.textLightMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
