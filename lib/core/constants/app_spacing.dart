import 'package:flutter/material.dart';

/// Design tokens for 4px base grid spacing, corner radii, and shadow elevations.
class AppSpacing {
  const AppSpacing._();

  // 4px Base Grid Spacing Units
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;

  // Corner Radii Constants
  static const double radiusMicro = 4.0; // Badges, Pills, Tags
  static const double radiusSmall = 8.0; // Buttons, Input Fields, SnackBars
  static const double radiusMedium = 12.0; // Product Cards, Category Tiles
  static const double radiusLarge = 20.0; // Bottom Sheets, Auth Cards, Modals
  static const double radiusFull = 9999.0; // Stepper capsules, round buttons

  // BorderRadius Convenience Getters
  static const BorderRadius roundedMicro = BorderRadius.all(Radius.circular(radiusMicro));
  static const BorderRadius roundedSmall = BorderRadius.all(Radius.circular(radiusSmall));
  static const BorderRadius roundedMedium = BorderRadius.all(Radius.circular(radiusMedium));
  static const BorderRadius roundedLarge = BorderRadius.all(Radius.circular(radiusLarge));
  static const BorderRadius roundedFull = BorderRadius.all(Radius.circular(radiusFull));

  // Bottom Sheet Radius (Top corners only)
  static const BorderRadius sheetRadius = BorderRadius.only(
    topLeft: Radius.circular(radiusLarge),
    topRight: Radius.circular(radiusLarge),
  );

  // Elevation Shadows
  static const List<BoxShadow> elevationSm = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.05),
      blurRadius: 2.0,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> elevationMd = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.1),
      blurRadius: 6.0,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.1),
      blurRadius: 4.0,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> elevationLg = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.1),
      blurRadius: 15.0,
      offset: Offset(0, 10),
    ),
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.1),
      blurRadius: 6.0,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> shadowCardSoft = [
    BoxShadow(
      color: Color.fromRGBO(15, 23, 42, 0.08),
      blurRadius: 8.0,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> shadowNavBar = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.05),
      blurRadius: 10.0,
      offset: Offset(0, -2),
    ),
  ];
}
