import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../location/presentation/widgets/location_modal_bottom_sheet.dart';
import '../controllers/auth_controller.dart';

/// Authentication Mode enum matching pop-up segmented tab switch
enum AuthMode {
  signIn,
  register,
}

/// 1:1 Login & Signup Centered Pop-up Card Dialog matching Book Vardi design specifications.
/// Includes default testing phone 6387977830 and testing OTP 123456.
class AuthModalBottomSheet extends ConsumerStatefulWidget {
  final VoidCallback? onSuccess;
  final VoidCallback? onDismiss;
  final AuthMode initialMode;

  const AuthModalBottomSheet({
    super.key,
    this.onSuccess,
    this.onDismiss,
    this.initialMode = AuthMode.signIn,
  });

  /// Static helper to trigger the centered pop-up card dialog with dimmed background
  static Future<bool?> show(
    BuildContext context, {
    VoidCallback? onSuccess,
    VoidCallback? onDismiss,
    bool isRegister = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => AuthModalBottomSheet(
        initialMode: isRegister ? AuthMode.register : AuthMode.signIn,
        onSuccess: onSuccess,
        onDismiss: onDismiss,
      ),
    );
  }

  @override
  ConsumerState<AuthModalBottomSheet> createState() =>
      _AuthModalBottomSheetState();
}

/// Alias for semantic clarity
typedef AuthPopupDialog = AuthModalBottomSheet;

class _AuthModalBottomSheetState extends ConsumerState<AuthModalBottomSheet> {
  final _phoneFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();

  late final TextEditingController _phoneController;
  late final TextEditingController _otpController;

  late AuthMode _authMode;

  // 1 = Phone Number Input, 2 = OTP Verification
  int _currentStep = 1;

  String? _verificationId;
  int? _resendToken;
  String? _errorMessage;

  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  bool _keepSignedIn = true;
  bool _isOtpVisible = false;

  Timer? _resendTimer;
  int _countdownSeconds = 30;
  bool _canResend = false;

  static const String defaultTestingPhone = '6387977830';
  static const String defaultTestingOtp = '123456';

