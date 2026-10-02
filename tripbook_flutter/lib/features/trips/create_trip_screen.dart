import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/tripsplit_widgets.dart';

/// Preset theme for the cover preview banner
class CoverTheme {
  final String id;
  final String name;
  final List<Color> gradient;
  final IconData defaultIcon;

  const CoverTheme({
    required this.id,
    required this.name,
    required this.gradient,
    required this.defaultIcon,
  });
}

class CreateTripScreen extends StatefulWidget {
  final String? initialType;
  const CreateTripScreen({Key? key, this.initialType}) : super(key: key);

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  String _selectedType = 'trip';
  final _nameController = TextEditingController();
  final _memberInputController = TextEditingController();
  final _budgetController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _memberFocusNode = FocusNode();

  bool _isSubmitting = false;
  bool _showBudgetField = false;
  String _selectedCurrency = '₹';
  late IconData _selectedIcon;
  late CoverTheme _selectedCover;

  final List<Map<String, String>> _members = [];
  bool _membersInitialized = false;

  // Preset covers
  static const List<CoverTheme> _coverThemes = [
    CoverTheme(
      id: 'cosmic',
      name: 'Cosmic Royal',
      gradient: [Color(0xFF6C38FF), Color(0xFF8B5CF6), Color(0xFFC084FC)],
      defaultIcon: Icons.flight_takeoff_rounded,
    ),
    CoverTheme(
      id: 'emerald',
      name: 'Emerald Green',
      gradient: [Color(0xFF059669), Color(0xFF10B981), Color(0xFF6EE7B7)],
      defaultIcon: Icons.home_rounded,
    ),
    CoverTheme(
      id: 'sunset',
      name: 'Sunset Rose',
      gradient: [Color(0xFFE11D48), Color(0xFFF43F5E), Color(0xFFFB923C)],
      defaultIcon: Icons.favorite_rounded,
    ),
    CoverTheme(
      id: 'ocean',
      name: 'Ocean Cyan',
      gradient: [Color(0xFF0284C7), Color(0xFF06B6D4), Color(0xFF38BDF8)],
      defaultIcon: Icons.person_rounded,
    ),
    CoverTheme(
      id: 'amber',
      name: 'Executive Gold',
      gradient: [Color(0xFFD97706), Color(0xFFF59E0B), Color(0xFFFCD34D)],
      defaultIcon: Icons.business_center_rounded,
    ),
    CoverTheme(
      id: 'midnight',
      name: 'Midnight Neon',
      gradient: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF4C1D95)],
      defaultIcon: Icons.auto_awesome_rounded,
    ),
  ];

  static const List<IconData> _selectableIcons = [
    Icons.flight_takeoff_rounded,
    Icons.beach_access_rounded,
    Icons.landscape_rounded,
    Icons.home_rounded,
    Icons.apartment_rounded,
    Icons.favorite_rounded,
    Icons.local_cafe_rounded,
    Icons.restaurant_rounded,
    Icons.celebration_rounded,
    Icons.business_center_rounded,
    Icons.directions_car_rounded,
    Icons.sports_esports_rounded,
    Icons.person_rounded,
    Icons.shopping_bag_rounded,
    Icons.account_balance_wallet_rounded,
    Icons.star_rounded,
  ];

  static const List<String> _commonCurrencies = ['₹', '\$', '€', '£', 'AED', '฿', 'C\$'];

  static const List<Map<String, dynamic>> _groupTypes = [
    {
      'key': 'trip',
      'label': 'Trip',
      'tagline': 'Vacations, road trips, hotels & adventures',
      'icon': Icons.flight_takeoff_rounded,
      'color': Color(0xFF6C38FF),
      'defaultCoverId': 'cosmic',
      'hint': 'e.g. Goa Trip 2025, Euro Roadtrip',
      'suggestions': ['Alex', 'Sarah', 'Driver', 'Guide'],
    },
    {
      'key': 'home',
      'label': 'Home',
      'tagline': 'Flatmates, rent, groceries, wifi & house bills',
      'icon': Icons.home_rounded,
      'color': Color(0xFF10B981),
      'defaultCoverId': 'emerald',
      'hint': 'e.g. Flat 302, Green Villa Housemates',
      'suggestions': ['Flatmate 1', 'Roommate', 'Landlord', 'Cook'],
    },
    {
      'key': 'couple',
      'label': 'Couple',
      'tagline': 'Dates, dinners, movies, groceries & daily life',
      'icon': Icons.favorite_rounded,
      'color': Color(0xFFF43F5E),
      'defaultCoverId': 'sunset',
      'hint': 'e.g. Us ❤️ & Date Nights',
      'suggestions': ['Partner ❤️', 'Babe'],
    },
    {
      'key': 'business',
      'label': 'Business',
      'tagline': 'Office lunches, client meetings & team offsites',
      'icon': Icons.business_center_rounded,
      'color': Color(0xFFF59E0B),
      'defaultCoverId': 'amber',
      'hint': 'e.g. Tech Team, Client Project, Offsite',
      'suggestions': ['Colleague', 'Manager', 'Client', 'Designer'],
    },
    {
      'key': 'personal',
      'label': 'Personal',
      'tagline': 'Solo budget tracker, pocket cash & private ledger',
      'icon': Icons.person_rounded,
      'color': Color(0xFF06B6D4),
      'defaultCoverId': 'ocean',
      'hint': 'e.g. Personal Pocketbook, Solo Spends',
      'suggestions': <String>[],
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialType != null && widget.initialType!.isNotEmpty) {
      _selectedType = widget.initialType!;
    }
    _syncThemeWithType();
  }

  void _syncThemeWithType() {
    final typeData = _currentTypeData;
    final coverId = typeData['defaultCoverId'] as String;
    _selectedCover = _coverThemes.firstWhere(
      (c) => c.id == coverId,
      orElse: () => _coverThemes[0],
    );
    _selectedIcon = typeData['icon'] as IconData;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_membersInitialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['type'] != null) {
        setState(() {
          _selectedType = args['type'].toString();
          _syncThemeWithType();
        });
      }

      final auth = Provider.of<AuthService>(context, listen: false);
      final currentUserName = auth.currentUser?.name ?? 'You';
      _members.add({'name': 'You ($currentUserName)', 'avatar': ''});
      _membersInitialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _memberInputController.dispose();
    _budgetController.dispose();
    _nameFocusNode.dispose();
    _memberFocusNode.dispose();
    super.dispose();
  }

  Map<String, dynamic> get _currentTypeData {
    return _groupTypes.firstWhere(
      (t) => t['key'] == _selectedType,
      orElse: () => _groupTypes[0],
    );
  }

  void _handleAddMember([String? presetName]) {
    final name = (presetName ?? _memberInputController.text).trim();
    if (name.isEmpty) return;

    if (_members.any((m) => m['name']!.toLowerCase() == name.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$name" is already added'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _members.add({'name': name, 'avatar': ''});
      if (presetName == null) {
        _memberInputController.clear();
      }
    });
  }

  void _handleRemoveMember(int index) {
    if (index == 0) return; // Cannot remove admin/creator
    setState(() {
      _members.removeAt(index);
    });
  }

  Future<void> _handleCreateGroup() async {
    if (_isSubmitting) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a group name'),
          backgroundColor: AppColors.negative,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _nameFocusNode.requestFocus();
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final memberNames = _selectedType == 'personal'
          ? <String>[]
          : _members
              .map((m) => m['name'] ?? '')
              .where((n) => n.trim().isNotEmpty && !n.startsWith('You'))
              .toList();

      final typeLabel = _currentTypeData['label'] as String;
      final fullDesc = '[$typeLabel] $typeLabel';
      final startingBudget = double.tryParse(_budgetController.text.trim());

      await auth.createTrip(
        name: name,
        description: fullDesc,
        startingMoney: startingBudget != null && startingBudget > 0 ? startingBudget : null,
        members: memberNames,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('Group "$name" created successfully!')),
            ],
          ),
          backgroundColor: AppColors.positive,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot create group: $e'),
          backgroundColor: AppColors.negative,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showCoverAndIconPicker(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: const [
                  BoxShadow(color: Colors.black38, blurRadius: 24, offset: Offset(0, -4)),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white : Colors.black).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Customize Cover & Icon',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'COLOR PALETTE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 56,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _coverThemes.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, idx) {
                          final cover = _coverThemes[idx];
                          final isSelected = cover.id == _selectedCover.id;
                          return GestureDetector(
                            onTap: () {
                              setModalState(() => _selectedCover = cover);
                              setState(() => _selectedCover = cover);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: cover.gradient,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? Colors.white : Colors.transparent,
                                  width: isSelected ? 3 : 0,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: cover.gradient.first.withOpacity(0.5),
                                          blurRadius: 10,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'GROUP ICON',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _selectableIcons.map((ic) {
                        final isSelected = ic == _selectedIcon;
                        return GestureDetector(
                          onTap: () {
                            setModalState(() => _selectedIcon = ic);
                            setState(() => _selectedIcon = ic);
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _selectedCover.gradient.first
                                  : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white.withOpacity(0.5)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Icon(
                              ic,
                              size: 22,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : const Color(0xFF475569)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedCover.gradient.first,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text(
                          'Apply Changes',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentType = _currentTypeData;
    final Color accentColor = _selectedCover.gradient.first;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF090D1A) : const Color(0xFFF8F9FD),
      body: SafeArea(
        child: Column(
          children: [
            // Top Nav Bar
            _buildTopNav(isDark, accentColor),

            // Main Scrollable Form Body
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==========================================
                    // 1. HERO PREVIEW BANNER CARD
                    // ==========================================
                    _buildHeroBannerCard(isDark),

                    const SizedBox(height: 24),

                    // ==========================================
                    // 2. GROUP NAME & CURRENCY CARD
                    // ==========================================
                    _buildNameAndCurrencyCard(isDark, accentColor),

                    const SizedBox(height: 24),

                    // ==========================================
                    // 3. CATEGORY / TYPE SELECTOR (RICH CARDS)
                    // ==========================================
                    _buildCategorySection(isDark, accentColor),

                    const SizedBox(height: 24),

                    // ==========================================
                    // 4. MEMBERS MANAGEMENT OR PRIVATE VAULT
                    // ==========================================
                    if (_selectedType != 'personal')
                      _buildMembersSection(isDark, accentColor)
                    else
                      _buildPersonalVaultBanner(isDark, accentColor),

                    const SizedBox(height: 24),

                    // ==========================================
                    // 5. OPTIONAL BUDGET / KITTY CASH
                    // ==========================================
                    _buildStartingBudgetSection(isDark, accentColor),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Bottom Floating Bar
            _buildBottomBar(isDark, accentColor, currentType),
          ],
        ),
      ),
    );
  }

  // --- TOP NAV BAR ---
  Widget _buildTopNav(bool isDark, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
          Text(
            'New Group',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          TextButton(
            onPressed: _isSubmitting ? null : _handleCreateGroup,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: Text(
              'Save',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 1. HERO PREVIEW BANNER ---
  Widget _buildHeroBannerCard(bool isDark) {
    final enteredName = _nameController.text.trim();
    final displayName = enteredName.isEmpty ? 'Your Group Name' : enteredName;
    final currentType = _currentTypeData;

    return Container(
      width: double.infinity,
      height: 185,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: _selectedCover.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _selectedCover.gradient.first.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background decorative patterns
          Positioned(
            right: -25,
            top: -25,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            left: -40,
            bottom: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),

          // "Change Cover" badge button top right
          Positioned(
            top: 14,
            right: 14,
            child: GestureDetector(
              onTap: () => _showCoverAndIconPicker(context, isDark),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.palette_rounded, size: 14, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'Theme & Icon',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Main Hero Contents
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Floating Icon Avatar
                GestureDetector(
                  onTap: () => _showCoverAndIconPicker(context, isDark),
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        _selectedIcon,
                        size: 28,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Live group title preview
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                    color: enteredName.isEmpty ? Colors.white.withOpacity(0.75) : Colors.white,
                  ),
                ),

                const SizedBox(height: 4),

                // Subtitle metadata pill
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        (currentType['label'] as String).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selectedType == 'personal'
                          ? 'Solo Vault • 1 Person'
                          : '${_members.length} Members • Split Equal',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. GROUP NAME & CURRENCY CARD ---
  Widget _buildNameAndCurrencyCard(bool isDark, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141C2E) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF243048) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'GROUP NAME',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                ),
              ),
              Text(
                'CURRENCY: $_selectedCurrency',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Name input row with clear button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  focusNode: _nameFocusNode,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    hintText: _currentTypeData['hint'] as String,
                    hintStyle: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white30 : Colors.grey.shade400,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
              ),
              if (_nameController.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _nameController.clear();
                    setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white12 : Colors.black.withOpacity(0.06),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),
          Divider(color: isDark ? const Color(0xFF243048) : const Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 12),

          // Quick currency pills
          Row(
            children: [
              Text(
                'Currency:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _commonCurrencies.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, idx) {
                      final curr = _commonCurrencies[idx];
                      final isSelected = curr == _selectedCurrency;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCurrency = curr),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? accentColor.withOpacity(0.15)
                                : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? accentColor : Colors.transparent,
                              width: 1.2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              curr,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected
                                    ? accentColor
                                    : (isDark ? Colors.white70 : const Color(0xFF475569)),
                              ),
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
        ],
      ),
    );
  }

  // --- 3. CATEGORY / TYPE SELECTION ---
  Widget _buildCategorySection(bool isDark, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'SELECT CATEGORY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
              ),
            ),
            Text(
              'Sets split mode & vibe',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // High-end category cards
        ..._groupTypes.map((item) {
          final key = item['key'] as String;
          final isSelected = key == _selectedType;
          final color = item['color'] as Color;
          final icon = item['icon'] as IconData;
          final label = item['label'] as String;
          final tagline = item['tagline'] as String;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedType = key;
                _syncThemeWithType();
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark
                        ? color.withOpacity(0.15)
                        : color.withOpacity(0.06))
                    : (isDark ? const Color(0xFF141C2E) : Colors.white),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected
                      ? color
                      : (isDark ? const Color(0xFF243048) : const Color(0xFFE2E8F0)),
                  width: isSelected ? 1.8 : 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  // Icon Avatar
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 14),

                  // Label and tagline
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tagline,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Active check indicator
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? color : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? color
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                        width: 1.5,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                        : null,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  // --- 4. MEMBERS MANAGEMENT SECTION ---
  Widget _buildMembersSection(bool isDark, Color accentColor) {
    final suggestions = (_currentTypeData['suggestions'] as List<dynamic>?)?.cast<String>() ?? [];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141C2E) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF243048) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'GROUP MEMBERS (${_members.length})',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(100 / _members.length).toStringAsFixed(1)}% split each',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Member visual chips / list
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _members.asMap().entries.map((entry) {
              final idx = entry.key;
              final member = entry.value;
              final isYou = idx == 0;
              final memberName = member['name'] ?? 'Member';

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isYou
                      ? accentColor.withOpacity(0.15)
                      : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isYou
                        ? accentColor.withOpacity(0.4)
                        : (isDark ? const Color(0xFF243048) : const Color(0xFFE2E8F0)),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: isYou ? accentColor : AppColors.secondary,
                      child: Text(
                        memberName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      memberName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isYou ? FontWeight.w800 : FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    if (isYou) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'YOU',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                    if (!isYou) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _handleRemoveMember(idx),
                        child: Icon(
                          Icons.cancel_rounded,
                          size: 16,
                          color: isDark ? Colors.white54 : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Add Member Input Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF243048) : const Color(0xFFCBD5E1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.person_add_alt_1_rounded,
                  size: 18,
                  color: isDark ? Colors.white54 : Colors.grey.shade500,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _memberInputController,
                    focusNode: _memberFocusNode,
                    textCapitalization: TextCapitalization.words,
                    onSubmitted: (_) => _handleAddMember(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: _selectedType == 'couple'
                          ? "Add partner's name..."
                          : "Enter member name...",
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white30 : Colors.grey.shade400,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _handleAddMember,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  child: const Text(
                    'Add',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),

          // Quick suggestions chips
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Quick suggestions:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: suggestions.map((tag) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ActionChip(
                            label: Text(
                              '+ $tag',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: accentColor,
                              ),
                            ),
                            backgroundColor: accentColor.withOpacity(0.08),
                            side: BorderSide(color: accentColor.withOpacity(0.3)),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            onPressed: () => _handleAddMember(tag),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // --- 4B. PERSONAL VAULT BANNER ---
  Widget _buildPersonalVaultBanner(bool isDark, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141C2E) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF243048) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.lock_rounded, color: accentColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Private Solo Vault',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This group is private to you. No split members or balances are needed. Perfect for tracking solo daily spends, pocket money & cash log.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 5. STARTING BUDGET SECTION ---
  Widget _buildStartingBudgetSection(bool isDark, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141C2E) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF243048) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 18,
                    color: accentColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Starting Budget / Cash Kitty',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Switch.adaptive(
                value: _showBudgetField,
                activeColor: accentColor,
                onChanged: (val) {
                  setState(() {
                    _showBudgetField = val;
                    if (!val) _budgetController.clear();
                  });
                },
              ),
            ],
          ),
          if (_showBudgetField) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? const Color(0xFF243048) : const Color(0xFFCBD5E1),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    _selectedCurrency,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _budgetController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. 5000 (starting cash pool)',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white30 : Colors.grey.shade400,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- BOTTOM FLOATING ACTION BAR ---
  Widget _buildBottomBar(bool isDark, Color accentColor, Map<String, dynamic> currentType) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A).withOpacity(0.95) : Colors.white.withOpacity(0.95),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _handleCreateGroup,
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: accentColor.withOpacity(0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_selectedIcon, size: 20, color: Colors.white),
                      const SizedBox(width: 10),
                      Text(
                        'Create ${currentType['label']} Group',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
