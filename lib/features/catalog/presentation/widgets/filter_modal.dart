import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/catalog_repository.dart';
import '../controllers/catalog_controller.dart';

/// Interactive 1:1 "Filters & Sorting" drawer / modal sheet matching the Book Vardi web design.
/// Supports both mobile bottom-sheet and wide-screen side-sheet presentations.
class FilterModal extends ConsumerStatefulWidget {
  final CatalogFilterState? initialState;
  final ValueChanged<CatalogFilterState>? onApply;
  final VoidCallback? onReset;
  final bool isSideSheet;

  const FilterModal({
    super.key,
    this.initialState,
    this.onApply,
    this.onReset,
    this.isSideSheet = false,
  });

  /// Displays the FilterModal responsively:
  /// - Mobile viewports (<700px): Rounded bottom sheet
  /// - Wide viewports (>=700px): Right-aligned sliding side sheet
  static Future<void> show(
    BuildContext context, {
    CatalogFilterState? initialState,
    ValueChanged<CatalogFilterState>? onApply,
    VoidCallback? onReset,
  }) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 700;

    if (isWide) {
      return showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Dismiss Filter',
        barrierColor: Colors.black.withValues(alpha: 0.55),
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (dialogContext, animation, secondaryAnimation) {
          final sheetWidth = math.min(math.max(size.width * 0.38, 380.0), 440.0);
          return Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: Colors.transparent,
              child: SizedBox(
                width: sheetWidth,
                height: size.height,
                child: FilterModal(
                  initialState: initialState,
                  onApply: onApply,
                  onReset: onReset,
                  isSideSheet: true,
                ),
              ),
            ),
          );
        },
        transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          );
        },
      );
    } else {
      return showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => FilterModal(
          initialState: initialState,
          onApply: onApply,
          onReset: onReset,
          isSideSheet: false,
        ),
      );
    }
  }

  @override
  ConsumerState<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends ConsumerState<FilterModal> {
  late SortOption _selectedSort;
  late String _selectedPriceRange; // 'all' | 'under250' | '250to500' | 'above500'
  late String _selectedRating; // 'all' | '4plus' | '3plus'
  late String _selectedAvailability; // 'all' | 'inStock' | 'outOfStock'
  late String _selectedSpecialOffers; // 'all' | 'sale'

  // Backward-compatible preserved fields
  String? _selectedCategoryId;
  String? _selectedSchoolId;
  String? _selectedSchoolName;
  String? _selectedGrade;

  @override
  void initState() {
    super.initState();
    final CatalogFilterState current =
        widget.initialState ?? ref.read(catalogFilterProvider);

    _selectedSort = current.sort;

    // Price Range deduction
    if (current.minPrice == null && current.maxPrice == 250.0) {
      _selectedPriceRange = 'under250';
    } else if (current.minPrice == 250.0 && current.maxPrice == 500.0) {
      _selectedPriceRange = '250to500';
    } else if (current.minPrice == 500.0 && current.maxPrice == null) {
      _selectedPriceRange = 'above500';
    } else {
      _selectedPriceRange = 'all';
    }

    // Rating deduction
    if (current.minRating == 4.0) {
      _selectedRating = '4plus';
    } else if (current.minRating == 3.0) {
      _selectedRating = '3plus';
    } else {
      _selectedRating = 'all';
    }

    // Availability deduction
    if (current.inStockOnly) {
      _selectedAvailability = 'inStock';
    } else if (current.outOfStockOnly) {
      _selectedAvailability = 'outOfStock';
    } else {
      _selectedAvailability = 'all';
    }

    // Special Offers deduction
    if (current.saleOnly) {
      _selectedSpecialOffers = 'sale';
    } else {
      _selectedSpecialOffers = 'all';
    }

    _selectedCategoryId = current.categoryId;
    _selectedSchoolId = current.schoolId;
    _selectedSchoolName = current.schoolName;
    _selectedGrade = current.grade;
  }

  int get _activeCount {
    int count = 0;
    if (_selectedSort != SortOption.relevance) count++;
    if (_selectedPriceRange != 'all') count++;
    if (_selectedRating != 'all') count++;
    if (_selectedAvailability != 'all') count++;
    if (_selectedSpecialOffers != 'all') count++;
    if (_selectedCategoryId != null && _selectedCategoryId!.isNotEmpty) count++;
    if (_selectedSchoolName != null && _selectedSchoolName!.isNotEmpty) count++;
    if (_selectedGrade != null && _selectedGrade!.isNotEmpty) count++;
    return count;
  }

  void _resetLocalFilters() {
    setState(() {
      _selectedSort = SortOption.relevance;
      _selectedPriceRange = 'all';
      _selectedRating = 'all';
      _selectedAvailability = 'all';
      _selectedSpecialOffers = 'all';
      _selectedCategoryId = null;
      _selectedSchoolId = null;
      _selectedSchoolName = null;
      _selectedGrade = null;
    });

    if (widget.onReset != null) {
      widget.onReset!();
    }
  }

  void _applyFilters() {
    double? minPrice;
    double? maxPrice;
    if (_selectedPriceRange == 'under250') {
      maxPrice = 250.0;
    } else if (_selectedPriceRange == '250to500') {
      minPrice = 250.0;
      maxPrice = 500.0;
    } else if (_selectedPriceRange == 'above500') {
      minPrice = 500.0;
    }

    double? minRating;
    if (_selectedRating == '4plus') {
      minRating = 4.0;
    } else if (_selectedRating == '3plus') {
      minRating = 3.0;
    }

    final inStockOnly = _selectedAvailability == 'inStock';
    final outOfStockOnly = _selectedAvailability == 'outOfStock';
    final saleOnly = _selectedSpecialOffers == 'sale';

    final CatalogFilterState current =
        widget.initialState ?? ref.read(catalogFilterProvider);

    final updatedState = current.copyWith(
      sort: _selectedSort,
      minPrice: minPrice,
      maxPrice: maxPrice,
      clearPriceRange: _selectedPriceRange == 'all',
      minRating: minRating,
      clearMinRating: _selectedRating == 'all',
      inStockOnly: inStockOnly,
      outOfStockOnly: outOfStockOnly,
      saleOnly: saleOnly,
      categoryId: _selectedCategoryId,
      clearCategory: _selectedCategoryId == null,
      schoolId: _selectedSchoolId,
      schoolName: _selectedSchoolName,
      clearSchool: _selectedSchoolId == null && _selectedSchoolName == null,
      grade: _selectedGrade,
      clearGrade: _selectedGrade == null,
    );

    if (widget.onApply != null) {
      widget.onApply!(updatedState);
    } else {
      ref.read(catalogFilterProvider.notifier).applyState(updatedState);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final maxHeight = size.height * 0.90;

    return Container(
      constraints: widget.isSideSheet
          ? null
          : BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: widget.isSideSheet
            ? const BorderRadius.horizontal(left: Radius.circular(20.0))
            : const BorderRadius.vertical(top: Radius.circular(24.0)),
        boxShadow: widget.isSideSheet
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20.0,
                  offset: const Offset(-4, 0),
                )
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: widget.isSideSheet ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle for mobile bottom sheet
          if (!widget.isSideSheet)
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                width: 36.0,
                height: 4.0,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            ),

          // Header
          _buildHeader(context),

          const Divider(height: 1.0, color: Color(0xFFF1F5F9)),

          // Scrollable Sections
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 18.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. SORT BY
                  _buildSortSection(),
                  const SizedBox(height: 24.0),

                  // 2. PRICE RANGE
                  _buildPriceSection(),
                  const SizedBox(height: 24.0),

                  // 3. RATING
                  _buildRatingSection(),
                  const SizedBox(height: 24.0),

                  // 4. AVAILABILITY
                  _buildAvailabilitySection(),
                  const SizedBox(height: 24.0),

                  // 5. SPECIAL OFFERS
                  _buildSpecialOffersSection(),
                  const SizedBox(height: 20.0),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
      child: Row(
        children: [
          const Icon(
            Icons.tune_outlined,
            size: 22.0,
            color: Color(0xFF0F172A),
          ),
          const SizedBox(width: 10.0),
          const Expanded(
            child: Text(
              'Filters & Sorting',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 18.0,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8.0),
          InkWell(
            key: const Key('filter_close_icon_btn'),
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(16.0),
            child: Container(
              width: 32.0,
              height: 32.0,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 16.0,
                color: Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: Color(0xFF64748B),
        letterSpacing: 0.6,
      ),
    );
  }

  Widget _buildPillChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Key? key,
    Color? selectedBgColor,
    Color? selectedTextColor,
    Color? selectedBorderColor,
  }) {
    final activeBg = selectedBgColor ?? const Color(0xFF223832);
    final activeText = selectedTextColor ?? Colors.white;
    final activeBorder = selectedBorderColor ?? activeBg;

    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(22.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 11.0),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.white,
          borderRadius: BorderRadius.circular(22.0),
          border: Border.all(
            color: isSelected ? activeBorder : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 13.0,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? activeText : const Color(0xFF334155),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSortSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('SORT BY'),
        const SizedBox(height: 12.0),
        Row(
          children: [
            Expanded(
              child: _buildPillChip(
                key: const Key('sort_chip_featured'),
                label: 'Featured',
                isSelected: _selectedSort == SortOption.relevance,
                onTap: () => setState(() => _selectedSort = SortOption.relevance),
              ),
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: _buildPillChip(
                key: const Key('sort_chip_priceLowToHigh'),
                label: 'Price: Low to High',
                isSelected: _selectedSort == SortOption.priceLowToHigh,
                onTap: () => setState(() => _selectedSort = SortOption.priceLowToHigh),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10.0),
        Row(
          children: [
            Expanded(
              child: _buildPillChip(
                key: const Key('sort_chip_priceHighToLow'),
                label: 'Price: High to Low',
                isSelected: _selectedSort == SortOption.priceHighToLow,
                onTap: () => setState(() => _selectedSort = SortOption.priceHighToLow),
              ),
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: _buildPillChip(
                key: const Key('sort_chip_topRated'),
                label: 'Top Rated',
                isSelected: _selectedSort == SortOption.ratingHighToLow,
                onTap: () => setState(() => _selectedSort = SortOption.ratingHighToLow),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10.0),
        Row(
          children: [
            Expanded(
              child: _buildPillChip(
                key: const Key('sort_chip_biggestDiscount'),
                label: 'Biggest Discount',
                isSelected: _selectedSort == SortOption.biggestDiscount,
                onTap: () => setState(() => _selectedSort = SortOption.biggestDiscount),
              ),
            ),
            const SizedBox(width: 10.0),
            const Expanded(child: SizedBox.shrink()),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('PRICE RANGE'),
        const SizedBox(height: 12.0),
        Row(
          children: [
            Expanded(
              child: _buildPillChip(
                key: const Key('price_chip_all'),
                label: 'All Prices',
                isSelected: _selectedPriceRange == 'all',
                onTap: () => setState(() => _selectedPriceRange = 'all'),
              ),
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: _buildPillChip(
                key: const Key('price_chip_under250'),
                label: 'Under ₹250',
                isSelected: _selectedPriceRange == 'under250',
                onTap: () => setState(() => _selectedPriceRange = 'under250'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10.0),
        Row(
          children: [
            Expanded(
              child: _buildPillChip(
                key: const Key('price_chip_250to500'),
                label: '₹250 - ₹500',
                isSelected: _selectedPriceRange == '250to500',
                onTap: () => setState(() => _selectedPriceRange = '250to500'),
              ),
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: _buildPillChip(
                key: const Key('price_chip_above500'),
                label: 'Above ₹500',
                isSelected: _selectedPriceRange == 'above500',
                onTap: () => setState(() => _selectedPriceRange = 'above500'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('RATING'),
        const SizedBox(height: 12.0),
        Row(
          children: [
            Expanded(
              child: _buildPillChip(
                key: const Key('rating_chip_all'),
                label: 'All',
                isSelected: _selectedRating == 'all',
                selectedBgColor: const Color(0xFFF5BF38),
                selectedTextColor: const Color(0xFF1E293B),
                selectedBorderColor: const Color(0xFFF5BF38),
                onTap: () => setState(() => _selectedRating = 'all'),
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: _buildPillChip(
                key: const Key('rating_chip_4plus'),
                label: '4+ Stars',
                isSelected: _selectedRating == '4plus',
                selectedBgColor: const Color(0xFFF5BF38),
                selectedTextColor: const Color(0xFF1E293B),
                selectedBorderColor: const Color(0xFFF5BF38),
                onTap: () => setState(() => _selectedRating = '4plus'),
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: _buildPillChip(
                key: const Key('rating_chip_3plus'),
                label: '3+ Stars',
                isSelected: _selectedRating == '3plus',
                selectedBgColor: const Color(0xFFF5BF38),
                selectedTextColor: const Color(0xFF1E293B),
                selectedBorderColor: const Color(0xFFF5BF38),
                onTap: () => setState(() => _selectedRating = '3plus'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvailabilitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('AVAILABILITY'),
        const SizedBox(height: 12.0),
        Row(
          children: [
            Expanded(
              child: _buildPillChip(
                key: const Key('availability_chip_all'),
                label: 'All',
                isSelected: _selectedAvailability == 'all',
                onTap: () => setState(() => _selectedAvailability = 'all'),
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: _buildPillChip(
                key: const Key('availability_chip_inStock'),
                label: 'In Stock',
                isSelected: _selectedAvailability == 'inStock',
                onTap: () => setState(() => _selectedAvailability = 'inStock'),
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: _buildPillChip(
                key: const Key('availability_chip_outOfStock'),
                label: 'Out Of-Stock',
                isSelected: _selectedAvailability == 'outOfStock',
                onTap: () => setState(() => _selectedAvailability = 'outOfStock'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSpecialOffersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('SPECIAL OFFERS'),
        const SizedBox(height: 12.0),
        Row(
          children: [
            Expanded(
              child: _buildPillChip(
                key: const Key('special_chip_all'),
                label: 'All Items',
                isSelected: _selectedSpecialOffers == 'all',
                selectedBgColor: const Color(0xFFBA4E68),
                selectedTextColor: Colors.white,
                selectedBorderColor: const Color(0xFFBA4E68),
                onTap: () => setState(() => _selectedSpecialOffers = 'all'),
              ),
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: _buildPillChip(
                key: const Key('special_chip_sale'),
                label: 'Sale Items',
                isSelected: _selectedSpecialOffers == 'sale',
                selectedBgColor: const Color(0xFFBA4E68),
                selectedTextColor: Colors.white,
                selectedBorderColor: const Color(0xFFBA4E68),
                onTap: () => setState(() => _selectedSpecialOffers = 'sale'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final count = _activeCount;
    final applyText = count > 0 ? 'Apply ($count)' : 'Apply';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFF1F5F9), width: 1.0),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                key: const Key('filter_clear_all_btn'),
                onTap: _resetLocalFilters,
                borderRadius: BorderRadius.circular(24.0),
                child: Container(
                  height: 48.0,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24.0),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Clear All',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14.0),
            Expanded(
              child: InkWell(
                key: const Key('filter_apply_btn'),
                onTap: _applyFilters,
                borderRadius: BorderRadius.circular(24.0),
                child: Container(
                  height: 48.0,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF223832),
                    borderRadius: BorderRadius.circular(24.0),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      applyText,
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
