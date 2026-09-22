import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../controllers/auth_controller.dart';

/// Full-screen Pure Phone + OTP Onboarding Screen with prominent "Skip" / "Continue as Guest".
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();

  final _phoneController = TextEditingController(text: '6387977830');
  final _nameController = TextEditingController();
  final _otpController = TextEditingController(text: '123456');

  // 1 = Phone & Optional Name, 2 = 6-digit OTP
  int _currentStep = 1;

  String? _verificationId;
  int? _resendToken;
  String? _errorMessage;

  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;

  Timer? _resendTimer;
  int _countdownSeconds = 30;
  bool _canResend = false;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _phoneController.dispose();
    _nameController.dispose();
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
        _navigateToHome();
      },
    );
  }

  Future<void> _handleVerifyOtp() async {
    if (!_otpFormKey.currentState!.validate()) return;
    if (_verificationId == null) {
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
    final optionalName = _nameController.text.trim();

    final success = await authCtrl.verifyOtp(
      verificationId: _verificationId!,
      smsCode: _otpController.text.trim(),
      name: optionalName.isNotEmpty ? optionalName : null,
    );

    if (!mounted) return;

    setState(() {
      _isVerifyingOtp = false;
    });

    if (success) {
      _navigateToHome();
    } else {
      final authState = ref.read(authControllerProvider);
      setState(() {
        _errorMessage =
            authState.error ?? 'Invalid OTP entered. Please try again.';
      });
    }
  }

  void _navigateToHome() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  void _handleSkipGuest() {
    _resendTimer?.cancel();
    ref.read(authControllerProvider.notifier).continueAsGuest();
    context.go('/');
  }

  void _handleEditPhone() {
    _resendTimer?.cancel();
    setState(() {
      _currentStep = 1;
      _otpController.clear();
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSlate,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton.icon(
            key: const Key('login_skip_button'),
            onPressed: _handleSkipGuest,
            icon: const Icon(
              Icons.arrow_forward_rounded,
              size: 16,
              color: AppColors.primaryNavy,
            ),
            label: Text(
              'Skip',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primaryNavy,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                elevation: 0,
                color: AppColors.surfaceWhite,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppSpacing.roundedLarge,
                  side: BorderSide(color: AppColors.borderGray),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Brand Logo Icon
                      Center(
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryNavy,
                            borderRadius: AppSpacing.roundedMedium,
                            boxShadow: AppSpacing.elevationMd,
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            color: AppColors.secondaryAmber,
                            size: 36,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Title & Subtitle
                      Text(
                        'Book Vardi',
                        style: AppTypography.heading1.copyWith(
                          color: AppColors.primaryNavy,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Sign in to access school uniforms, book bundles, and orders',
                        style: AppTypography.bodyRegular.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Error Banner
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color:
                                AppColors.destructiveRed.withValues(alpha: 0.1),
                            borderRadius: AppSpacing.roundedSmall,
                            border: Border.all(
                              color:
                                  AppColors.destructiveRed.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.destructiveRed,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],

                      // Step 1 or Step 2
                      if (_currentStep == 1)
                        _buildStep1PhoneForm()
                      else
                        _buildStep2OtpForm(),

                      const SizedBox(height: AppSpacing.lg),

                      // Prominent "Continue as Guest" Card Button
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.backgroundSlate,
                          borderRadius: AppSpacing.roundedMedium,
                          border: Border.all(color: AppColors.borderGray),
                        ),
                        child: TextButton.icon(
                          key: const Key('login_continue_as_guest_button'),
                          onPressed: _handleSkipGuest,
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: AppColors.textDark,
                          ),
                          label: Text(
                            'Continue as Guest',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Step 1 Form: Mobile Number + Optional Full Name
  Widget _buildStep1PhoneForm() {
    return Form(
      key: _phoneFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mobile Number Field
          CustomTextField(
            key: const Key('login_phone_field'),
            label: 'Mobile Number',
            hintText: '9876543210',
            prefixText: '+91 ',
            keyboardType: TextInputType.phone,
            maxLength: 10,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            controller: _phoneController,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Mobile number is required';
              }
              final clean = v.trim().replaceAll(RegExp(r'[\s\-]'), '');
              if (clean.length != 10) {
                return 'Please enter a valid 10-digit mobile number';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Optional Full Name Field for new user creation
          CustomTextField(
            key: const Key('login_name_field'),
            label: 'Full Name (Optional)',
            hintText: 'e.g. Aditya Sharma',
            controller: _nameController,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Primary CTA: Get OTP
          CustomButton(
            key: const Key('login_get_otp_button'),
            text: 'GET OTP',
            isLoading: _isSendingOtp,
            onPressed: () => _handleSendOtp(isResend: false),
          ),
        ],
      ),
    );
  }

  /// Step 2 Form: 6-digit OTP Input
  Widget _buildStep2OtpForm() {
    return Form(
      key: _otpFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Phone Info with Edit button
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'OTP sent to +91 ${_phoneController.text}',
                style: AppTypography.bodyRegular.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                key: const Key('login_edit_phone_button'),
                onTap: _handleEditPhone,
                child: Text(
                  'Edit',
                  style: AppTypography.bodyRegular.copyWith(
                    color: AppColors.primaryNavy,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          // Generated OTP (Testing) Helper Capsule
          InkWell(
            onTap: () {
              setState(() {
                _otpController.text = '123456';
              });
            },
            borderRadius: BorderRadius.circular(12.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: const Color(0xFFFBBF24), width: 1.2),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, size: 15.0, color: Color(0xFFD97706)),
                  const SizedBox(width: 6.0),
                  const Expanded(
                    child: Text(
                      'Generated OTP (Testing):',
                      style: TextStyle(
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
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6.0),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: const Text(
                      '123456',
                      style: TextStyle(
                        fontSize: 12.5,
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
          const SizedBox(height: AppSpacing.sm),

          // 6-digit OTP Field
          CustomTextField(
            key: const Key('login_otp_field'),
            label: 'Enter 6-digit OTP',
            hintText: '• • • • • •',
            autofocus: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            controller: _otpController,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'OTP is required';
              }
              if (v.trim().length != 6) {
                return 'Enter the complete 6-digit OTP';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.xs),

          // Resend Timer & Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (!_canResend)
                Text(
                  'Resend OTP in ${_countdownSeconds}s',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                )
              else
                TextButton(
                  key: const Key('login_resend_button'),
                  onPressed: _isSendingOtp ? null : () => _handleSendOtp(isResend: true),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Resend OTP',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primaryNavy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Primary CTA: Verify & Continue
          CustomButton(
            key: const Key('login_verify_button'),
            text: 'VERIFY & CONTINUE',
            isLoading: _isVerifyingOtp,
            onPressed: _handleVerifyOtp,
          ),
        ],
      ),
    );
  }
}
