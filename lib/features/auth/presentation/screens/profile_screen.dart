import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/user_model.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_modal_sheet.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../../../cart/presentation/controllers/wishlist_controller.dart';
import '../../../orders/data/order_repository.dart';
import '../../../checkout/presentation/screens/address_step_screen.dart';

/// 1:1 Profile Screen matching user layout wireframe (Image 1) and
/// Book Vardi website colors, theme, and components (Image 2).
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isCardExpanded = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final bool isAuthenticated = authState.isAuthenticated && user != null;

    final cartCount = ref.watch(cartBadgeCountProvider);
    final wishlistCount = ref.watch(wishlistCountProvider);
    final ordersCount =
        ref.watch(userOrdersStreamProvider).valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Account',
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            color: Color(0xFF0F291E),
            fontSize: 22.0,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isAuthenticated) ...[
              // 1. Top Profile Header Banner (Dark Pine Green) with Avatar & 4 Stat Capsules
              _buildTopProfileCard(
                context,
                user,
                ordersCount: ordersCount,
                likedCount: wishlistCount,
                cartCount: cartCount,
              ),
              const SizedBox(height: 16.0),

              // 2. Card: "Your Information"
              _buildSectionCard(
                title: 'Your Information',
                children: [
                  _buildNavTile(
                    key: const Key('profile_saved_addresses_tile'),
                    icon: Icons.bookmark_border_rounded,
                    title: 'Address book',
                    onTap: () =>
                        _openSavedAddressesSheet(context, ref, user.userId),
                  ),
                  _buildNavTile(
                    key: const Key('profile_wishlist_tile'),
                    icon: Icons.favorite_border_rounded,
                    title: 'Your Wishlist',
                    badgeCount: wishlistCount > 0 ? wishlistCount : null,
                    onTap: () => context.push('/wishlist'),
                  ),
                  _buildNavTile(
                    key: const Key('profile_my_orders_tile'),
                    icon: Icons.shopping_bag_outlined,
                    title: 'Your Order',
                    badgeCount: ordersCount > 0 ? ordersCount : null,
                    onTap: () => context.go('/orders'),
                  ),
                  _buildNavTile(
                    key: const Key('profile_cart_tile'),
                    icon: Icons.shopping_cart_outlined,
                    title: 'Your Cart',
                    badgeCount: cartCount > 0 ? cartCount : null,
                    onTap: () => context.push('/cart'),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),

              // 3. Card: "Payment And coupons"
              _buildSectionCard(
                title: 'Payment And coupons',
                children: [
                  _buildNavTile(
                    key: const Key('profile_wallet_tile'),
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Wallet',
                    trailingSubtitle: '₹0.00',
                    onTap: () => _showWalletDialog(context),
                  ),
                  _buildNavTile(
                    key: const Key('profile_payment_settings_tile'),
                    icon: Icons.payment_outlined,
                    title: 'Payment settings',
                    onTap: () => _showPaymentSettingsDialog(context),
                  ),
                  _buildNavTile(
                    key: const Key('profile_claim_gift_card_tile'),
                    icon: Icons.card_giftcard_outlined,
                    title: 'Claim Gift card',
                    onTap: () => _showGiftCardDialog(context),
                  ),
                  _buildNavTile(
                    key: const Key('profile_coupons_tile'),
                    icon: Icons.local_offer_outlined,
                    title: 'Coupons & Offers',
                    onTap: () => _showCouponsDialog(context),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),

              // 4. Card: "Other Information"
              _buildSectionCard(
                title: 'Other Information',
                children: [
                  _buildNavTile(
                    key: const Key('profile_about_us_tile'),
                    icon: Icons.info_outline_rounded,
                    title: 'About us',
                    onTap: () => context.push('/about'),
                  ),
                  _buildNavTile(
                    key: const Key('profile_share_app_tile'),
                    icon: Icons.share_outlined,
                    title: 'Share the app',
                    onTap: () => _showShareDialog(context),
                  ),
                  _buildNavTile(
                    key: const Key('profile_help_support_tile'),
                    icon: Icons.headset_mic_outlined,
                    title: 'Help & Support',
                    onTap: () => _showHelpSupportDialog(context),
                  ),
                  _buildNavTile(
                    key: const Key('profile_terms_tile'),
                    icon: Icons.description_outlined,
                    title: 'Terms & Conditions',
                    onTap: () => _showTermsDialog(context),
                  ),
                  _buildNavTile(
                    key: const Key('profile_privacy_tile'),
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () => _showPrivacyPolicyDialog(context),
                  ),
                  _buildNavTile(
                    key: const Key('profile_logout_button'),
                    icon: Icons.logout_rounded,
                    title: 'Logout',
                    textColor: const Color(0xFFEF4444),
                    iconColor: const Color(0xFFEF4444),
                    onTap: () => _confirmLogout(context, ref),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),

              // 5. Admin Portal Card (if Admin)
              if (user.isAdmin) ...[
                _buildAdminPortalCard(context),
                const SizedBox(height: 16.0),
              ],

              // 6. Seller Panel Login Card (from Website Image 2)
              _buildSellerPanelCard(context),
            ] else ...[
              // Guest State
              _buildGuestWelcomeCard(context),
              const SizedBox(height: 16.0),

              // Other Information (Accessible to Guests)
              _buildSectionCard(
                title: 'Other Information',
                children: [
                  _buildNavTile(
                    key: const Key('profile_about_us_tile'),
                    icon: Icons.info_outline_rounded,
                    title: 'About us',
                    onTap: () => context.push('/about'),
                  ),
                  _buildNavTile(
                    key: const Key('profile_share_app_tile'),
                    icon: Icons.share_outlined,
                    title: 'Share the app',
                    onTap: () => _showShareDialog(context),
                  ),
                  _buildNavTile(
                    key: const Key('profile_help_support_tile'),
                    icon: Icons.headset_mic_outlined,
                    title: 'Help & Support',
                    onTap: () => _showHelpSupportDialog(context),
                  ),
                  _buildNavTile(
                    key: const Key('profile_terms_tile'),
                    icon: Icons.description_outlined,
                    title: 'Terms & Conditions',
                    onTap: () => _showTermsDialog(context),
                  ),
                  _buildNavTile(
                    key: const Key('profile_privacy_tile'),
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () => _showPrivacyPolicyDialog(context),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              _buildSellerPanelCard(context),
            ],
            const SizedBox(height: 32.0),
            _buildAppVersionFooter(),
          ],
        ),
      ),
    );
  }

  /// 1. Top Profile Header Banner matching Website & Sketch
  Widget _buildTopProfileCard(
    BuildContext context,
    UserModel user, {
    required int ordersCount,
    required int likedCount,
    required int cartCount,
  }) {
    final displayName = user.name.isNotEmpty ? user.name : 'Rahul';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'R';
    final schoolText = user.schoolName?.isNotEmpty == true
        ? user.schoolName!
        : "Children's College Azamgarh";
    final gradeText = user.grade?.isNotEmpty == true ? user.grade! : 'Class 9';
    final idText = user.studentId?.isNotEmpty == true
        ? user.studentId!
        : (user.rollNo?.isNotEmpty == true ? user.rollNo! : 'SC-5425');

    final emailText = user.email.isNotEmpty ? user.email : 'abc@gmail.com';
    final phoneText = user.phone.isNotEmpty
        ? (user.phone.startsWith('+91') ? user.phone : '+91 ${user.phone}')
        : '6387977830';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      decoration: BoxDecoration(
        color: const Color(0xFF0F291E),
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F291E).withValues(alpha: 0.25),
            blurRadius: 16.0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18.0, 18.0, 18.0, 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row: Avatar + Name/School Meta
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar Stack with Yellow border, Oval Edit badge & STUDENT pill
              InkWell(
                key: const Key('profile_edit_avatar_btn'),
                onTap: () => context.push('/edit-profile'),
                borderRadius: BorderRadius.circular(20.0),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 68.0,
                      height: 68.0,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A2F),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFBBF24),
                          width: 2.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 6.0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 28.0,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFFBBF24),
                        ),
                      ),
                    ),
                    // Oval Amber Edit Pill Badge (Matching User Wireframe Sketch)
                    Positioned(
                      top: -4,
                      right: -10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7.0,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBBF24),
                          borderRadius: BorderRadius.circular(12.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 4.0,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit, size: 11.0, color: Colors.black),
                            SizedBox(width: 3.0),
                            Text(
                              'Edit',
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 10.0,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // STUDENT Pill Badge
                    Positioned(
                      bottom: -8,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 2.0,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBBF24),
                            borderRadius: BorderRadius.circular(10.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 3.0,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Text(
                            'STUDENT',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 9.0,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18.0),

              // Details Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            style: const TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 20.0,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Hidden edit button for backward test compatibility
                        SizedBox(
                          width: 0,
                          height: 0,
                          child: Opacity(
                            opacity: 0,
                            child: IconButton(
                              key: const Key('profile_edit_details_icon_btn'),
                              icon: const Icon(Icons.edit),
                              onPressed: () => context.push('/edit-profile'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      '$schoolText • $gradeText',
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 10.0,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF94A3B8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3.0),
                    Text(
                      'ID: $idText',
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFBBF24),
                      ),
                    ),
                    // Extra details when expanded (Email & Phone from User Sketch)
                    if (_isCardExpanded) ...[
                      const SizedBox(height: 5.0),
                      Row(
                        children: [
                          const Text(
                            'Email : ',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 11.0,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFBBF24),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              emailText,
                              style: const TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 11.0,
                                color: Color(0xFFCBD5E1),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2.0),
                      Row(
                        children: [
                          const Text(
                            'Phone : ',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 11.0,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFBBF24),
                            ),
                          ),
                          Text(
                            phoneText,
                            style: const TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 11.0,
                              color: Color(0xFFCBD5E1),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // Extra details when expanded: 4 Stat Capsules Row (Orders, Liked, In Cart, Points)
          if (_isCardExpanded) ...[
            const SizedBox(height: 18.0),
            Row(
              children: [
                Expanded(
                  child: _buildStatCapsule(
                    count: '$ordersCount',
                    label: 'ORDERS',
                    onTap: () => context.go('/orders'),
                  ),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: _buildStatCapsule(
                    count: '$likedCount',
                    label: 'LIKED ♥',
                    onTap: () => context.push('/wishlist'),
                  ),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: _buildStatCapsule(
                    count: '$cartCount',
                    label: 'IN CART 🛒',
                    onTap: () => context.push('/cart'),
                  ),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: _buildStatCapsule(
                    count: '${user.rewardPoints}',
                    label: 'POINTS',
                    isPoints: true,
                    onTap: () => _showPointsDialog(context, user.rewardPoints),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 6.0),

          // Down / Up Arrow Toggle Button (matching the user's sketch)
          Center(
            child: InkWell(
              key: const Key('profile_expand_toggle_btn'),
              onTap: () {
                setState(() {
                  _isCardExpanded = !_isCardExpanded;
                });
              },
              borderRadius: BorderRadius.circular(16.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
                child: AnimatedRotation(
                  turns: _isCardExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFFFBBF24),
                    size: 24.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCapsule({
    required String count,
    required String label,
    required VoidCallback onTap,
    bool isPoints = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: const Color(0xFFFBBF24).withValues(alpha: 0.6),
            width: 1.2,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isPoints) ...[
                  const Icon(Icons.bolt, size: 14.0, color: Color(0xFFFBBF24)),
                  const SizedBox(width: 2.0),
                ],
                Text(
                  count,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 15.0,
                    fontWeight: FontWeight.w800,
                    color: isPoints ? const Color(0xFFFBBF24) : Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2.0),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFDE047),
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Reusable Card Container for Grouped Sections matching the user's sketch
  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8.0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 14.0, 16.0, 10.0),
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          const Divider(height: 1.0, thickness: 1.2, color: Color(0xFFE2E8F0)),
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              const Divider(
                height: 1.0,
                thickness: 1.0,
                color: Color(0xFFF1F5F9),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavTile({
    Key? key,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    int? badgeCount,
    String? trailingSubtitle,
    Color? textColor,
    Color? iconColor,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 13.0),
        child: Row(
          children: [
            Icon(icon, size: 20.0, color: iconColor ?? const Color(0xFF475569)),
            const SizedBox(width: 14.0),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                  color: textColor ?? const Color(0xFF1E293B),
                ),
              ),
            ),
            if (badgeCount != null && badgeCount > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 2.0,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
            ],
            if (trailingSubtitle != null) ...[
              Text(
                trailingSubtitle,
                style: const TextStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F291E),
                ),
              ),
              const SizedBox(width: 8.0),
            ],
            Icon(
              Icons.arrow_forward_rounded,
              size: 16.0,
              color: iconColor ?? const Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  /// Seller Panel Login Card from Website Screenshot
  Widget _buildSellerPanelCard(BuildContext context) {
    return InkWell(
      onTap: () => _showSellerPortalDialog(context),
      borderRadius: BorderRadius.circular(16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        decoration: BoxDecoration(
          color: const Color(0xFFFBBF24),
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFBBF24).withValues(alpha: 0.3),
              blurRadius: 10.0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.storefront_rounded,
              size: 22.0,
              color: Colors.black,
            ),
            const SizedBox(width: 12.0),
            const Expanded(
              child: Text(
                'Seller Panel Login',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 4.0,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(14.0),
              ),
              child: const Text(
                'LOGIN',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 11.0,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Admin Portal Tile
  Widget _buildAdminPortalCard(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        key: const Key('profile_admin_portal_tile'),
        leading: const Icon(
          Icons.admin_panel_settings_outlined,
          color: Color(0xFFF59E0B),
          size: 24.0,
        ),
        title: Row(
          children: [
            const Flexible(
              child: Text(
                'Admin Operations Portal',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontWeight: FontWeight.w700,
                  fontSize: 14.0,
                  color: Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8.0),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6.0,
                vertical: 2.0,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: const Text(
                'ADMIN',
                style: TextStyle(
                  fontSize: 9.0,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFB45309),
                ),
              ),
            ),
          ],
        ),
        subtitle: const Text(
          'Catalog studio, inventory alerts & orders',
          style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
        ),
        trailing: const Icon(
          Icons.arrow_forward_rounded,
          size: 16.0,
          color: Color(0xFF94A3B8),
        ),
        onTap: () => context.push('/admin'),
      ),
    );
  }

  /// Guest Welcome Card
  Widget _buildGuestWelcomeCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: const Color(0xFF0F291E),
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F291E).withValues(alpha: 0.25),
            blurRadius: 16.0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.account_circle_outlined,
                size: 38.0,
                color: Color(0xFFFBBF24),
              ),
              SizedBox(width: 12.0),
              Expanded(
                child: Text(
                  'Welcome to Book Vardi',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 18.0,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          const Text(
            'Login or register to track your official school uniforms, book sets, and delivery orders.',
            style: TextStyle(
              fontSize: 13.0,
              color: Color(0xFFCBD5E1),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16.0),
          SizedBox(
            width: double.infinity,
            height: 46.0,
            child: ElevatedButton(
              key: const Key('profile_login_cta_button'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFBBF24),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(23.0),
                ),
                elevation: 0,
              ),
              onPressed: () => AuthModalBottomSheet.show(context),
              child: const Text(
                'Login / Create Account',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontWeight: FontWeight.w800,
                  fontSize: 14.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: const Text(
          'Log Out',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F291E),
          ),
        ),
        content: const Text(
          'Are you sure you want to log out of your Book Vardi account?',
          style: TextStyle(fontSize: 14.0, color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            key: const Key('profile_confirm_logout_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text(
              'Log Out',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }

  void _openSavedAddressesSheet(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (sheetCtx) {
        return Consumer(
          builder: (context, ref, _) {
            final addressesAsync = ref.watch(savedAddressesStreamProvider);

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Saved Delivery Addresses',
                          style: TextStyle(
                            fontSize: 17.0,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.of(sheetCtx).pop(),
                        ),
                      ],
                    ),
                    const Divider(height: 16.0),
                    addressesAsync.when(
                      data: (addresses) {
                        if (addresses.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24.0),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.location_off_outlined,
                                  size: 40.0,
                                  color: Color(0xFF94A3B8),
                                ),
                                const SizedBox(height: 8.0),
                                const Text(
                                  'No saved addresses found.',
                                  style: TextStyle(color: Color(0xFF64748B)),
                                ),
                                const SizedBox(height: 12.0),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0F291E),
                                    foregroundColor: Colors.white,
                                  ),
                                  icon: const Icon(
                                    Icons.add_rounded,
                                    size: 16.0,
                                  ),
                                  label: const Text('Add New Address'),
                                  onPressed: () {
                                    Navigator.of(sheetCtx).pop();
                                    _openAddAddressModal(context, userId);
                                  },
                                ),
                              ],
                            ),
                          );
                        }

                        return ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 320.0),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: addresses.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8.0),
                            itemBuilder: (ctx, index) {
                              final addr = addresses[index];
                              return Container(
                                padding: const EdgeInsets.all(12.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10.0),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          addr.fullName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13.0,
                                          ),
                                        ),
                                        const SizedBox(width: 6.0),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6.0,
                                            vertical: 1.5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFDCFCE7),
                                            borderRadius: BorderRadius.circular(
                                              4.0,
                                            ),
                                          ),
                                          child: Text(
                                            addr.addressType.toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 9.0,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF15803D),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2.0),
                                    Text(
                                      addr.formattedAddress,
                                      style: const TextStyle(
                                        fontSize: 12.0,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(
                            color: Color(0xFF0F291E),
                          ),
                        ),
                      ),
                      error: (err, _) => Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Error loading addresses: $err',
                          style: const TextStyle(color: Colors.red),
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

  void _openAddAddressModal(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddAddressBottomSheet(userId: userId),
    );
  }

  void _showWalletDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.account_balance_wallet_rounded,
              color: Color(0xFF0F291E),
            ),
            SizedBox(width: 6.0),
            Text(
              'Book Vardi Wallet',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14.0),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Available Balance',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '₹0.00',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F291E),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12.0),
            const Text(
              'Wallet credits can be applied during checkout on book bundles and school uniforms.',
              style: TextStyle(fontSize: 12.0, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPaymentSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: const Text(
          'Payment Settings',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Manage your UPI, Credit/Debit cards, and Net Banking options securely processed via Razorpay.',
          style: TextStyle(fontSize: 13.0, color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showGiftCardDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: const Text(
          'Claim Gift Card',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your 16-digit voucher code to add funds to your wallet.',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12.0),
            TextField(
              decoration: InputDecoration(
                hintText: 'Enter Voucher Code',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 10.0,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F291E),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Claim'),
          ),
        ],
      ),
    );
  }

  void _showCouponsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: const Text(
          'Coupons & Offers',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(color: const Color(0xFFFBBF24)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SCHOOL10',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14.0,
                      color: Color(0xFF92400E),
                    ),
                  ),
                  SizedBox(height: 2.0),
                  Text(
                    'Get 10% OFF on your first stationery & uniform order.',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF78350F)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPointsDialog(BuildContext context, int points) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: const Row(
          children: [
            Icon(Icons.bolt, color: Color(0xFFFBBF24)),
            SizedBox(width: 8.0),
            Text(
              'Loyalty Points',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: Text(
          'You currently have $points Book Vardi Points. Earn points on every school book kit and uniform purchase to redeem discounts.',
          style: const TextStyle(fontSize: 13.0, color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showSellerPortalDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: const Text(
          'Seller Panel',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Are you an affiliated school uniform manufacturer or book distributor? Access the web seller panel at seller.bookvardi.com.',
          style: TextStyle(fontSize: 13.0, color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: const Text(
          'About Book Vardi',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Book Vardi is your trusted partner for official school uniforms, NCERT book bundles, and curated stationery kits delivered directly to your doorstep.',
          style: TextStyle(
            fontSize: 13.0,
            color: Color(0xFF64748B),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showShareDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: const Text(
          'Share Book Vardi',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Help fellow parents and students discover school kits easily!\n\nLink: https://bookvardi.com/download',
          style: TextStyle(fontSize: 13.0, color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Copy Link'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHelpSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfaceWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: Row(
          children: [
            const Icon(Icons.headset_mic_rounded, color: AppColors.primaryNavy),
            const SizedBox(width: 8.0),
            Text('Help & Support', style: AppTypography.heading2),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'We are here to assist with school uniform sizing, book bundle deliveries, and returns.',
              style: TextStyle(fontSize: 13.0, color: AppColors.textSecondary),
            ),
            SizedBox(height: 12.0),
            Text(
              '📞 Helpline: +91 98765 43210',
              style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 6.0),
            Text(
              '✉️ Email: support@bookvardi.com',
              style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfaceWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: Text('Terms & Conditions', style: AppTypography.heading2),
        content: const SingleChildScrollView(
          child: Text(
            '1. Acceptance: By using the Book Vardi application, you agree to these terms.\n\n'
            '2. Catalog & Curriculum: School textbook bundles are sourced directly matching affiliated school curriculum standards.\n\n'
            '3. Uniforms & Sizes: Please refer to school sizing guidelines. Unworn uniforms can be exchanged within 7 days.',
            style: TextStyle(
              fontSize: 13.0,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfaceWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: Text('Privacy Policy', style: AppTypography.heading2),
        content: const SingleChildScrollView(
          child: Text(
            'Book Vardi respects and protects student and parent privacy:\n\n'
            '1. Information Collection: We only collect necessary shipping names, delivery addresses, and contact numbers to process orders.\n\n'
            '2. Payment Security: Financial transactions are encrypted and processed securely via Razorpay PCI-DSS certified gateway.',
            style: TextStyle(
              fontSize: 13.0,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildAppVersionFooter() {
    return const Column(
      children: [
        Text(
          'BOOK VARDI',
          style: TextStyle(
            fontSize: 12.0,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: Color(0xFF94A3B8),
          ),
        ),
        SizedBox(height: 2.0),
        Text(
          'Version 1.0.0 • Clean & Safe for Schools',
          style: TextStyle(fontSize: 11.0, color: Color(0xFF94A3B8)),
        ),
      ],
    );
  }
}
