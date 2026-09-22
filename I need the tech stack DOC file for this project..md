# **Tech Stack Specification Document**

**Project:** Book Vardi Mobile & Web Platform

**Target Architecture:** Multi-platform Mobile Client (Android & iOS) \+ Web Admin Portal \+ Serverless BaaS

**Primary Deliverable:** Production-Ready Tech Stack Specification for Engineering & AI Coding Agents

## **1\. Architectural Blueprint**

The platform follows a **Serverless Event-Driven Clean Architecture**. The client apps communicate directly with Firebase services for read-heavy operations, while transactional workflows (checkout, stock decrement, order mutations) run through sandboxed serverless Cloud Functions to ensure atomic data integrity.

&nbsp;

&nbsp;

&nbsp;

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;┌────────────────────────────────────────┐  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│            CLIENT INTERFACES           │  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│   ┌────────────────────────────────┐   │  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│   │  Customer App (iOS & Android)  │   │  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│   │   Flutter 3.x (Clean Arch)     │   │  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│   └───────────────┬────────────────┘   │  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│   ┌───────────────┴────────────────┐   │  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│   │    Admin Portal (Web/App)      │   │  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│   │     Flutter Web / React        │   │  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│   └───────────────┬────────────────┘   │  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;└───────────────────┼────────────────────┘  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;▼  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;┌─────────────────────────────────────┴─────────────────────────────────────┐  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│                          GATEWAY & IDENTITY LAYER                         │  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│   ┌───────────────────────────────┐     ┌─────────────────────────────┐   │  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│   │   Firebase App Check          │     │   Firebase Authentication   │   │  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│   │   (Play Integrity/DeviceCheck)│     │   (Email, Phone OTP, Google)│   │  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│   └───────────────────────────────┘     └─────────────────────────────┘   │  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;└─────────────────────────────────────┬─────────────────────────────────────┘  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;┌───────────────────────────────┼───────────────────────────────┐  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;▼                               ▼                               ▼  
┌──────────────────────────────┐ ┌──────────────────────────────┐ ┌──────────────────────────────┐  
│       PERSISTENCE LAYER      │ │       COMPUTE ENGINE         │ │        STORAGE & CDN         │  
│                              │ │                              │ │                              │  
│ Cloud Firestore (NoSQL)      │ │ Firebase Cloud Functions     │ │ Firebase Cloud Storage       │  
│ \- Realtime Catalog Sync      │ │ \- Node.js 20 / TypeScript    │ │ \- WebP Image Delivery        │  
│ \- Offline Client Caching     │ │ \- Atomic Stock Decrements    │ │ \- Automated Resizing Pipeline│  
│ \- Role-based Security Rules  │ │ \- Payment Webhook Ingestion  │ │                              │  
└──────────────────────────────┘ └──────────────┬───────────────┘ └──────────────────────────────┘  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;▼  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;┌────────────────────────────────┐  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│     EXTERNAL INTEGRATIONS      │  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│ \- Razorpay / Cashfree SDK      │  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│ \- Firebase Cloud Messaging     │  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│ \- WhatsApp Cloud API / SMS     │  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;└────────────────────────────────┘

## **2\. Client-Side Mobile Stack (Customer App)**

| Component | Technology / Library | Version / Baseline | Justification |
| :---- | :---- | :---- | :---- |
| **Framework** | Flutter SDK | 3.22.x+ (Dart 3.4+) | Single codebase for iOS and Android; high-performance compiled UI. |
| **Architecture Pattern** | Feature-First Clean Architecture | Domain / Data / Presentation | Enforces separation between business logic, network states, and UI rendering. |
| **State Management** | flutter\_riverpod | ^2.5.1 | Compile-safe, testable, eliminates BuildContext dependency for state mutations. |
| **Navigation & Routing** | go\_router | ^14.1.4 | Declarative routing; natively supports deep links and **Guest Guard Route Redirects**. |
| **Local Persistence** | flutter\_secure\_storage \+ hive\_ce | ^9.2.2 / ^1.8.0 | Fast key-value binary storage for user preferences and encrypted token persistence. |
| **Image Caching & Shimmer** | cached\_network\_image \+ shimmer | ^3.3.1 / ^3.0.0 | Eliminates image re-downloads; provides zero-layout-shift skeleton loaders. |
| **Payment SDK** | razorpay\_flutter | ^1.3.7 | Native payment sheet invocation for UPI (PhonePe, GPay), Cards, and Net Banking. |
| **Device Feedback** | flutter\_haptic | Built-in Engine | Tactile micro-interactions on button tap and variant selection. |

