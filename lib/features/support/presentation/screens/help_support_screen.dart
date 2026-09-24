import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/stationery_background.dart';

/// Help & Support Screen for Book Vardi app.
/// Provides helpline contact options, categorized FAQs, and an interactive query submission form.
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _messageController = TextEditingController();

  String _selectedCategory = 'Order & Delivery';
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Order & Delivery',
    'Uniform Sizing & Exchange',
    'School Books & Kit Issue',
    'Payment & Refund',
    'Other Inquiries',
  ];

  final List<Map<String, String>> _faqs = [
    {
      'question': 'How do I track my school book kit or uniform order?',
      'answer':
          'You can track live delivery status in the "Your Order" section from your Account tab or by entering your Order ID on the tracking screen.',
    },
    {
      'question': 'What if the uniform size does not fit my child?',
      'answer':
          'We offer a 7-day hassle-free size exchange policy for all unworn school uniforms with original tags intact.',
    },
    {
      'question': 'Are the textbooks aligned with the official school syllabus?',
      'answer':
          'Yes, 100%! All textbook bundles and syllabus kits are sourced directly in strict adherence with your affiliated school board (CBSE/ICSE/State).',
    },
    {
      'question': 'How long does standard delivery take?',
      'answer':
          'Standard delivery takes 2–4 business days within the same city and 3–6 business days for outstation shipments. School-batch dispatches are delivered per school schedule.',
    },
    {
      'question': 'How can I request a cancellation or refund?',
      'answer':
          'Orders can be cancelled prior to warehouse dispatch from the Order Details page. Refunds are processed back to the original payment source within 3–5 business days.',
    },
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _handleSubmitQuery() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    _nameController.clear();
    _contactController.clear();
    _messageController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.successGreen,
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20.0),
            SizedBox(width: 8.0),
            Expanded(
              child: Text(
                'Thank you! Your query has been received. Our support team will reach out within 24 hours.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    );
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard!'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSlate,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          key: const Key('help_support_back_button'),
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
          'Help & Support',
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
              // 1. Hero Header Banner
              _buildHeroBanner(),

              // 2. Direct Contact Channels
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildContactChannelsCard(),
                    const SizedBox(height: AppSpacing.lg),

                    // 3. Frequently Asked Questions (Accordion)
                    _buildFaqSection(),
                    const SizedBox(height: AppSpacing.lg),

                    // 4. Send Us a Message Form
                    _buildContactForm(),
                    const SizedBox(height: AppSpacing.lg),

                    // 5. Operating Hours & Address Info
                    _buildOperatingHoursCard(),
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

  Widget _buildHeroBanner() {
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.headset_mic_rounded,
                  color: AppColors.secondaryAmber,
                  size: 14.0,
                ),
                const SizedBox(width: 4.0),
                Text(
                  '24/7 STUDENT & PARENT SUPPORT',
                  style: AppTypography.micro.copyWith(
                    color: AppColors.secondaryAmber,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12.0),
          RichText(
            text: TextSpan(
              style: AppTypography.heading1.copyWith(
                fontSize: 22.0,
                fontWeight: FontWeight.w800,
                color: AppColors.surfaceWhite,
                height: 1.25,
              ),
              children: const [
                TextSpan(text: 'How can we help you '),
                TextSpan(
                  text: 'today?',
                  style: TextStyle(color: AppColors.secondaryAmber),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6.0),
          Text(
            'Get quick assistance for school uniform sizing, textbook kit deliveries, payments, and order tracking.',
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

  Widget _buildContactChannelsCard() {
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
          Text(
            'Quick Contact Options',
            style: AppTypography.heading2.copyWith(
              fontSize: 16.0,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12.0),
          _buildChannelTile(
            icon: Icons.phone_in_talk_rounded,
            title: 'Call Support Helpline',
            subtitle: '+91 98765 43210 (Toll Free)',
            tag: 'CALL NOW',
            onTap: () => _copyToClipboard('+919876543210', 'Phone number'),
          ),
          const Divider(height: 16.0, color: AppColors.borderGray),
          _buildChannelTile(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'WhatsApp Assistance',
            subtitle: '+91 98765 43210 (Mon-Sat, 9AM-7PM)',
            tag: 'CHAT',
            onTap: () => _copyToClipboard('+919876543210', 'WhatsApp number'),
          ),
          const Divider(height: 16.0, color: AppColors.borderGray),
          _buildChannelTile(
            icon: Icons.mail_outline_rounded,
            title: 'Email Support',
            subtitle: 'support@bookvardi.com',
            tag: 'EMAIL',
            onTap: () => _copyToClipboard('support@bookvardi.com', 'Email address'),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String tag,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Container(
              width: 42.0,
              height: 42.0,
              decoration: BoxDecoration(
                color: AppColors.categoryPillBg,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Icon(icon, color: AppColors.primaryNavy, size: 22.0),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                      fontSize: 13.5,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: AppColors.secondaryAmber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6.0),
                border: Border.all(
                  color: AppColors.secondaryAmber.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                tag,
                style: AppTypography.micro.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  fontSize: 9.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqSection() {
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
              const Icon(
                Icons.help_outline_rounded,
                color: AppColors.primaryNavy,
                size: 20.0,
              ),
              const SizedBox(width: 8.0),
              Text(
                'Frequently Asked Questions',
                style: AppTypography.heading2.copyWith(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          ..._faqs.map((faq) => Container(
                margin: const EdgeInsets.only(top: 8.0),
                child: Material(
                  color: AppColors.backgroundSlate,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    side: const BorderSide(color: AppColors.borderGray),
                  ),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 12.0),
                    childrenPadding: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 12.0),
                    title: Text(
                      faq['question']!,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.0,
                        color: AppColors.textDark,
                      ),
                    ),
                    iconColor: AppColors.primaryNavy,
                    collapsedIconColor: AppColors.textSecondary,
                    children: [
                      Text(
                        faq['answer']!,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12.0,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildContactForm() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: AppSpacing.roundedMedium,
        border: Border.all(color: AppColors.borderGray),
        boxShadow: AppSpacing.elevationSm,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.send_rounded,
                  color: AppColors.primaryNavy,
                  size: 20.0,
                ),
                const SizedBox(width: 8.0),
                Text(
                  'Send Us a Query',
                  style: AppTypography.heading2.copyWith(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4.0),
            Text(
              'Fill in your details and our team will get back to you promptly.',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14.0),

            // Category Selection
            Text(
              'Query Topic',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6.0),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 10.0,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: AppColors.borderGray),
                ),
              ),
              items: _categories
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedCategory = val);
                }
              },
            ),
            const SizedBox(height: 12.0),

            // Name
            Text(
              'Your Name',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6.0),
            TextFormField(
              key: const Key('help_support_name_field'),
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'e.g. Ramesh Kumar',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 10.0,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: AppColors.borderGray),
                ),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter your name'
                  : null,
            ),
            const SizedBox(height: 12.0),

            // Contact (Phone/Email)
            Text(
              'Phone Number or Email',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6.0),
            TextFormField(
              key: const Key('help_support_contact_field'),
              controller: _contactController,
              decoration: InputDecoration(
                hintText: 'e.g. 9876543210 or parent@gmail.com',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 10.0,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: AppColors.borderGray),
                ),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please provide your contact info'
                  : null,
            ),
            const SizedBox(height: 12.0),

            // Message
            Text(
              'Describe your issue or question',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6.0),
            TextFormField(
              key: const Key('help_support_message_field'),
              controller: _messageController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText:
                    'Please mention your Order ID or School Name if applicable...',
                contentPadding: const EdgeInsets.all(12.0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: AppColors.borderGray),
                ),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please write your message'
                  : null,
            ),
            const SizedBox(height: 16.0),

            CustomButton(
              key: const Key('help_support_submit_button'),
              text: 'SUBMIT QUERY',
              isLoading: _isSubmitting,
              onPressed: _handleSubmitQuery,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperatingHoursCard() {
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
            Icons.access_time_rounded,
            color: AppColors.primaryNavy,
            size: 24.0,
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Support Hours & Logistics Center',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryNavy,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  'Monday – Saturday: 9:00 AM to 7:00 PM IST\nSunday & National Holidays: Closed\nOfficial Address: Book Vardi Educational Logistics Hub, Sector 62, Noida, UP - 201301',
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
