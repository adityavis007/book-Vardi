# **Product Requirement Document (PRD)**

**Project:** Book Vardi Mobile Application

**Target Platform:** Android & iOS (Flutter Engine)

**Web Reference:** [book-vardi-website.vercel.app](http://book-vardi-website.vercel.app/?utm_source=gemini)

**Version:** 1.0.0

**Status:** Ready for Engineering

## **1\. Executive Summary & Vision**

Book Vardi is a dedicated school commerce ecosystem delivering school uniforms, textbooks, notebooks, footwear, and stationery directly to parents and students. The mobile application translates the Book Vardi web experience into a native mobile interface, engineered for high discovery speed and friction-free mobile checkouts.

### **Core Value Proposition**

* **Zero Friction Discovery:** Guest users can browse the full catalog, filter by grade/school/category, and inspect variant configurations without upfront login barriers.  
* **Strict Transactional Security:** Any transactional or personalized action (*Add to Cart*, *Wishlist*, *Buy Now*, *Order Tracking*) triggers an inline contextual authentication gateway.  
* **Operational Control:** An administrative interface to manage stock, update multi-tier order tracking, and control inventory.

### **Key Performance Indicators (KPIs)**

* **Guest-to-Signup Conversion Rate:** $\\ge 25\\%$ at the first transactional intercept point.  
* **Checkout Drop-off Rate:** $\< 35\\%$ from Address selection to Payment Success.  
* **App Cold Launch Time:** $\< 1.8\\text{ seconds}$ on mid-tier Android devices.  
* **Order Processing Cycle Time:** Admin acknowledgment to "Packed" status in $\< 4\\text{ hours}$.

## **2\. User Access & Permission Matrix**

| Feature / Screen | Guest User | Registered / Logged-In User | Admin User |
| :---- | :---- | :---- | :---- |
| **Splash & Onboarding** | Full Access (Skip option) | Automatic session pass-through | Console auth |
| **Catalog Browsing & Search** | Full Access | Full Access | Full Access |
| **Product Details & Variants** | View Only | View & Select | View, Edit, Audit |
| **Wishlist** | 🔒 Auth Intercept | Full Access | N/A |
| **Cart Operations** | 🔒 Auth Intercept | Full Access (Synced Firestore) | N/A |
| **Direct "Buy Now"** | 🔒 Auth Intercept | Full Access | N/A |
| **Address Management** | ❌ No Access | Full Access (Multi-address) | Read-only (per order) |
| **Checkout & Payments** | ❌ No Access | Full Access (UPI/Cards/COD) | Refund/Status Override |
| **Order History & Tracking** | ❌ No Access | Full Access | Full Access (Status mutation) |
| **User Profile Management** | ❌ No Access | Full Access | View user ledger |
| **Catalog & Stock CRUD** | ❌ No Access | ❌ No Access | Full Access |

## **3\. System Architecture & Tech Stack**

&nbsp;

&nbsp;

&nbsp;

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;┌──────────────────────────────────┐  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│     Flutter Multi-Platform       │  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│   (Customer App \+ Admin Web)     │  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;└─────────────────┬────────────────┘  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;┌──────────────────────────────┼──────────────────────────────┐  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;▼                              ▼                              ▼  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;┌──────────────────────┐       ┌──────────────────────┐       ┌──────────────────────┐  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│    Firebase Auth     │       │   Cloud Firestore    │       │   Firebase Storage   │  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│  (Email/Pass, Phone) │       │ (NoSQL Core DB sync) │       │ (Media, Assets, CDN) │  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;└──────────────────────┘       └──────────┬───────────┘       └──────────────────────┘  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;▼  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;┌──────────────────────────┐  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│   Third-Party Services   │  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│  \- Razorpay / Cashfree   │  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│  \- Firebase FCM          │  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│  \- WhatsApp Notifications│  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;└──────────────────────────┘

* **Client Engine:** Flutter 3.x (Dart) with Provider / Riverpod for state management.  
* **Database & Realtime Sync:** Cloud Firestore.  
* **Authentication:** Firebase Authentication (Email/Password, Phone OTP ready).  
* **Asset Storage:** Firebase Cloud Storage with image compression pipeline.  
* **Messaging & Alerts:** Firebase Cloud Messaging (FCM) triggered via Cloud Functions.  
* **Payment Rails:** Native Gateway SDK (Razorpay / Cashfree) \+ Cash on Delivery (COD) mode.

## **4\. Functional Specifications**

### **4.1. Splash, Session, and Interceptive Auth**

#### **Splash Pipeline**

> 1. Check device network connectivity.  
> 2. Query cached auth token via FirebaseAuth.instance.authStateChanges().  
> 3. If token valid: Navigate to HomeScreen(mode: Authenticated).  
> 4. If token null/expired: Check is\_first\_launch flag:  
   * If true: Show LoginScreen with visible Continue as Guest CTA.  
   * If false: Route straight to HomeScreen(mode: Guest) without blocking dialogs.

#### **The "Guest Guard" Interceptor Pattern**

* When a guest executes a protected intent (AddToCart, Wishlist, BuyNow, OpenCart, OpenProfile):  
  1. Capture the intent state in an ephemeral session object:  
     Dart  
     class PendingAction {  
     &nbsp;&nbsp;final PendingActionType type; // ADD\_TO\_CART, BUY\_NOW, etc.  
     &nbsp;&nbsp;final String productId;  
     &nbsp;&nbsp;final String? variantId;  
     &nbsp;&nbsp;final int quantity;  
     }

  2. Launch the AuthModalBottomSheet / AuthScreen.  
  3. Upon successful registration or login:  
     * Flush PendingAction by running the pending transaction into the user's Firestore path.  
     * Route user directly to target destination (e.g., CartScreen or direct CheckoutScreen) without losing context.

### **4.2. Catalog, Search, and Variant Systems**

#### **Categories & Taxonomies**

* **Core Taxonomy:** Books, Uniforms, Stationery, School Bags, Footwear, Accessories.  
* Uniforms and Footwear require multi-attribute selection (Size, Color, Gender, Grade/Standard).  
* Books require attributes for Class/Grade, Board (CBSE/ICSE/State), and Subject.

#### **Discovery & Filters**

* **Search Execution:** Client-side substring/prefix caching for fast local results, backed by server search indexing.  
* **Sort Dimensions:** Price: Low to High, Price: High to Low, Newest Arrivals, Popularity.  
* **Filter Stack:** Category, Price Range Slider, Size/Variant, School Association (if applicable), In-Stock Only toggle.

### **4.3. Shopping Cart, Wishlist, and Direct Checkout**

#### **Cart Rules**

* Cloud-backed under users/{userId}/cart/{cartItemId}.  
* Every cart write must validate:  
  * Maximum order limit per SKU (e.g., max 5 units for uniforms).  
  * Current stock ceiling (requested\_qty \<= live\_stock).  
* Cart subtotal recalculates dynamically:  
  $$\\text{Grand Total} \= \\sum(\\text{Unit Price} \\times \\text{Qty}) \+ \\text{Delivery Fee} \- \\text{Discount Code}$$

#### **Buy Now Bypass Logic**

* Tapping **Buy Now** on a Product Detail Page validates stock, bypasses the persistent shopping cart, and mounts a transient checkout session populated solely with the selected SKU, moving straight to Address Selection.

### **4.4. Checkout and Payment Pipeline**

&nbsp;

&nbsp;

&nbsp;

\[ Cart / Buy Now \]  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;▼  
\[ Address Selection \] ──( Add / Edit / Select Default )  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;▼  
\[ Payment Selection \] ──┬──\> Cash on Delivery (COD) ──\> \[ Place Order \]  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;└──\> Online (Razorpay/UPI)  ──\> \[ Gateway SDK \]  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;┌─────────────────────────┴─────────────────────────┐  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;▼                                                   ▼  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\[ Payment Success \]                                 \[ Payment Failure \]  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│                                                   │  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;▼                                                   ▼  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\[ Create Order Document \]                               \[ Retry Payment \]  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;▼  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\[ Clear Cart Items \]  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;▼  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\[ Trigger FCM Push \]  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;▼  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\[ Confirmation Screen \]

### **4.5. Order Lifecycle & Status Engine**

Order states are strictly sequential. Mutations are governed by database security rules and Cloud Functions.

&nbsp;

&nbsp;

&nbsp;

PENDING ──► CONFIRMED ──► PACKED ──► SHIPPED ──► OUT\_FOR\_DELIVERY ──► DELIVERED  
&nbsp;&nbsp;&nbsp;│            │  
&nbsp;&nbsp;&nbsp;└────────────┴──────► CANCELLED (Customer or Admin initiated)

| Order State | Permitted Initiator | Description |
| :---- | :---- | :---- |
| PENDING | System | Online payment authorization awaited / COD initialized. |
| CONFIRMED | System / Admin | Payment verified; inventory reserved. |
| PACKED | Admin / Warehouse | Goods boxed; shipping label generated. |
| SHIPPED | Admin | Handed over to logistics carrier; tracking ID attached. |
| OUT\_FOR\_DELIVERY | Admin / Logistics | Consignment out with the local delivery agent. |
| DELIVERED | Delivery Agent / Admin | Handed to customer; OTP verification (optional). |
| CANCELLED | Customer / Admin | Allowed only prior to SHIPPED status. Reverts inventory. |

### **4.6. Admin Operations Panel**

The Admin Panel operates as a Flutter Web or mobile portal pointing to the same Firebase instance, protected by custom claims (role \== 'admin').

* **Dashboard Analytics:** Daily GMV, Open Orders, Unfulfilled Orders, Critical Stock Alerts ($\< 5\\text{ units}$).  
* **Product Catalog Studio:**  
  * Multi-image uploads straight to Firebase Storage with automated 800x800 WebP conversion.  
  * SKU variant builders (Size $\\times$ Color matrix with dedicated stock counters).  
  * Instant price adjustments and sale flags.  
* **Order Fulfillment Center:**  
  * Order status updating with carrier tracking link injections.  
  * Printable packing slips and invoices.  
* **Inventory Control:** Bulk stock increments and decrement alerts.

## **5\. Data Architecture (Cloud Firestore Schema)**

### **Collection: users**

Document ID: userId (matches auth.uid)

&nbsp;

&nbsp;

&nbsp;

JSON

{  
&nbsp;&nbsp;"userId": "string (PK)",  
&nbsp;&nbsp;"name": "string",  
&nbsp;&nbsp;"email": "string",  
&nbsp;&nbsp;"phone": "string",  
&nbsp;&nbsp;"role": "customer | admin",  
&nbsp;&nbsp;"createdAt": "timestamp",  
&nbsp;&nbsp;"updatedAt": "timestamp"  
}

#### **Subcollection: users/{userId}/addresses**

Document ID: addressId

&nbsp;

&nbsp;

&nbsp;

JSON

{  
&nbsp;&nbsp;"addressId": "string (PK)",  
&nbsp;&nbsp;"fullName": "string",  
&nbsp;&nbsp;"phone": "string",  
&nbsp;&nbsp;"addressLine1": "string",  
&nbsp;&nbsp;"addressLine2": "string",  
&nbsp;&nbsp;"city": "string",  
&nbsp;&nbsp;"state": "string",  
&nbsp;&nbsp;"pincode": "string",  
&nbsp;&nbsp;"isDefault": "boolean"  
}

#### **Subcollection: users/{userId}/cart**

Document ID: cartItemId (Composite: productId\_variantId)

&nbsp;

&nbsp;

&nbsp;

JSON

{  
&nbsp;&nbsp;"productId": "string",  
&nbsp;&nbsp;"variantId": "string",  
&nbsp;&nbsp;"productName": "string",  
&nbsp;&nbsp;"imageUrl": "string",  
&nbsp;&nbsp;"unitPrice": "number",  
&nbsp;&nbsp;"quantity": "number",  
&nbsp;&nbsp;"updatedAt": "timestamp"  
}

### **Collection: products**

Document ID: productId

&nbsp;

&nbsp;

&nbsp;

JSON

{  
&nbsp;&nbsp;"productId": "string (PK)",  
&nbsp;&nbsp;"name": "string",  
&nbsp;&nbsp;"categoryId": "string",  
&nbsp;&nbsp;"description": "string",  
&nbsp;&nbsp;"basePrice": "number",  
&nbsp;&nbsp;"discountPercentage": "number",  
&nbsp;&nbsp;"images": \["string (URL)"\],  
&nbsp;&nbsp;"isActive": "boolean",  
&nbsp;&nbsp;"isFeatured": "boolean",  
&nbsp;&nbsp;"hasVariants": "boolean",  
&nbsp;&nbsp;"variants": \[  
&nbsp;&nbsp;&nbsp;&nbsp;{  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"variantId": "string",  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"sku": "string",  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"label": "string (e.g. Size 32, Class 6)",  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"price": "number",  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"stock": "number"  
&nbsp;&nbsp;&nbsp;&nbsp;}  
&nbsp;&nbsp;\],  
&nbsp;&nbsp;"totalStock": "number",  
&nbsp;&nbsp;"tags": \["string"\],  
&nbsp;&nbsp;"createdAt": "timestamp",  
&nbsp;&nbsp;"updatedAt": "timestamp"  
}

### **Collection: orders**

Document ID: orderId (e.g., BV-2026-00918)

&nbsp;

&nbsp;

&nbsp;

JSON

{  
&nbsp;&nbsp;"orderId": "string (PK)",  
&nbsp;&nbsp;"userId": "string (FK)",  
&nbsp;&nbsp;"items": \[  
&nbsp;&nbsp;&nbsp;&nbsp;{  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"productId": "string",  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"variantId": "string",  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"productName": "string",  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"quantity": "number",  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"unitPrice": "number",  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"totalPrice": "number"  
&nbsp;&nbsp;&nbsp;&nbsp;}  
&nbsp;&nbsp;\],  
&nbsp;&nbsp;"shippingAddress": {  
&nbsp;&nbsp;&nbsp;&nbsp;"fullName": "string",  
&nbsp;&nbsp;&nbsp;&nbsp;"phone": "string",  
&nbsp;&nbsp;&nbsp;&nbsp;"addressLine1": "string",  
&nbsp;&nbsp;&nbsp;&nbsp;"city": "string",  
&nbsp;&nbsp;&nbsp;&nbsp;"state": "string",  
&nbsp;&nbsp;&nbsp;&nbsp;"pincode": "string"  
&nbsp;&nbsp;},  
&nbsp;&nbsp;"pricing": {  
&nbsp;&nbsp;&nbsp;&nbsp;"subtotal": "number",  
&nbsp;&nbsp;&nbsp;&nbsp;"deliveryCharge": "number",  
&nbsp;&nbsp;&nbsp;&nbsp;"discountAmount": "number",  
&nbsp;&nbsp;&nbsp;&nbsp;"grandTotal": "number"  
&nbsp;&nbsp;},  
&nbsp;&nbsp;"payment": {  
&nbsp;&nbsp;&nbsp;&nbsp;"method": "COD | ONLINE",  
&nbsp;&nbsp;&nbsp;&nbsp;"transactionId": "string | null",  
&nbsp;&nbsp;&nbsp;&nbsp;"status": "PENDING | SUCCESS | FAILED"  
&nbsp;&nbsp;},  
&nbsp;&nbsp;"orderStatus": "PENDING | CONFIRMED | PACKED | SHIPPED | OUT\_FOR\_DELIVERY | DELIVERED | CANCELLED",  
&nbsp;&nbsp;"trackingMetadata": {  
&nbsp;&nbsp;&nbsp;&nbsp;"courierName": "string | null",  
&nbsp;&nbsp;&nbsp;&nbsp;"trackingNumber": "string | null"  
&nbsp;&nbsp;},  
&nbsp;&nbsp;"createdAt": "timestamp",  
&nbsp;&nbsp;"updatedAt": "timestamp"  
}

## **6\. Non-Functional Requirements (NFRs)**

### **Performance & Caching**

* **Catalog Caching:** Products and categories must leverage Firestore's offline persistence layer (PersistenceSettings(cacheSizeBytes: 104857600\) \- 100MB cache limit).  
* **Image Delivery:** All product assets stored in Firebase Storage must be cached using cached\_network\_image with local disk caching and low-resolution image placeholders (shimmer effects).

### **Security Rules Baseline (Firestore)**

&nbsp;

&nbsp;

&nbsp;

JavaScript

rules\_version \= '2';  
service cloud.firestore {  
&nbsp;&nbsp;match /databases/{database}/documents {  
&nbsp;&nbsp;&nbsp;&nbsp;  
&nbsp;&nbsp;&nbsp;&nbsp;function isAuthenticated() {  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;return request.auth \!= null;  
&nbsp;&nbsp;&nbsp;&nbsp;}  
&nbsp;&nbsp;&nbsp;&nbsp;  
&nbsp;&nbsp;&nbsp;&nbsp;function isOwner(userId) {  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;return isAuthenticated() && request.auth.uid \== userId;  
&nbsp;&nbsp;&nbsp;&nbsp;}  
&nbsp;&nbsp;&nbsp;&nbsp;  
&nbsp;&nbsp;&nbsp;&nbsp;function isAdmin() {  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;return isAuthenticated() &&&nbsp;  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;request.auth.token.role \== 'admin';  
&nbsp;&nbsp;&nbsp;&nbsp;}

&nbsp;&nbsp;&nbsp;&nbsp;// Public read for products & categories; Admin write only  
&nbsp;&nbsp;&nbsp;&nbsp;match /categories/{categoryId} {  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;allow read: if true;  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;allow write: if isAdmin();  
&nbsp;&nbsp;&nbsp;&nbsp;}  
&nbsp;&nbsp;&nbsp;&nbsp;  
&nbsp;&nbsp;&nbsp;&nbsp;match /products/{productId} {  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;allow read: if true;  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;allow write: if isAdmin();  
&nbsp;&nbsp;&nbsp;&nbsp;}

&nbsp;&nbsp;&nbsp;&nbsp;// Users and subcollections  
&nbsp;&nbsp;&nbsp;&nbsp;match /users/{userId} {  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;allow read, write: if isOwner(userId) || isAdmin();  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;match /cart/{cartItem} {  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;allow read, write: if isOwner(userId);  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;}  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;match /wishlist/{wishlistItem} {  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;allow read, write: if isOwner(userId);  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;}  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;match /addresses/{addressId} {  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;allow read, write: if isOwner(userId);  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;}  
&nbsp;&nbsp;&nbsp;&nbsp;}

&nbsp;&nbsp;&nbsp;&nbsp;// Orders  
&nbsp;&nbsp;&nbsp;&nbsp;match /orders/{orderId} {  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;allow read: if isAuthenticated() && (resource.data.userId \== request.auth.uid || isAdmin());  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;allow create: if isAuthenticated() && request.resource.data.userId \== request.auth.uid;  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;allow update: if isAdmin(); // Only admins can mutate order status  
&nbsp;&nbsp;&nbsp;&nbsp;}  
&nbsp;&nbsp;}  
}

## **7\. Implementation Roadmap**

&nbsp;

&nbsp;

&nbsp;

PHASE 1: Foundations & Catalog  
├── Setup Flutter project architecture & Firebase configs  
├── Authentication system (Email/Password \+ Anonymous/Guest tracking)  
├── Home screen, Categories, and Product Discovery  
└── Product Detail Screen with Variant Selectors

PHASE 2: Transactional Core & Interceptors  
├── Implement the Guest-Guard interceptor engine  
├── Cloud Firestore Cart & Wishlist integration  
├── Multi-address management module  
└── Checkout steps (Order compilation \+ Razorpay/Cashfree \+ COD)

PHASE 3: Fulfillment, Tracking & Admin  
├── Customer Order History & Realtime Order Tracking screen  
├── Push Notifications (FCM) on order status transitions  
├── Admin Console: Product catalog management & inventory forms  
└── Admin Console: Order pipeline state update dashboard

PHASE 4: Hardening & Launch  
├── Comprehensive end-to-end security rules audit  
├── Real-device performance profiling (Frame budget: 60fps)  
└── Production Deployment (Play Store, App Store & Web Admin)

## **8\. Success & Acceptance Criteria**

> 1. **Guest Browsing Integrity:** A guest user can launch the app, search for a uniform or textbook, select size/variants, and navigate product pages without encountering any auth dialogs until an order-intent button is tapped.  
> 2. **Context Persistence:** If a guest selects a variant (e.g., Size 34, Qty 2\) and clicks *Add to Cart*, logs in via the prompted sheet, the item is committed to their account cart without re-selecting variants.  
> 3. **Inventory Race Prevention:** Orders cannot be finalized for items whose variant stock reaches $0$ during the checkout session.  
> 4. **Instant Admin Sync:** Order status changes made in the Admin Console update the customer's timeline view within 2 seconds using real-time Firestore listeners.