## **3\. Backend, Database & Infrastructure (Serverless)**

### **3.1. Core Cloud Services**

* **Backend Engine:** Firebase Cloud Functions (v2)  
  * **Runtime:** Node.js 20 LTS  
  * **Language:** TypeScript 5.x  
  * **Responsibilities:** Payment signature verification, transactional inventory locking, order document generation, FCM push triggers.  
* **Primary Database:** Cloud Firestore (Native Mode)  
  * **Type:** Distributed Document NoSQL  
  * **Sync Mechanism:** Real-time listeners (snapshots()) for Order Tracking and Admin Stock counters.  
  * **Caching Strategy:** Client-side offline cache enabled (PersistenceEnabled: true).  
* **Asset Storage:** Firebase Cloud Storage \+ Cloud Functions Resize Extension  
  * Automated conversion of product uploads into WebP (800x800 for PDP, 200x200 for thumbnails).

## **4\. Third-Party Integrations & Gateways**

&nbsp;

&nbsp;

&nbsp;

\[Customer Checkout\] ──► \[Razorpay / Cashfree API\] ──► \[Cloud Function Webhook\]  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;│  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;┌─────────────────────────────────────────┴────────────────────────────────────────┐  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;▼                                                                                  ▼  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\[FCM Push Notification\]                                                               \[WhatsApp / SMS API\]  
&nbsp;&nbsp;&nbsp;"Your order \#BV-1024 is confirmed"                                                "Order confirmed: Track at link..."

* **Payment Gateway:** Razorpay or Cashfree Payments India  
  * Methods supported: UPI Intent (seamless drop into PhonePe/GPay), Credit/Debit Cards, Net Banking, COD.  
* **Notification Rail (FCM):**  
  * Android: High-priority notification channels (order\_updates\_channel).  
  * iOS: Apple Push Notification service (APNs) mapped through FCM.  
* **Transactional Communication:**  
  * WhatsApp Business Cloud API / Twilio for instant order confirmation and tracking URLs.

## **5\. Security & Access Control Infrastructure**

### **5.1. Authentication Engine**

* **Firebase Auth Providers:**  
  1. Email/Password (with secure password reset flows).  
  2. Phone Number OTP via Firebase SMS.  
  3. Google Sign-In (google\_sign\_in: ^6.2.1).  
* **Anonymous Tracking (Guest Mode):**  
  * Browsing requires zero auth tokens.  
  * Transaction actions trigger the modal auth interceptor without clearing local state.

### **5.2. Network & Application Security**

* **App Check:** Integrated with **Play Integrity** (Android) and **DeviceCheck / App Attest** (iOS) to block unauthorized bot traffic and screen-scraping of product listings.  
* **Transport Layer:** Strict TLS 1.3 encryption across all network transactions.  
* **PCI-DSS Compliance:** Card and UPI details are captured entirely inside the native Razorpay SDK; no raw cardholder data touches Firestore or local device logs.

## **6\. Dependency Manifests**

### **6.1. Mobile Application (pubspec.yaml)**

&nbsp;

&nbsp;

&nbsp;

YAML

name: book\_vardi  
description: "Book Vardi Mobile E-commerce Application"  
version: 1.0.0\+1  
publish\_to: "none"

environment:  
&nbsp;&nbsp;sdk: "\>=3.4.0 \<4.0.0"  
&nbsp;&nbsp;flutter: "\>=3.22.0"

dependencies:  
&nbsp;&nbsp;flutter:  
&nbsp;&nbsp;&nbsp;&nbsp;sdk: flutter  
&nbsp;&nbsp;  
&nbsp;&nbsp;\# State Management & Architecture  
&nbsp;&nbsp;flutter\_riverpod: ^2.5.1  
&nbsp;&nbsp;riverpod\_annotation: ^2.3.5

