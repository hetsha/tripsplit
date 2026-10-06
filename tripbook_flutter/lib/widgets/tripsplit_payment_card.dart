import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

enum CardNetwork {
  mastercard,
  visa,
  rupay,
}

class TripSplitPaymentCard extends StatefulWidget {
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

  @override
  State<TripSplitPaymentCard> createState() => _TripSplitPaymentCardState();
}

class _TripSplitPaymentCardState extends State<TripSplitPaymentCard>
    with TickerProviderStateMixin {
  bool _isNumberMasked = false;
  bool _isFrozen = false;
  bool _isCopied = false;
  CardNetwork _selectedNetwork = CardNetwork.mastercard;

  // 3D Flip Animation
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _isBackShowing = false;

  // Subtle Specular Reflection Light Sheen
  late AnimationController _sheenController;
  late Animation<double> _sheenAnimation;

  // Interactive 3D Gyroscope/Tilt on touch drag
  double _tiltX = 0.0;
  double _tiltY = 0.0;

  @override
  void initState() {
    super.initState();

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutBack),
    );

    _sheenController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat(reverse: true);
    _sheenAnimation = Tween<double>(begin: -1.2, end: 1.8).animate(
      CurvedAnimation(parent: _sheenController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    _sheenController.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    if (_isBackShowing) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() {
      _isBackShowing = !_isBackShowing;
    });
  }

  void _copyCardNumber() {
    Clipboard.setData(ClipboardData(text: _cardNumber.replaceAll('  ', ' ')));
    HapticFeedback.lightImpact();
    setState(() {
      _isCopied = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'Card number copied to clipboard',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  // 16-digit card number derived from login number
  String get _cardNumber {
    final raw = widget.loginNumber?.trim();
    if (raw == null || raw.isEmpty) {
      return '5421  8920  3412  1025';
    }
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 10) {
      final ten = digits.substring(digits.length - 10);
      return '54${ten.substring(0, 2)}  ${ten.substring(2, 6)}  ${ten.substring(6, 9)}8  ${ten.substring(9)}25';
    } else {
      final padded = digits.padRight(16, '7');
      return '${padded.substring(0, 4)}  ${padded.substring(4, 8)}  ${padded.substring(8, 12)}  ${padded.substring(12, 16)}';
    }
  }

  String get _displayCardNumber {
    if (!_isNumberMasked) return _cardNumber;
    final parts = _cardNumber.split('  ');
    if (parts.length == 4) {
      return '••••  ••••  ••••  ${parts[3]}';
    }
    return '••••  ••••  ••••  1025';
  }

  // Generate 3-digit CVV deterministically from card number
  String get _cvvCode {
    final clean = _cardNumber.replaceAll(' ', '');
    if (clean.length >= 3) {
      final hash = (clean.codeUnitAt(0) + clean.codeUnitAt(clean.length - 1) * 7) % 900 + 100;
      return hash.toString();
    }
    return '742';
  }

  // Authentic Titanium / Composite Card Material Gradients
  // Calibrated for authentic physical appearance in both Dark and Light themes
  List<Color> getCardGradients(bool isDark) {
    if (isDark) {
      // In dark theme: Deep graphite brushed titanium with specular highlights
      // so it clearly separates from dark background without looking washed out
      return const [
        Color(0xFF252A38), // Top-left specular titanium
        Color(0xFF181C26), // Core body
        Color(0xFF222837), // Subtle diagonal luster
        Color(0xFF12151E), // Deep shadow edge
      ];
    } else {
      // In light theme: Heavy solid space-grey titanium sitting on white surface
      return const [
        Color(0xFF212634),
        Color(0xFF141722),
        Color(0xFF1E2330),
        Color(0xFF0D0F17),
      ];
    }
  }

  void _cycleNetwork() {
    setState(() {
      if (_selectedNetwork == CardNetwork.mastercard) {
        _selectedNetwork = CardNetwork.visa;
      } else if (_selectedNetwork == CardNetwork.visa) {
        _selectedNetwork = CardNetwork.rupay;
      } else {
        _selectedNetwork = CardNetwork.mastercard;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ==========================================
        // 1. 3D FLIPPABLE PHYSICAL CARD WITH REALISTIC DROP SHADOW
        // ==========================================
        Center(
          child: Container(
            // Authentic physical drop shadow (soft optical shadow, NO cartoonish neon glow)
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                // Soft directional ambient drop shadow onto desk/surface
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.70 : 0.20),
                  blurRadius: isDark ? 28 : 22,
                  offset: const Offset(0, 12),
                  spreadRadius: isDark ? 1 : 0,
                ),
                // Contact shadow immediately beneath card rim
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.45 : 0.10),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: GestureDetector(
              onTap: _toggleFlip, // Tap anywhere on the card to flip in 3D
              onPanUpdate: (details) {
                setState(() {
                  _tiltY += details.delta.dx * 0.0012;
                  _tiltX -= details.delta.dy * 0.0012;
                  _tiltX = _tiltX.clamp(-0.16, 0.16);
                  _tiltY = _tiltY.clamp(-0.16, 0.16);
                });
              },
              onPanEnd: (_) {
                setState(() {
                  _tiltX = 0.0;
                  _tiltY = 0.0;
                });
              },
              child: AnimatedBuilder(
                animation: Listenable.merge([_flipAnimation, _sheenAnimation]),
                builder: (context, child) {
                  final angle = _flipAnimation.value * math.pi;
                  final isBack = angle > math.pi / 2;

                  return Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0014) // 3D Perspective Depth
                      ..rotateX(_tiltX)
                      ..rotateY(angle + _tiltY),
                    alignment: Alignment.center,
                    child: isBack
                        ? Transform(
                            transform: Matrix4.identity()..rotateY(math.pi),
                            alignment: Alignment.center,
                            child: _buildPhysicalCardBack(isDark),
                          )
                        : _buildPhysicalCardFront(isDark),
                  );
                },
              ),
            ),
          ),
        ),

        // ==========================================
        // 2. CARD UTILITY ACTION DOCK (FLIP, MASK, COPY, FREEZE)
        // ==========================================
        Container(
          margin: const EdgeInsets.only(top: 13),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131B2C) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF243048) : const Color(0xFFE2E8F0),
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildCardActionBtn(
                  icon: Icons.sync_alt_rounded,
                  label: _isBackShowing ? 'Front' : 'Flip',
                  isDark: isDark,
                  onTap: _toggleFlip,
                ),
              ),
              _buildDivider(isDark),
              Expanded(
                child: _buildCardActionBtn(
                  icon: _isNumberMasked ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  label: _isNumberMasked ? 'Reveal' : 'Mask',
                  isDark: isDark,
                  onTap: () => setState(() => _isNumberMasked = !_isNumberMasked),
                ),
              ),
              _buildDivider(isDark),
              Expanded(
                child: _buildCardActionBtn(
                  icon: _isCopied ? Icons.check_circle_rounded : Icons.content_copy_rounded,
                  label: _isCopied ? 'Copied' : 'Copy',
                  iconColor: _isCopied ? AppColors.positive : null,
                  isDark: isDark,
                  onTap: _copyCardNumber,
                ),
              ),
              _buildDivider(isDark),
              Expanded(
                child: _buildCardActionBtn(
                  icon: _isFrozen ? Icons.ac_unit_rounded : Icons.lock_open_rounded,
                  label: _isFrozen ? 'Unfreeze' : 'Freeze',
                  iconColor: _isFrozen ? const Color(0xFF38BDF8) : null,
                  isDark: isDark,
                  onTap: () {
                    setState(() => _isFrozen = !_isFrozen);
                    HapticFeedback.mediumImpact();
                  },
                ),
              ),
            ],
          ),
        ),

        // ==========================================
        // 4. COMPANION STATS DOCK (RECEIVE & OWE)
        // ==========================================
        Container(
          margin: const EdgeInsets.only(top: 11),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141C2E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF243048) : const Color(0xFFE2E8F0),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // You receive
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.positive.withOpacity(0.14),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.south_west_rounded,
                        size: 17,
                        color: AppColors.positive,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'You receive',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            widget.toReceive,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.positive,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Vertical divider
              Container(
                height: 30,
                width: 1,
                color: isDark ? const Color(0xFF243048) : const Color(0xFFE2E8F0),
              ),
              const SizedBox(width: 14),

              // You owe
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.negative.withOpacity(0.14),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.north_east_rounded,
                        size: 17,
                        color: AppColors.negative,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'You owe',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            widget.toPay,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.negative,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      height: 18,
      width: 1,
      color: isDark ? const Color(0xFF26334D) : const Color(0xFFE2E8F0),
    );
  }

  Widget _buildCardActionBtn({
    required IconData icon,
    required String label,
    required bool isDark,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 13,
              color: iconColor ?? (isDark ? Colors.white70 : const Color(0xFF475569)),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getNetworkName() {
    switch (_selectedNetwork) {
      case CardNetwork.mastercard:
        return 'Mastercard';
      case CardNetwork.visa:
        return 'Visa';
      case CardNetwork.rupay:
        return 'RuPay';
    }
  }

  // ==========================================
  // FRONT OF THE CARD (ORIGINAL PHYSICAL DESIGN)
  // ==========================================
  Widget _buildPhysicalCardFront(bool isDark) {
    final gradients = getCardGradients(isDark);

    return AspectRatio(
      aspectRatio: 1.586, // ISO/IEC 7810 ID-1 standard ratio (85.60 × 53.98 mm)
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: gradients,
            stops: const [0.0, 0.35, 0.70, 1.0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          // Precision Milled Metallic Chamfer Outer Rim
          // Catches ambient light on top/left, shadows on bottom/right
          border: Border.all(
            color: isDark
                ? const Color(0xFFCBD5E1).withOpacity(0.35)
                : const Color(0xFF94A3B8).withOpacity(0.30),
            width: 1.2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            children: [
              // 1. Solid Core Inset Bevel (Visible multi-layer card edge)
              Positioned.fill(
                child: Container(
                  margin: const EdgeInsets.all(2.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13.5),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.10)
                          : Colors.white.withOpacity(0.08),
                      width: 0.8,
                    ),
                  ),
                ),
              ),

              // 2. Micro Brushed Metal Hairline Texture
              Positioned.fill(
                child: CustomPaint(
                  painter: _BrushedMetalTexturePainter(isDark: isDark),
                ),
              ),

              // 3. Banknote Guilloche Anti-Counterfeit Security Patterns
              Positioned.fill(
                child: CustomPaint(
                  painter: _GuillocheSecurityPainter(isDark: isDark),
                ),
              ),

              // 4. Natural Specular Reflection Sheen (Glides across card)
              Positioned(
                top: -120,
                left: -100 + (_sheenAnimation.value * 280),
                width: 200,
                bottom: -120,
                child: Transform.rotate(
                  angle: -0.42,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(0.01),
                          Colors.white.withOpacity(isDark ? 0.10 : 0.06),
                          Colors.white.withOpacity(0.01),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.40, 0.50, 0.60, 1.0],
                      ),
                    ),
                  ),
                ),
              ),

              // 5. Frozen State Ice Overlay
              if (_isFrozen)
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
                    child: Container(
                      color: const Color(0xFF0284C7).withOpacity(0.30),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A).withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF38BDF8), width: 1.4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.ac_unit_rounded, size: 14, color: Color(0xFF38BDF8)),
                              SizedBox(width: 6),
                              Text(
                                'CARD FROZEN',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // 6. Main Card Face Elements
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // --- TOP ROW: Bank Brand & Debit/Credit Badge ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            // Authentic Foil Shield Crest
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFE2E8F0), Color(0xFF94A3B8)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.7),
                                  width: 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.4),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.shield_outlined,
                                  color: Color(0xFF0F172A),
                                  size: 15,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'TRIPSPLIT',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.96),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2.2,
                                    shadows: const [
                                      Shadow(
                                        color: Colors.black87,
                                        offset: Offset(1, 1),
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  'WORLD ELITE TITANIUM',
                                  style: TextStyle(
                                    color: const Color(0xFFCBD5E1).withOpacity(0.85),
                                    fontSize: 6.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Card Tier Foil Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.28),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            'DEBIT',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.92),
                              fontSize: 8.0,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // --- MIDDLE ROW: EMV Smart Chip, Contactless Waves & Balance ---
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Ultra-realistic 8-pin Gold Contact EMV Chip
                        _buildRealisticEmvChip(),
                        const SizedBox(width: 12),

                        // Genuine Contactless Waves
                        _buildContactlessWaves(),

                        const Spacer(),

                        // Digital Ledger Balance Display
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.positive,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.positive,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'LEDGER BALANCE',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.65),
                                    fontSize: 7.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 1),
                            Text(
                              widget.balance,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.4,
                                shadows: [
                                  Shadow(
                                    color: Colors.black87,
                                    offset: Offset(1.2, 1.2),
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // --- CARD NUMBER: 3D Stamped Embossed Foil Numbers ---
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _displayCardNumber,
                        style: TextStyle(
                          color: _isCopied ? const Color(0xFF34D399) : const Color(0xFFF8FAFC),
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                          letterSpacing: 2.8,
                          shadows: [
                            // 3D Stamped Bevel Specular Highlights
                            Shadow(
                              color: _isCopied ? const Color(0xFF34D399).withOpacity(0.9) : Colors.white.withOpacity(0.85),
                              offset: const Offset(-0.8, -0.8),
                              blurRadius: 0.5,
                            ),
                            // Deep Emboss Under-Shadow
                            Shadow(
                              color: Colors.black.withOpacity(0.95),
                              offset: const Offset(1.5, 1.8),
                              blurRadius: 2.5,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // --- BOTTOM ROW: Cardholder, Valid Thru, Hologram & Logo ---
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Cardholder Name
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'CARDHOLDER',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.55),
                                  fontSize: 6.8,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 1.5),
                              Text(
                                widget.cardHolder.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.96),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.85),
                                      offset: const Offset(1.2, 1.2),
                                      blurRadius: 2.5,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Valid Thru
                        Expanded(
                          flex: 3,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'VALID',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 5.0,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                      height: 1.0,
                                    ),
                                  ),
                                  Text(
                                    'THRU',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 5.0,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                      height: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '12/29',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.95),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.8),
                                      offset: const Offset(1, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Iridescent Holographic Security Patch
                        _buildHologramFoilPatch(),
                        const SizedBox(width: 8),

                        // Network Brand Logo (Mastercard / Visa / RuPay)
                        GestureDetector(
                          onTap: _cycleNetwork,
                          child: _buildNetworkLogo(),
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
    );
  }

  // ==========================================
  // BACK OF THE CARD (ORIGINAL PHYSICAL BACK DETAILS)
  // ==========================================
  Widget _buildPhysicalCardBack(bool isDark) {
    final gradients = getCardGradients(isDark);

    return AspectRatio(
      aspectRatio: 1.586,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: gradients,
            stops: const [0.0, 0.35, 0.70, 1.0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: isDark
                ? const Color(0xFFCBD5E1).withOpacity(0.35)
                : const Color(0xFF94A3B8).withOpacity(0.30),
            width: 1.2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 15),

              // 1. Black Magnetic Stripe (HiCo Dual-Track Magstripe with Head Notch)
              Container(
                width: double.infinity,
                height: 40,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF060608),
                      Color(0xFF1A1A22),
                      Color(0xFF0A0A0D),
                      Color(0xFF14141A),
                    ],
                    stops: [0.0, 0.45, 0.55, 1.0],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 14),
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 2. Signature Panel & Stamped CVV Code
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    // Security Signature Strip
                    Expanded(
                      flex: 4,
                      child: Container(
                        height: 33,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.black38, width: 0.6),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              offset: Offset(0, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _SignatureStripPatternPainter(),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 10.0),
                              child: Text(
                                widget.cardHolder,
                                style: const TextStyle(
                                  fontFamily: 'cursive',
                                  fontSize: 15,
                                  color: Color(0xFF0F172A),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Stamped CVV / CVC Box with Last 4 Digits Preceding
                    Container(
                      height: 33,
                      padding: const EdgeInsets.symmetric(horizontal: 9),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.black38, width: 0.6),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            offset: Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _cardNumber.split('  ').last,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 9.5,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _cvvCode,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              color: Color(0xFF0F172A),
                              letterSpacing: 2.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 9),

              // 3. Reversed Debossed Number Silhouette (Indent Impression from Front)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    Text(
                      _displayCardNumber.split('').reversed.join(''),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 9,
                        letterSpacing: 2.0,
                        color: Colors.white.withOpacity(0.12),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 4),

              // 4. Legal and Issuer Information Micro-print
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Text(
                  'Authorized signature required. This card is issued by TripSplit Digital Vault and remains property of the issuer. If found, please return to any partner branch or call 24/7 VIP Concierge at 1800-TRIPSPLIT.',
                  style: TextStyle(
                    fontSize: 6.8,
                    height: 1.25,
                    color: Colors.white.withOpacity(0.65),
                  ),
                ),
              ),

              const Spacer(),

              // 5. Back Bottom Row: Inter-bank Networks & Hologram
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.contactless_rounded,
                          size: 17,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'CIRRUS  •  PLUS  •  PULSE  •  STAR',
                          style: TextStyle(
                            fontSize: 8.2,
                            fontWeight: FontWeight.w800,
                            color: Colors.white.withOpacity(0.6),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'ISO 7810 ID-1',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withOpacity(0.6),
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- REALISTIC 8-CONTACT EMV GOLD CHIP ---
  Widget _buildRealisticEmvChip() {
    return Container(
      width: 40,
      height: 29,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFE58F),
            Color(0xFFD4AF37),
            Color(0xFFA17C17),
            Color(0xFFFFDF7A),
          ],
          stops: [0.0, 0.35, 0.7, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color(0xFF8A6510),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.55),
            blurRadius: 3,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Inner circuit groove ring
          Center(
            child: Container(
              width: 22,
              height: 16,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: const Color(0xFF5E4205),
                  width: 0.8,
                ),
              ),
            ),
          ),
          // Vertical circuit divider
          Center(
            child: Container(
              width: 0.8,
              height: 29,
              color: const Color(0xFF5E4205),
            ),
          ),
          // Horizontal left groove
          Positioned(
            left: 0,
            top: 14,
            child: Container(
              width: 9,
              height: 0.8,
              color: const Color(0xFF5E4205),
            ),
          ),
          // Horizontal right groove
          Positioned(
            right: 0,
            top: 14,
            child: Container(
              width: 9,
              height: 0.8,
              color: const Color(0xFF5E4205),
            ),
          ),
          // Central silicon die circle
          Center(
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8A6510).withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- CONTACTLESS / NFC WAVES ---
  Widget _buildContactlessWaves() {
    return SizedBox(
      width: 16,
      height: 18,
      child: CustomPaint(
        painter: _NfcArcsPainter(),
      ),
    );
  }

  // --- IRIDESCENT HOLOGRAPHIC SECURITY PATCH ---
  Widget _buildHologramFoilPatch() {
    return Container(
      width: 22,
      height: 17,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3.5),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFF8E8E),
            Color(0xFFFFD166),
            Color(0xFF06D6A0),
            Color(0xFF118AB2),
            Color(0xFF073B4C),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white70, width: 0.7),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 2.5),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.verified_user_rounded,
          size: 10.5,
          color: Colors.white.withOpacity(0.95),
        ),
      ),
    );
  }

  // --- NETWORK BRAND LOGO (MASTERCARD / VISA / RUPAY) ---
  Widget _buildNetworkLogo() {
    switch (_selectedNetwork) {
      case CardNetwork.mastercard:
        return _buildMastercardLogo();
      case CardNetwork.visa:
        return _buildVisaLogo();
      case CardNetwork.rupay:
        return _buildRupayLogo();
    }
  }

  // Mastercard Overlapping Crimson & Amber Discs with authentic brand mark
  Widget _buildMastercardLogo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 38,
          height: 21,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Left Red Disc
              Positioned(
                left: 0,
                child: Container(
                  width: 21,
                  height: 21,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFEB001B), // Mastercard Crimson
                  ),
                ),
              ),
              // Right Yellow/Amber Disc
              Positioned(
                right: 0,
                child: Container(
                  width: 21,
                  height: 21,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF79E1B).withOpacity(0.96),
                  ),
                ),
              ),
              // Blended center lens
              Container(
                width: 8,
                height: 17,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFFFF5F00).withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 1),
        Text(
          'mastercard',
          style: TextStyle(
            color: Colors.white.withOpacity(0.85),
            fontSize: 6.0,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  // Visa Infinite Laser Foil Logo
  Widget _buildVisaLogo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: const Text(
        'VISA',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18.5,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          letterSpacing: 1.5,
          shadows: [
            Shadow(
              color: Colors.black87,
              offset: Offset(1, 1),
              blurRadius: 3,
            ),
          ],
        ),
      ),
    );
  }

  // RuPay Platinum Logo
  Widget _buildRupayLogo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'RuPay',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
            shadows: [
              Shadow(
                color: Colors.black87,
                offset: Offset(1, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
        const SizedBox(width: 3),
        Container(
          width: 8,
          height: 13,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF059669), Color(0xFFF59E0B)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.all(Radius.circular(2)),
          ),
        ),
      ],
    );
  }
}

