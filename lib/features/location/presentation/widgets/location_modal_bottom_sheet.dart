import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_typography.dart';
import '../../domain/location_hub_model.dart';
import '../controllers/location_controller.dart';

/// 1:1 Location Selector Pop-Up Dialog matching the Book Vardi web design.
class LocationModalBottomSheet extends ConsumerWidget {
  const LocationModalBottomSheet({super.key});

  /// Displays the Location Selector as a centered pop-up dialog with rounded corners.
  static Future<LocationHubModel?> show(BuildContext context) {
    return showDialog<LocationHubModel>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (context) => const LocationModalBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(locationControllerProvider);
    final activeHub = locationState.currentHub;
    final size = MediaQuery.of(context).size;
    final maxHeight = size.height * 0.88;
    final maxWidth = math.min(size.width - 32.0, 440.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 24.0,
      ),
      elevation: 0,
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: maxHeight * 0.86,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 28.0,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Dark Green Pine Header Banner with Pin Icon & Close Button
                _buildHeader(context),

                // Main Body Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(18.0, 10.0, 18.0, 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 2. Large Yellow GPS Action Button
                      _buildGpsButton(context, ref, locationState),
                      const SizedBox(height: 10.0),

                      // 3. Privacy Assurance
                      _buildPrivacyAssurance(),
                      const SizedBox(height: 10.0),

                      // 4. "OR CHOOSE CITY" Divider
                      _buildDivider(),
                      const SizedBox(height: 10.0),

                      // 5. Popular Cities & Hubs 2-Column Grid
                      _buildPopularHubsGrid(context, ref, activeHub),
                      const SizedBox(height: 10.0),

                      // 6. Current Active Filter Card
                      _buildCurrentFilterCard(activeHub),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 1. Dark Green Header with Circular Yellow Pin and Fixed Top-Right Close Button
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF0F291E), // Dark Pine Green matching website
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10.0, 16.0, 10.0, 16.0),
            child: Column(
              children: [
                // Circular Yellow Location Pin Icon
                Container(
                  width: 56.0,
                  height: 56.0,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBBF24), // Amber/Yellow
                    borderRadius: BorderRadius.circular(16.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 10.0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.location_on_rounded,
                      color: Color(0xFF0F172A),
                      size: 32.0,
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),

                // Title: "Find Schools Near You"
                const Text(
                  'Find Schools Near You',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 21.0,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6.0),

                // Subtitle with highlighted "25 km"
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 11.5,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                      children: [
                        TextSpan(
                          text: 'Allow location access to discover official school uniforms & book sets within the admin-defined ',
                        ),
                        TextSpan(
                          text: '25 km',
                          style: TextStyle(
                            color: Color(0xFFFDE047),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(text: ' radius.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Top-right positioned Close Button (Doesn't affect dialog height or push icon)
          Positioned(
            top: 8.0,
            right: 8.0,
            child: IconButton(
              key: const Key('location_modal_close_button'),
              icon: const Icon(
                Icons.close_rounded,
                color: Colors.white70,
                size: 22.0,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }

  /// 2. GPS Location Button
  Widget _buildGpsButton(
    BuildContext context,
    WidgetRef ref,
    LocationState locationState,
  ) {
    return SizedBox(
      height: 40.0,
      child: ElevatedButton(
        key: const Key('use_gps_location_button'),
        onPressed: locationState.isLoadingGps
            ? null
            : () async {
                final result = await ref
                    .read(locationControllerProvider.notifier)
                    .useCurrentGpsLocation();

                if (!context.mounted) return;

                if (result == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Location access not granted. Please pick your city from Popular Cities below.',
                      ),
                      backgroundColor: Color(0xFF0F172A),
                    ),
                  );
                  return;
                }

                if (!result.isWithinOperationalRadius) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'We are currently serving in Lucknow, Kanpur & NCR. Showing nearest hub: ${result.hub.name}',
                      ),
                      backgroundColor: const Color(0xFF0F291E),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }

                Navigator.of(context).pop(result.hub);
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFBBF24), // Yellow
          foregroundColor: const Color(0xFF0F172A),
          disabledBackgroundColor: const Color(0xFFFBBF24)
              .withValues(alpha: 0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
        ),
        child: locationState.isLoadingGps
            ? const SizedBox(
                width: 20.0,
                height: 20.0,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F172A)),
                ),
              )
            : const FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.navigation_rounded,
                      size: 18.0,
                      color: Color(0xFF0F172A),
                    ),
                    SizedBox(width: 8.0),
                    Text(
                      'Use Current GPS Location',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  /// 3. Privacy note
  Widget _buildPrivacyAssurance() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.verified_user_outlined,
          size: 15.0,
          color: Color(0xFF10B981), // Emerald green
        ),
        SizedBox(width: 6.0),
        Flexible(
          child: Text(
            'We never store or share your exact coordinates',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 11.5,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// 4. Line divider with "OR CHOOSE CITY"
  Widget _buildDivider() {
    return const Row(
      children: [
        Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1.0)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.0),
          child: Text(
            'OR CHOOSE CITY',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 11.0,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: Color(0xFF94A3B8),
            ),
          ),
        ),
        Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1.0)),
      ],
    );
  }

  /// 5. Popular Cities & Hubs 2-Column Grid
  Widget _buildPopularHubsGrid(
    BuildContext context,
    WidgetRef ref,
    LocationHubModel activeHub,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'POPULAR CITIES & HUBS',
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 11.0,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 12.0),

        // 2-Column Layout (Responsive to dialog container width)
        LayoutBuilder(
          builder: (context, constraints) {
            final double itemWidth = (constraints.maxWidth - 10.0) / 2;

            return Wrap(
              spacing: 10.0,
              runSpacing: 10.0,
              children: LocationHubModel.popularHubs.map((hub) {
                final isSelected =
                    activeHub.id == hub.id || activeHub.city == hub.city;

                return InkWell(
                  key: Key('location_chip_${hub.id}'),
                  onTap: () {
                    ref
                        .read(locationControllerProvider.notifier)
                        .selectHub(hub);
                    Navigator.of(context).pop(hub);
                  },
                  borderRadius: BorderRadius.circular(16.0),
                  child: Container(
                    width: itemWidth,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 6.0,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF0F291E)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF0F291E)
                            : const Color(0xFFE2E8F0),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            hub.name,
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 12.0,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 4.0),
                          const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 16.0,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  /// 6. Current Active Filter Capsule Card (Bottom)
  Widget _buildCurrentFilterCard(LocationHubModel activeHub) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Current Active Filter Label & City
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CURRENT ACTIVE FILTER',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  activeHub.name,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 13.0,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Right: Badge Counter (e.g. "4 / 12 in 25 km")
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10.0,
              vertical: 4.0,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Text(
              '${activeHub.activeSchools} / ${activeHub.totalSchools} in 25 km',
              style: const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 11.0,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F291E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Type alias for semantic clarity when presenting as a pop-up dialog
typedef LocationPopupDialog = LocationModalBottomSheet;