&nbsp;&nbsp;\# Navigation & Routing  
&nbsp;&nbsp;go\_router: ^14.1.4

&nbsp;&nbsp;\# Firebase Core Suite  
&nbsp;&nbsp;firebase\_core: ^3.1.0  
&nbsp;&nbsp;firebase\_auth: ^5.1.0  
&nbsp;&nbsp;cloud\_firestore: ^5.0.1  
&nbsp;&nbsp;firebase\_storage: ^12.0.1  
&nbsp;&nbsp;firebase\_messaging: ^15.0.1  
&nbsp;&nbsp;firebase\_app\_check: ^0.3.0+1  
&nbsp;&nbsp;firebase\_crashlytics: ^4.0.1

&nbsp;&nbsp;\# Network, Storage & Utilities  
&nbsp;&nbsp;cached\_network\_image: ^3.3.1  
&nbsp;&nbsp;flutter\_secure\_storage: ^9.2.2  
&nbsp;&nbsp;hive\_ce: ^1.8.0  
&nbsp;&nbsp;hive\_ce\_flutter: ^1.8.0  
&nbsp;&nbsp;intl: ^0.19.0  
&nbsp;&nbsp;uuid: ^4.4.0

&nbsp;&nbsp;\# UI, Icons & Animations  
&nbsp;&nbsp;google\_fonts: ^6.2.1  
&nbsp;&nbsp;shimmer: ^3.0.0  
&nbsp;&nbsp;flutter\_svg: ^2.0.10+1  
&nbsp;&nbsp;badges: ^3.1.2

&nbsp;&nbsp;\# Payments  
&nbsp;&nbsp;razorpay\_flutter: ^1.3.7

dev\_dependencies:  
&nbsp;&nbsp;flutter\_test:  
&nbsp;&nbsp;&nbsp;&nbsp;sdk: flutter  
&nbsp;&nbsp;flutter\_lints: ^4.0.0  
&nbsp;&nbsp;build\_runner: ^2.4.9  
&nbsp;&nbsp;riverpod\_generator: ^2.4.0  
&nbsp;&nbsp;custom\_lint: ^0.6.4  
&nbsp;&nbsp;riverpod\_lint: ^2.3.10

### **6.2. Cloud Backend Engine (functions/package.json)**

&nbsp;

&nbsp;

&nbsp;

JSON

{  
&nbsp;&nbsp;"name": "book-vardi-functions",  
&nbsp;&nbsp;"scripts": {  
&nbsp;&nbsp;&nbsp;&nbsp;"lint": "eslint \--ext .js,.ts .",  
&nbsp;&nbsp;&nbsp;&nbsp;"build": "tsc",  
&nbsp;&nbsp;&nbsp;&nbsp;"serve": "npm run build && firebase emulators:start \--only functions",  
&nbsp;&nbsp;&nbsp;&nbsp;"deploy": "firebase deploy \--only functions"  
&nbsp;&nbsp;},  
&nbsp;&nbsp;"engines": {  
&nbsp;&nbsp;&nbsp;&nbsp;"node": "20"  
&nbsp;&nbsp;},  
&nbsp;&nbsp;"main": "lib/index.js",  
&nbsp;&nbsp;"dependencies": {  
&nbsp;&nbsp;&nbsp;&nbsp;"firebase-admin": "^12.1.0",  
&nbsp;&nbsp;&nbsp;&nbsp;"firebase-functions": "^5.0.0",  
&nbsp;&nbsp;&nbsp;&nbsp;"razorpay": "^2.9.2",  
&nbsp;&nbsp;&nbsp;&nbsp;"zod": "^3.23.8"  
&nbsp;&nbsp;},  
&nbsp;&nbsp;"devDependencies": {  
&nbsp;&nbsp;&nbsp;&nbsp;"@typescript-eslint/eslint-plugin": "^7.8.0",  
&nbsp;&nbsp;&nbsp;&nbsp;"@typescript-eslint/parser": "^7.8.0",  
&nbsp;&nbsp;&nbsp;&nbsp;"eslint": "^8.57.0",  
&nbsp;&nbsp;&nbsp;&nbsp;"typescript": "^5.4.5"  
&nbsp;&nbsp;},  
&nbsp;&nbsp;"private": true  
}

