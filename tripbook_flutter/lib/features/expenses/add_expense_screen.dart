import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/tripsplit_widgets.dart';
import '../../services/auth_service.dart';
import '../../services/expense_service.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({Key? key}) : super(key: key);

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  int? _selectedCategoryId;
  String _selectedCategoryName = 'Food & Dining';
  DateTime _expenseDate = DateTime.now();
  int? _paidByUserId;
  String _paidByName = 'You';
  bool _splitEqually = true;
  String _selectedPaymentMethod = 'upi'; // 'upi', 'cash', 'card', 'bank'
  bool _isSaving = false;

  Map<String, dynamic>? _selectedTrip;
  List<Map<String, dynamic>> _activeTrips = [];
  bool _initialized = false;

  // Members for the current trip split
  List<Map<String, dynamic>> _tripMembers = [];

  final List<Map<String, String>> _paymentMethods = [
    {'id': 'upi', 'label': 'UPI / GPay', 'icon': '⚡'},
    {'id': 'cash', 'label': 'Cash', 'icon': '💵'},
    {'id': 'card', 'label': 'Card', 'icon': '💳'},
    {'id': 'bank', 'label': 'Bank Transfer', 'icon': '🏦'},
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final auth = Provider.of<AuthService>(context, listen: false);
      final expense = Provider.of<ExpenseService>(context, listen: false);

      // Load trips
      if (auth.detailedTrips.isNotEmpty) {
        _activeTrips = auth.detailedTrips;
      }

      int? targetTripId = args?['tripId'] ?? args?['trip']?['id'] ?? auth.activeTripId;

      if (_activeTrips.isNotEmpty) {
        _selectedTrip = _activeTrips.firstWhere(
          (t) => t['id'] == targetTripId,
          orElse: () => _activeTrips.first,
        );
      }

      // Load categories for active trip if not already loaded
      expense.loadCategories(tripId: targetTripId).then((_) {
        if (mounted && expense.categories.isNotEmpty) {
          setState(() {
            _selectedCategoryId = expense.categories.first['id'] as int?;
            _selectedCategoryName = expense.categories.first['name'] as String? ?? 'Food & Dining';
          });
        }
      });

      _setupMembers();
      _initialized = true;
    }
  }

  void _setupMembers() {
    final auth = Provider.of<AuthService>(context, listen: false);
    final expense = Provider.of<ExpenseService>(context, listen: false);
    final currentUser = auth.currentUser;

    List<Map<String, dynamic>> rawMembers = [];

    // Attempt 1: from _selectedTrip['members']
    if (_selectedTrip != null && _selectedTrip!['members'] is List && (_selectedTrip!['members'] as List).isNotEmpty) {
      rawMembers = List<Map<String, dynamic>>.from(_selectedTrip!['members']);
    }
    // Attempt 2: from expense.dashboardData['member_balances']
    else if (expense.dashboardData?['member_balances'] is List && (expense.dashboardData!['member_balances'] as List).isNotEmpty) {
      rawMembers = List<Map<String, dynamic>>.from(expense.dashboardData!['member_balances']);
    }

    if (rawMembers.isEmpty && currentUser != null) {
      rawMembers = [
        {
          'id': currentUser.id,
          'user_id': currentUser.id,
          'name': currentUser.name,
          'avatar_color': currentUser.avatarColor,
        }
      ];
    }

    _tripMembers = rawMembers.map((m) {
      final uid = m['id'] ?? m['user_id'] ?? 0;
      final isCurrent = currentUser != null && uid == currentUser.id;
      final mName = isCurrent ? 'You (${m['name']})' : (m['name'] ?? 'Member');

      return {
        'user_id': uid,
        'name': mName,
        'avatar_color': m['avatar_color'] ?? '#3b82f6',
        'included': true,
        'amount': 0.0,
      };
    }).toList();

    // Default payer
    if (currentUser != null) {
      _paidByUserId = currentUser.id;
      _paidByName = 'You (${currentUser.name})';
    } else if (_tripMembers.isNotEmpty) {
      _paidByUserId = _tripMembers.first['user_id'] as int?;
      _paidByName = _tripMembers.first['name'] as String? ?? 'Payer';
    }

    _recalculateEqualSplit();
  }

  double _getExpenseTotal() {
    final clean = _amountController.text.replaceAll(',', '').replaceAll(' ', '');
    return double.tryParse(clean) ?? 0.0;
  }

  void _recalculateEqualSplit() {
    final total = _getExpenseTotal();
    final includedMembers = _tripMembers.where((m) => m['included'] == true).toList();
    if (includedMembers.isNotEmpty && total > 0) {
      final perPerson = total / includedMembers.length;
      double accumulated = 0.0;

      for (int i = 0; i < includedMembers.length; i++) {
        if (i == includedMembers.length - 1) {
          includedMembers[i]['amount'] = double.parse((total - accumulated).toStringAsFixed(2));
        } else {
          final rounded = double.parse(perPerson.toStringAsFixed(2));
          includedMembers[i]['amount'] = rounded;
          accumulated += rounded;
        }
      }
    }

    for (final m in _tripMembers) {
      if (m['included'] != true) {
        m['amount'] = 0.0;
      }
    }
  }

  double _getCustomAllocatedTotal() {
    double sum = 0;
    for (final m in _tripMembers) {
      if (m['included'] == true) {
        sum += (m['amount'] as double? ?? 0.0);
      }
    }
    return sum;
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _handleSaveExpense(bool isPersonal) async {
    final title = _titleController.text.trim();
    final total = _getExpenseTotal();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an expense title')),
      );
      return;
    }

    if (total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount greater than 0')),
      );
      return;
    }

    if (!isPersonal) {
      final included = _tripMembers.where((m) => m['included'] == true).toList();
      if (included.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please include at least one member in the split')),
        );
        return;
      }

      if (_splitEqually) {
        _recalculateEqualSplit();
      } else {
        final allocated = _getCustomAllocatedTotal();
        if ((total - allocated).abs() > 0.05) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Split amounts must equal total bill (₹ $total). Currently: ₹ $allocated')),
          );
          return;
        }
      }
    }

    setState(() => _isSaving = true);

    try {
      final expense = Provider.of<ExpenseService>(context, listen: false);
      final auth = Provider.of<AuthService>(context, listen: false);
      final tripId = _selectedTrip?['id'] as int? ?? auth.activeTripId;

      final splits = isPersonal
          ? <Map<String, dynamic>>[]
          : _tripMembers
              .where((m) => m['included'] == true && (m['amount'] as double) > 0)
              .map((m) => {
                    'user_id': m['user_id'],
                    'amount': m['amount'],
                  })
              .toList();

      final categoryId = _selectedCategoryId ??
          (expense.categories.isNotEmpty ? expense.categories.first['id'] as int : 1);

      await expense.saveExpense(
        amount: total,
        description: title,
        categoryId: categoryId,
        paidBy: _paidByUserId ?? auth.currentUser?.id ?? 0,
        paymentMethod: _selectedPaymentMethod,
        isPersonal: isPersonal,
        clientRequestId: DateTime.now().millisecondsSinceEpoch.toString(),
        splits: splits,
        tripId: tripId,
        notes: _noteController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isPersonal
                ? 'Personal expense recorded to Cashbook!'
                : 'Expense added to ${_selectedTrip?['title'] ?? 'trip'} successfully!'),
            backgroundColor: AppColors.positive,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save expense: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final isPersonal = args?['isPersonal'] == true;
    final expense = Provider.of<ExpenseService>(context);

    final categoriesList = expense.categories.isNotEmpty
        ? expense.categories
        : [
            {'id': 1, 'name': 'Food & Dining'},
            {'id': 2, 'name': 'Transportation'},
            {'id': 3, 'name': 'Accommodation'},
            {'id': 4, 'name': 'Activities'},
            {'id': 5, 'name': 'Shopping'},
            {'id': 10, 'name': 'Other'},
          ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header
            TripSplitHeader(
              title: isPersonal ? 'Add Personal Expense' : 'Add Expense',
              subtitle: isPersonal
                  ? 'Personal Cashbook 👤'
                  : '${_selectedTrip?['title'] ?? 'Trip'} • Active 🟢',
              onBack: () => Navigator.of(context).maybePop(),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cover Banner at top
                    TripSplitCoverBanner(
                      height: 110,
                      customImageUrl: isPersonal
                          ? 'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?w=800&auto=format&fit=crop&q=80'
                          : (_selectedTrip?['image'] as String? ??
                              'https://images.unsplash.com/photo-1512343879784-a960bf40e7f2?w=800&auto=format&fit=crop&q=80'),
                    ),

                    if (!isPersonal && _selectedTrip != null) ...[
                      const SizedBox(height: 12),
                      _buildActiveTripSelectorCard(isDark),
                    ],

                    const SizedBox(height: 16),

                    Text(
                      'Expense Details',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Expense Title
                    TripSplitTextField(
                      label: 'Expense Title',
                      hint: 'e.g. Dinner at Beach Shack',
                      controller: _titleController,
                    ),

                    const SizedBox(height: 14),

                    // Amount Field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Amount (₹)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.elevatedDark : AppColors.inputBgLight,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? AppColors.borderDark : AppColors.borderLight,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Text(
                                '₹',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _amountController,
                                  keyboardType: TextInputType.number,
                                  onChanged: (val) {
                                    setState(() {
                                      if (_splitEqually) {
                                        _recalculateEqualSplit();
                                      }
                                    });
                                  },
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: '0',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Category and Date Row
                    Row(
                      children: [
                        // Category Dropdown
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Category',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.elevatedDark : AppColors.inputBgLight,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: _selectedCategoryId ?? (categoriesList.isNotEmpty ? categoriesList.first['id'] as int : null),
                                    isExpanded: true,
                                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                                    items: categoriesList.map((c) {
                                      final id = c['id'] as int;
                                      final name = c['name'] as String? ?? 'Category';
                                      return DropdownMenuItem<int>(
                                        value: id,
                                        child: Text(
                                          name,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        final matched = categoriesList.firstWhere((c) => c['id'] == val, orElse: () => categoriesList.first);
                                        setState(() {
                                          _selectedCategoryId = val;
                                          _selectedCategoryName = matched['name'] as String? ?? 'Category';
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Date Picker
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Date',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                                ),
                              ),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _expenseDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                  );
                                  if (picked != null) {
                                    setState(() => _expenseDate = picked);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.elevatedDark : AppColors.inputBgLight,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _formatDate(_expenseDate),
                                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Payment Method Quick Selector
                    Text(
                      'Payment Method',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _paymentMethods.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (ctx, idx) {
                          final pm = _paymentMethods[idx];
                          final isSelected = _selectedPaymentMethod == pm['id'];

                          return GestureDetector(
                            onTap: () => setState(() => _selectedPaymentMethod = pm['id']!),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDark ? const Color(0xFF131A29) : Colors.white),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : (isDark ? const Color(0xFF222F43) : const Color(0xFFE2E8F0)),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(pm['icon']!, style: const TextStyle(fontSize: 13)),
                                  const SizedBox(width: 5),
                                  Text(
                                    pm['label']!,
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
                    ),

                    const SizedBox(height: 14),

                    if (isPersonal) ...[
                      // Personal Cashbook Banner
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFF10B981).withOpacity(0.35),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.person_outline_rounded, size: 20, color: Colors.white),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '100% Personal Expense',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF059669),
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Recorded in your private cashbook only. Not shared or split with any travel group.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF047857),
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Paid By & Split Type
                      Row(
                        children: [
                          // Paid By Chip
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Paid by',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: () => _showPaidByPicker(context, isDark),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.elevatedDark : AppColors.inputBgLight,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 12,
                                          backgroundColor: AppColors.primary,
                                          child: Text(
                                            _paidByName.isNotEmpty ? _paidByName[0].toUpperCase() : 'P',
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            _paidByName,
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          size: 16,
                                          color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Split Type Toggle
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Split Type',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _splitEqually = true;
                                            _recalculateEqualSplit();
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          decoration: BoxDecoration(
                                            color: _splitEqually ? AppColors.primary : Colors.transparent,
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(
                                              color: _splitEqually ? AppColors.primary : (isDark ? AppColors.borderDark : Colors.grey.shade300),
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              'Split Equally',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: _splitEqually ? Colors.white : (isDark ? AppColors.textDarkMuted : AppColors.textLightMuted),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _splitEqually = false;
                                          });
                                          _showCustomSplitModal(context, isDark);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          decoration: BoxDecoration(
                                            color: !_splitEqually ? AppColors.primary : Colors.transparent,
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(
                                              color: !_splitEqually ? AppColors.primary : (isDark ? AppColors.borderDark : Colors.grey.shade300),
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              'Custom',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: !_splitEqually ? Colors.white : (isDark ? AppColors.textDarkMuted : AppColors.textLightMuted),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Split Summary Breakdown Card
                      Builder(
                        builder: (ctx) {
                          final includedCount = _tripMembers.where((m) => m['included'] == true).length;
                          final totalExpense = _getExpenseTotal();
                          final perPerson = includedCount > 0 ? (totalExpense / includedCount).round() : 0;
                          final customTotal = _getCustomAllocatedTotal();

                          if (_splitEqually) {
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.brandLavender.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.people_outline_rounded, size: 16, color: Colors.white),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Split equally among $includedCount members.\nEach person will owe ₹ $perPerson',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryDark,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => _showEqualSplitMembersModal(context, isDark),
                                    child: const Text(
                                      'Edit Split',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            // Custom Split Card
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E2235) : const Color(0xFFF5F3FF),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.primary.withOpacity(0.35)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.tune_rounded, size: 16, color: Colors.white),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Custom Split Active',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                            Text(
                                              'Allocated: ₹ ${customTotal.toStringAsFixed(0)} / ₹ ${totalExpense.toStringAsFixed(0)}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: (totalExpense - customTotal).abs() < 1
                                                    ? const Color(0xFF10B981)
                                                    : (isDark ? AppColors.textDarkMuted : AppColors.textLightMuted),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => _showCustomSplitModal(context, isDark),
                                        child: const Text(
                                          'Edit Split',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: _tripMembers.map((m) {
                                      final amt = (m['amount'] as double? ?? 0.0).toStringAsFixed(0);
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF262D42) : Colors.white,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: isDark ? const Color(0xFF333D58) : const Color(0xFFE2E8F0),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CircleAvatar(
                                              radius: 8,
                                              backgroundColor: AppColors.primary,
                                              child: Text(
                                                m['name'].toString().isNotEmpty ? m['name'].toString()[0].toUpperCase() : 'M',
                                                style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              '${m['name'].toString().split(' ').first}: ₹$amt',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                      ),
                    ],

                    const SizedBox(height: 14),

                    // Note (Optional)
                    TripSplitTextField(
                      label: 'Note (Optional)',
                      hint: 'Add an optional note...',
                      controller: _noteController,
                      maxLines: 2,
                    ),

                    const SizedBox(height: 24),

                    // Save Expense CTA Button
                    TripSplitButton(
                      label: _isSaving
                          ? 'Saving...'
                          : (isPersonal ? 'Save Personal Expense' : 'Save Expense'),
                      trailingIcon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                      onPressed: _isSaving ? () {} : () => _handleSaveExpense(isPersonal),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Active Trip Selector Card
  Widget _buildActiveTripSelectorCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131A29) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.flight_takeoff_rounded, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'SELECTED TRIP',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 3),
                          const Text(
                            'ACTIVE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _selectedTrip?['title'] ?? _selectedTrip?['name'] ?? 'Trip',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (_activeTrips.length > 1)
            GestureDetector(
              onTap: () => _showTripPickerBottomSheet(context, isDark),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Change',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.primary),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Active Trips Switcher
  void _showTripPickerBottomSheet(BuildContext context, bool isDark) {
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
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Switch Active Trip',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ..._activeTrips.map((trip) {
                final isSelected = trip['id'] == _selectedTrip?['id'];
                final title = trip['title'] ?? trip['name'] ?? 'Trip';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTrip = trip;
                        _setupMembers();
                      });
                      Navigator.of(ctx).pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withOpacity(isDark ? 0.2 : 0.08)
                            : (isDark ? const Color(0xFF172033) : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? const Color(0xFF24324D) : const Color(0xFFE2E8F0)),
                          width: isSelected ? 1.8 : 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.flight_takeoff_rounded, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
                          else
                            const Icon(Icons.radio_button_unchecked_rounded, color: Colors.grey, size: 20),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  // Who Paid Picker Modal Sheet
  void _showPaidByPicker(BuildContext context, bool isDark) {
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
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Who paid for this?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ..._tripMembers.map((member) {
                final isSelected = member['user_id'] == _paidByUserId;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _paidByUserId = member['user_id'] as int?;
                        _paidByName = member['name'] as String;
                      });
                      Navigator.of(ctx).pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withOpacity(isDark ? 0.2 : 0.08)
                            : (isDark ? const Color(0xFF172033) : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? const Color(0xFF24324D) : const Color(0xFFE2E8F0)),
                          width: isSelected ? 1.8 : 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.primary,
                            child: Text(
                              member['name'].toString().isNotEmpty ? member['name'].toString()[0].toUpperCase() : 'M',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              member['name'] as String,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
                          else
                            const Icon(Icons.radio_button_unchecked_rounded, color: Colors.grey, size: 20),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  // Equal Split Members Modal Sheet (Include / Exclude Members)
  void _showEqualSplitMembersModal(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final includedCount = _tripMembers.where((m) => m['included'] == true).length;
            final total = _getExpenseTotal();
            final perPerson = includedCount > 0 ? (total / includedCount).round() : 0;

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
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Edit Split Members',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$includedCount of ${_tripMembers.length} members sharing • ₹ $perPerson / person',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ..._tripMembers.map((member) {
                    final isInc = member['included'] == true;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () {
                          if (isInc && includedCount <= 1) return;
                          setModalState(() {
                            member['included'] = !isInc;
                          });
                          setState(() {
                            _recalculateEqualSplit();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isInc
                                ? (isDark ? const Color(0xFF1E283D) : const Color(0xFFF1F5F9))
                                : (isDark ? Colors.transparent : Colors.grey.shade100),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isInc ? AppColors.primary.withOpacity(0.5) : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 15,
                                backgroundColor: AppColors.primary,
                                child: Text(
                                  member['name'].toString().isNotEmpty ? member['name'].toString()[0].toUpperCase() : 'M',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  member['name'] as String,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isInc
                                        ? (isDark ? Colors.white : Colors.black87)
                                        : (isDark ? Colors.white38 : Colors.grey),
                                  ),
                                ),
                              ),
                              if (isInc)
                                Text(
                                  '₹ $perPerson',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              const SizedBox(width: 8),
                              Icon(
                                isInc ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                color: isInc ? AppColors.primary : Colors.grey,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 16),
                  TripSplitButton(
                    label: 'Done',
                    onPressed: () {
                      setState(() {
                        _recalculateEqualSplit();
                      });
                      Navigator.of(ctx).pop();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Custom Split Amounts Modal Sheet
  void _showCustomSplitModal(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final total = _getExpenseTotal();
            final allocated = _getCustomAllocatedTotal();
            final difference = total - allocated;

            return Container(
              height: MediaQuery.of(ctx).size.height * 0.75,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF111726) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(
                  color: isDark ? const Color(0xFF222F43) : const Color(0xFFE2E8F0),
                ),
              ),
              padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(ctx).padding.bottom + 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Custom Split Amounts',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Total Expense: ₹ ${total.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            final per = (total / _tripMembers.length).roundToDouble();
                            for (final m in _tripMembers) {
                              m['amount'] = per;
                            }
                          });
                          setState(() {});
                        },
                        child: const Text('Split Evenly', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Allocation Tracker Banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: difference.abs() < 1
                          ? const Color(0xFF10B981).withOpacity(0.12)
                          : (difference > 0 ? const Color(0xFFF59E0B).withOpacity(0.12) : const Color(0xFFEF4444).withOpacity(0.12)),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: difference.abs() < 1
                            ? const Color(0xFF10B981).withOpacity(0.3)
                            : (difference > 0 ? const Color(0xFFF59E0B).withOpacity(0.3) : const Color(0xFFEF4444).withOpacity(0.3)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          difference.abs() < 1
                              ? Icons.check_circle_rounded
                              : (difference > 0 ? Icons.info_outline_rounded : Icons.warning_amber_rounded),
                          size: 18,
                          color: difference.abs() < 1
                              ? const Color(0xFF10B981)
                              : (difference > 0 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            difference.abs() < 1
                                ? 'Perfect! Allocated: ₹ ${allocated.toStringAsFixed(0)} / ₹ ${total.toStringAsFixed(0)}'
                                : (difference > 0
                                    ? 'Left to allocate: ₹ ${difference.toStringAsFixed(0)} (Total ₹ ${allocated.toStringAsFixed(0)})'
                                    : 'Exceeds total by ₹ ${(-difference).toStringAsFixed(0)} (Total ₹ ${allocated.toStringAsFixed(0)})'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: difference.abs() < 1
                                  ? const Color(0xFF10B981)
                                  : (difference > 0 ? const Color(0xFFD97706) : const Color(0xFFEF4444)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Members List with Increments / Input
                  Expanded(
                    child: ListView.builder(
                      itemCount: _tripMembers.length,
                      itemBuilder: (context, index) {
                        final member = _tripMembers[index];
                        final memberAmount = (member['amount'] as double? ?? 0.0);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF172033) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? const Color(0xFF24324D) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: AppColors.primary,
                                child: Text(
                                  member['name'].toString().isNotEmpty ? member['name'].toString()[0].toUpperCase() : 'M',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  member['name'] as String,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                                color: isDark ? Colors.white60 : Colors.black54,
                                onPressed: () {
                                  if (memberAmount >= 50) {
                                    setModalState(() {
                                      member['amount'] = memberAmount - 50;
                                    });
                                    setState(() {});
                                  }
                                },
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '₹ ${memberAmount.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                                color: AppColors.primary,
                                onPressed: () {
                                  setModalState(() {
                                    member['amount'] = memberAmount + 50;
                                  });
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  TripSplitButton(
                    label: 'Save Custom Split',
                    onPressed: () {
                      setState(() {});
                      Navigator.of(ctx).pop();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
