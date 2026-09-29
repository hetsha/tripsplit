import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/tripsplit_widgets.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({Key? key}) : super(key: key);

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _titleController = TextEditingController(text: 'Dinner at Beach Shack');
  final _amountController = TextEditingController(text: '2,450');
  final _noteController = TextEditingController(text: 'Dinner with the group at beach shack. Great food! 🍲');

  String _selectedCategory = 'Food & Drinks';
  DateTime _expenseDate = DateTime(2024, 12, 12);
  String _paidBy = 'You (Het)';
  bool _splitEqually = true;

  // Members for the current trip split
  final List<Map<String, dynamic>> _tripMembers = [
    {
      'name': 'You (Het)',
      'avatar': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
      'included': true,
      'amount': 490.0,
    },
    {
      'name': 'Priya S.',
      'avatar': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100',
      'included': true,
      'amount': 490.0,
    },
    {
      'name': 'Rahul V.',
      'avatar': 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=100',
      'included': true,
      'amount': 490.0,
    },
    {
      'name': 'Sneha K.',
      'avatar': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100',
      'included': true,
      'amount': 490.0,
    },
    {
      'name': 'Amit M.',
      'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
      'included': true,
      'amount': 490.0,
    },
  ];

  double _getExpenseTotal() {
    final clean = _amountController.text.replaceAll(',', '').replaceAll(' ', '');
    return double.tryParse(clean) ?? 2450.0;
  }

  void _recalculateEqualSplit() {
    final total = _getExpenseTotal();
    final includedMembers = _tripMembers.where((m) => m['included'] == true).toList();
    if (includedMembers.isNotEmpty) {
      final perPerson = (total / includedMembers.length).roundToDouble();
      for (final m in _tripMembers) {
        if (m['included'] == true) {
          m['amount'] = perPerson;
        } else {
          m['amount'] = 0.0;
        }
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

  Map<String, dynamic>? _selectedTrip;
  List<Map<String, dynamic>> _activeTrips = [];
  bool _initializedFromArgs = false;

  // Fallback active trips list (strictly active ongoing trips)
  final List<Map<String, dynamic>> _fallbackActiveTrips = [
    {
      'id': 1,
      'title': 'Goa Trip 🏖️',
      'destination': 'Goa, India',
      'dates': '12 - 16 Dec 2024',
      'image': 'https://images.unsplash.com/photo-1512343879784-a960bf40e7f2?w=800&auto=format&fit=crop&q=80',
      'membersCount': 5,
    },
    {
      'id': 2,
      'title': 'Manali Winter Trip 🏔️',
      'destination': 'Manali, Himachal',
      'dates': '5 - 10 Jan 2025',
      'image': 'https://images.unsplash.com/photo-1517411032315-54ef2cb783bb?w=800&auto=format&fit=crop&q=80',
      'membersCount': 4,
    },
    {
      'id': 3,
      'title': 'Weekend Roadtrip 🚗',
      'destination': 'Lonavala & Khandala',
      'dates': '22 - 24 Nov 2024',
      'image': 'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?w=800&auto=format&fit=crop&q=80',
      'membersCount': 3,
    },
  ];

  final List<String> _categories = [
    'Food & Drinks',
    'Stay & Hotel',
    'Transport',
    'Activities',
    'Shopping',
    'Other'
  ];

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final isPersonal = args?['isPersonal'] == true;

    if (!_initializedFromArgs) {
      if (args?['activeTrips'] != null) {
        _activeTrips = (args!['activeTrips'] as List).cast<Map<String, dynamic>>();
      } else {
        _activeTrips = _fallbackActiveTrips;
      }

      if (args?['trip'] != null) {
        _selectedTrip = args!['trip'] as Map<String, dynamic>;
      } else {
        _selectedTrip = _activeTrips.isNotEmpty ? _activeTrips.first : null;
      }
      _initializedFromArgs = true;
    }

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
                                  child: DropdownButton<String>(
                                    value: _selectedCategory,
                                    isExpanded: true,
                                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                                    items: _categories.map((c) {
                                      return DropdownMenuItem(
                                        value: c,
                                        child: Row(
                                          children: [
                                            const Icon(Icons.restaurant_rounded, size: 16, color: AppColors.primary),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                c,
                                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) setState(() => _selectedCategory = val);
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
                                  if (picked != null) setState(() => _expenseDate = picked);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.elevatedDark : AppColors.inputBgLight,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_month_rounded, size: 16, color: AppColors.primary),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          _formatDate(_expenseDate),
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
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    if (isPersonal) ...[
                      // Personal Expense Notice Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF13221C) : const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFF10B981).withOpacity(isDark ? 0.35 : 0.4),
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
                                          backgroundImage: NetworkImage(
                                            _tripMembers.firstWhere(
                                              (m) => m['name'] == _paidBy,
                                              orElse: () => _tripMembers.first,
                                            )['avatar'] as String,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            _paidBy,
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

                      // Interactive Split Summary Card (Equal or Custom)
                      Builder(
                        builder: (context) {
                          final totalExpense = _getExpenseTotal();
                          final includedList = _tripMembers.where((m) => m['included'] == true).toList();
                          final includedCount = includedList.length;
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
                                              backgroundImage: NetworkImage(m['avatar'] as String),
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

                    const SizedBox(height: 18),

                    // Add Photos (Optional)
                    Text(
                      'Add Photos (Optional)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?w=150',
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=150',
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Add More dashed container
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.primary,
                              style: BorderStyle.solid,
                              width: 1.2,
                            ),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_rounded, size: 20, color: AppColors.primary),
                              SizedBox(height: 2),
                              Text(
                                'Add More',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

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
                      label: isPersonal ? 'Save Personal Expense' : 'Save Expense',
                      trailingIcon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isPersonal
                                  ? 'Personal expense recorded to Cashbook!'
                                  : 'Expense added to ${_selectedTrip?['title'] ?? 'trip'} successfully!',
                            ),
                            backgroundColor: AppColors.positive,
                          ),
                        );
                        Navigator.of(context).pushNamed('/all_expenses');
                      },
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

  // Active Trip Selector Card: Displays current trip & allows switching among ACTIVE trips only
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
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              _selectedTrip?['image'] as String? ?? '',
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 44,
                height: 44,
                color: AppColors.primary,
                child: const Icon(Icons.flight_takeoff_rounded, color: Colors.white, size: 20),
              ),
            ),
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
                  _selectedTrip?['title'] as String? ?? 'Trip',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${_selectedTrip?['destination'] ?? ''} • ${_selectedTrip?['membersCount'] ?? 5} members',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                  ),
                ),
              ],
            ),
          ),
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

  // Active Trips Switcher: Shows ONLY ACTIVE TRIPS
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Switch Active Trip',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Only active trips shown (${_activeTrips.length})',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
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
              ..._activeTrips.map((trip) {
                final isSelected = trip['id'] == _selectedTrip?['id'];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTrip = trip;
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
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              trip['image'] as String,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 48,
                                height: 48,
                                color: AppColors.primary,
                                child: const Icon(Icons.flight_takeoff_rounded, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        trip['title'] as String,
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w800,
                                          color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'ACTIVE',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF10B981),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${trip['destination']} • ${trip['membersCount']} members',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Who paid for this?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Total Bill: ₹ ${_getExpenseTotal().toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
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
                final isSelected = member['name'] == _paidBy;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _paidBy = member['name'] as String;
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
                            backgroundImage: NetworkImage(member['avatar'] as String),
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
                          // Prevent unchecking all members
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
                                backgroundImage: NetworkImage(member['avatar'] as String),
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
                                backgroundImage: NetworkImage(member['avatar'] as String),
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
                              // Decrement -50
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
                              // Amount Pill
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
                              // Increment +50
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