## **7\. Directory Structure (Feature-First Architecture)**

&nbsp;

&nbsp;

&nbsp;

book\_vardi/  
├── android/  
├── ios/  
├── functions/                         \# Cloud Functions (TypeScript)  
│   ├── src/  
│   │   ├── orders/                    \# Order placement & state mutation triggers  
│   │   ├── payments/                  \# Payment webhook handlers  
│   │   ├── inventory/                 \# Stock reservation & deduction  
│   │   └── index.ts  
│   └── package.json  
├── lib/  
│   ├── main.dart                      \# App initialization & App Check bootstrap  
│   ├── core/  
│   │   ├── constants/                 \# App assets, colors, and API strings  
│   │   ├── guards/                    \# Guest-Guard route redirect logic  
│   │   ├── network/                   \# Connectivity & network wrappers  
│   │   ├── router/                    \# GoRouter route declarations  
│   │   └── theme/                     \# BookVardiTheme & Typography tokens  
│   ├── shared/  
│   │   └── widgets/                   \# CustomButton, CustomTextField, ShimmerTile  
│   └── features/  
│       ├── auth/  
│       │   ├── data/                  \# AuthRepository (Firebase Auth implementation)  
│       │   ├── domain/                \# UserModel & AuthState interfaces  
│       │   └── presentation/          \# LoginScreen, AuthModalSheet  
│       ├── catalog/  
│       │   ├── data/                  \# ProductRepository (Firestore queries)  
│       │   ├── domain/                \# Product, Category, Variant entities  
│       │   └── presentation/          \# HomeScreen, ProductDetailScreen, FilterModal  
│       ├── cart/  
│       │   ├── data/                  \# CartRepository (Firestore transaction sync)  
│       │   ├── domain/                \# CartItem & PriceBreakup models  
│       │   └── presentation/          \# CartScreen, QuantityStepper  
│       ├── checkout/  
│       │   ├── data/                  \# CheckoutRepository & Razorpay client  
│       │   ├── domain/                \# OrderIntent, Address models  
│       │   └── presentation/          \# AddressStepScreen, PaymentGatewayScreen  
│       └── orders/  
│           ├── data/                  \# OrderRepository (Firestore streams)  
│           ├── domain/                \# OrderModel & TrackingStep models  
│           └── presentation/          \# OrderHistoryScreen, OrderTrackingScreen  
└── pubspec.yaml

## **8\. Deployment & CI/CD Pipeline**

* **Source Control:** GitHub Repository with strict branch protections on main (requires passing checks).  
* **CI/CD Orchestrator:** GitHub Actions  
  * **Static Analysis:** Runs flutter analyze and dart format \--output=none \--set-exit-if-changed . on every pull request.  
  * **Android Workflow:** Fastlane builds .aab artifacts, signs with release keystore, and pushes to Google Play Console Internal Track.  
  * **iOS Workflow:** Fastlane signs with Apple Distribution certificates, runs build pipelines on macOS runners, and pushes to TestFlight.  
  * **Backend Deployment:** Automated Cloud Functions deployment on merge to main:  
    Bash  
    firebase deploy \--only functions,firestore:rules,storage

## **9\. Environment Configuration Matrix**

| Environment Variable | Mobile App (--dart-define) | Cloud Functions (.env) | Description |
| :---- | :---- | :---- | :---- |
| ENVIRONMENT | development | production | development | production | Toggles test mode vs production logic |
| RAZORPAY\_KEY\_ID | rzp\_test\_xxxx / rzp\_live\_xxxx | rzp\_test\_xxxx / rzp\_live\_xxxx | Public client key for payment SDK |
| RAZORPAY\_KEY\_SECRET | *Never exposed to client* | SECURED\_IN\_SECRET\_MANAGER | Server-side signature verification key |
| API\_BASE\_URL | \[https://api.bookvardi.com\](https://api.bookvardi.com) | N/A | Base domain for webhooks/proxies |
| ENABLE\_APP\_CHECK | true | false | N/A | Enforces device attestation checks |

&nbsp;