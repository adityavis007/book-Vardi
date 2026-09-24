import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/stationery_background.dart';

/// Terms & Conditions Screen for Book Vardi app.
/// Outlines syllabus alignment, uniform sizing/exchange rules, payment terms, and user guidelines.
class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSlate,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          key: const Key('terms_back_button'),
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
          'Terms & Conditions',
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

              // 2. Terms Sections
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    _buildSectionCard(
                      number: '1',
                      title: 'Acceptance of Terms',
                      icon: Icons.check_circle_outline_rounded,
                      content:
                          'By accessing, downloading, or placing an order through the Book Vardi application or website, you agree to be bound by these Terms and Conditions and our Privacy Policy. If you do not agree with any part of these terms, please do not use our services.',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildSectionCard(
                      number: '2',
                      title: 'School Curriculum & Textbook Bundles',
                      icon: Icons.menu_book_rounded,
                      content:
                          'All textbook bundles, notebooks, and student kits listed on Book Vardi are verified against official school syllabus requirements (CBSE, ICSE, Cambridge, and State Education Boards). While we ensure 100% genuine and authorized publications, schools may update supplementary reading materials periodically.',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildSectionCard(
                      number: '3',
                      title: 'Uniform Sizing, Exchanges & Returns',
                      icon: Icons.checkroom_rounded,
                      content:
                          '• Sizing Guide: Please refer to school-specific measurement charts prior to selecting uniform sizes.\n• 7-Day Exchange: Unworn, unwashed uniforms with original tags and packaging intact can be exchanged for an alternate size within 7 days of delivery.\n• Customized Uniforms: Embroidered name tags or bespoke tailored items are eligible for replacement only in cases of manufacturing defect.',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildSectionCard(
                      number: '4',
                      title: 'Pricing, Taxes & Secure Payments',
                      icon: Icons.payments_outlined,
                      content:
                          '• All product prices are displayed in Indian Rupees (INR) and inclusive of applicable Goods and Services Tax (GST).\n• Payments are securely processed via Razorpay PCI-DSS certified gateway with end-to-end encryption for UPI, Cards, Net Banking, and Wallet credits.\n• Cash on Delivery (COD) may carry a nominal convenience/handling charge as indicated at checkout.',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildSectionCard(
                      number: '5',
                      title: 'Shipping & Delivery Timelines',
                      icon: Icons.local_shipping_outlined,
                      content:
                          '• Standard school kits are dispatched within 24–48 hours of order confirmation.\n• Bulk school-session dispatches follow scheduled delivery windows aligned with reopening dates.\n• We partner with reputable courier networks (BlueDart, Delhivery, Express) to ensure safe doorstep delivery.',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildSectionCard(
                      number: '6',
                      title: 'Cancellations & Refund Policy',
                      icon: Icons.assignment_return_outlined,
                      content:
                          '• Orders can be cancelled at zero penalty prior to warehouse dispatch.\n• Once shipped, return requests must be raised within 7 days of delivery for eligible items.\n• Approved refunds are credited directly to the original payment source within 3–5 banking business days.',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildSectionCard(
                      number: '7',
                      title: 'Intellectual Property & Platform Conduct',
                      icon: Icons.shield_outlined,
                      content:
                          'All branding, trademarks, logos, UI designs, and digital content are the exclusive intellectual property of Book Vardi Technologies Pvt. Ltd. Unauthorized scraping, copying, or misuse of catalog assets is strictly prohibited.',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildSectionCard(
                      number: '8',
                      title: 'Governing Law & Jurisdiction',
                      icon: Icons.gavel_rounded,
                      content:
                          'These terms shall be governed by and construed in accordance with the laws of India. Any disputes arising out of or in connection with the platform shall be subject to the exclusive jurisdiction of the courts in Gautam Buddha Nagar / New Delhi, India.',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _buildLegalContactFooter(),
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
              'LEGAL AGREEMENT • LAST UPDATED: SEPTEMBER 2026',
              style: AppTypography.micro.copyWith(
                color: AppColors.secondaryAmber,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 12.0),
          Text(
            'Terms of Service',
            style: AppTypography.heading1.copyWith(
              fontSize: 22.0,
              fontWeight: FontWeight.w800,
              color: AppColors.surfaceWhite,
            ),
          ),
          const SizedBox(height: 6.0),
          Text(
            'Please review our policies regarding syllabus kits, uniform exchanges, orders, and customer rights.',
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

  Widget _buildLegalContactFooter() {
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
            Icons.help_outline_rounded,
            color: AppColors.primaryNavy,
            size: 22.0,
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Questions regarding our Terms?',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryNavy,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  'If you have inquiries about school policies or return agreements, contact our legal desk at legal@bookvardi.com.',
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
