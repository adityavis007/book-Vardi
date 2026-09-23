import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/stationery_background.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSlate,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          key: const Key('about_back_button'),
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primaryNavy),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: Text(
          'About Us',
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
            // 1. Hero Dark Banner
            _buildHeroBanner(context),

            // 2. Impact Stats Grid
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  _buildStatsGrid(),
                  const SizedBox(height: AppSpacing.xxl),

                  // 3. Journey & Timeline Section
                  _buildJourneyTimeline(),
                  const SizedBox(height: AppSpacing.xxl),

                  // 4. Our Values Section
                  _buildCoreValues(),
                  const SizedBox(height: AppSpacing.xxl),

                  // 5. Meet the Team Section
                  _buildTeamSection(),
                  const SizedBox(height: AppSpacing.xxl),

                  // 6. Testimonial Quote Card
                  _buildTestimonialCard(),
                  const SizedBox(height: AppSpacing.xxl),

                  // 7. Bottom CTA Banner
                  _buildCtaBanner(context),
                  const SizedBox(height: AppSpacing.xxxl),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildHeroBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.announcementDarkBg,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24.0)),
      ),
      padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: AppColors.secondaryAmber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: AppColors.secondaryAmber.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt_rounded, color: AppColors.secondaryAmber, size: 14.0),
                const SizedBox(width: 4.0),
                Text(
                  'OUR PURPOSE & STORY',
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
                fontSize: 24.0,
                fontWeight: FontWeight.w800,
                color: AppColors.surfaceWhite,
                height: 1.25,
              ),
              children: const [
                TextSpan(text: 'Crafting Joy for Every Classroom & '),
                TextSpan(
                  text: 'Study Desk.',
                  style: TextStyle(color: AppColors.secondaryAmber),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10.0),
          Text(
            'To make authentic, school-approved uniforms, textbooks, and kits accessible to every parent and student across India.',
            style: AppTypography.bodyRegular.copyWith(
              color: AppColors.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20.0),
          Row(
            children: [
              CustomButton.accentBuyNow(
                text: 'EXPLORE SUPPLIES ➔',
                isFullWidth: false,
                height: 40.0,
                onPressed: () => context.push('/products'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = [
      {'value': '50+', 'label': 'PARTNER SCHOOLS'},
      {'value': '10,000+', 'label': 'STUDENTS SERVED'},
      {'value': '100%', 'label': 'GENUINE PRODUCTS'},
      {'value': '25+', 'label': 'CITIES COVERED'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.8,
      ),
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: AppSpacing.roundedMedium,
            border: Border.all(color: AppColors.borderGray),
            boxShadow: AppSpacing.elevationSm,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                stat['value']!,
                style: AppTypography.heading1.copyWith(
                  fontSize: 22.0,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 2.0),
              Text(
                stat['label']!,
                style: AppTypography.micro.copyWith(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildJourneyTimeline() {
    final milestones = [
      {
        'year': '2021',
        'tag': 'Milestone #1',
        'title': 'Book Vardi Founded',
        'desc': 'Started with a vision to simplify school uniform and book purchasing for families.',
      },
      {
        'year': '2022',
        'tag': 'Milestone #2',
        'title': '50+ School Partnerships',
        'desc': 'Partnered with premier schools to offer syllabus-aligned kits directly.',
      },
      {
        'year': '2023',
        'tag': 'Milestone #3',
        'title': '10,000+ Happy Students',
        'desc': 'Delivered authentic kits across 25+ cities with 100% genuine product guarantee.',
      },
      {
        'year': '2024',
        'tag': 'Milestone #4',
        'title': 'Digital Platform Launch',
        'desc': 'Launched seamless web and mobile ordering with instant seller dispatch.',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: AppSpacing.roundedMedium,
        border: Border.all(color: AppColors.borderGray),
        boxShadow: AppSpacing.elevationSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: AppColors.categoryPillBg,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Text(
                'HOW WE GREW',
                style: AppTypography.micro.copyWith(
                  color: AppColors.primaryNavy,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          Center(
            child: Text(
              'The Journey of Book Vardi',
              style: AppTypography.heading1.copyWith(fontSize: 18.0, color: AppColors.textDark),
            ),
          ),
          const SizedBox(height: 4.0),
          Center(
            child: Text(
              'From late-night study sessions to supplying over 50,000 students across India.',
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Milestone Cards
          ...milestones.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.backgroundSlate,
                borderRadius: AppSpacing.roundedSmall,
                border: Border.all(color: AppColors.borderGray),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32.0,
                    height: 32.0,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryNavy,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${idx + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryAmber.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: Text(
                                item['year']!,
                                style: AppTypography.micro.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                            Text(
                              item['tag']!,
                              style: AppTypography.micro.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          item['title']!,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          item['desc']!,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCoreValues() {
    final values = [
      {'icon': Icons.verified_user_outlined, 'title': 'Authenticity Guarantee', 'badge': 'VERIFIED'},
      {'icon': Icons.favorite_border_rounded, 'title': 'Student-Centric Care', 'badge': 'POPULAR'},
      {'icon': Icons.workspace_premium_outlined, 'title': 'Quality Assurance', 'badge': 'PREMIUM'},
      {'icon': Icons.support_agent_rounded, 'title': 'Reliable Support', 'badge': '24/7'},
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: AppSpacing.roundedMedium,
        border: Border.all(color: AppColors.borderGray),
        boxShadow: AppSpacing.elevationSm,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: AppColors.categoryPillBg,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Text(
              'OUR PROMISES',
              style: AppTypography.micro.copyWith(
                color: AppColors.primaryNavy,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Values We Will Never Compromise On',
            style: AppTypography.heading1.copyWith(fontSize: 18.0, color: AppColors.textDark),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4.0),
          Text(
            'Every pencil, spiral notebook, and geometry box we ship carries these 4 pillars.',
            style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: values.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.3,
            ),
            itemBuilder: (context, index) {
              final val = values[index];
              return Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSlate,
                  borderRadius: AppSpacing.roundedSmall,
                  border: Border.all(color: AppColors.borderGray),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(val['icon'] as IconData, color: AppColors.primaryNavy, size: 22.0),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                          decoration: BoxDecoration(
                            color: AppColors.categoryPillBg,
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Text(
                            val['badge'] as String,
                            style: AppTypography.micro.copyWith(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryNavy,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      val['title'] as String,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                        fontSize: 12.0,
                      ),
                    ),
                    Text(
                      'Book Vardi Certified ✓',
                      style: AppTypography.micro.copyWith(
                        color: AppColors.successGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSection() {
    final team = [
      {
        'name': 'Gaurav Gupta',
        'role': 'Founder & CEO',
        'bio': 'Passionate about modernizing educational logistics and student experience.',
      },
      {
        'name': 'Ananya Sharma',
        'role': 'Head of Operations',
        'bio': 'Ensuring seamless school onboarding and supply chain quality control.',
      },
      {
        'name': 'Rahul Verma',
        'role': 'Lead Product Manager',
        'bio': 'Creating intuitive digital tools for parents, sellers, and school systems.',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: AppSpacing.roundedMedium,
        border: Border.all(color: AppColors.borderGray),
        boxShadow: AppSpacing.elevationSm,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: AppColors.categoryPillBg,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Text(
              'PEOPLE BEHIND THE BRAND',
              style: AppTypography.micro.copyWith(
                color: AppColors.primaryNavy,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Meet the Passionate Team',
            style: AppTypography.heading1.copyWith(fontSize: 18.0, color: AppColors.textDark),
          ),
          const SizedBox(height: 4.0),
          Text(
            'Designers, educators, and stationery lovers obsessed with creating the best learning experience.',
            style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          ...team.map((member) => Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSlate,
                  borderRadius: AppSpacing.roundedSmall,
                  border: Border.all(color: AppColors.borderGray),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52.0,
                      height: 52.0,
                      decoration: const BoxDecoration(
                      color: AppColors.categoryPillBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: AppColors.primaryNavy,
                      size: 28.0,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member['name']!,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          member['role']!,
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryNavy,
                            fontSize: 11.5,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          member['bio']!,
                          style: AppTypography.micro.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildTestimonialCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.announcementDarkBg,
        borderRadius: AppSpacing.roundedMedium,
      ),
      child: Column(
        children: [
          const Icon(
            Icons.format_quote_rounded,
            size: 36.0,
            color: AppColors.secondaryAmber,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '"Book Vardi saved me hours of standing in uniform shop queues. The kit arrived perfectly fitted!"',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.surfaceWhite,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Priya Sharma',
            style: AppTypography.caption.copyWith(
              color: AppColors.secondaryAmber,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            'Parent of Class 6 Student',
            style: AppTypography.micro.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCtaBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.creamCardBg,
        borderRadius: AppSpacing.roundedMedium,
        border: Border.all(color: AppColors.creamCardBorder),
      ),
      child: Column(
        children: [
          Text(
            'Ready to Upgrade Your Study & Workspace?',
            style: AppTypography.heading2.copyWith(
              fontSize: 16.0,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryNavy,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6.0),
          Text(
            'Explore 22+ non-toxic student notebooks, smooth gel pen sets, and artist sketchpads today.',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          CustomButton(
            text: 'SHOP ALL PRODUCTS ➔',
            onPressed: () => context.push('/products'),
          ),
        ],
      ),
    );
  }
}
