import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class FloatingBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const FloatingBottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottomPadding > 0 ? 0 : 8),
      height: 62,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: const SizedBox.expand(),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [
                          Colors.white.withOpacity(0.05),
                          Colors.white.withOpacity(0.02),
                        ]
                      : [
                          Colors.white.withOpacity(0.25),
                          Colors.white.withOpacity(0.10),
                        ],
                ),
              ),
            ),
            Positioned(
              top: 0.5,
              left: 24,
              right: 24,
              height: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.transparent,
                      Colors.white.withOpacity(isDark ? 0.10 : 0.30),
                      Colors.white.withOpacity(isDark ? 0.18 : 0.45),
                      Colors.white.withOpacity(isDark ? 0.10 : 0.30),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.15, 0.5, 0.85, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 1,
              left: 8,
              right: 8,
              height: 18,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(isDark ? 0.02 : 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.04)
                        : Colors.white.withOpacity(0.15),
                    width: 0.5,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: _LiquidNavItemRow(
                currentIndex: currentIndex,
                isDark: isDark,
                onTap: onTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiquidNavItemRow extends StatelessWidget {
  final int currentIndex;
  final bool isDark;
  final ValueChanged<int> onTap;

  const _LiquidNavItemRow({
    required this.currentIndex,
    required this.isDark,
    required this.onTap,
  });

  static const _items = [
    _NavItem(icon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.history_rounded, label: 'History'),
    _NavItem(icon: Icons.people_rounded, label: 'People'),
    _NavItem(icon: Icons.check_circle_outline_rounded, label: 'Settle'),
    _NavItem(icon: Icons.menu_rounded, label: 'More'),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tabWidth = constraints.maxWidth / _items.length;
        final chipWidth = 62.0;
        final chipHeight = 46.0;
        final chipLeft = tabWidth * currentIndex + (tabWidth - chipWidth) / 2;

        return Stack(
          children: [
            // Sliding capsule
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: chipLeft,
              top: (constraints.maxHeight - chipHeight) / 2,
              width: chipWidth,
              height: chipHeight,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            Colors.white.withOpacity(0.06),
                            Colors.white.withOpacity(0.02),
                          ]
                        : [
                            Colors.white.withOpacity(0.30),
                            Colors.white.withOpacity(0.12),
                          ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.15),
                      blurRadius: 14,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),

            // Tab items
            Row(
              children: List.generate(_items.length, (index) {
                final item = _items[index];
                final isSelected = currentIndex == index;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onTap(index);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: tabWidth,
                    height: constraints.maxHeight,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item.icon,
                          size: 22,
                          color: isSelected
                              ? AppColors.primary
                              : isDark
                                  ? Colors.white.withOpacity(0.70)
                                  : Colors.black.withOpacity(0.60),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected
                                ? AppColors.primary
                                : isDark
                                    ? Colors.white.withOpacity(0.70)
                                    : Colors.black.withOpacity(0.60),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
