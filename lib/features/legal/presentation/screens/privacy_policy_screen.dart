import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/stationery_background.dart';

/// Privacy Policy Screen for Book Vardi app.
/// Documents student data security, payment protection via Razorpay, and user rights.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSlate,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          key: const Key('privacy_back_button'),
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primaryNavy),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
        ),
        title: Text(
          'Privacy Policy',
          style: AppTypography.heading1.copyWith(
            fontSize: 18.0,
            color: AppColors.primaryNavy,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: StationeryBackground(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // 1. Header Banner
              _buildHeaderBanner(),

              // 2. Trust Pillars
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
                child: _buildTrustPillarsGrid(),
              ),

              // 3. Privacy Sections
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    _buildSectionCard(
                      number: '1',
                      title: 'Information We Collect',
                      icon: Icons.person_pin_circle_outlined,
                      content:
                          'To ensure accurate delivery of school book kits and uniforms, we collect minimal and necessary information:\n• Account Details: Parent/Student name, verified mobile number, and email address.\n• School Affiliation: School name, branch, grade/class, and optional roll number for uniform fitting.\n• Delivery Details: Shipping address, PIN code, and contact recipient details.',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildSectionCard(
                      number: '2',
                      title: 'How We Use Your Data',
                      icon: Icons.sync_alt_rounded,
                      content:
                          'Your information is strictly utilized to:\n• Verify syllabus and uniform requirements with your affiliated school.\n• Process, pack, and deliver doorstep school orders.\n• Send real-time SMS and WhatsApp order tracking updates and GST invoices.\n• Provide dedicated customer support for size replacements or order queries.',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildSectionCard(
                      number: '3',
                      title: 'Payment & Financial Data Security',
                      icon: Icons.lock_outline_rounded,
                      content:
                          'Book Vardi prioritizes your payment security:\n• All transactions are encrypted with 256-bit SSL encryption.\n• Payments are handled directly by Razorpay (RBI Authorized & PCI-DSS Level 1 Certified).\n• Book Vardi never stores your credit/debit card numbers, CVVs, or Net Banking credentials.',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildSectionCard(
                      number: '4',
                      title: 'Student & Children Privacy Commitment',
                      icon: Icons.school_outlined,
                      content:
                          'We are deeply committed to protecting student privacy:\n• We do NOT sell, rent, or trade student data to third-party advertisers.\n• We do NOT run intrusive behavioral tracking or behavioral ad profiling.\n• Student information is strictly accessed by verified fulfillment teams for syllabus kit dispatch.',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildSectionCard(
                      number: '5',
                      title: 'Third-Party Logistics Sharing',
                      icon: Icons.local_shipping_outlined,
                      content:
                          'We only share essential shipping details (Name, Address, Phone Number) with trusted national courier partners (such as BlueDart, Delhivery, Express) strictly to facilitate doorstep parcel delivery.',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildSectionCard(
                      number: '6',
                      title: 'Data Retention & Account Deletion Rights',
                      icon: Icons.delete_sweep_outlined,
                      content:
                          'You have full control over your personal data. You may request a copy of your stored information or request permanent account deletion at any time by emailing privacy@bookvardi.com or through the Profile settings.',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _buildPrivacyOfficerCard(),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.announcementDarkBg,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24.0)),
      ),
      padding: const EdgeInsets.fromLTRB(20.0, 18.0, 20.0, 26.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: AppColors.secondaryAmber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: AppColors.secondaryAmber.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              'DATA PROTECTION • LAST UPDATED: SEPTEMBER 2026',
              style: AppTypography.micro.copyWith(
                color: AppColors.secondaryAmber,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 12.0),
          Text(
            'Your Privacy Matters to Us',
            style: AppTypography.heading1.copyWith(
              fontSize: 22.0,
              fontWeight: FontWeight.w800,
              color: AppColors.surfaceWhite,
            ),
          ),
          const SizedBox(height: 6.0),
          Text(
            'How Book Vardi safeguards and respects student, parent, and school partner data with industry-grade security.',
            style: AppTypography.bodyRegular.copyWith(
              color: AppColors.textMuted,
              fontSize: 13.0,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustPillarsGrid() {
    final pillars = [
      {'icon': Icons.lock_outline_rounded, 'title': '256-Bit SSL Encrypted'},
      {'icon': Icons.security_rounded, 'title': 'PCI-DSS Compliant'},
      {'icon': Icons.no_accounts_rounded, 'title': 'No Third-Party Ads'},
      {'icon': Icons.verified_user_outlined, 'title': 'Student-Safe Policy'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: pillars.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 2.8,
      ),
      itemBuilder: (context, index) {
        final p = pillars[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: AppColors.borderGray),
          ),
          child: Row(
            children: [
              Icon(p['icon'] as IconData, color: AppColors.primaryNavy, size: 18.0),
              const SizedBox(width: 6.0),
              Expanded(
                child: Text(
                  p['title'] as String,
                  style: AppTypography.micro.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                    fontSize: 10.5,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionCard({
    required String number,
    required String title,
    required IconData icon,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: AppSpacing.roundedMedium,
        border: Border.all(color: AppColors.borderGray),
        boxShadow: AppSpacing.elevationSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28.0,
                height: 28.0,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.categoryPillBg,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  number,
                  style: const TextStyle(
                    color: AppColors.primaryNavy,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.0,
                  ),
                ),
              ),
              const SizedBox(width: 10.0),
              Icon(icon, color: AppColors.primaryNavy, size: 20.0),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.heading2.copyWith(
                    fontSize: 15.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          Text(
            content,
            style: AppTypography.bodyRegular.copyWith(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyOfficerCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.creamCardBg,
        borderRadius: AppSpacing.roundedMedium,
        border: Border.all(color: AppColors.creamCardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.privacy_tip_outlined,
            color: AppColors.primaryNavy,
            size: 22.0,
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data Grievance & Privacy Officer',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryNavy,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  'To exercise your data privacy rights, withdraw consent, or file a query:\nEmail: privacy@bookvardi.com / grievance@bookvardi.com\nNodal Officer: Book Vardi Legal & Trust Cell, Sector 62, Noida, UP',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
