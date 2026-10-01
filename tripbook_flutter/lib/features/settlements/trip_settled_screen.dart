import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/tripsplit_widgets.dart';
import '../../services/auth_service.dart';
import '../../services/expense_service.dart';

class TripSettledScreen extends StatelessWidget {
  const TripSettledScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final auth = Provider.of<AuthService>(context);
    final expense = Provider.of<ExpenseService>(context);

    final currentUserId = auth.currentUser?.id ?? 0;
    final int? tripId = args?['tripId'] ?? args?['trip']?['id'] ?? auth.activeTripId;

    Map<String, dynamic>? trip;
    if (args?['trip'] != null) {
      trip = args!['trip'] as Map<String, dynamic>;
    } else if (auth.detailedTrips.isNotEmpty && tripId != null) {
      trip = auth.detailedTrips.firstWhere(
        (t) => t['id'] == tripId,
        orElse: () => auth.detailedTrips.first,
      );
    }

    final tripTitle = trip?['title'] ?? trip?['name'] ?? 'Trip';
    final tripDestination = trip?['destination'] ?? 'Travel Group';
    final double totalSpent = (trip?['total_spent'] as num?)?.toDouble() ??
        (expense.dashboardData?['summary']?['total_expenses'] as num?)?.toDouble() ??
        0.0;

    // Balances
    final List rawBalances = expense.settlementData?['all_balances'] ??
        expense.dashboardData?['member_balances'] ??
        [];

    final int membersCount = rawBalances.isNotEmpty
        ? rawBalances.length
        : ((trip?['members_count'] as num?)?.toInt() ?? 1);

    final double fairShare = membersCount > 0 ? (totalSpent / membersCount) : 0.0;

    double youPaid = 0.0;
    double youReceived = 0.0;

    for (var b in rawBalances) {
      final uid = b['user_id'] is int ? b['user_id'] : int.tryParse(b['user_id'].toString()) ?? 0;
      if (uid == currentUserId) {
        youPaid = (b['total_paid'] as num?)?.toDouble() ?? 0.0;
        final net = (b['net_balance'] as num?)?.toDouble() ?? 0.0;
        youReceived = net > 0 ? net : 0.0;
        break;
      }
    }

    final membersStatus = rawBalances.map((m) {
      final uid = m['user_id'] is int ? m['user_id'] : int.tryParse(m['user_id'].toString()) ?? 0;
      final name = m['name'] as String? ?? 'Member';
      final isCurrentUser = uid == currentUserId;
      final paid = (m['total_paid'] as num?)?.toDouble() ?? 0.0;
      final share = (m['total_share'] as num?)?.toDouble() ?? fairShare;
      final balance = (m['net_balance'] as num?)?.toDouble() ?? 0.0;
      final isPositive = balance >= 0;

      return {
        'name': isCurrentUser ? 'You ($name)' : name,
        'paid': '₹ ${paid.toStringAsFixed(0)}',
        'share': '₹ ${share.toStringAsFixed(0)}',
        'status': '₹ 0',
        'statusLabel': isPositive ? 'Balanced' : 'Settled',
        'isPositive': true,
        'avatar_color': m['avatar_color'] ?? '#3b82f6',
      };
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header
            TripSplitHeader(
              title: '',
              showBack: true,
              onBack: () => Navigator.of(context).maybePop(),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
                child: Column(
                  children: [
                    // Glowing Green Checkmark Circle
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF10B981),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.4),
                            blurRadius: 24,
                            spreadRadius: 4,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.check_rounded, color: Colors.white, size: 48),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Success Headline
                    Text(
                      'Trip Successfully Settled!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'All accounts and balances in $tripTitle are now completely balanced.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Trip Summary Card
                    TripSplitCard(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.flight_takeoff_rounded, color: AppColors.primary, size: 26),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tripTitle,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '$tripDestination • $membersCount Members',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF10B981)),
                                SizedBox(width: 4),
                                Text(
                                  'Settled',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Settlement Details Stat Card
                    TripSplitCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMiniStat('$membersCount', 'Members', isDark),
                          _buildMiniStat('₹ ${youPaid.toStringAsFixed(0)}', 'You Paid', isDark),
                          _buildMiniStat('₹ ${fairShare.toStringAsFixed(0)}', 'Your Share', isDark),
                          _buildMiniStat('₹ ${youReceived.toStringAsFixed(0)}', 'Collected', isDark, isHighlight: true),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Final Status Header
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Member Accounts Balanced',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Final Status Member Cards
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: membersStatus.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, index) {
                        final item = membersStatus[index];

                        return TripSplitCard(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: const Color(0xFF10B981).withOpacity(0.2),
                                child: Text(
                                  item['name'].toString().isNotEmpty ? item['name'].toString()[0].toUpperCase() : 'M',
                                  style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF10B981)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'] as String,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Paid: ${item['paid']} • Share: ${item['share']}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    '₹ 0',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                  Text(
                                    item['statusLabel'] as String,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Two Buttons: View Trip & Back to Home
                    Row(
                      children: [
                        Expanded(
                          child: TripSplitSecondaryButton(
                            label: 'View Trip',
                            icon: const Icon(Icons.remove_red_eye_outlined, size: 18, color: AppColors.primary),
                            onPressed: () => Navigator.of(context).pushNamed(
                              '/dashboard',
                              arguments: {'tripId': tripId},
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TripSplitButton(
                            label: 'Back to Home',
                            icon: const Icon(Icons.home_rounded, color: Colors.white, size: 18),
                            onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false),
                          ),
                        ),
                      ],
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

  Widget _buildMiniStat(String value, String label, bool isDark, {bool isHighlight = false}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: isHighlight
                ? const Color(0xFF10B981)
                : (isDark ? AppColors.textDarkMain : AppColors.textLightMain),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
          ),
        ),
      ],
    );
  }
}
