import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../catalog/domain/product_model.dart';
import '../controllers/admin_controller.dart';
import '../../data/admin_repository.dart';

/// Central Administration & Operations Command Portal.
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminDashboardStatsProvider);
    final lowStockAsync = ref.watch(adminLowStockAlertsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundSlate,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: const BoxDecoration(
                color: AppColors.secondaryAmber,
                borderRadius: AppSpacing.roundedSmall,
              ),
              child: const Text(
                'ADMIN',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryNavy,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Operations Portal',
              style: AppTypography.heading2.copyWith(
                color: AppColors.primaryNavy,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        scrolledUnderElevation: 1,
        actions: [
          IconButton(
            tooltip: 'View Customer Store',
            icon: const Icon(Icons.storefront_rounded, color: AppColors.primaryNavy),
            onPressed: () => context.go('/'),
          ),
          IconButton(
            tooltip: 'Refresh Dashboard',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primaryNavy),
            onPressed: () {
              ref.invalidate(adminDashboardStatsProvider);
              ref.invalidate(adminLowStockAlertsProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primaryNavy,
        onRefresh: () async {
          ref.invalidate(adminDashboardStatsProvider);
          ref.invalidate(adminLowStockAlertsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. KPI Statistics Overview Grid
              statsAsync.when(
                data: (stats) => _buildKpiGrid(context, stats),
                loading: () => _buildKpiShimmer(),
                error: (err, _) => _buildStatsError(ref, err.toString()),
              ),
              const SizedBox(height: AppSpacing.lg),

              // 2. Operations Quick Launch Cards
              _buildOperationsNavSection(context),
              const SizedBox(height: AppSpacing.lg),

              // 3. Critical Low-Stock Inventory Alerts
              _buildLowStockHeader(),
              const SizedBox(height: AppSpacing.sm),
              lowStockAsync.when(
                data: (products) => _buildLowStockList(context, products),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: CircularProgressIndicator(color: AppColors.primaryNavy),
                  ),
                ),
                error: (err, _) => Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text('Error loading low stock alerts: $err', style: AppTypography.caption),
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiGrid(BuildContext context, AdminDashboardStats stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.35,
          children: [
            _kpiCard(
              title: 'Total GMV',
              value: '₹${stats.totalGmv.toStringAsFixed(0)}',
              icon: Icons.currency_rupee_rounded,
              color: const Color(0xFF0F5132),
              bgColor: const Color(0xFFD1E7DD),
            ),
            _kpiCard(
              title: 'Unfulfilled Queue',
              value: '${stats.unfulfilledOrdersCount}',
              subtitle: 'Needs Packing / Dispatch',
              icon: Icons.pending_actions_rounded,
              color: const Color(0xFF664D03),
              bgColor: const Color(0xFFFFF3CD),
              onTap: () => context.push('/admin/orders'),
            ),
            _kpiCard(
              title: 'Total Orders',
              value: '${stats.totalOrdersCount}',
              icon: Icons.receipt_long_rounded,
              color: AppColors.primaryNavy,
              bgColor: AppColors.mintPillBg,
              onTap: () => context.push('/admin/orders'),
            ),
            _kpiCard(
              title: 'Low Stock Alert',
              value: '${stats.lowStockProductsCount}',
              subtitle: 'SKUs < 5 units',
              icon: Icons.warning_amber_rounded,
              color: AppColors.destructiveRed,
              bgColor: const Color(0xFFF8D7DA),
            ),
          ],
        );
      },
    );
  }

  Widget _kpiCard({
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.roundedSmall,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: AppSpacing.roundedSmall,
          border: Border.all(color: AppColors.borderGray),
          boxShadow: AppSpacing.elevationSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                  child: Icon(icon, size: 16, color: color),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTypography.heading1.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryNavy,
                    fontSize: 20,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.micro.copyWith(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationsNavSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Operations Center',
          style: AppTypography.heading2.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryNavy,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _actionCard(
                key: const Key('admin_nav_products_btn'),
                title: 'Catalog Studio',
                subtitle: 'Manage SKUs, variants & prices',
                icon: Icons.inventory_2_outlined,
                accentColor: AppColors.primaryNavy,
                onTap: () => context.push('/admin/products'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _actionCard(
                key: const Key('admin_nav_orders_btn'),
                title: 'Order Fulfillment',
                subtitle: 'Pack, ship & generate invoices',
                icon: Icons.local_shipping_outlined,
                accentColor: AppColors.secondaryAmberDark,
                onTap: () => context.push('/admin/orders'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionCard({
    Key? key,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: AppSpacing.roundedSmall,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: AppSpacing.roundedSmall,
          border: Border.all(color: AppColors.borderGray),
          boxShadow: AppSpacing.elevationSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: AppSpacing.roundedSmall,
              ),
              child: Icon(icon, color: accentColor, size: 24),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLowStockHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            'Critical Inventory Alerts',
            style: AppTypography.heading2.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryNavy,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: const BoxDecoration(
            color: Color(0xFFF8D7DA),
            borderRadius: AppSpacing.roundedFull,
          ),
          child: const Text(
            '< 5 Units',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.destructiveRed,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLowStockList(BuildContext context, List<ProductModel> products) {
    if (products.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: AppSpacing.roundedSmall,
          border: Border.all(color: AppColors.borderGray),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF0F5132), size: 28),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'All Inventory Healthy',
                    style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'No SKUs are currently below the critical stock threshold.',
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final p = products[index];
        final isOutOfStock = !p.inStock || p.totalStock == 0;

        return Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: AppSpacing.roundedSmall,
            border: Border.all(
              color: isOutOfStock ? const Color(0xFFF8D7DA) : AppColors.borderGray,
            ),
            boxShadow: AppSpacing.elevationSm,
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: AppSpacing.roundedSmall,
                child: Container(
                  width: 48,
                  height: 48,
                  color: AppColors.backgroundSlate,
                  child: p.primaryImage.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: p.primaryImage,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const Icon(
                            Icons.inventory_2_outlined,
                            color: AppColors.primaryNavy,
                          ),
                        )
                      : const Icon(Icons.inventory_2_outlined, color: AppColors.primaryNavy),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      p.schoolName ?? p.categoryId,
                      style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isOutOfStock ? const Color(0xFFF8D7DA) : const Color(0xFFFFF3CD),
                  borderRadius: AppSpacing.roundedFull,
                ),
                child: Text(
                  isOutOfStock ? 'OUT OF STOCK' : '${p.totalStock} left',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isOutOfStock ? AppColors.destructiveRed : const Color(0xFF664D03),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primaryNavy),
                onPressed: () => context.push('/admin/products/edit/${p.productId}'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKpiShimmer() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.35,
      children: List.generate(
        4,
        (_) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: AppSpacing.roundedSmall,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsError(WidgetRef ref, String err) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: Color(0xFFF8D7DA),
        borderRadius: AppSpacing.roundedSmall,
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.destructiveRed),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text('Failed to load stats: $err', style: AppTypography.caption)),
          TextButton(
            onPressed: () => ref.invalidate(adminDashboardStatsProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
