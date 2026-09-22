import 'package:flutter/material.dart';

/// Design tokens for colors specified in Book Vardi Design System.
class AppColors {
  const AppColors._();

  // Primary & Secondary Brand Colors (Website Deep Pine Green & Warm School Bus Gold)
  static const Color primaryNavy = Color(0xFF142921); // #142921: Deep Pine / Forest Green
  static const Color primaryNavyHover = Color(0xFF1D3B30); // #1D3B30: Forest Green Hover
  static const Color primaryPineGreen = Color(0xFF142921);
  static const Color primaryPineGreenHover = Color(0xFF1D3B30);
  static const Color secondaryAmber = Color(0xFFFBBF24); // #FBBF24: Warm Golden Yellow / CTAs
  static const Color secondaryAmberDark = Color(0xFFF59E0B); // #F59E0B: Amber for ratings / badges

  // Website Theme Highlights & Cards
  static const Color accentRose = Color(0xFFE11D48); // #E11D48: Rose highlight in headlines
  static const Color announcementDarkBg = Color(0xFF0F241D); // #0F241D: Top announcement bar
  static const Color mintPillBg = Color(0xFFECFDF5); // #ECFDF5: Delivery pill background
  static const Color mintPillText = Color(0xFF047857); // #047857: Delivery pill text
  static const Color creamCardBg = Color(0xFFFFFBEB); // #FFFBEB: Warm kit combo background
  static const Color creamCardBorder = Color(0xFFFEF08A); // #FEF08A: Warm kit border

  // Surfaces & Backgrounds
  static const Color backgroundSlate = Color(0xFFF8FAFC); // slate-50: Scaffold background
  static const Color surfaceWhite = Color(0xFFFFFFFF); // white: Cards, Modals, Bottom sheets
  static const Color imagePlaceholder = Color(0xFFF1F5F9); // slate-100: Neutral image preview
  static const Color categoryPillBg = Color(0xFFF0FDF4); // mint-50: Category rail container
  static const Color categoryPillBorder = Color(0xFFDCFCE7); // mint-100: Category rail border

  // Structural & Borders
  static const Color borderGray = Color(0xFFE2E8F0); // slate-200: Dividers, card strokes

  // Typography & Text
  static const Color textDark = Color(0xFF0F172A); // slate-900: Headings, titles, prices
  static const Color textSecondary = Color(0xFF64748B); // slate-500: Metadata, SKU, notes
  static const Color textMuted = Color(0xFF94A3B8); // slate-400: Strikethrough, placeholders

  // Functional & Semantic Status
  static const Color successGreen = Color(0xFF10B981); // emerald-500: In stock, Delivered
  static const Color destructiveRed = Color(0xFFEF4444); // red-500: Out of stock, Errors, Cancel
  static const Color disabledBg = Color(0xFFCBD5E1); // slate-300: Disabled buttons/inputs
  static const Color disabledText = Color(0xFF94A3B8); // slate-400: Disabled text

  // Shimmer Pulse Gradients
  static const Color shimmerBase = Color(0xFFE2E8F0); // slate-200
  static const Color shimmerHighlight = Color(0xFFF1F5F9); // slate-100
}