/// Custom Painter for NFC Wireless Contactless 4 Curved Arcs
class _NfcArcsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width * 1.2, size.height / 2);

    for (int i = 1; i <= 3; i++) {
      final radius = 5.0 + (i * 4.5);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        2.6,
        1.1,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom Painter for Guilloche Anti-Counterfeit Security Waves
class _GuillocheSecurityPainter extends CustomPainter {
  final bool isDark;
  _GuillocheSecurityPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(isDark ? 0.045 : 0.025)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.85;

    final path = Path();
    for (double i = 0; i < size.height; i += 16) {
      path.moveTo(0, i);
      path.cubicTo(
        size.width * 0.25,
        i + 14,
        size.width * 0.75,
        i - 14,
        size.width,
        i + 6,
      );
    }
    canvas.drawPath(path, paint);

    // Concentric Guilloche watermarks
    final circlePaint = Paint()
      ..color = Colors.white.withOpacity(isDark ? 0.035 : 0.018)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75;

    final center = Offset(size.width * 0.75, size.height * 0.45);
    for (double r = 20; r <= 140; r += 22) {
      canvas.drawCircle(center, r, circlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom Painter for Brushed Metal Hairline Texture
class _BrushedMetalTexturePainter extends CustomPainter {
  final bool isDark;
  _BrushedMetalTexturePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(isDark ? 0.028 : 0.015)
      ..strokeWidth = 0.55;

    for (double y = 0; y < size.height; y += 3.5) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom Painter for Signature Strip Security Pattern
class _SignatureStripPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.24)
      ..strokeWidth = 1.0;

    for (double x = -size.height; x < size.width; x += 8) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
