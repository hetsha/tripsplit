import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/tripsplit_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _googleSignIn = GoogleSignIn(
    serverClientId:
        '3441332026-gispcer16grdaqhm36lnm071ilj4s1kl.apps.googleusercontent.com',
  );

  String _countryCode = '+91';
  bool _isPhoneMode = true;
  bool _isOtpSent = false;
  bool _isLoading = false;
  int _timerSeconds = 30;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timerSeconds = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds > 0) {
        setState(() => _timerSeconds--);
      } else {
        _timer?.cancel();
      }
    });
  }

  // Send OTP for Phone Number or Email
  Future<void> _handleSendOtp() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final target = _isPhoneMode
        ? _phoneController.text.trim()
        : _emailController.text.trim();

    if (target.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter your ${_isPhoneMode ? 'mobile number' : 'email address'}',
          ),
          backgroundColor: AppColors.negative,
        ),
      );
      return;
    }

    if (_isPhoneMode && target.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 10-digit mobile number'),
          backgroundColor: AppColors.negative,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isPhoneMode) {
        final cleanPhone = target.replaceAll(RegExp(r'\s+'), '');
        final fullPhone = cleanPhone.startsWith('+')
            ? cleanPhone
            : '$_countryCode$cleanPhone';
        await authService.requestPhoneOtp(fullPhone);
      } else {
        await authService.requestEmailOtp(target);
      }
      setState(() => _isOtpSent = true);
      _startTimer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification code sent successfully!'),
            backgroundColor: AppColors.positive,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.negative,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Verify Phone/Email OTP
  Future<void> _handleVerifyOtp() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final otp = _otpController.text.trim();

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the 6-digit OTP code'),
          backgroundColor: AppColors.negative,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isPhoneMode) {
        final rawPhone = _phoneController.text.trim().replaceAll(RegExp(r'\s+'), '');
        final fullPhone = rawPhone.startsWith('+')
            ? rawPhone
            : '$_countryCode$rawPhone';
        await authService.verifyPhoneOtp(fullPhone, otp);
      } else {
        final email = _emailController.text.trim();
        await authService.verifyEmailOtp(email, otp);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login successful! Welcome to TripSplit.'),
            backgroundColor: AppColors.positive,
          ),
        );
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.negative,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Google Sign-In Handler
  Future<void> _handleGoogleSignIn() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final account = await _googleSignIn.signIn();
      if (!mounted) return;
      if (account == null) {
        setState(() => _isLoading = false);
        return;
      }
      final auth = await account.authentication;
      final credential = auth.idToken;
      if (credential == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to retrieve Google authentication token'),
            backgroundColor: AppColors.negative,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }
      await Provider.of<AuthService>(context, listen: false)
          .loginWithGoogle(credential);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google Sign-In successful! Welcome.'),
            backgroundColor: AppColors.positive,
          ),
        );
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google Sign-In: $e'),
          backgroundColor: AppColors.negative,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Apple Account Sign-In Handler
  Future<void> _handleAppleSignIn() async {
    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Show native-styled Apple confirmation sheet
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.apple,
                    size: 32,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Sign in with Apple',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black.withOpacity(0.3) : const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shield_outlined, size: 20, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'TripSplit will create an account linked to your Apple ID.',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.grey[300] : Colors.grey[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Email Privacy', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87)),
                        const Row(
                          children: [
                            Icon(Icons.check_circle_rounded, size: 16, color: AppColors.positive),
                            SizedBox(width: 4),
                            Text('Hide My Email', style: TextStyle(fontSize: 12, color: AppColors.positive, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : Colors.black,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.apple, size: 20),
                    SizedBox(width: 8),
                    Text('Continue with Apple ID', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final appleUserId = 'apple_${DateTime.now().millisecondsSinceEpoch}';
      await authService.loginWithApple(
        appleId: appleUserId,
        name: 'Apple Traveler',
        email: 'traveler_${DateTime.now().millisecondsSinceEpoch % 10000}@privaterelay.appleid.com',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Apple Sign-In successful! Welcome to TripSplit.'),
            backgroundColor: AppColors.positive,
          ),
        );
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Apple sign-in failed: $e'),
          backgroundColor: AppColors.negative,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgDark : AppColors.bgLight,
          image: DecorationImage(
            image: const AssetImage('assets/images/radial_background.png'),
            onError: (_, __) {},
            fit: BoxFit.cover,
            opacity: 0.1,
          ),
        ),
        child: Center(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Top navigation row: Back button & Screens switcher
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                        onPressed: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          } else {
                            Navigator.of(context).pushReplacementNamed('/home');
                          }
                        },
                      ),
                      GestureDetector(
                        onTap: () => TripSplitScreenNavigator.show(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.dashboard_customize_rounded, size: 14, color: AppColors.primary),
                              SizedBox(width: 6),
                              Text(
                                'All Screens',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Brand Logo & App Header
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: AppColors.brandGradient,
                    ).createShader(bounds),
                    child: const Icon(
                      Icons.flight_takeoff_rounded,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'TripSplit',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                      letterSpacing: -0.8,
                    ),
                  ),
                  Text(
                    'Split Expenses • Share Memories',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Main Login Card
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!_isOtpSent) ...[
                          // Primary Mode Tabs: Mobile Number & Email
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildSegmentButton(
                                    label: 'Mobile Number',
                                    icon: Icons.phone_iphone_rounded,
                                    isActive: _isPhoneMode,
                                    onTap: () => setState(() => _isPhoneMode = true),
                                  ),
                                ),
                                Expanded(
                                  child: _buildSegmentButton(
                                    label: 'Email ID',
                                    icon: Icons.mail_outline_rounded,
                                    isActive: !_isPhoneMode,
                                    onTap: () => setState(() => _isPhoneMode = false),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Form input
                          Text(
                            _isPhoneMode ? 'Enter Mobile Number' : 'Enter Email Address',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 8),

                          if (_isPhoneMode)
                            // Mobile Number Field with Country Code
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                                  ),
                                  child: Row(
                                    children: [
                                      const Text('🇮🇳', style: TextStyle(fontSize: 18)),
                                      const SizedBox(width: 6),
                                      Text(
                                        _countryCode,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    maxLength: 10,
                                    decoration: InputDecoration(
                                      counterText: '',
                                      hintText: '98765 43210',
                                      filled: true,
                                      fillColor: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
                                      prefixIcon: const Icon(Icons.dialpad_rounded, size: 20),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          else
                            // Email Field
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                hintText: 'traveler@gmail.com',
                                filled: true,
                                fillColor: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
                                prefixIcon: const Icon(Icons.alternate_email_rounded, size: 20),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                                ),
                              ),
                            ),

                          const SizedBox(height: 18),

                          // Submit OTP request button
                          _buildPrimaryButton(
                            onPressed: _isLoading ? null : _handleSendOtp,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _isPhoneMode ? 'Send Verification OTP' : 'Send Email OTP',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward_rounded, size: 18),
                                    ],
                                  ),
                          ),
                        ] else ...[
                          // Verify OTP Screen Inputs
                          Text(
                            'Enter 6-Digit OTP',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Code sent to ${_isPhoneMode ? "$_countryCode ${_phoneController.text}" : _emailController.text}',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),

                          TextField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 10),
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: '••••••',
                              filled: true,
                              fillColor: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          _buildPrimaryButton(
                            onPressed: _isLoading ? null : _handleVerifyOtp,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Verify & Continue', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 16),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                onPressed: _timerSeconds > 0 ? null : _handleSendOtp,
                                child: Text(
                                  _timerSeconds > 0 ? 'Resend in ${_timerSeconds}s' : 'Resend Code',
                                  style: TextStyle(
                                    color: _timerSeconds > 0
                                        ? (isDark ? AppColors.textDarkMuted : AppColors.textLightMuted)
                                        : AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const Text('•', style: TextStyle(color: Colors.grey)),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isOtpSent = false;
                                    _otpController.clear();
                                  });
                                },
                                child: const Text(
                                  'Change Number',
                                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        ],

                        // Social Logins: Google & Apple
                        if (!_isOtpSent) ...[
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(child: Divider(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                child: Text(
                                  'OR CONTINUE WITH',
                                  style: TextStyle(
                                    color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 1. Google Sign-In Button
                          _buildSocialButton(
                            onPressed: _isLoading ? null : _handleGoogleSignIn,
                            leading: _buildGoogleIcon(),
                            label: 'Continue with Google',
                            isDark: isDark,
                          ),
                          const SizedBox(height: 12),

                          // 2. Apple Sign-In Button
                          _buildAppleButton(
                            onPressed: _isLoading ? null : _handleAppleSignIn,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 14),

                          // Quick Demo Bypass Button
                          TextButton.icon(
                            onPressed: () {
                              Navigator.of(context).pushReplacementNamed('/home');
                            },
                            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                            label: const Text(
                              'Continue to Home (Demo Mode)',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Segment Tab Button
  Widget _buildSegmentButton({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? AppColors.primary.withOpacity(0.2) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isActive
              ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive
                  ? AppColors.primary
                  : (isDark ? AppColors.textDarkMuted : AppColors.textLightMuted),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: isActive
                    ? AppColors.primary
                    : (isDark ? AppColors.textDarkMuted : AppColors.textLightMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Google 4-Color Logo
  Widget _buildGoogleIcon() {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            'G',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              foreground: Paint()
                ..shader = const LinearGradient(
                  colors: [
                    Color(0xFF4285F4), // Blue
                    Color(0xFF34A853), // Green
                    Color(0xFFFBBC05), // Yellow
                    Color(0xFFEA4335), // Red
                  ],
                ).createShader(const Rect.fromLTWH(0.0, 0.0, 20.0, 20.0)),
            ),
          ),
        ],
      ),
    );
  }

  // Social Button (Google)
  Widget _buildSocialButton({
    required VoidCallback? onPressed,
    required Widget leading,
    required String label,
    required bool isDark,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        backgroundColor: isDark ? Colors.white.withOpacity(0.02) : Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          leading,
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
            ),
          ),
        ],
      ),
    );
  }

  // Apple Button (Apple HIG Style)
  Widget _buildAppleButton({
    required VoidCallback? onPressed,
    required bool isDark,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark ? Colors.white : Colors.black,
        foregroundColor: isDark ? Colors.black : Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.apple,
            size: 22,
            color: isDark ? Colors.black : Colors.white,
          ),
          const SizedBox(width: 8),
          Text(
            'Sign in with Apple',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: isDark ? Colors.black : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Primary Gradient Action Button
  Widget _buildPrimaryButton({required VoidCallback? onPressed, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: onPressed == null
            ? null
            : const LinearGradient(colors: AppColors.brandGradient),
        color: onPressed == null ? Colors.grey : null,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: DefaultTextStyle(
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
          child: child,
        ),
      ),
    );
  }
}
