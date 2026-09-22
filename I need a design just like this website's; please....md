# **UI/UX Design System & Specification Document**

**Project:** Book Vardi (Mobile App & Responsive Web)

**Target Consumer:** Antigravity Autonomous Coding Agent

**Design Paradigm:** Utility-first, mobile-native e-commerce, school-focused micro-brand aesthetic.

## **1\. Design Tokens & Visual Hierarchy**

### **1.1. Color Palette**

&nbsp;

&nbsp;

&nbsp;

Surface Neutral:      \#F8FAFC ──── \#FFFFFF  
Text Primary:         \#0F172A  
Primary Navy:         \#1E3A8A ── (School Trust / Brand Identity)  
Secondary Amber:      \#F59E0B ── (Discounts / Promotional Badges)  
Success Green:        \#10B981 ── (In-Stock / Delivery Confirmed)  
Destructive Red:      \#EF4444 ── (Out of Stock / Form Errors)

| Token Name | Hex Code | Tailwind Token | Flutter ColorScheme Role | Usage |
| :---- | :---- | :---- | :---- | :---- |
| color-primary | \#1E3A8A | blue-900 | primary | Headers, primary CTAs, active tab icons |
| color-primary-hover | \#1E40AF | blue-800 | primaryContainer | Hover states, button press overlays |
| color-accent | \#F59E0B | amber-500 | tertiary | Discount tags, sale pills, rating stars |
| color-background | \#F8FAFC | slate-50 | surface | Scaffold background, category pill track |
| color-surface | \#FFFFFF | white | surfaceContainerLowest | Card containers, modals, bottom sheets |
| color-border | \#E2E8F0 | slate-200 | outlineVariant | Dividers, card strokes, unselected chips |
| color-text-primary | \#0F172A | slate-900 | onSurface | Product titles, prices, headings |
| color-text-secondary | \#64748B | slate-500 | onSurfaceVariant | SKU metadata, grade labels, delivery notes |
| color-success | \#10B981 | emerald-500 | secondary | Order delivered, "In Stock" indicators |
| color-danger | \#EF4444 | red-500 | error | Form validation, "Out of Stock", cancel action |

### **1.2. Typography (Type Scale)**

* **Font Family:** Plus Jakarta Sans or Inter (sans-serif fallbacks: system-ui, \-apple-system, Roboto).  
* **Scale Factor:** $1.25$ (Major Third).

&nbsp;

&nbsp;

&nbsp;

Display Large: 32px / SemiBold (700) ── Home Hero Banner Headings  
Heading 1:     24px / Bold (700)     ── Screen Titles (PDP Title, Cart Header)  
Heading 2:     18px / SemiBold (600) ── Section Titles ("Featured Categories")  
Body Regular:  14px / Regular (400)  ── Descriptions, Input Fields, Specifications  
Body Medium:   14px / Medium (500)   ── Buttons, Table Headers, Filter Labels  
Caption:       12px / Medium (500)   ── Badges, Variant Labels, Delivery Estimates  
Micro:         10px / Regular (400)  ── Footnotes, SKU Numbers, Timestamps

### **1.3. Spacing, Elevation & Corner Radii**

* **Spacing Grid Unit:** $4\\text{px}$ Base (4px, 8px, 12px, 16px, 24px, 32px).  
* **Corner Radius (border-radius):**  
  * Micro (Badges, Tags): 4px  
  * Small (Buttons, Input Fields): 8px  
  * Medium (Product Cards, Category Tiles): 12px  
  * Large (Bottom Sheets, Auth Cards, Modals): 20px (top-left, top-right only for bottom sheets)  
  * Full (Pills, Counter Steppers): 9999px  
* **Elevation / Shadows:**  
  * elevation-sm: 0 1px 2px 0 rgb(0 0 0 / 0.05) (Product cards, input inputs)  
  * elevation-md: 0 4px 6px \-1px rgb(0 0 0 / 0.1), 0 2px 4px \-2px rgb(0 0 0 / 0.1) (Hovered cards, dropdowns)  
  * elevation-lg: 0 10px 15px \-3px rgb(0 0 0 / 0.1), 0 4px 6px \-4px rgb(0 0 0 / 0.1) (Bottom navigation, Modals)

## **2\. Global Layout & Screen Shells**

### **2.1. Breakpoint Grid**

&nbsp;

&nbsp;

&nbsp;

Mobile (Target: 360px \- 428px viewport)  
└── Fluid 4-column grid | Margin: 16px | Gutter: 12px

