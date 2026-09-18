import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

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
    serverClientId: '3441332026-gispcer16grdaqhm36lnm071ilj4s1kl.apps.googleusercontent.com',
  );

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

  Future<void> _handleSendOtp() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final target = _isPhoneMode ? _phoneController.text.trim() : _emailController.text.trim();

    if (target.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter your ${_isPhoneMode ? 'phone number' : 'email address'}')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isPhoneMode) {
        // Prepend code if needed (assuming user enters country code, or default to +91)
        final fullPhone = target.startsWith('+') ? target : '+91$target';
        await authService.requestPhoneOtp(fullPhone);
      } else {
        await authService.requestEmailOtp(target);
      }
      setState(() => _isOtpSent = true);
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP sent successfully!'), backgroundColor: AppColors.positive),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.negative),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleVerifyOtp() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final otp = _otpController.text.trim();

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a 6-digit code')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isPhoneMode) {
        final rawPhone = _phoneController.text.trim();
        final fullPhone = rawPhone.startsWith('+') ? rawPhone : '+91$rawPhone';
        await authService.verifyPhoneOtp(fullPhone, otp);
      } else {
        final email = _emailController.text.trim();
        await authService.verifyEmailOtp(email, otp);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.negative),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

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
          const SnackBar(content: Text('Failed to get Google ID token'), backgroundColor: AppColors.negative),
        );
        setState(() => _isLoading = false);
        return;
      }
      await Provider.of<AuthService>(context, listen: false).loginWithGoogle(credential);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign-in failed: $e'), backgroundColor: AppColors.negative),
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
            image: const AssetImage('assets/images/radial_background.png'), // Fallback layout glow
            onError: (_, __) {},
            fit: BoxFit.cover,
            opacity: 0.1,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Icon and App Title
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: AppColors.brandGradient,
                  ).createShader(bounds),
                  child: const Icon(
                    Icons.explore_rounded,
                    size: 72,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'TripBook',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                    letterSpacing: -0.8,
                  ),
                ),
                Text(
                  'Premium Group Finance',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                  ),
                ),
                const SizedBox(height: 36),

                // Main Onboarding Login Card
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!_isOtpSent) ...[
                        // Phone / Email Tab Toggle Switches
                        Row(
                          children: [
                            Expanded(
                              child: _buildTabButton('Phone', _isPhoneMode, () {
                                setState(() => _isPhoneMode = true);
                              }),
                            ),
                            Expanded(
                              child: _buildTabButton('Email', !_isPhoneMode, () {
                                setState(() => _isPhoneMode = false);
                              }),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Form input
                        Text(
                          _isPhoneMode ? 'Enter Phone Number' : 'Enter Email Address',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _isPhoneMode ? _phoneController : _emailController,
                          keyboardType: _isPhoneMode ? TextInputType.phone : TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: _isPhoneMode ? '99999 99999' : 'name@domain.com',
                            prefixText: _isPhoneMode ? '+91 ' : null,
                            filled: true,
                            fillColor: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
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
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Send Verification OTP', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ] else ...[
                        // Verify OTP Screen Inputs
                        Text(
                          'Enter 6-Digit Code',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Sent to ${_isPhoneMode ? _phoneController.text : _emailController.text}',
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
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 10),
                          decoration: InputDecoration(
                            counterText: '',
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
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Verify & Continue', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: _timerSeconds > 0 ? null : _handleSendOtp,
                              child: Text(
                                _timerSeconds > 0 ? 'Resend OTP in ${_timerSeconds}s' : 'Resend OTP',
                                style: TextStyle(
                                  color: _timerSeconds > 0
                                      ? (isDark ? AppColors.textDarkMuted : AppColors.textLightMuted)
                                      : AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const Text('•'),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isOtpSent = false;
                                  _otpController.clear();
                                });
                              },
                              child: const Text('Change Details', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ],

                      // Google Login Section
                      if (!_isOtpSent) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: Divider(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text('OR', style: TextStyle(color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted, fontSize: 12)),
                            ),
                            Expanded(child: Divider(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: _isLoading ? null : _handleGoogleSignIn,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.g_mobiledata_rounded, size: 24, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Sign in with Google',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.textDarkMain : AppColors.textLightMain,
                                ),
                              ),
                            ],
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
    );
  }

  Widget _buildTabButton(String text, bool isActive, VoidCallback onPressed) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
            color: isActive
                ? AppColors.primary
                : isDark
                    ? AppColors.textDarkMuted
                    : AppColors.textLightMuted,
          ),
        ),
      ),
    );
  }

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
          padding: const EdgeInsets.symmetric(vertical: 16),
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
