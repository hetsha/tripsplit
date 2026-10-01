import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/tripsplit_widgets.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({Key? key}) : super(key: key);

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _tripNameController = TextEditingController(text: 'Goa Trip');
  final _destinationController = TextEditingController(text: 'Goa, India');
  DateTime _startDate = DateTime(2024, 12, 12);
  DateTime _endDate = DateTime(2024, 12, 16);
  bool _isSubmitting = false;

  final List<Map<String, String>> _members = [];
  bool _membersInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_membersInitialized) {
      final auth = Provider.of<AuthService>(context, listen: false);
      final currentUserName = auth.currentUser?.name ?? 'You';
      _members.add({'name': 'You ($currentUserName)', 'avatar': ''});
      _membersInitialized = true;
    }
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _handleCreateTrip() async {
    if (_isSubmitting) return;
    final name = _tripNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a trip name')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final memberNames = _members
          .map((m) => m['name'] ?? '')
          .where((n) => n.trim().isNotEmpty && !n.startsWith('You'))
          .toList();
      final dest = _destinationController.text.trim();

      await auth.createTrip(
        name: name,
        description: dest.isNotEmpty ? dest : null,
        members: memberNames,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Trip "$name" created successfully!'),
          backgroundColor: AppColors.positive,
        ),
      );
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot connect: $e'),
          backgroundColor: AppColors.negative,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _addMemberDialog() {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Member', style: TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            hintText: 'Enter friend name or phone',
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                setState(() {
                  _members.add({'name': nameCtrl.text.trim(), 'avatar': ''});
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            TripSplitHeader(
              title: 'Create a New Trip',
              onBack: () => Navigator.of(context).maybePop(),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Trip Photo Banner
                    TripSplitCoverBanner(
                      height: 150,
                      onChangePhoto: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Photo selector opened')),
                        );
                      },
                    ),

                    const SizedBox(height: 18),

                    // Trip Name Input
                    TripSplitTextField(
                      label: 'Trip Name',
                      hint: 'e.g. Goa Trip',
                      controller: _tripNameController,
                      prefixIcon: Icons.luggage_rounded,
                    ),

                    const SizedBox(height: 16),

                    // Destination Input
                    TripSplitTextField(
                      label: 'Destination',
                      hint: 'e.g. Goa, India',
                      controller: _destinationController,
                      prefixIcon: Icons.location_on_rounded,
                    ),

                    const SizedBox(height: 16),

                    // Start Date & End Date Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Start Date',
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
                                    initialDate: _startDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                  );
                                  if (picked != null) setState(() => _startDate = picked);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.elevatedDark : AppColors.inputBgLight,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _formatDate(_startDate),
                                          style: TextStyle(
                                            fontSize: 14,
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'End Date',
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
                                    initialDate: _endDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                  );
                                  if (picked != null) setState(() => _endDate = picked);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.elevatedDark : AppColors.inputBgLight,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _formatDate(_endDate),
                                          style: TextStyle(
                                            fontSize: 14,
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

                    const SizedBox(height: 24),

                    // Add Members Section
                    Text(
                      'Add Members',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                      ),
                    ),
                    const SizedBox(height: 12),

                    SizedBox(
                      height: 76,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _members.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (ctx, index) {
                          if (index == _members.length) {
                            // Add Member Circle Button
                            return GestureDetector(
                              onTap: _addMemberDialog,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.primary,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.add_rounded,
                                      color: AppColors.primary,
                                      size: 26,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Add',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                                  ),
                                ],
                              ),
                            );
                          }

                          final member = _members[index];
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.brandLavender,
                                backgroundImage: member['avatar']!.isNotEmpty
                                    ? NetworkImage(member['avatar']!)
                                    : null,
                                child: member['avatar']!.isEmpty
                                    ? Text(
                                        member['name']!.substring(0, 1),
                                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                                      )
                                    : null,
                              ),
                              const SizedBox(height: 6),
                              SizedBox(
                                width: 56,
                                child: Text(
                                  member['name']!.split(' ').first,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.textDarkMuted : AppColors.textLightMain,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Create Trip Button with DB Persistence
                    TripSplitButton(
                      label: 'Create Trip',
                      isLoading: _isSubmitting,
                      trailingIcon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                      onPressed: _isSubmitting ? null : _handleCreateTrip,
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
}