Tablet (Target: 768px \- 1024px viewport)  
└── Fluid 8-column grid | Margin: 32px | Gutter: 16px

Desktop (Target: 1280px+ viewport)  
└── Max Content Container: 1200px centered | 12-column grid | Gutter: 24px

### **2.2. Navigation Scaffolding**

&nbsp;

&nbsp;

&nbsp;

MOBILE SHELL  
┌──────────────────────────────────────────────┐  
│ \[☰\]  BOOK VARDI                 \[🔍\]  \[🛒 2\] │ ◄ Fixed Top App Bar (H: 56px)  
├──────────────────────────────────────────────┤  
│                                              │  
│                                              │  
│             SCROLLABLE VIEWPORT              │  
│                                              │  
│                                              │  
├──────────────────────────────────────────────┤  
│  \[Home\]  \[Category\]  \[Cart\]  \[Orders\] \[User\] │ ◄ Fixed Bottom Nav Bar (H: 64px)  
└──────────────────────────────────────────────┘

DESKTOP SHELL  
┌────────────────────────────────────────────────────────────────────────┐  
│ BOOK VARDI  | \[Search books, uniforms...\] 🔍 | Schools | Cart(2) | Acc │ ◄ Header (H: 72px)  
├────────────────────────────────────────────────────────────────────────┤  
│ Categories: Books | Uniforms | Stationery | School Bags | Shoes | Sale │ ◄ Nav Rail (H: 40px)  
├────────────────────────────────────────────────────────────────────────┤  
│                          CONTENT CONTAINER (1200px)                    │  
└────────────────────────────────────────────────────────────────────────┘

## **3\. Core Component Specifications**

### **3.1. Primary Button (CustomButton)**

* **Height:** 48px (Full width on mobile sheets; Auto width min-w-\[140px\] on desktop).  
* **Border Radius:** 8px.  
* **Variants:**  
  * **Filled:** Background \#1E3A8A, Text \#FFFFFF, Typography Body Medium (14px).  
  * **Secondary / Outline:** Background \#FFFFFF, Border 1px solid \#1E3A8A, Text \#1E3A8A.  
  * **Accent / Buy Now:** Background \#F59E0B, Text \#0F172A, Weight SemiBold (600).  
  * **Disabled:** Background \#CBD5E1, Text \#94A3B8, Cursor not-allowed.  
