import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TripSplitPaymentCard extends StatelessWidget {
  final String cardHolder;
  final String? loginNumber;
  final String balance;
  final String toReceive;
  final String toPay;
  final VoidCallback? onTap;

  const TripSplitPaymentCard({
    Key? key,
    this.cardHolder = 'HET SHAH',
    this.loginNumber,
    this.balance = '₹ 32,450',
    this.toReceive = '+₹ 4,120',
    this.toPay = '-₹ 850',
    this.onTap,
  }) : super(key: key);

  // Format user login phone number from database onto card digits
  String get _formattedCardNumber {
    final raw = loginNumber?.trim();
    if (raw == null || raw.isEmpty) {
      return '9876  5432  1025';
    }
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 10) {
      final ten = digits.substring(digits.length - 10);
      // Formats the 10-digit login phone number: "9876  5432  10" + "25" (edition year)
      return '${ten.substring(0, 4)}  ${ten.substring(4, 8)}  ${ten.substring(8, 10)}25';
    } else if (digits.length >= 4) {
      return digits.padRight(16, '0').replaceAllMapped(
          RegExp(r".{4}"), (match) => "${match.group(0)}  ").trim();
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ATM / Credit / Debit Physical Premium Card Layout
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            height: 220,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF0F172A),
                  Color(0xFF1E1B4B),
                  Color(0xFF2E1065),
                  Color(0xFF0F172A),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: const Color(0xFFF59E0B).withOpacity(0.65),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withOpacity(0.25),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                children: [
                  // Subtle Iridescent Hologram Gold Sheen Background
                  Positioned(
                    right: -40,
                    top: -40,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFF59E0B).withOpacity(0.28),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Bottom Purple Glow Watermark
                  Positioned(
                    left: -20,
                    bottom: -30,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.purpleAccent.withOpacity(0.18),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Card Content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Header Row: Brand Logo
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.flight_takeoff_rounded,
                                size: 16,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'TripSplit Card',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),

                        // Gold Chip & Wireless Contactless Waves Row
                        Row(
                          children: [
                            _buildEmvGoldChip(),
                            const SizedBox(width: 12),
                            Transform.rotate(
                              angle: 1.5708,
                              child: const Icon(
                                Icons.wifi_rounded,
                                size: 20,
                                color: Color(0xFFF59E0B),
                              ),
                            ),
                            const Spacer(),
                            // Overall Balance Display
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'OVERALL BALANCE',
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                Text(
                                  balance,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Card Number Row (Derived directly from User Database Login Number)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'CARD / LOGIN NUMBER',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _formattedCardNumber,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.95),
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2.2,
                                fontFamily: 'monospace',
                                shadows: const [
                                  Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1)),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Bottom Row: Cardholder Name, Expiry & TripSplit Pay Logo
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'CARDHOLDER',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  cardHolder,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),

                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'VALID THRU',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '12/28',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),

                            // TripSplit Pay / Network Logo
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 14,
                                      height: 14,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFFF59E0B),
                                      ),
                                    ),
                                    Transform.translate(
                                      offset: const Offset(-4, 0),
                                      child: Container(
                                        width: 14,
                                        height: 14,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0xFFFDE047),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 1),
                                const Text(
                                  'TripSplit Pay',
                                  style: TextStyle(
                                    color: Color(0xFFFDE047),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Quick Sub-Stats Strip: You will receive & You owe
        Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.surfaceDark
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.borderDark
                  : AppColors.borderLight,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.positiveBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_downward_rounded, size: 14, color: AppColors.positiveText),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'You will receive',
                        style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        toReceive,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.positiveText),
                      ),
                    ],
                  ),
                ],
              ),
              Container(height: 24, width: 1, color: Colors.grey.withOpacity(0.2)),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.negativeBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_upward_rounded, size: 14, color: AppColors.negativeText),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'You owe',
                        style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        toPay,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.negativeText),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Realistic EMV Metallic Gold Chip
  Widget _buildEmvGoldChip() {
    const chipColor = Color(0xFFFDE047);
    const borderColor = Color(0xFFCA8A04);

    return Container(
      width: 40,
      height: 30,
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: 1),
        gradient: const LinearGradient(
          colors: [Color(0xFFFDE047), Color(0xFFCA8A04), Color(0xFFFEF08A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Container(
              width: 22,
              height: 16,
              decoration: BoxDecoration(
                border: Border.all(color: borderColor.withOpacity(0.7), width: 0.8),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 1,
              height: 30,
              color: borderColor.withOpacity(0.7),
            ),
          ),
          Center(
            child: Container(
              width: 40,
              height: 1,
              color: borderColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
