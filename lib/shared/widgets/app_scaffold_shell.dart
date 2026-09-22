import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'stationery_background.dart';

/// Navigation item model for AppScaffoldShell.
class NavigationTabItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final int? badgeCount;

  const NavigationTabItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.badgeCount,
  });
}

/// Responsive scaffold shell providing fixed 56px Top App Bar and
/// fixed 64px Bottom Navigation Bar with strict SafeArea compliance.
class AppScaffoldShell extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback? onSearchPressed;
  final VoidCallback? onCartPressed;
  final VoidCallback? onWishlistPressed;
  final VoidCallback? onLocationPressed;
  final String? selectedLocationName;
  final int cartBadgeCount;
  final String? title;
  final bool showAppBar;
  final bool showBottomNav;

  const AppScaffoldShell({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onTabSelected,
    this.onSearchPressed,
    this.onCartPressed,
    this.onWishlistPressed,
    this.onLocationPressed,
    this.selectedLocationName,
    this.cartBadgeCount = 0,
    this.title,
    this.showAppBar = true,
    this.showBottomNav = true,
  });

  static const List<NavigationTabItem> tabs = [
    NavigationTabItem(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
    ),
    NavigationTabItem(
      label: 'Categories',
      icon: Icons.grid_view_outlined,
      selectedIcon: Icons.grid_view,
    ),
    NavigationTabItem(
      label: 'Products',
      icon: Icons.storefront_outlined,
      selectedIcon: Icons.storefront,
    ),
    NavigationTabItem(
      label: 'Orders',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
    ),
    NavigationTabItem(
      label: 'Account',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 1024;

        final bool isHomeTab = currentIndex == 0;
        final bool shouldShowAppBar = showAppBar && isHomeTab;

        return Scaffold(
          backgroundColor: AppColors.backgroundSlate,
          appBar: shouldShowAppBar ? _buildAppBar(context, isDesktop) : null,
          body: StationeryBackground(
            child: SafeArea(
              top: !shouldShowAppBar,
              bottom: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: child,
                ),
              ),
            ),
          ),
          bottomNavigationBar:
              showBottomNav && !isDesktop ? _buildBottomNavBar(context) : null,
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDesktop) {
    return PreferredSize(
      preferredSize: Size.fromHeight(isDesktop ? 104.0 : 92.0),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceWhite,
          border: Border(
            bottom: BorderSide(color: AppColors.borderGray, width: 1.0),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Announcement Bar (Deep Pine Green with Gold accents from website)
              Container(
                height: 32.0,
                color: AppColors.announcementDarkBg,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Flexible(
                      child: AnnouncementsTicker(),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: onLocationPressed,
                      borderRadius: BorderRadius.circular(12.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 3.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(
                            color: AppColors.secondaryAmber.withValues(alpha: 0.4),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color: AppColors.secondaryAmber,
                              size: 13,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              selectedLocationName ?? 'Kamta, Lucknow',
                              style: const TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                color: AppColors.secondaryAmber,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppColors.secondaryAmber,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Main Header Bar
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Circular Brand Logo (Left)
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surfaceWhite,
                          border: Border.all(
                            color: AppColors.borderGray,
                            width: 1.2,
                          ),
                          boxShadow: AppSpacing.elevationSm,
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/app_logo.png',
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.primaryNavy,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.school_rounded,
                                color: AppColors.secondaryAmber,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // 3 Circular Action Buttons (Right: Search, Cart, Favorite)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 1. Search circular button
                          _buildCircularAction(
                            icon: const Icon(Icons.search_rounded),
                            tooltip: 'Search catalog',
                            onPressed: onSearchPressed ??
                                () => context.push('/search'),
                          ),
                          const SizedBox(width: 8),

                          // 2. Cart circular button with badge
                          _buildCircularAction(
                            icon: const Icon(Icons.shopping_bag_outlined),
                            tooltip: 'Shopping Cart',
                            badgeCount: cartBadgeCount,
                            onPressed:
                                onCartPressed ?? () => context.push('/cart'),
                          ),
                          const SizedBox(width: 8),

                          // 3. Favorite / Wishlist circular button
                          _buildCircularAction(
                            icon: const Icon(Icons.favorite_border_rounded),
                            tooltip: 'Wishlist',
                            onPressed: onWishlistPressed ??
                                () => context.push('/wishlist'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircularAction({
    required Widget icon,
    required String tooltip,
    required VoidCallback? onPressed,
    int badgeCount = 0,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.backgroundSlate,
            border: Border.all(color: AppColors.borderGray, width: 1.0),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            iconSize: 20,
            icon: icon,
            color: AppColors.primaryNavy,
            tooltip: tooltip,
            onPressed: onPressed,
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.all(2.5),
              constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
              decoration: const BoxDecoration(
                color: AppColors.secondaryAmber,
                shape: BoxShape.circle,
              ),
              child: Text(
                cartBadgeCount > 99 ? '99+' : '$badgeCount',
                style: const TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  color: AppColors.textDark,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        boxShadow: AppSpacing.shadowNavBar,
        border: Border(
          top: BorderSide(color: AppColors.borderGray, width: 1.0),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(tabs.length, (index) {
              final tab = tabs[index];
              final bool isSelected = currentIndex == index;
              final Color itemColor = isSelected
                  ? AppColors.primaryNavy
                  : AppColors.textSecondary;

              return Expanded(
                child: InkWell(
                  onTap: () => onTabSelected(index),
                  borderRadius: AppSpacing.roundedSmall,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isSelected ? tab.selectedIcon : tab.icon,
                        color: itemColor,
                        size: 24,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        tab.label,
                        style: TextStyle(
                          color: itemColor,
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// Rotating Announcements Ticker for the top announcement bar.
/// Cycles through promotional offers every 2 seconds with a vertical slide transition.
class AnnouncementsTicker extends StatefulWidget {
  const AnnouncementsTicker({super.key});

  @override
  State<AnnouncementsTicker> createState() => _AnnouncementsTickerState();
}

class _AnnouncementsTickerState extends State<AnnouncementsTicker> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _offers = [
    {
      'icon': Icons.local_shipping_outlined,
      'prefix': 'Free Shipping Over ',
      'highlight': '₹499',
    },
    {
      'icon': Icons.local_offer_outlined,
      'prefix': 'Extra 10% OFF on ',
      'highlight': 'School Kits',
    },
    {
      'icon': Icons.flash_on_outlined,
      'prefix': 'Fast Delivery in ',
      'highlight': '24-48 Hours',
    },
    {
      'icon': Icons.school_outlined,
      'prefix': '100% Genuine ',
      'highlight': 'CBSE & ICSE Books',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;
      _currentIndex = (_currentIndex + 1) % _offers.length;
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32.0,
      child: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _offers.length,
        itemBuilder: (context, index) {
          final offer = _offers[index];
          return GestureDetector(
            onTap: () => context.push('/coupons'),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    offer['icon'] as IconData,
                    color: AppColors.secondaryAmber,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: RichText(
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: AppTypography.fontFamily,
                          color: Colors.white,
                        ),
                        children: [
                          TextSpan(text: offer['prefix'] as String),
                          TextSpan(
                            text: offer['highlight'] as String,
                            style: const TextStyle(
                              color: AppColors.secondaryAmber,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

