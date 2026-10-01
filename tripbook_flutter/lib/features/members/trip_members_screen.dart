import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/tripsplit_widgets.dart';
import '../../services/auth_service.dart';
import '../../services/expense_service.dart';

class TripMembersScreen extends StatefulWidget {
  const TripMembersScreen({Key? key}) : super(key: key);

  @override
  State<TripMembersScreen> createState() => _TripMembersScreenState();
}

class _TripMembersScreenState extends State<TripMembersScreen> {
  int? _tripId;
  String _tripCode = '';
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = false;
  bool _initialized = false;
  String _userRole = 'member';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final auth = Provider.of<AuthService>(context, listen: false);
      _tripId = args?['tripId'] ?? args?['trip']?['id'] ?? auth.activeTripId;
      _loadMembers();
      _initialized = true;
    }
  }

  Future<void> _loadMembers() async {
    if (_tripId == null) return;
    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final expense = Provider.of<ExpenseService>(context, listen: false);

      final data = await auth.loadTripMembers(tripId: _tripId!);
      await expense.loadSettlements(tripId: _tripId!);

      if (mounted) {
        setState(() {
          _tripCode = data['trip_code'] as String? ?? '';
          if (data['members'] is List) {
            _members = List<Map<String, dynamic>>.from(data['members']);
          }

          // Check current user role
          final currentUserId = auth.currentUser?.id;
          final userMember = _members.firstWhere(
            (m) => (m['id'] ?? m['user_id']) == currentUserId,
            orElse: () => {},
          );
          _userRole = userMember['role'] as String? ?? 'member';
        });
      }
    } catch (e) {
      print('Load members error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddMemberModal() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    bool isAdding = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;

            return Container(
              padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF111726) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: isDark ? const Color(0xFF222F43) : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
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
                      Text(
                        'Add Group Member',
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
                  const SizedBox(height: 14),
                  TripSplitTextField(
                    label: 'Member Name',
                    hint: 'e.g. Rohan Verma',
                    controller: nameCtrl,
                    prefixIcon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 12),
                  TripSplitTextField(
                    label: 'Email (Optional)',
                    hint: 'rohan@example.com',
                    controller: emailCtrl,
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TripSplitTextField(
                    label: 'Phone (Optional)',
                    hint: '+91 9876543210',
                    controller: phoneCtrl,
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 20),
                  TripSplitButton(
                    label: isAdding ? 'Adding Member...' : 'Add to Trip',
                    trailingIcon: isAdding
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.person_add_rounded, color: Colors.white, size: 18),
                    onPressed: isAdding
                        ? () {}
                        : () async {
                            final name = nameCtrl.text.trim();
                            if (name.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter a name')),
                              );
                              return;
                            }

                            setModalState(() => isAdding = true);
                            try {
                              final auth = Provider.of<AuthService>(context, listen: false);
                              await auth.addMemberToTrip(
                                tripId: _tripId!,
                                name: name,
                                email: emailCtrl.text.trim(),
                                phone: phoneCtrl.text.trim(),
                              );
                              Navigator.of(ctx).pop();
                              _loadMembers();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('$name added to the trip! 🎉'),
                                    backgroundColor: const Color(0xFF10B981),
                                  ),
                                );
                              }
                            } catch (e) {
                              setModalState(() => isAdding = false);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to add: $e'), backgroundColor: Colors.red),
                                );
                              }
                            }
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

  void _confirmRemoveMember(Map<String, dynamic> member) async {
    final memberId = (member['id'] ?? member['user_id']) as int;
    final name = member['name'] as String? ?? 'Member';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove $name?'),
        content: const Text('Are you sure you want to remove this member from the trip?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final auth = Provider.of<AuthService>(context, listen: false);
        await auth.removeMemberFromTrip(tripId: _tripId!, userId: memberId);
        _loadMembers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$name removed from the trip')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not remove member: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = Provider.of<AuthService>(context);
    final currentUserId = auth.currentUser?.id;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header Bar
            TripSplitHeader(
              title: 'Trip Members',
              rightAction: GestureDetector(
                onTap: _showAddMemberModal,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 16, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Add Member',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              onBack: () => Navigator.of(context).maybePop(),
            ),

            const SizedBox(height: 8),

            // Trip Invite Code Banner
            if (_tripCode.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF131A29) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.vpn_key_rounded, size: 18, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TRIP INVITE CODE',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primary),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              _tripCode,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _tripCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Trip code copied to clipboard! Share with friends.')),
                          );
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.copy_rounded, size: 13, color: AppColors.primary),
                            SizedBox(width: 4),
                            Text('Copy', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Members List
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadMembers,
                color: AppColors.primary,
                child: _isLoading && _members.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _members.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (ctx, index) {
                          final member = _members[index];
                          final uid = (member['id'] ?? member['user_id']) as int;
                          final name = member['name'] as String? ?? 'Member';
                          final role = member['role'] as String? ?? 'member';
                          final isCreator = role == 'owner' || role == 'creator';
                          final isCurrent = uid == currentUserId;

                          final balanceInfo = member['balance_info'] as Map<String, dynamic>?;
                          final double paid = (balanceInfo?['total_paid'] as num?)?.toDouble() ?? 0.0;
                          final double share = (balanceInfo?['total_share'] as num?)?.toDouble() ?? 0.0;
                          final double net = (balanceInfo?['net_balance'] as num?)?.toDouble() ?? 0.0;

                          return TripSplitCard(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: isCreator
                                      ? const Color(0xFFF59E0B)
                                      : (isCurrent ? const Color(0xFF10B981) : AppColors.primary),
                                  child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : 'M',
                                    style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              isCurrent ? 'You ($name)' : name,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (isCreator) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFEF3C7),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Text(
                                                'Creator',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFFD97706),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Paid: ₹ ${paid.toStringAsFixed(0)}   |   Share: ₹ ${share.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_userRole == 'owner' && !isCreator && !isCurrent)
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline_rounded, size: 20, color: Color(0xFFEF4444)),
                                    onPressed: () => _confirmRemoveMember(member),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: (net >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      net >= 0 ? '+₹ ${net.toStringAsFixed(0)}' : '-₹ ${net.abs().toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: net >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Opacity(
                opacity: 0.7,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.park_rounded, color: AppColors.primary.withOpacity(0.3), size: 28),
                    const SizedBox(width: 6),
                    Text(
                      'Split smartly with your travel crew',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
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