* **State Behavior:**  
  * Loading state: Replaces text with a circular progress spinner (20px, \#FFFFFF, stroke width 2.5px).

### **3.2. Product Card Component (ProductCard)**

Card footprint in mobile grid: width: 100%, aspect ratio of preview image 1:1.

&nbsp;

&nbsp;

&nbsp;

┌──────────────────────────────┐  
│ \[Badge: 20% OFF\]     \[♡ Wish\]│ ◄ Badges Absolute (Top-4)  
│                              │  
│         PRODUCT IMAGE        │ ◄ Gray neutral bg (\#F1F5F9), Object-contain  
│          (1:1 Ratio)         │  
│                              │  
├──────────────────────────────┤  
│ St. Xavier's High School     │ ◄ Micro text (\#64748B), 1 line truncate  
│ Complete Uniform Set (Boys)  │ ◄ Body Medium (\#0F172A), 2 line clamp  
│ Class: 5th \- 8th Std         │ ◄ Caption text (\#475569)  
│                              │  
│ ₹1,299  \~\~₹1,599\~\~           │ ◄ Price (16px Bold) \+ Strikethrough (\#94A3B8)  
├──────────────────────────────┤  
│ \[      ADD TO CART \+       \] │ ◄ Outlined Button (H: 36px, Radius: 6px)  
└──────────────────────────────┘

* **Props Contract:**  
  TypeScript  
  interface ProductCardProps {  
  &nbsp;&nbsp;id: string;  
  &nbsp;&nbsp;title: string;  
  &nbsp;&nbsp;schoolName?: string;  
  &nbsp;&nbsp;targetGrade?: string;  
  &nbsp;&nbsp;price: number;  
  &nbsp;&nbsp;originalPrice?: number;  
  &nbsp;&nbsp;imageUrl: string;  
  &nbsp;&nbsp;inStock: boolean;  
  &nbsp;&nbsp;isWishlisted: boolean;  
  &nbsp;&nbsp;onAddToCart: (id: string) \=\> void;  
  &nbsp;&nbsp;onToggleWishlist: (id: string) \=\> void;  
  &nbsp;&nbsp;onClick: (id: string) \=\> void;  
  }

### **3.3. Category Pill / Quick Rail (CategoryItem)**

* **Container:** Horizontal scroll view with physics bounce.  
* **Item Geometry:** width: 76px, gap: 12px.  
* **Visual Anchor:** Circle container (60px × 60px), Background \#EFF6FF, Border 1px solid \#DBEAFE.  
* **Icon / Asset:** Centered vector or 3D product render (36px × 36px).  
* **Label:** Caption (12px), Center aligned, single line truncate.

### **3.4. Contextual Auth Modal (The "Guest Guard" Intercept Sheet)**

Triggered automatically when a guest taps **Add to Cart**, **Wishlist**, **Buy Now**, or bottom nav **Cart / Orders**.

&nbsp;

&nbsp;

&nbsp;

┌────────────────────────────────────────────────────────┐  
│                        ─ ─ ─                           │ ◄ Drag Handle (W: 40px, H: 4px)  
│                                                        │  
│  Welcome to Book Vardi                                 │ ◄ Heading 1 (20px, Bold)  
│  Please sign in to add items and manage your orders    │ ◄ Body Regular (\#64748B)  
│                                                        │  
│  \[ Email or Phone Number                             \] │ ◄ Input (H: 48px, Radius: 8px)  
│  \[ Password                                          \] │ ◄ Password field with eye-toggle  
│                                                        │  
│  \[                LOGIN TO CONTINUE                  \] │ ◄ Filled Primary Button  
│                                                        │  
│  ─────────────── or continue with ───────────────      │ ◄ Divider with text  
│                                                        │  
│  \[ G  Continue with Google                           \] │ ◄ Social Login Button  
│                                                        │  
│  Don't have an account? Create Account                 │ ◄ Inline link (\#1E3A8A)  
│                                                        │  
│  \[ Continue Browsing as Guest \]                        │ ◄ Text Button (\#64748B)  
└────────────────────────────────────────────────────────┘

* **Interaction Blueprint:**  
  * Slides up from bottom on mobile (Offset(0, 1\) \-\> Offset(0, 0\) in 250ms).  
  * Centered dialog modal on desktop viewports (max-width: 440px, backdrop blur 4px).  
  * Does NOT reset selected size/variant parameters in state when completed.

## **4\. Screen-by-Screen Layout Blueprints**

### **4.1. Screen 1: Home Dashboard**

&nbsp;

&nbsp;

&nbsp;

┌─────────────────────────────────────────────────────────┐  
│ ☰  BOOK VARDI                              🔍   🛒 \[2\] │  
├─────────────────────────────────────────────────────────┤  
│ ┌─────────────────────────────────────────────────────┐ │  
│ │ PROMO BANNER CAROUSEL (Aspect 16:9 or 21:9)        │ │  
│ │ "Back to School 2026: Flat 20% on Full Sets"        │ │  
│ │ \[ Shop By School → \]                                │ │  
│ └─────────────────────────────────────────────────────┘ │  
│   ● ○ ○ ○ (Pagination Dots)                             │  
├─────────────────────────────────────────────────────────┤  
│ Shop By Category                               \[View All\]│  
│ (Rail) \[Uniform\] \[Books\] \[Bags\] \[Shoes\] \[Stationery\]    │  
├─────────────────────────────────────────────────────────┤  
│ Filter By School                                        │  
│ \[ All Schools ▼ \]   \[ Select Class / Grade ▼ \]          │  
├─────────────────────────────────────────────────────────┤  
│ Recommended Bundles                                     │  
│ ┌──────────────────┐  ┌──────────────────┐              │  
│ │ \[Bundle Card\]    │  │ \[Bundle Card\]    │              │  
│ │ Class 6 Book Set │  │ Complete Uniform │              │  
│ │ ₹2,450           │  │ ₹1,890           │              │  
│ └──────────────────┘  └──────────────────┘              │  
├─────────────────────────────────────────────────────────┤  
│ Popular Items                                           │  
│ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐             │  
│ │ Card 1 │ │ Card 2 │ │ Card 3 │ │ Card 4 │             │  
│ └────────┘ └────────┘ └────────┘ └────────┘             │  
└─────────────────────────────────────────────────────────┘

### **4.2. Screen 2: Product Detail Page (PDP)**

* **Top App Bar:** Transparent-to-white on scroll, Back arrow, Search icon, Cart badge counter.  
* **Section 1: Gallery Carousel:**  
  * Square aspect ratio 1:1.  
  * Multi-image thumbnail strip below main preview.  
* **Section 2: Pricing & Title Block:**  
  * School Identity Badge: \[St. Anne's Convent School\] (Tag with soft border).  
  * Product Title: Heading 1 (20px).  
  * Rating & Reviews summary: ★ 4.4 (128 reviews).  
  * Price: ₹850 (24px Bold) with MRP ₹1,050 and (19% off) badge.  
* **Section 3: Variant Matrix Selector:**  
  * **Size Selection (Uniforms/Shoes):**  
    Select Size: \[Size Chart Link ↗\]  
    ( ) 28   (•) 30 \[In Stock\]   ( ) 32   ( ) 34 \[Out of Stock \- Strikethrough\]

  * **Grade/Standard Selection (Textbooks):**  
    Select Class:  
    \[ Class 1 \] \[ Class 2 \] \[ Class 3 \] ...

* **Section 4: Specifications & Set Contents:**  
  * Key-value table layout:  
    * Material: 100% Combed Cotton / Poly-blend  
    * School Board: CBSE  
    * Fit Type: Regular School Standard  
    * Return Policy: 7-day exchange for sizing issues  
* **Section 5: Sticky Purchase Bar (Bottom Fixed on Mobile):**  
  ┌────────────────────────────────────────────────────────┐  
  │ ₹850.00         │ \[ Add to Cart \]   │ \[  Buy Now   \] │  
  │ (Inclusive tax) │ (Outline Navy)    │ (Filled Amber) │  
  └────────────────────────────────────────────────────────┘

### **4.3. Screen 3: Cart & Checkout Stepper**

* **Stepper Header:** \[ 1\. Cart \] ─── \[ 2\. Address \] ─── \[ 3\. Payment \]

#### **Cart List View (Step 1):**

* Items itemized with thumbnail (64px × 64px), title, selected variant pill (Size: 32), dynamic price.  
* Stepper Quantity Controller: \[ \- \] 1 \[ \+ \] (Triggers confirm dialog on 0).  
* Price Breakup Card:  
  * Items Total: ₹2,149.00  
  * School Bulk Discount: \-₹200.00  
  * Estimated Shipping: FREE (Orders above ₹999)  
  * Total Payable: ₹1,949.00

#### **Address Selection (Step 2):**

* Radio selector card group for saved addresses (Home, School Delivery).  
* \+ Add New Delivery Address CTA modal trigger.

#### **Payment Rail (Step 3):**

* Payment Radio Group:  
  1. UPI Options (Google Pay, PhonePe, Paytm, Any UPI ID)  
  2. Credit / Debit Card (Visa, Mastercard, RuPay)  
  3. Net Banking  
  4. Cash on Delivery (COD) (with ₹40 processing fee pill)  
* Security Assurance Banner: 🔒 256-bit SSL Encrypted Transaction.

### **4.4. Screen 4: Real-time Order Tracking**

&nbsp;

&nbsp;

&nbsp;

Order ID: \#BV-2026-9812  
Placed On: 18 Sep 2026

\[●\] ORDER PLACED ──────────────── 18 Sep, 10:30 AM  
&nbsp;│  "Order confirmed by Book Vardi"  
&nbsp;│  
\[●\] PACKED ────────────────────── 18 Sep, 03:45 PM  
&nbsp;│  "Items boxed & quality inspected"  
&nbsp;│  
\[○\] SHIPPED ───────────────────── Expected 19 Sep  
&nbsp;│  "Carrier: Delhivery | Track: DL982312389"  
&nbsp;│  
\[○\] OUT FOR DELIVERY ──────────── Pending  
&nbsp;│  
\[○\] DELIVERED ─────────────────── Estimated: 20 Sep 2026

\[ Need Help with Order? \]   \[ Download Tax Invoice \]

## **5\. Animation, Gestures & Feedback Rules**

* **Page Transitions:** Standard platform-native smooth sliding:  
  * Android: Predictive Back / Material Shared Axis.  
  * iOS: CupertinoPageRoute (edge swipe back support mandatory).  
* **Button Tap Feedback:**  
  * Immediate scale transform: transform: scale(0.98) with duration 100ms.  
  * Haptic Feedback: HapticFeedback.lightImpact() on all variant selects and CTA taps.  
* **Skeleton / Loading States:**  
  * No blocking spinners for lists; use shimmer pulse animation.  
  * Gradient: \#E2E8F0 transitioning to \#F1F5F9 at 1200ms infinite loop.  
* **Toast / SnackBar Notifications:**  
  * Bottom floating capsule (margin: 16px, border-radius: 8px).  
  * Duration: 2500ms. Action button optional (UNDO).

## **6\. Implementation Code Contracts for Agent**

### **6.1. Tailwind Config Theme Extension (tailwind.config.js)**

&nbsp;

&nbsp;

&nbsp;

JavaScript

module.exports \= {  
&nbsp;&nbsp;theme: {  
&nbsp;&nbsp;&nbsp;&nbsp;extend: {  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;colors: {  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;brand: {  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;navy: '\#1E3A8A',  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;'navy-hover': '\#1E40AF',  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;amber: '\#F59E0B',  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;surface: '\#F8FAFC',  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;card: '\#FFFFFF',  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;}  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;},  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;fontFamily: {  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;sans: \['Plus Jakarta Sans', 'Inter', 'sans-serif'\],  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;},  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;borderRadius: {  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;'card': '12px',  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;'sheet': '20px',  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;},  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;boxShadow: {  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;'card-soft': '0 2px 8px \-2px rgba(15, 23, 42, 0.08)',  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;'nav-bar': '0 \-2px 10px rgba(0, 0, 0, 0.05)',  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;}  
&nbsp;&nbsp;&nbsp;&nbsp;}  
&nbsp;&nbsp;}  
}

### **6.2. Flutter Theme System Baseline (app\_theme.dart)**

&nbsp;

&nbsp;

&nbsp;

Dart

import 'package:flutter/material.dart';

class BookVardiTheme {  
&nbsp;&nbsp;static const Color primaryNavy \= Color(0xFF1E3A8A);  
&nbsp;&nbsp;static const Color accentAmber \= Color(0xFFF59E0B);  
&nbsp;&nbsp;static const Color backgroundSlate \= Color(0xFFF8FAFC);  
&nbsp;&nbsp;static const Color surfaceWhite \= Color(0xFFFFFFFF);  
&nbsp;&nbsp;static const Color textDark \= Color(0xFF0F172A);  
&nbsp;&nbsp;static const Color borderGray \= Color(0xFFE2E8F0);

&nbsp;&nbsp;static ThemeData get lightTheme {  
&nbsp;&nbsp;&nbsp;&nbsp;return ThemeData(  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;useMaterial3: true,  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;scaffoldBackgroundColor: backgroundSlate,  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;fontFamily: 'PlusJakartaSans',  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;colorScheme: const ColorScheme.light(  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;primary: primaryNavy,  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;secondary: accentAmber,  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;surface: surfaceWhite,  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;onSurface: textDark,  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;outlineVariant: borderGray,  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;),  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;appBarTheme: const AppBarTheme(  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;backgroundColor: surfaceWhite,  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;elevation: 0,  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;scrolledUnderElevation: 1,  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;titleTextStyle: TextStyle(  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;color: textDark,  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;fontSize: 18,  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;fontWeight: FontWeight.w700,  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;),  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;iconTheme: IconThemeData(color: primaryNavy),  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;),  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;elevatedButtonTheme: ElevatedButtonThemeData(  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;style: ElevatedButton.styleFrom(  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;backgroundColor: primaryNavy,  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;foregroundColor: Colors.white,  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;minimumSize: const Size.fromHeight(48),  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;shape: RoundedRectangleBorder(  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;borderRadius: BorderRadius.circular(8),  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;),  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;textStyle: const TextStyle(  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;fontSize: 14,  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;fontWeight: FontWeight.w600,  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;),  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;),  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;),  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;cardTheme: CardTheme(  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;color: surfaceWhite,  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;elevation: 0,  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;shape: RoundedRectangleBorder(  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;borderRadius: BorderRadius.circular(12),  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;side: const BorderSide(color: borderGray, width: 1),  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;),  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;),  
&nbsp;&nbsp;&nbsp;&nbsp;);  
&nbsp;&nbsp;}  
}

## **7\. Quality Checklist for Code Generation**

Before considering any screen implementation complete, verify:

* \[ \] **Guest Guard Integrity:** Tapping any transactional CTA without a valid auth token halts navigation and renders the AuthModalBottomSheet.  
* \[ \] **Responsive Breakpoint Stability:** Layout collapses to 2 columns on \< 640px and expands cleanly to 4 columns on desktop without viewport overflow errors.  
* \[ \] **Form Labeling & Accessibility:** All inputs include explicit \<label\> or InputDecoration.labelText and WCAG AA contrast against \#FFFFFF / \#F8FAFC.  
* \[ \] **Safe Area Compliance:** Bottom navigation and sticky CTA bars strictly honor SafeArea / env(safe-area-inset-bottom) for iOS indicator bars.