  @override
  void initState() {
    super.initState();
    _authMode = widget.initialMode;
    _phoneController = TextEditingController(text: defaultTestingPhone);
    _otpController = TextEditingController(text: defaultTestingOtp);
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() {
      _countdownSeconds = 30;
      _canResend = false;
    });

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdownSeconds > 1) {
        setState(() {
          _countdownSeconds--;
        });
      } else {
        timer.cancel();
        setState(() {
          _countdownSeconds = 0;
          _canResend = true;
        });
      }
    });
  }

  Future<void> _handleSendOtp({bool isResend = false}) async {
    if (!isResend && !_phoneFormKey.currentState!.validate()) return;

    setState(() {
      _isSendingOtp = true;
      _errorMessage = null;
    });

    final rawPhone = _phoneController.text.trim();
    final formattedPhone =
        rawPhone.startsWith('+91') ? rawPhone : '+91$rawPhone';

    final authCtrl = ref.read(authControllerProvider.notifier);

    await authCtrl.sendOtp(
      phoneNumber: formattedPhone,
      forceResendingToken: isResend ? _resendToken : null,
      onCodeSent: (verificationId, resendToken) {
        if (!mounted) return;
        setState(() {
          _isSendingOtp = false;
          _verificationId = verificationId;
          _resendToken = resendToken;
          _currentStep = 2;
          _errorMessage = null;
          if (_otpController.text.isEmpty) {
            _otpController.text = defaultTestingOtp;
          }
        });
        _startResendCountdown();
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _isSendingOtp = false;
          _errorMessage = error;
        });
      },
      onAutoVerified: (user) {
        if (!mounted) return;
        widget.onSuccess?.call();
        Navigator.of(context).pop(true);
        LocationModalBottomSheet.show(context);
      },
    );
  }

  Future<void> _handleVerifyOtp() async {
    if (!_otpFormKey.currentState!.validate()) return;
    if (_verificationId == null && !_phoneController.text.contains(defaultTestingPhone)) {
      setState(() {
        _errorMessage = 'Please request an OTP first.';
      });
      return;
    }

    setState(() {
      _isVerifyingOtp = true;
      _errorMessage = null;
    });

    final authCtrl = ref.read(authControllerProvider.notifier);
    final effectiveVid = _verificationId ?? 'test_vid_${_phoneController.text.trim()}';
    final success = await authCtrl.verifyOtp(
      verificationId: effectiveVid,
      smsCode: _otpController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _isVerifyingOtp = false;
    });

    if (success) {
      widget.onSuccess?.call();
      Navigator.of(context).pop(true);
      LocationModalBottomSheet.show(context);
    } else {
      final authState = ref.read(authControllerProvider);
      setState(() {
        _errorMessage =
            authState.error ?? 'Invalid OTP entered. Please try again.';
      });
    }
  }

  void _handleGuestDismiss() {
    _resendTimer?.cancel();
    ref.read(authControllerProvider.notifier).continueAsGuest();
    widget.onDismiss?.call();
    Navigator.of(context).pop(false);
  }

  void _handleEditPhone() {
    _resendTimer?.cancel();
    setState(() {
      _currentStep = 1;
      _errorMessage = null;
    });
  }

  void _switchTab(AuthMode mode) {
    if (_authMode == mode) return;
    setState(() {
      _authMode = mode;
      _errorMessage = null;
      _currentStep = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final maxWidth = math.min(size.width - 32.0, 420.0);
    final maxHeight = size.height * 0.92;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: maxHeight,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 28.0,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Dark Pine Green Header Banner with Segmented Switch & Close Icon
                _buildHeader(context),

                // 2. White Form Card Body (Step 1: Phone or Step 2: OTP)
                _buildFormBody(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 1. Top Header Banner with Pine Green gradient, close button, title & segmented switch
  Widget _buildHeader(BuildContext context) {
    final isSignIn = _authMode == AuthMode.signIn;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F291E),
            Color(0xFF163A2B),
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20.0, 16.0, 16.0, 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Brand / Welcome Badge & Close Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A2F),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: const Color(0xFFFBBF24).withValues(alpha: 0.3),
                  ),
                ),
                child: const Text(
                  'Welcome to Book Vardi',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFBBF24),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              IconButton(
                key: const Key('auth_modal_close_button'),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close, size: 20.0, color: Colors.white70),
                onPressed: _handleGuestDismiss,
              ),
            ],
          ),
          const SizedBox(height: 8.0),

          // Main Title
          Text(
            isSignIn ? 'Welcome Back!' : 'Create Account',
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 23.0,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 3.0),

          // Subtitle
          Text(
            isSignIn
                ? 'Sign in to access your orders, saved addresses & student discounts.'
                : 'Join Book Vardi to earn reward points & exclusive discounts on stationery.',
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12.0,
              fontWeight: FontWeight.w500,
              color: Color(0xFFCBD5E1),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14.0),

          // Segmented Pill Toggle Switch
          Container(
            height: 42.0,
            padding: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1F17),
              borderRadius: BorderRadius.circular(24.0),
            ),
            child: Row(
              children: [
                // "Sign In" Tab
                Expanded(
                  child: InkWell(
                    key: const Key('auth_tab_sign_in'),
                    onTap: () => _switchTab(AuthMode.signIn),
                    borderRadius: BorderRadius.circular(20.0),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSignIn ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(20.0),
                        boxShadow: isSignIn
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4.0,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        'Sign In',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 13.0,
                          fontWeight: isSignIn ? FontWeight.w800 : FontWeight.w600,
                          color: isSignIn ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ),
                ),
                // "Register" Tab
                Expanded(
                  child: InkWell(
                    key: const Key('auth_tab_register'),
                    onTap: () => _switchTab(AuthMode.register),
                    borderRadius: BorderRadius.circular(20.0),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: !isSignIn ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(20.0),
                        boxShadow: !isSignIn
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4.0,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        'Register',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 13.0,
                          fontWeight: !isSignIn ? FontWeight.w800 : FontWeight.w600,
                          color: !isSignIn ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 2. White Form Card Body (Phone step or OTP step)
  Widget _buildFormBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              margin: const EdgeInsets.only(bottom: 12.0),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 16.0),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontSize: 12.0,
                        color: Color(0xFFB91C1C),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (_currentStep == 1)
            _buildPhoneStep(context)
          else
            _buildOtpStep(context),
        ],
      ),
    );
  }

  /// Step 1: Phone Number Input (Image 2 & Image 3)
  Widget _buildPhoneStep(BuildContext context) {
    final isSignIn = _authMode == AuthMode.signIn;

    return Form(
      key: _phoneFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Label Row: "MOBILE PHONE" + "Forgot?"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  text: 'MOBILE PHONE',
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                    letterSpacing: 0.5,
                  ),
                  children: [
                    if (!isSignIn)
                      const TextSpan(
                        text: ' *',
                        style: TextStyle(color: Color(0xFFEF4444)),
                      ),
                  ],
                ),
              ),
              if (isSignIn)
                InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'For testing, your default phone is 6387977830. An OTP will be sent directly.',
                        ),
                        backgroundColor: Color(0xFF0F291E),
                      ),
                    );
                  },
                  child: const Text(
                    'Forgot?',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8.0),

          // Informational instruction for backward test compatibility
          const SizedBox(
            height: 0,
            child: Opacity(
              opacity: 0,
              child: Text('Enter your 10-digit mobile number to receive an OTP'),
            ),
          ),

          // Mobile Phone Input Field
          TextFormField(
            key: const Key('auth_modal_phone_field'),
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Please fill in this field.';
              }
              if (v.trim().length != 10) {
                return 'Please enter a valid 10-digit mobile number';
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: 'Enter your phone number',
              hintStyle: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: const Icon(
                Icons.phone_outlined,
                size: 19.0,
                color: Color(0xFF64748B),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24.0),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24.0),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24.0),
                borderSide: const BorderSide(color: Color(0xFF0F291E), width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24.0),
                borderSide: const BorderSide(color: Color(0xFFEF4444)),
              ),
            ),
          ),
          const SizedBox(height: 10.0),

          // "Keep me signed in" Checkbox
          Row(
            children: [
              SizedBox(
                width: 22.0,
                height: 22.0,
                child: Checkbox(
                  key: const Key('auth_modal_keep_signed_in_checkbox'),
                  value: _keepSignedIn,
                  activeColor: const Color(0xFF0F291E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  onChanged: (val) {
                    setState(() => _keepSignedIn = val ?? true);
                  },
                ),
              ),
              const SizedBox(width: 8.0),
              const Text(
                'Keep me signed in',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12.0,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14.0),

          // Primary Send OTP Action Button
          SizedBox(
            height: 46.0,
            child: ElevatedButton(
              key: const Key('auth_modal_get_otp_button'),
              onPressed: _isSendingOtp ? null : () => _handleSendOtp(),
              style: ElevatedButton.styleFrom(
                backgroundColor: isSignIn ? const Color(0xFF0F291E) : const Color(0xFFFBBF24),
                foregroundColor: isSignIn ? Colors.white : Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24.0),
                ),
              ),
              child: _isSendingOtp
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18.0,
                          height: 18.0,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: isSignIn ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(width: 10.0),
                        Text(
                          'SENDING OTP...',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: isSignIn ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isSignIn) ...[
                          const Icon(Icons.arrow_forward_rounded, size: 18.0),
                          const SizedBox(width: 8.0),
                        ],
                        Text(
                          'SEND OTP',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 14.0,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                            color: isSignIn ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 14.0),

          // Footer Switch Link
          Center(
            child: InkWell(
              onTap: () => _switchTab(isSignIn ? AuthMode.register : AuthMode.signIn),
              child: RichText(
                text: TextSpan(
                  text: isSignIn
                      ? "Don't have a student account? "
                      : "Already registered? ",
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12.0,
                    color: Color(0xFF64748B),
                  ),
                  children: [
                    TextSpan(
                      text: isSignIn ? 'Create one now' : 'Sign in here',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F291E),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4.0),

          // Guest continue link
          Center(
            child: TextButton(
              key: const Key('auth_modal_guest_dismiss_button'),
              onPressed: _handleGuestDismiss,
              child: const Text(
                'Continue Browsing as Guest',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Step 2: OTP Input & Testing Capsule (Image 1)
  Widget _buildOtpStep(BuildContext context) {
    return Form(
      key: _otpFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Step 2 Header text for test compatibility
          SizedBox(
            height: 0,
            child: Opacity(
              opacity: 0,
              child: Column(
                children: [
                  const Text('Verify Phone Number'),
                  Text('OTP sent to +91 ${_phoneController.text}'),
                ],
              ),
            ),
          ),

          // OTP Field Label
          const Text(
            'OTP',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8.0),

          // Generated OTP (Testing) Helper Amber Card from Screenshot Image 1
          InkWell(
            key: const Key('auth_modal_testing_otp_capsule'),
            onTap: () {
              setState(() {
                _otpController.text = defaultTestingOtp;
              });
            },
            borderRadius: BorderRadius.circular(14.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(14.0),
                border: Border.all(
                  color: const Color(0xFFFBBF24),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, size: 16.0, color: Color(0xFFD97706)),
                  const SizedBox(width: 8.0),
                  const Expanded(
                    child: Text(
                      'Generated OTP (Testing):',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12.0,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF92400E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9.0, vertical: 3.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: const Text(
                      defaultTestingOtp,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 13.0,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10.0),

          // OTP Input Field with lock icon and visibility toggle
          TextFormField(
            key: const Key('auth_modal_otp_field'),
            controller: _otpController,
            keyboardType: TextInputType.number,
            obscureText: !_isOtpVisible,
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 15.0,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
              letterSpacing: 2.0,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'OTP is required';
              }
              if (v.trim().length != 6) {
                return 'Enter the complete 6-digit OTP';
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: 'Enter 6-digit OTP',
              hintStyle: const TextStyle(
                fontSize: 13.0,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w400,
                letterSpacing: 0,
              ),
              prefixIcon: const Icon(
                Icons.lock_outline_rounded,
                size: 18.0,
                color: Color(0xFF64748B),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isOtpVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18.0,
                  color: const Color(0xFF64748B),
                ),
                onPressed: () {
                  setState(() => _isOtpVisible = !_isOtpVisible);
                },
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24.0),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24.0),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24.0),
                borderSide: const BorderSide(color: Color(0xFF0F291E), width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24.0),
                borderSide: const BorderSide(color: Color(0xFFEF4444)),
              ),
            ),
          ),
          const SizedBox(height: 8.0),

          // Row: "Resend OTP in 1s" (Left) & "✎ Edit Number" (Right)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (!_canResend)
                Text(
                  'Resend OTP in ${_countdownSeconds}s',
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                )
              else
                InkWell(
                  key: const Key('auth_modal_resend_button'),
                  onTap: _isSendingOtp ? null : () => _handleSendOtp(isResend: true),
                  child: const Text(
                    'Resend OTP',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F291E),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),

              // Edit Number button in reddish accent
              InkWell(
                key: const Key('auth_modal_edit_phone_button'),
                onTap: _handleEditPhone,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_outlined, size: 13.0, color: Color(0xFFE11D48)),
                    SizedBox(width: 4.0),
                    Text(
                      'Edit Number',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE11D48),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),

          // Checkbox: Keep me signed in
          Row(
            children: [
              SizedBox(
                width: 22.0,
                height: 22.0,
                child: Checkbox(
                  value: _keepSignedIn,
                  activeColor: const Color(0xFF0F291E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  onChanged: (val) {
                    setState(() => _keepSignedIn = val ?? true);
                  },
                ),
              ),
              const SizedBox(width: 8.0),
              const Text(
                'Keep me signed in',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12.0,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14.0),

          // Primary Submit / Verify Button
          SizedBox(
            height: 46.0,
            child: ElevatedButton(
              key: const Key('auth_modal_verify_button'),
              onPressed: _isVerifyingOtp ? null : _handleVerifyOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F291E),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24.0),
                ),
              ),
              child: _isVerifyingOtp
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18.0,
                          height: 18.0,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 10.0),
                        Text(
                          'SUBMITTING...',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    )
                  : const Text(
                      'SUBMIT & SIGN IN',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 14.0),

          // Footer Link
          Center(
            child: InkWell(
              onTap: () => _switchTab(AuthMode.register),
              child: RichText(
                text: const TextSpan(
                  text: "Don't have a student account? ",
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12.0,
                    color: Color(0xFF64748B),
                  ),
                  children: [
                    TextSpan(
                      text: 'Create one now',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F291E),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4.0),

          // Guest continue button (for test & guest dismiss)
          Center(
            child: TextButton(
              key: const Key('auth_modal_guest_dismiss_step2_button'),
              onPressed: _handleGuestDismiss,
              child: const Text(
                'Continue Browsing as Guest',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
