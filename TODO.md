# Book Vardi — Project Implementation Master TODO List

> **Source Documents Synthesized:**
> - [Product Requirement Document (PRD)](file:///f:/flutter_project/book_vardi/Ab%20workflow%20ko%20Guest%20=%20Browse%20Only%20aur%20Logged-in....md)
> - [UI/UX Design System & Specification](file:///f:/flutter_project/book_vardi/I%20need%20a%20design%20just%20like%20this%20website%27s;%20please....md)
> - [Tech Stack Specification Document](file:///f:/flutter_project/book_vardi/I%20need%20the%20tech%20stack%20DOC%20file%20for%20this%20project..md)
>
> **Execution Directives:**
> 1. **Strictly Sequential:** Every task strictly depends on the completion of the preceding task.
> 2. **Atomic & Singular:** Exactly one focused deliverable per task. No overlapping or bundled sub-tasks.
> 3. **Verification Criteria:** Each task specifies explicit "Done Criteria" to test and verify before moving forward.

---

## Phase 1: Environment, Dependencies & Backend Scaffolding

- [x] **TASK-001: Configure Flutter Project Dependencies in `pubspec.yaml`**
  - **Prerequisites:** None (Initial repo state).
  - **Scope:** Update [pubspec.yaml](file:///f:/flutter_project/book_vardi/pubspec.yaml) to declare exact production-ready dependencies specified in the Tech Stack doc:
    - State & Routing: `flutter_riverpod: ^2.5.1`, `riverpod_annotation: ^2.3.5`, `go_router: ^14.1.4`
    - Firebase Suite: `firebase_core: ^3.1.0`, `firebase_auth: ^5.1.0`, `cloud_firestore: ^5.0.1`, `firebase_storage: ^12.0.1`, `firebase_messaging: ^15.0.1`, `firebase_app_check: ^0.3.0+1`, `firebase_crashlytics: ^4.0.1`
    - Persistence & Network: `flutter_secure_storage: ^9.2.2`, `hive_ce: ^1.8.0`, `hive_ce_flutter: ^1.8.0`, `cached_network_image: ^3.3.1`
    - UI & Utilities: `google_fonts: ^6.2.1`, `shimmer: ^3.0.0`, `flutter_svg: ^2.0.10+1`, `badges: ^3.1.2`, `intl: ^0.19.0`, `uuid: ^4.4.0`
    - Payments: `razorpay_flutter: ^1.3.7`
    - Dev Dependencies: `build_runner: ^2.4.9`, `riverpod_generator: ^2.4.0`, `riverpod_lint: ^2.3.10`, `custom_lint: ^0.6.4`
  - **Done Criteria:** Run `flutter pub get` successfully with zero dependency conflicts and exit code 0.

- [x] **TASK-002: Configure Android Platform Settings & Manifest Permissions**
  - **Prerequisites:** TASK-001
  - **Scope:** In `android/app/build.gradle` and `android/app/src/main/AndroidManifest.xml`:
    - Set `minSdkVersion 23`, `compileSdkVersion 34`, and enable `multiDexEnabled true`.
    - Add required permissions: `INTERNET`, `ACCESS_NETWORK_STATE`, `POST_NOTIFICATIONS`.
    - Configure ProGuard rules in `android/app/proguard-rules.pro` for Razorpay and Firebase.
  - **Done Criteria:** Android Gradle configuration syncs cleanly without compile SDK or multidex errors.

- [x] **TASK-003: Configure iOS Platform Settings & Podfile**
  - **Prerequisites:** TASK-002
  - **Scope:** In `ios/Podfile` and `ios/Runner/Info.plist`:
    - Set iOS platform target `platform :ios, '14.0'`.
    - Configure background modes for Firebase Cloud Messaging in `Info.plist`.
  - **Done Criteria:** Verify Podfile syntax and run `pod install --repo-update` (or dry-run lint) with no version mismatch.

- [x] **TASK-004: Setup Firebase Initialization & Environment Config**
  - **Prerequisites:** TASK-003
  - **Scope:** Create `lib/core/config/env_config.dart` and `lib/core/config/firebase_config.dart`:
    - Support `--dart-define` parameters (`ENVIRONMENT`, `RAZORPAY_KEY_ID`, `ENABLE_APP_CHECK`).
    - Provide structured Firebase bootstrap initialization with error boundary handling.
  - **Done Criteria:** App can compile and call `FirebaseConfig.initialize()` with fallback mock/config parameters without unhandled exceptions.

- [x] **TASK-005: Initialize TypeScript Cloud Functions Scaffolding**
  - **Prerequisites:** TASK-004
  - **Scope:** In `functions/` directory, initialize:
    - `functions/package.json` with Node 20 runtime, `firebase-admin: ^12.1.0`, `firebase-functions: ^5.0.0`, `razorpay: ^2.9.2`, and `zod: ^3.23.8`.
    - `functions/tsconfig.json` with ES2022 target and strict TypeScript checking.
    - `functions/src/index.ts` entrypoint skeleton.
  - **Done Criteria:** Run `npm install` and `npm run build` inside `functions/` producing zero compiler errors.

---

## Phase 2: Design Tokens, Typography & Shared Core UI

- [x] **TASK-006: Implement Design System Color & Spacing Tokens**
  - **Prerequisites:** TASK-005
  - **Scope:** Create `lib/core/constants/app_colors.dart` and `lib/core/constants/app_spacing.dart`:
    - Primary Navy (`#1E3A8A`), Primary Hover (`#1E40AF`), Accent Amber (`#F59E0B`), Background Slate (`#F8FAFC`), Surface White (`#FFFFFF`), Border Gray (`#E2E8F0`), Text Dark (`#0F172A`), Text Secondary (`#64748B`), Success Green (`#10B981`), Destructive Red (`#EF4444`).
    - 4px grid spacing tokens (xs: 4, sm: 8, md: 12, lg: 16, xl: 24, xxl: 32) and Corner Radii (micro: 4, sm: 8, md: 12, sheet: 20, full: 9999).
  - **Done Criteria:** Unit test asserting all hex codes and border radius constants match design specifications exactly.

- [x] **TASK-007: Implement Typography System & Plus Jakarta Sans Font Scale**
  - **Prerequisites:** TASK-006
  - **Scope:** Create `lib/core/theme/app_typography.dart`:
    - Define type scale using `GoogleFonts.plusJakartaSans` (with fallback to Inter/sans-serif).
    - Display Large (32px / 700), Heading 1 (24px / 700), Heading 2 (18px / 600), Body Regular (14px / 400), Body Medium (14px / 500), Caption (12px / 500), Micro (10px / 400).
  - **Done Criteria:** Verify all text style getters conform to the 1.25 major third scale and proper line-height ratios.

- [x] **TASK-008: Implement Global ThemeData Configuration**
  - **Prerequisites:** TASK-007
  - **Scope:** Create `lib/core/theme/app_theme.dart`:
    - Assemble `BookVardiTheme.lightTheme` with `ColorScheme.light` referencing `AppColors`.
    - Configure component themes: `AppBarTheme` (surface white, 0 elevation, navy icon theme), `ElevatedButtonTheme`, `CardTheme` (12px radius, border gray outline), `DividerTheme`, and `InputDecorationTheme`.
  - **Done Criteria:** Set `theme: BookVardiTheme.lightTheme` in `MaterialApp` and verify default scaffold background renders `#F8FAFC`.

- [x] **TASK-009: Build Atomic Shared Component: `CustomButton`**
  - **Prerequisites:** TASK-008
  - **Scope:** Create `lib/shared/widgets/custom_button.dart`:
    - Height: 48px, Radius: 8px, tactile scale animation (`scale: 0.98` on tap) + `HapticFeedback.lightImpact()`.
    - Variants: `Filled` (Primary Navy), `SecondaryOutline` (White bg, Navy border), `AccentBuyNow` (Amber #F59E0B, Dark text), `Disabled` (Slate-300).
    - Built-in loading state displaying 20px centered `CircularProgressIndicator`.
  - **Done Criteria:** Widget test rendering all 4 button states and verifying tap, loading spinner, and disabled behaviors.

- [x] **TASK-010: Build Atomic Shared Component: `CustomTextField`**
  - **Prerequisites:** TASK-009
  - **Scope:** Create `lib/shared/widgets/custom_text_field.dart`:
    - 48px input height, 8px border radius, Slate-200 border, slate-50 focused border `#1E3A8A`.
    - Password visibility eye-toggle for obscureText mode.
    - WCAG AA compliant label text, helper text, and inline validation error text styling.
  - **Done Criteria:** Widget test verifying text input, validation error rendering, and password reveal toggle.

- [x] **TASK-011: Build Atomic Shared Component: `ShimmerLoading`**
  - **Prerequisites:** TASK-010
  - **Scope:** Create `lib/shared/widgets/shimmer_loading.dart`:
    - Pulse animation with gradient `#E2E8F0` to `#F1F5F9` on a 1200ms loop using `package:shimmer`.
    - Provide pre-built presets: `ShimmerTile`, `ShimmerProductCard`, and `ShimmerBanner`.
  - **Done Criteria:** Widget renders without layout overflow across various sizes and animates continuously.

- [x] **TASK-012: Build Base App Shell with Responsive Navigation Scaffolding**
  - **Prerequisites:** TASK-011
  - **Scope:** Create `lib/shared/widgets/app_scaffold_shell.dart`:
    - Fixed Top App Bar (56px) with brand logo/text "BOOK VARDI", Search action icon, and Cart icon with badge counter.
    - Fixed Bottom Navigation Bar (64px) with 5 tabs: [Home, Category, Cart, Orders, User].
    - Strict `SafeArea` compliance for Android & iOS bottom navigation bars.
  - **Done Criteria:** Shell renders on mobile viewports (<640px) with responsive navigation bar switching tabs cleanly.

- [x] **TASK-013: Setup GoRouter Declarative Routing Scaffolding**
  - **Prerequisites:** TASK-012
  - **Scope:** Create `lib/core/router/app_router.dart`:
    - Setup `GoRouter` with `StatefulShellRoute.indexedStack` for bottom navigation tabs.
    - Declare routes: `/` (Home), `/category`, `/cart`, `/orders`, `/profile`, `/product/:id`, `/checkout`, `/order/:id`.
  - **Done Criteria:** Navigation between root shell tabs works without rebuild flash or index state loss.

---

## Phase 3: Authentication, Session & Guest-Guard Interceptor

- [x] **TASK-014: Define User Domain Model & Auth State Entities**
  - **Prerequisites:** TASK-013
  - **Scope:** Create `lib/features/auth/domain/user_model.dart` and `auth_state.dart`:
    - `UserModel` schema: `userId`, `name`, `email`, `phone`, `role` (`customer` | `admin`), `createdAt`, `updatedAt`.
    - `AuthState` union/sealed class: `Initial`, `Loading`, `Unauthenticated(isGuest: true)`, `Authenticated(UserModel)`.
  - **Done Criteria:** Unit tests verifying JSON serialization and immutability for `UserModel`.

- [x] **TASK-015: Implement Auth Repository with Pure Firebase Phone Auth**
  - **Prerequisites:** TASK-014
  - **Scope:** In `lib/features/auth/data/auth_repository.dart`:
    - Pure Phone Auth methods: `verifyPhoneNumber`, `signInWithOtp`, `signOut`, `watchAuthState`.
    - Removed legacy email/password and Google Sign-In SDK.
    - Map Firebase phone user credentials to Firestore `users/{userId}` document.
  - **Done Criteria:** Unit test with mock FirebaseAuth verifying phone + OTP verification and exceptions handling.

- [x] **TASK-016: Implement Auth Riverpod Controller & Session Provider**
  - **Prerequisites:** TASK-015
  - **Scope:** In `lib/features/auth/presentation/controllers/auth_controller.dart`:
    - Provide `authControllerProvider` managing `AuthState`.
    - Methods: `sendOtp`, `verifyOtp`, `logout`, `continueAsGuest`.
    - Default unauthenticated mode transitions to `AuthState.unauthenticated(isGuest: true)`.
  - **Done Criteria:** StateNotifier transitions correctly between Guest and Authenticated on phone OTP verification stream events.

- [x] **TASK-017: Implement Ephemeral `PendingAction` Model & Interceptor Queue**
  - **Prerequisites:** TASK-016
  - **Scope:** Create `lib/core/guards/pending_action.dart`:
    - Enum `PendingActionType`: `addToCart`, `buyNow`, `toggleWishlist`, `openCart`, `openOrders`, `openProfile`.
    - `PendingAction` class: `type`, `productId`, `variantId`, `quantity`, `extraPayload`.
    - Provider `pendingActionProvider` storing active pending intent during auth flow.
  - **Done Criteria:** Unit tests verifying payload retention, retrieval, and clearance on `PendingActionNotifier`.

- [x] **TASK-018: Build Contextual `AuthModalBottomSheet` (Guest Guard Sheet)**
  - **Prerequisites:** TASK-017
  - **Scope:** In `lib/features/auth/presentation/widgets/auth_modal_sheet.dart`:
    - Drag handle, "Welcome to Book Vardi", "Enter your 10-digit mobile number to receive an OTP".
    - Step 1: 10-digit Phone input (+91 prefix), "GET OTP" button, and "Continue Browsing as Guest" dismiss button.
    - Step 2: 6-digit OTP field with autofocus, 30s countdown resend timer, "Edit" number link, and "VERIFY & CONTINUE" button.
    - 20px top corner radius, 250ms slide-up animation.
  - **Done Criteria:** Sheet displays without wiping background route state, executes pending actions seamlessly upon OTP verification.

- [x] **TASK-019: Build Dedicated `LoginScreen` & Registration Screen with Guest Pass-through**
  - **Prerequisites:** TASK-018
  - **Scope:** In `lib/features/auth/presentation/screens/login_screen.dart` and `register_screen.dart`:
    - Full-screen Phone + OTP onboarding view with optional Full Name field.
    - Prominent top-right "Skip" action and bottom "Continue as Guest" card button.
  - **Done Criteria:** Tapping "Skip" or "Continue as Guest" navigates directly to `/` with guest state flag set.

- [x] **TASK-020: Implement `withGuestGuard` Execution Interceptor**
  - **Prerequisites:** TASK-019
  - **Scope:** Create `lib/core/guards/guest_guard.dart`:
    - Interceptor helper function `executeWithAuthGuard(BuildContext context, WidgetRef ref, {required PendingAction action, required VoidCallback onAuthenticated})`.
    - If user is authenticated: immediately executes `onAuthenticated()`.
    - If user is guest: saves action to `pendingActionProvider`, displays `AuthModalBottomSheet`, and executes action seamlessly upon login completion without user losing selected variant.
  - **Done Criteria:** Test simulating guest tap -> modal pops -> user logs in -> `onAuthenticated` callback fires automatically with identical parameters.

---

## Phase 4: Product Catalog, Taxonomies & Discovery Engine

- [x] **TASK-021: Define Catalog Domain Entities & Firestore Schemas**
  - **Prerequisites:** TASK-020
  - **Scope:** Create `lib/features/catalog/domain/product_model.dart`, `category_model.dart`, and `variant_model.dart`:
    - `CategoryModel`: `categoryId`, `name`, `iconUrl`, `displayOrder`.
    - `VariantModel`: `variantId`, `sku`, `label` (e.g. "Size 32", "Class 6"), `price`, `stock`.
    - `ProductModel`: `productId`, `name`, `categoryId`, `schoolName`, `targetGrade`, `description`, `basePrice`, `discountPercentage`, `images`, `isActive`, `isFeatured`, `hasVariants`, `variants`, `totalStock`, `specifications` (`material`, `board`, etc.).
  - **Done Criteria:** Serialization unit tests verifying round-trip JSON parsing matching the PRD Section 5 schema.

- [x] **TASK-022: Implement Firestore Product & Category Repositories**
  - **Prerequisites:** TASK-021
  - **Scope:** Create `lib/features/catalog/data/catalog_repository.dart`:
    - Methods: `fetchCategories()`, `fetchProducts({String? categoryId, String? school, String? grade, String? searchQuery, SortOption? sort})`, `fetchProductById(String id)`.
    - Configure Firestore offline client caching settings (`persistenceEnabled: true`, 100MB cache ceiling).
  - **Done Criteria:** Integration/mock tests verifying query filters, category matching, and offline snapshot emission.

- [x] **TASK-023: Implement Catalog Riverpod State Providers & Filter State**
  - **Prerequisites:** TASK-022
  - **Scope:** Create `lib/features/catalog/presentation/controllers/catalog_controller.dart`:
    - `categoriesProvider`, `featuredProductsProvider`, `catalogFilterProvider` (selected category, school, grade, price range, inStockOnly).
    - Filtered product list provider with reactive debounce for search terms.
  - **Done Criteria:** State updates immediately emit filtered product lists without UI stutter.

- [x] **TASK-024: Build Category Quick Rail Component (`CategoryItem`)**
  - **Prerequisites:** TASK-023
  - **Scope:** Create `lib/features/catalog/presentation/widgets/category_item.dart`:
    - 60x60 circular container, light blue background `#EFF6FF`, border 1px `#DBEAFE`.
    - 36x36 vector icon or image render, caption text label (12px) single-line truncate.
    - Horizontal scroll view with physics bounce.
  - **Done Criteria:** Widget renders items cleanly with smooth horizontal scroll and active selection indicator.

- [x] **TASK-025: Build Product Grid Card Component (`ProductCard`)**
  - **Prerequisites:** TASK-024
  - **Scope:** Create `lib/features/catalog/presentation/widgets/product_card.dart`:
    - 1:1 square aspect ratio image with `#F1F5F9` placeholder background and `CachedNetworkImage`.
    - Badges: discount tag pill (e.g., "20% OFF" amber), wishlist heart button (with guest guard check).
    - School name micro text (`#64748B`), 2-line title clamp, grade caption text, price bold + MRP strikethrough.
    - Outlined "ADD TO CART +" button (H: 36px, radius: 6px) wrapped with `executeWithAuthGuard`.
  - **Done Criteria:** Widget tests verifying discount calculation display, wishlist toggle callback, and Add to Cart trigger.

- [x] **TASK-026: Build Home Dashboard Screen (`HomeScreen`)**
  - **Prerequisites:** TASK-025
  - **Scope:** Create `lib/features/catalog/presentation/screens/home_screen.dart`:
    - Fixed top bar search shortcut and cart counter.
    - Promo banner carousel (16:9 aspect ratio, pagination indicator dots).
    - Category quick rail section with "View All" CTA.
    - "Filter By School" dropdown row (School dropdown + Grade/Class selector).
    - "Recommended Bundles" horizontal scroll section (e.g. Class 6 Book Set).
    - "Popular Items" responsive 2-column mobile grid.
  - **Done Criteria:** Screen renders with zero overflow errors on 360px–428px viewports and responds to pull-to-refresh.

- [x] **TASK-027: Build Search & Filtering Screen with Debounce**
  - **Prerequisites:** TASK-026
  - **Scope:** Create `lib/features/catalog/presentation/screens/search_screen.dart` & `filter_modal.dart`:
    - Instant search input with 300ms debounce.
    - Filter sheet: Category chips, School selector, Grade selector, Price range slider (`RangeSlider`), In-Stock only switch.
    - Sorting options: Price Low to High, Price High to Low, Popularity, Newest.
  - **Done Criteria:** Dynamic query updates results in realtime; clearing filters resets product list.

- [x] **TASK-028: Build Product Detail Page (PDP) Layout & Image Carousel**
  - **Prerequisites:** TASK-027
  - **Scope:** Create `lib/features/catalog/presentation/screens/product_detail_screen.dart`:
    - Top bar: back button, title, search icon, cart badge.
    - 1:1 image carousel with thumbnail strip selector below preview.
    - School identity tag badge, Product title (H1 20px), Rating chip (★ 4.4), Price ₹850 with MRP ₹1,050 and discount pill.
  - **Done Criteria:** Carousel swipes smoothly and tapping thumbnails updates the active preview image.

- [x] **TASK-029: Build PDP Variant Selector Matrix (Size, Grade, Color)**
  - **Prerequisites:** TASK-028
  - **Scope:** Create `lib/features/catalog/presentation/widgets/variant_selector.dart`:
    - Uniform/Shoes: Size selector pills (e.g., 28, 30, 32, 34) with live "In Stock" vs "Out of Stock - Strikethrough" states, plus Size Chart modal link.
    - Textbooks: Class/Grade chips (Class 1, Class 2, ...).
    - Update current SKU, price, and stock counter dynamically upon pill tap with `HapticFeedback.lightImpact()`.
  - **Done Criteria:** Selecting variant modifies price and prevents selecting out-of-stock items.

- [x] **TASK-030: Build PDP Specifications Table & Sticky Bottom Purchase Bar**
  - **Prerequisites:** TASK-029
  - **Scope:** In `product_detail_screen.dart`:
    - Key-value specifications table (Material, School Board, Fit Type, Return Policy).
    - Sticky bottom purchase bar (Safe Area compliant):
      - Left: Live price with "(Inclusive tax)".
      - Center: "Add to Cart" (Outline Navy `CustomButton`).
      - Right: "Buy Now" (Filled Amber `CustomButton`).
    - Connect both buttons to `executeWithAuthGuard`.
  - **Done Criteria:** Sticky bar remains visible during scroll; tapping Add to Cart or Buy Now executes guest intercept if unauthenticated.

---

## Phase 5: Shopping Cart & Wishlist Operations

- [x] **TASK-031: Define Cart & Wishlist Domain Models & Pricing Engine**
  - **Prerequisites:** TASK-030
  - **Scope:** Create `lib/features/cart/domain/cart_item_model.dart`, `wishlist_item_model.dart`, and `price_breakup_model.dart`:
    - `CartItemModel`: `productId`, `variantId`, `productName`, `schoolName`, `variantLabel`, `imageUrl`, `unitPrice`, `quantity`, `maxStock`.
    - `PriceBreakupModel`: subtotal, schoolBulkDiscount, deliveryCharge (FREE if subtotal > ₹999, else ₹50), grandTotal calculation.
  - **Done Criteria:** Unit test validating formula: `Grand Total = Subtotal + Delivery - Discounts`.

- [x] **TASK-032: Implement Cart Repository with Cloud Firestore Sync**
  - **Prerequisites:** TASK-031
  - **Scope:** Create `lib/features/cart/data/cart_repository.dart`:
    - Path: `users/{userId}/cart/{productId_variantId}`.
    - Methods: `watchCart(userId)`, `addToCart(userId, CartItemModel)`, `updateQuantity(userId, cartItemId, qty)`, `removeFromCart(userId, cartItemId)`, `clearCart(userId)`.
    - Enforce max limit constraint (e.g., max 5 units per uniform SKU).
  - **Done Criteria:** Adding item updates Firestore subcollection; quantity changes reflect in real-time.

- [x] **TASK-033: Implement Wishlist Repository**
  - **Prerequisites:** TASK-032
  - **Scope:** Create `lib/features/cart/data/wishlist_repository.dart`:
    - Path: `users/{userId}/wishlist/{productId}`.
    - Methods: `watchWishlist(userId)`, `toggleWishlist(userId, productId)`.
  - **Done Criteria:** Tapping heart icon adds/removes item from Firestore wishlist subcollection.

- [x] **TASK-034: Implement Cart Riverpod Controller & Badge Synchronizer**
  - **Prerequisites:** TASK-033
  - **Scope:** Create `lib/features/cart/presentation/controllers/cart_controller.dart`:
    - `cartItemsStreamProvider`, `cartTotalProvider`, `cartBadgeCountProvider`.
    - Ensure cart count badge in top app bar reactively updates everywhere across the app.
  - **Done Criteria:** Global cart badge icon count updates immediately when items are added/removed.

- [x] **TASK-035: Build Atomic `QuantityStepper` Component**
  - **Prerequisites:** TASK-034
  - **Scope:** Create `lib/features/cart/presentation/widgets/quantity_stepper.dart`:
    - Capsule pill layout: `[-] quantity [+]` with 32px height.
    - Decrementing from 1 triggers a confirmation dialog ("Remove item from cart?").
    - Increment disabled when `quantity >= maxStock` or SKU limit.
  - **Done Criteria:** Stepper prevents incrementing past stock limit and removes item upon confirmed 0 decrement.

- [x] **TASK-036: Build Price Breakup Summary Card Component**
  - **Prerequisites:** TASK-035
  - **Scope:** Create `lib/features/cart/presentation/widgets/price_breakup_card.dart`:
    - Items Total, School Bulk Discount, Estimated Shipping ("FREE" in green if applicable), Total Payable in 18px Bold.
    - Promo code coupon entry box with "APPLY" action.
  - **Done Criteria:** Card cleanly formats currency (₹) and displays discounts/free shipping status.

- [x] **TASK-037: Build Full Cart Screen (`CartScreen`) with Stepper Header**
  - **Prerequisites:** TASK-036
  - **Scope:** Create `lib/features/cart/presentation/screens/cart_screen.dart`:
    - Stepper header indicator: `[ 1. Cart ] ── [ 2. Address ] ── [ 3. Payment ]`.
    - List of cart items with thumbnail, title, selected variant pill, stepper controller, and delete button.
    - Empty cart state with "Your cart is empty" illustration and "Start Shopping" button.
    - Sticky bottom bar: Total payable + "PROCEED TO CHECKOUT" `CustomButton`.
  - **Done Criteria:** Screen renders cart items, recalculates price on stepper click, and navigates to checkout on tap.

- [x] **TASK-038: Build Wishlist Screen & Guest Intercept Verification**
  - **Prerequisites:** TASK-037
  - **Scope:** Create `lib/features/cart/presentation/screens/wishlist_screen.dart`:
    - Grid view of wishlisted items with quick "Move to Cart" button.
    - Guest guard integration: navigating to Wishlist as guest triggers `AuthModalBottomSheet`.
  - **Done Criteria:** Guests are intercepted; logged-in users view real-time wishlisted items.

---

## Phase 6: Checkout Pipeline, Address Management & Payment SDK

- [x] **TASK-039: Define Address & Order Intent Domain Entities**
  - **Prerequisites:** TASK-038
  - **Scope:** Create `lib/features/checkout/domain/address_model.dart` and `order_intent_model.dart`:
    - `AddressModel`: `addressId`, `fullName`, `phone`, `addressLine1`, `addressLine2`, `city`, `state`, `pincode`, `isDefault`.
    - `OrderIntentModel`: `items`, `shippingAddress`, `pricing`, `isBuyNowBypass`.
  - **Done Criteria:** Unit tests verifying address validation (10-digit phone, 6-digit Indian PIN code).

- [x] **TASK-040: Implement Address Repository with Firestore Storage**
  - **Prerequisites:** TASK-039
  - **Scope:** Create `lib/features/checkout/data/address_repository.dart`:
    - Path: `users/{userId}/addresses/{addressId}`.
    - Methods: `fetchAddresses(userId)`, `addAddress(userId, AddressModel)`, `updateAddress(userId, AddressModel)`, `deleteAddress(userId, addressId)`, `setDefaultAddress(userId, addressId)`.
  - **Done Criteria:** Setting an address as default atomically unsets previous default flag.

- [x] **TASK-041: Implement Checkout State Controller (Standard & Buy-Now Sessions)**
  - **Prerequisites:** TASK-040
  - **Scope:** Create `lib/features/checkout/presentation/controllers/checkout_controller.dart`:
    - Manage active checkout flow: Step 1 (Review) -> Step 2 (Address) -> Step 3 (Payment).
    - Support Direct "Buy Now" session bypassing persistent shopping cart.
  - **Done Criteria:** State retains selected address, delivery mode, and pricing across step transitions.

- [x] **TASK-042: Build Address Selection & Entry Screen (Step 2)**
  - **Prerequisites:** TASK-041
  - **Scope:** Create `lib/features/checkout/presentation/screens/address_step_screen.dart`:
    - Radio card list of saved addresses (Home, School Delivery).
    - "+ Add New Delivery Address" modal bottom sheet form with PIN code lookup and form validation.
    - "Deliver to this Address" primary button.
  - **Done Criteria:** Selecting address updates checkout controller and enables proceeding to Step 3.

- [x] **TASK-043: Build Payment Method Selection Screen (Step 3)**
  - **Prerequisites:** TASK-042
  - **Scope:** Create `lib/features/checkout/presentation/screens/payment_step_screen.dart`:
    - Payment options radio group:
      1. UPI (Google Pay, PhonePe, Paytm, Any UPI ID)
      2. Credit / Debit Card (Visa, MasterCard, RuPay)
      3. Net Banking
      4. Cash on Delivery (COD) (with ₹40 handling fee pill)
    - Security banner: "🔒 256-bit SSL Encrypted Transaction".
  - **Done Criteria:** Radio selection dynamically updates COD handling fee in Grand Total.

- [x] **TASK-044: Integrate Native Razorpay SDK Client Wrapper**
  - **Prerequisites:** TASK-043
  - **Scope:** Create `lib/features/checkout/data/razorpay_service.dart`:
    - Initialize `Razorpay` event listeners: `EVENT_PAYMENT_SUCCESS`, `EVENT_PAYMENT_ERROR`, `EVENT_EXTERNAL_WALLET`.
    - Setup checkout payload (Key, Amount in paise, Order Name, Prefill Phone & Email).
    - Dispose Razorpay instance on checkout teardown.
  - **Done Criteria:** Service opens native Razorpay checkout sheet with test credentials and passes event callbacks.

- [x] **TASK-045: Implement Order Placement & Payment Resolution Handler**
  - **Prerequisites:** TASK-044
  - **Scope:** In `checkout_controller.dart`:
    - On COD: Direct call to create order with status `CONFIRMED`.
    - On Online: Trigger Razorpay; on `EVENT_PAYMENT_SUCCESS`, call order creation with payment ID and status `CONFIRMED`.
    - On Success: Clear cart in Firestore (`clearCart`) and navigate to confirmation screen.
    - On Failure: Display retry dialog without losing address or selected options.
  - **Done Criteria:** Completed test order writes to Firestore `orders` collection, clears user cart, and returns order ID.

- [x] **TASK-046: Build Order Confirmation Screen**
  - **Prerequisites:** TASK-045
  - **Scope:** Create `lib/features/checkout/presentation/screens/order_confirmation_screen.dart`:
    - Animated green checkmark, "Order Placed Successfully!".
    - Display Order ID (e.g. `#BV-2026-9812`), estimated delivery date, summary of ordered items.
    - Actions: "Track Order" button (navigates to tracking screen) and "Continue Shopping" button (returns to home).
  - **Done Criteria:** Screen renders order details and disables back navigation into checkout stack (`go_router` replacement).

---

## Phase 7: Serverless Cloud Functions & Transactional Backend

- [x] **TASK-047: Implement TypeScript Zod Schemas & Event Types**
  - **Prerequisites:** TASK-046
  - **Scope:** In `functions/src/types/schemas.ts`:
    - Define schemas: `OrderCreateSchema`, `PaymentWebhookSchema`, `InventoryDeductSchema`.
    - Export TypeScript interfaces for type-safe handlers.
  - **Done Criteria:** TypeScript compiles without any `any` types or validation gaps.

- [x] **TASK-048: Implement Cloud Function: Atomic Inventory Decrement**
  - **Prerequisites:** TASK-047
  - **Scope:** In `functions/src/inventory/atomicDecrement.ts`:
    - Firestore `runTransaction` verifying each variant stock is `>= requested_quantity`.
    - Decrement variant stock and total product stock atomically.
    - Reject transaction with descriptive error if stock reached 0 during checkout.
  - **Done Criteria:** Test transaction with concurrency: simultaneous orders on 1 stock item allow exactly one success and fail the second.

- [x] **TASK-049: Implement Cloud Function: Razorpay Webhook & Signature Verification**
  - **Prerequisites:** TASK-048
  - **Scope:** In `functions/src/payments/webhook.ts`:
    - Verify `x-razorpay-signature` using HMAC SHA256 with `RAZORPAY_KEY_SECRET`.
    - On `order.paid`: atomically update Firestore order status to `CONFIRMED` and record transaction payload.
  - **Done Criteria:** Automated test sending valid signature returns HTTP 200 and updates order; invalid signature returns HTTP 400.

- [x] **TASK-050: Implement Cloud Function: Inventory Restock on Order Cancellation**
  - **Prerequisites:** TASK-049
  - **Scope:** In `functions/src/orders/onOrderCancelled.ts`:
    - Triggered on `orders/{orderId}` status updated to `CANCELLED`.
    - Restores inventory counts to product variants in Firestore.
  - **Done Criteria:** Updating test order to `CANCELLED` increments product variant stock back to previous level.

- [x] **TASK-051: Implement Cloud Function: FCM Push Notification Triggers**
  - **Prerequisites:** TASK-050
  - **Scope:** In `functions/src/orders/notifications.ts`:
    - Firestore trigger `onDocumentUpdated("orders/{orderId}")`.
    - If `orderStatus` changes (e.g. PACKED, SHIPPED, OUT_FOR_DELIVERY, DELIVERED): dispatch high-priority FCM notification to customer device tokens.
  - **Done Criteria:** Status update event logs generated FCM payload with order ID and title.

- [x] **TASK-052: Configure Cloud Storage WebP Resizing Pipeline**
  - **Prerequisites:** TASK-051
  - **Scope:** Configure Firebase Storage Resize Extension or trigger in `functions/src/storage/resizeImage.ts`:
    - Resize uploaded product images to 800x800 (PDP preview) and 200x200 (Thumbnails) in WebP format.
  - **Done Criteria:** Image upload produces thumbnail and display WebP assets in target bucket folder.

---

## Phase 8: Order Management, Realtime Tracking & Notifications

- [x] **TASK-053: Define Order Domain Entities & Tracking Models**
  - **Prerequisites:** TASK-052
  - **Scope:** Create `lib/features/orders/domain/order_model.dart` and `tracking_step_model.dart`:
    - `OrderStatus` enum: `PENDING`, `CONFIRMED`, `PACKED`, `SHIPPED`, `OUT_FOR_DELIVERY`, `DELIVERED`, `CANCELLED`.
    - `TrackingMetadata`: courier name, tracking number, tracking URL.
    - List of timeline milestones with timestamps and status remarks.
  - **Done Criteria:** Unit test parsing order documents and tracking timeline progress calculation.

- [x] **TASK-054: Implement Order Repository with Real-time Streams**
  - **Prerequisites:** TASK-053
  - **Scope:** Create `lib/features/orders/data/order_repository.dart`:
    - Methods: `watchUserOrders(userId)`, `watchOrderById(orderId)`, `cancelOrder(orderId, reason)`.
    - Stream Firestore snapshots for instantaneous real-time status updates.
  - **Done Criteria:** Modifying status in database emits updated `OrderModel` in stream within < 2 seconds.

- [x] **TASK-055: Build Customer Order History Screen (`OrderHistoryScreen`)**
  - **Prerequisites:** TASK-054
  - **Scope:** Create `lib/features/orders/presentation/screens/order_history_screen.dart`:
    - List of past orders with Order ID, placement date, item thumbnail previews, total amount, and status chip.
    - Guest guard protection: guest users attempting to open Orders tab encounter `AuthModalBottomSheet`.
    - Tapping an order opens tracking screen.
  - **Done Criteria:** List displays orders chronologically; clicking card navigates to `/order/:id`.

- [x] **TASK-056: Build Real-time Order Tracking Screen with Vertical Milestone Timeline**
  - **Prerequisites:** TASK-055
  - **Scope:** Create `lib/features/orders/presentation/screens/order_tracking_screen.dart`:
    - Vertical step indicator: `[ORDER PLACED] -> [PACKED] -> [SHIPPED] -> [OUT FOR DELIVERY] -> [DELIVERED]`.
    - Show carrier name and active tracking number when in `SHIPPED` status.
    - Action buttons: "Download Tax Invoice" (PDF generator trigger) and "Need Help with Order?".
  - **Done Criteria:** Stream builder updates active timeline dot automatically when order state changes in Firestore.

- [x] **TASK-057: Implement Client FCM Push Notification Service**
  - **Prerequisites:** TASK-056
  - **Scope:** Create `lib/core/network/fcm_service.dart`:
    - Request notification permissions on iOS & Android 13+.
    - Setup Android notification channel `order_updates_channel` with high importance.
    - Store FCM device token under `users/{userId}/fcmTokens`.
    - Handle foreground notifications and background payload taps (deep-linking to `/order/:id`).
  - **Done Criteria:** Receiving FCM message displays system notification and tapping routes to target order tracking page.

---

## Phase 9: Admin Operations Portal & Inventory Control

- [x] **TASK-058: Implement Admin Role Verification & Routing Guard**
  - **Prerequisites:** TASK-057
  - **Scope:** Create `lib/core/guards/admin_guard.dart`:
    - Check Firebase Auth custom claims or Firestore `users/{userId}.role == 'admin'`.
    - Redirect non-admin users attempting to open `/admin` back to Home with access denied banner.
  - **Done Criteria:** Unit test verifying unauthorized access rejection and authorized admin pass-through.

- [x] **TASK-059: Build Admin Dashboard Analytics Screen**
  - **Prerequisites:** TASK-058
  - **Scope:** Create `lib/features/admin/presentation/screens/admin_dashboard_screen.dart`:
    - Metrics cards: Daily GMV, Total Orders, Unfulfilled Orders count.
    - Critical Stock Alert table (highlighting SKUs with `< 5 units` remaining).
  - **Done Criteria:** Screen aggregates metrics from Firestore collections accurately.

- [x] **TASK-060: Build Admin Product Catalog Studio (CRUD & Variant Matrix Builder)**
  - **Prerequisites:** TASK-059
  - **Scope:** Create `lib/features/admin/presentation/screens/admin_product_form.dart`:
    - Multi-image selector uploading directly to Firebase Storage.
    - Dynamic variant matrix builder (adding size/grade variants with individual price and stock counts).
    - Category dropdown, School name input, sale price toggle, and instant save/update to Firestore.
  - **Done Criteria:** Adding a product via admin form reflects in customer catalog in real-time.

- [x] **TASK-061: Build Admin Order Fulfillment Center (Status Mutation & Logistics)**
  - **Prerequisites:** TASK-060
  - **Scope:** Create `lib/features/admin/presentation/screens/admin_orders_screen.dart`:
    - Filter orders by status (PENDING, CONFIRMED, PACKED, SHIPPED, etc.).
    - Status progression button (e.g. advance to "PACKED" -> "SHIPPED").
    - Carrier selection modal injecting courier name and tracking ID.
  - **Done Criteria:** Admin status change updates customer tracking timeline within 2 seconds.

- [x] **TASK-062: Build Packing Slip & Tax Invoice Generator**
  - **Prerequisites:** TASK-061
  - **Scope:** Create `lib/features/admin/presentation/widgets/invoice_generator.dart`:
    - Render printable GST-compliant invoice view with customer address, itemized SKU breakdown, HSN codes, and pricing.
  - **Done Criteria:** Invoice renders correctly formatted PDF preview ready for printing.

---

## Phase 10: Security Rules, Performance, Testing & Launch Readiness

- [x] **TASK-063: Deploy Comprehensive Cloud Firestore Security Rules**
  - **Prerequisites:** TASK-062
  - **Scope:** In `firestore.rules`:
    - Public read for `products` and `categories`.
    - Admin-only write for `products` and `categories`.
    - Strict `isOwner(userId)` rules for `users/{userId}`, `cart`, `wishlist`, `addresses`.
    - Customer create permissions for `orders` where `userId == request.auth.uid`.
    - Admin-only update permissions for `orders` status mutations.
  - **Done Criteria:** Run Firestore Security Rules unit test suite (`@firebase/rules-unit-testing`) verifying all access vectors pass/fail appropriately.

- [x] **TASK-064: Configure Firebase App Check with Play Integrity & DeviceCheck**
  - **Prerequisites:** TASK-063
  - **Scope:** In `lib/main.dart` and Firebase Console:
    - Activate `FirebaseAppCheck.instance.activate()` using `PlayIntegrity` provider on Android and `DeviceCheck` / `AppAttest` on iOS.
    - Enable App Check enforcement on Firestore and Storage.
  - **Done Criteria:** API calls from unauthorized clients or curl scripts are blocked with 403 Forbidden.

- [x] **TASK-065: Implement Performance Optimization & Cache Policies**
  - **Prerequisites:** TASK-064
  - **Scope:**
    - Profile frame rendering across product catalog lists ensuring steady 60fps scrolling on target devices.
    - Verify image cache limits in `cached_network_image` preventing out-of-memory errors on low-end hardware.
  - **Done Criteria:** Flutter DevTools performance profile confirms zero red junk frames during rapid catalog scrolling.

- [x] **TASK-066: Setup GitHub Actions CI/CD Pipeline & Fastlane Build Scripts**
  - **Prerequisites:** TASK-065
  - **Scope:** In `.github/workflows/main.yml`:
    - Step 1: Run `flutter analyze` and `dart format --set-exit-if-changed .`.
    - Step 2: Run `flutter test`.
    - Step 3: Setup Fastlane scripts to build Android `.aab` and iOS archive.
    - Step 4: Deploy Cloud Functions to Firebase on merge to `main`.
  - **Done Criteria:** GitHub Actions workflow completes successfully with all checkmarks green.

- [x] **TASK-067: Execute End-to-End User Journey Regression & Verification**
  - **Prerequisites:** TASK-066
  - **Scope:** Execute full end-to-end verification checklist:
    1. Guest user launches app -> browses catalog, filters by school, views PDP, selects variant (Size 32).
    2. Guest taps "Add to Cart" -> `AuthModalBottomSheet` smoothly slides up with zero loss of selected variant parameters.
    3. User registers/logs in -> item is immediately committed to Firestore cart -> user redirected to Cart.
    4. Proceed to Checkout -> Select address -> Choose payment method (Razorpay/COD) -> Place order.
    5. Admin panel updates status -> Customer tracking screen updates in real time via Firestore listener.
  - **Done Criteria:** Complete regression test passes without errors or dropped state across all platforms.
