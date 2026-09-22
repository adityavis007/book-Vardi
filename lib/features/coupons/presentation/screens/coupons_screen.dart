import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/custom_button.dart';

class CouponModel {
  final String id;
  final String title;
  final String description;
  final String code;
  final String category;
  final String expiry;
  final bool isSpecial;

  const CouponModel({
    required this.id,
    required this.title,
    required this.description,
    required this.code,
    required this.category,
    required this.expiry,
    this.isSpecial = false,
  });
}

class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key});

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  int _selectedBottomTab = 0; // 0: All rewards, 1: Scratch cards
  String _selectedFilter = 'All';
  final TextEditingController _couponController = TextEditingController();

  final List<CouponModel> _coupons = const [
    CouponModel(
      id: 'c1',
      title: 'Free Shipping',
      description: 'Free Delivery on all orders over ₹499',
      code: 'FREESHIP',
      category: 'Shipping',
      expiry: 'Expires in 3 days',
      isSpecial: true,
    ),
    CouponModel(
      id: 'c2',
      title: 'Special Discount',
      description: 'Get 10% off on School Uniforms & Books',
      code: 'WELCOME100',
      category: 'Kits',
      expiry: 'Expires in 7 days',
      isSpecial: true,
    ),
    CouponModel(
      id: 'c3',
      title: 'Special Discount',
      description: 'Flat ₹50 off on orders above ₹999',
      code: 'VARDI50',
      category: 'Discount',
      expiry: 'Expires tomorrow',
      isSpecial: false,
    ),
    CouponModel(
      id: 'c4',
      title: 'Stationery Offer',
      description: 'Extra 5% off on all Notebooks & Pens',
      code: 'PEN5',
      category: 'Stationery',
      expiry: 'Expires in 10 days',
      isSpecial: false,
    ),
  ];

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Coupon code "$code" copied to clipboard!'),
        backgroundColor: AppColors.primaryNavy,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _applyCoupon(String code) {
    if (code.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Coupon "$code" applied successfully!'),
        backgroundColor: AppColors.successGreen,
        duration: const Duration(seconds: 2),
      ),
    );
    _couponController.clear();
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
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primaryNavy),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
        title: Text(
          'My Coupons',
          style: AppTypography.heading1.copyWith(
            fontSize: 18.0,
            color: AppColors.primaryNavy,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          // Top Header Banner styled with Book Vardi Theme (Deep Pine Green to Amber accents)
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryNavy, AppColors.primaryNavyHover],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28.0),
                bottomRight: Radius.circular(28.0),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 24.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.auto_awesome, color: AppColors.secondaryAmber, size: 16.0),
                    const SizedBox(width: 6.0),
                    Text(
                      'Level Up Your Savings!',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.secondaryAmber,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 6.0),
                    const Icon(Icons.auto_awesome, color: AppColors.secondaryAmber, size: 16.0),
                  ],
                ),
                const SizedBox(height: 6.0),
                Text(
                  'COUPONS FOR YOU',
                  style: AppTypography.heading1.copyWith(
                    fontSize: 22.0,
                    color: AppColors.surfaceWhite,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 10.0),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Text(
                    'You have ${_coupons.length} active coupons available',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.secondaryAmber,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                // Ticket / Coupon Illustration Icon
                Container(
                  width: 56.0,
                  height: 56.0,
                  decoration: BoxDecoration(
                    color: AppColors.secondaryAmber.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.secondaryAmber, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.local_offer_rounded,
                    color: AppColors.secondaryAmber,
                    size: 28.0,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                // Add Coupon Input Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                    border: Border.all(color: AppColors.borderGray, width: 1.0),
                    boxShadow: AppSpacing.elevationSm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _couponController,
                          decoration: const InputDecoration(
                            hintText: 'Enter coupon code',
                            hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14.0),
                            border: InputBorder.none,
                          ),
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.textDark),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _applyCoupon(_couponController.text.trim().toUpperCase()),
                        child: Text(
                          'Add coupon',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.primaryNavy,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Section Title & Filters
                Text(
                  'Save more with coupons',
                  style: AppTypography.heading2.copyWith(
                    fontSize: 16.0,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Filter Chips Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All'),
                      const SizedBox(width: AppSpacing.sm),
                      _buildFilterChip('Shipping'),
                      const SizedBox(width: AppSpacing.sm),
                      _buildFilterChip('Kits'),
                      const SizedBox(width: AppSpacing.sm),
                      _buildFilterChip('Discount'),
                      const SizedBox(width: AppSpacing.sm),
                      _buildFilterChip('Stationery'),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Coupons List
                ..._coupons
                    .where((c) => _selectedFilter == 'All' || c.category == _selectedFilter)
                    .map((coupon) => _buildCouponCard(coupon)),
                const SizedBox(height: 80.0),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: const BoxDecoration(
          color: AppColors.surfaceWhite,
          border: Border(top: BorderSide(color: AppColors.borderGray, width: 1.0)),
          boxShadow: AppSpacing.shadowNavBar,
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: _buildBottomTabButton(
                  index: 0,
                  icon: Icons.card_giftcard_rounded,
                  label: 'All rewards',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildBottomTabButton(
                  index: 1,
                  icon: Icons.confirmation_number_outlined,
                  label: 'Scratch cards',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final bool isSelected = _selectedFilter == label;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = label),
      borderRadius: BorderRadius.circular(20.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryNavy : AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
            color: isSelected ? AppColors.primaryNavy : AppColors.borderGray,
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: isSelected ? AppColors.surfaceWhite : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildCouponCard(CouponModel coupon) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: AppSpacing.roundedMedium,
        border: Border.all(color: AppColors.borderGray, width: 1.0),
        boxShadow: AppSpacing.elevationSm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Coupon Icon Badge
          Container(
            width: 64.0,
            height: 64.0,
            decoration: BoxDecoration(
              color: AppColors.categoryPillBg,
              borderRadius: AppSpacing.roundedSmall,
              border: Border.all(color: AppColors.categoryPillBorder, width: 1.0),
            ),
            child: const Icon(
              Icons.local_offer_rounded,
              color: AppColors.primaryNavy,
              size: 28.0,
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      coupon.title,
                      style: AppTypography.micro.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryAmber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        coupon.code,
                        style: AppTypography.micro.copyWith(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4.0),
                Text(
                  coupon.description,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      coupon.expiry,
                      style: AppTypography.micro.copyWith(
                        color: AppColors.destructiveRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 24),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => _copyCode(coupon.code),
                      child: Text(
                        'Copy Code ➔',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primaryNavy,
                          fontWeight: FontWeight.w700,
                        ),
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

  Widget _buildBottomTabButton({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool isSelected = _selectedBottomTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedBottomTab = index),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.categoryPillBg : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(
            color: isSelected ? AppColors.primaryNavy.withValues(alpha: 0.3) : AppColors.borderGray,
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20.0,
              color: isSelected ? AppColors.primaryNavy : AppColors.textSecondary,
            ),
            const SizedBox(width: 8.0),
            Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? AppColors.primaryNavy : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
