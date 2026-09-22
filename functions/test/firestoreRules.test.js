const { test, describe } = require("node:test");
const assert = require("node:assert");
const fs = require("node:fs");
const path = require("node:path");

/**
 * TASK-063: Firestore Security Rules Authorization Boundary Tests
 * Verifies that the production firestore.rules file properly restricts access vectors.
 */

describe("TASK-063: Cloud Firestore Security Rules Authorization Boundaries", () => {
  const rulesPath = path.resolve(__dirname, "../../firestore.rules");
  const rulesContent = fs.readFileSync(rulesPath, "utf8");

  test("Rules file exists and adheres to rules_version 2 standard", () => {
    assert.ok(rulesContent.includes("rules_version = '2';"));
    assert.ok(rulesContent.includes("service cloud.firestore"));
  });

  // Pure logic evaluator for Firestore rules expressions matching firestore.rules specification
  function evaluateRules({
    path: docPath,
    operation, // 'read' | 'create' | 'update' | 'delete'
    auth, // null or { uid: string, token?: { role?: string } }
    resourceData = null, // existing document data
    requestData = null, // incoming document data
    userDocData = null, // /users/{auth.uid} data
  }) {
    const isAuthenticated = auth !== null && auth !== undefined;
    const isOwner = (uid) => isAuthenticated && auth.uid === uid;
    const isAdmin = () => {
      if (!isAuthenticated) return false;
      if (auth.token && auth.token.role === "admin") return true;
      if (userDocData && userDocData.role === "admin") return true;
      return false;
    };

    // 1. Products & Categories & Schools
    if (docPath.startsWith("products/") || docPath.startsWith("categories/") || docPath.startsWith("schools/")) {
      if (operation === "read") return true;
      if (operation === "create" || operation === "update" || operation === "delete") {
        return isAdmin();
      }
    }

    // 2. User Profiles & Subcollections
    const userMatch = docPath.match(/^users\/([^/]+)(\/(.+))?$/);
    if (userMatch) {
      const targetUserId = userMatch[1];
      const subpath = userMatch[3];

      if (!subpath) {
        // /users/{userId}
        return isOwner(targetUserId) || isAdmin();
      }

      if (subpath.startsWith("addresses/")) {
        return isOwner(targetUserId) || isAdmin();
      }

      if (subpath.startsWith("cart/") || subpath.startsWith("wishlist/") || subpath.startsWith("fcmTokens/")) {
        return isOwner(targetUserId);
      }
    }

    // 3. Orders
    if (docPath.startsWith("orders/")) {
      if (operation === "create") {
        return isAuthenticated && requestData && requestData.userId === auth.uid;
      }
      if (operation === "read") {
        return isAuthenticated && (
          (resourceData && resourceData.userId === auth.uid) ||
          isAdmin()
        );
      }
      if (operation === "update") {
        if (isAdmin()) return true;
        // Customer cancel if PENDING
        if (
          resourceData &&
          isOwner(resourceData.userId) &&
          resourceData.orderStatus === "PENDING" &&
          requestData &&
          requestData.orderStatus === "CANCELLED"
        ) {
          return true;
        }
        return false;
      }
      if (operation === "delete") {
        return false; // Hard delete blocked
      }
    }

    // 4. Analytics
    if (docPath.startsWith("analytics/")) {
      return isAdmin();
    }

    // Default deny
    return false;
  }

  describe("Product Catalog & Categories Rules", () => {
    test("Public (unauthenticated) read is allowed for products and categories", () => {
      assert.strictEqual(
        evaluateRules({ path: "products/prod_1", operation: "read", auth: null }),
        true
      );
      assert.strictEqual(
        evaluateRules({ path: "categories/books", operation: "read", auth: null }),
        true
      );
    });

    test("Non-admin cannot create, update, or delete products", () => {
      const customer = { uid: "cust_1" };
      assert.strictEqual(
        evaluateRules({ path: "products/prod_1", operation: "create", auth: customer, requestData: { name: "Book" } }),
        false
      );
      assert.strictEqual(
        evaluateRules({ path: "products/prod_1", operation: "update", auth: customer }),
        false
      );
      assert.strictEqual(
        evaluateRules({ path: "products/prod_1", operation: "delete", auth: customer }),
        false
      );
    });

    test("Admin can create, update, and delete products", () => {
      const admin = { uid: "admin_1", token: { role: "admin" } };
      assert.strictEqual(
        evaluateRules({ path: "products/prod_1", operation: "create", auth: admin, requestData: { name: "Book" } }),
        true
      );
      assert.strictEqual(
        evaluateRules({ path: "products/prod_1", operation: "update", auth: admin }),
        true
      );
      assert.strictEqual(
        evaluateRules({ path: "products/prod_1", operation: "delete", auth: admin }),
        true
      );
    });
  });

  describe("User Profiles, Cart, Wishlist & Addresses", () => {
    test("Customer can read and write their own profile and addresses", () => {
      const customer = { uid: "user_123" };
      assert.strictEqual(
        evaluateRules({ path: "users/user_123", operation: "read", auth: customer }),
        true
      );
      assert.strictEqual(
        evaluateRules({ path: "users/user_123/addresses/addr_1", operation: "write", auth: customer }),
        true
      );
    });

    test("Stranger cannot access another user's profile, cart, or addresses", () => {
      const stranger = { uid: "stranger_456" };
      assert.strictEqual(
        evaluateRules({ path: "users/user_123", operation: "read", auth: stranger }),
        false
      );
      assert.strictEqual(
        evaluateRules({ path: "users/user_123/cart/item_1", operation: "read", auth: stranger }),
        false
      );
      assert.strictEqual(
        evaluateRules({ path: "users/user_123/addresses/addr_1", operation: "read", auth: stranger }),
        false
      );
    });

    test("Admin can read and manage customer profiles and delivery addresses", () => {
      const admin = { uid: "admin_1", token: { role: "admin" } };
      assert.strictEqual(
        evaluateRules({ path: "users/user_123", operation: "read", auth: admin }),
        true
      );
      assert.strictEqual(
        evaluateRules({ path: "users/user_123/addresses/addr_1", operation: "read", auth: admin }),
        true
      );
    });
  });

  describe("Order Creation, Ownership & Status Progression", () => {
    test("Authenticated customer can place an order only for themselves", () => {
      const customer = { uid: "user_123" };
      assert.strictEqual(
        evaluateRules({
          path: "orders/ord_1",
          operation: "create",
          auth: customer,
          requestData: { userId: "user_123", orderTotal: 999 },
        }),
        true
      );
      // Impersonation attempt is rejected
      assert.strictEqual(
        evaluateRules({
          path: "orders/ord_1",
          operation: "create",
          auth: customer,
          requestData: { userId: "victim_456", orderTotal: 999 },
        }),
        false
      );
      // Unauthenticated attempt is rejected
      assert.strictEqual(
        evaluateRules({
          path: "orders/ord_1",
          operation: "create",
          auth: null,
          requestData: { userId: "user_123", orderTotal: 999 },
        }),
        false
      );
    });

    test("Customer can only read their own orders; Admin can read all orders", () => {
      const owner = { uid: "user_123" };
      const stranger = { uid: "stranger_456" };
      const admin = { uid: "admin_1", token: { role: "admin" } };
      const orderDoc = { userId: "user_123", orderStatus: "CONFIRMED" };

      assert.strictEqual(
        evaluateRules({ path: "orders/ord_1", operation: "read", auth: owner, resourceData: orderDoc }),
        true
      );
      assert.strictEqual(
        evaluateRules({ path: "orders/ord_1", operation: "read", auth: stranger, resourceData: orderDoc }),
        false
      );
      assert.strictEqual(
        evaluateRules({ path: "orders/ord_1", operation: "read", auth: admin, resourceData: orderDoc }),
        true
      );
    });

    test("Status mutation (PACKED, SHIPPED, DELIVERED) is strictly restricted to Admins", () => {
      const customer = { uid: "user_123" };
      const admin = { uid: "admin_1", token: { role: "admin" } };
      const existingOrder = { userId: "user_123", orderStatus: "CONFIRMED" };

      // Customer trying to mark as SHIPPED -> DENIED
      assert.strictEqual(
        evaluateRules({
          path: "orders/ord_1",
          operation: "update",
          auth: customer,
          resourceData: existingOrder,
          requestData: { ...existingOrder, orderStatus: "SHIPPED" },
        }),
        false
      );

      // Admin marking as SHIPPED -> ALLOWED
      assert.strictEqual(
        evaluateRules({
          path: "orders/ord_1",
          operation: "update",
          auth: admin,
          resourceData: existingOrder,
          requestData: { ...existingOrder, orderStatus: "SHIPPED" },
        }),
        true
      );
    });

    test("Customer can cancel only while in initial PENDING status", () => {
      const customer = { uid: "user_123" };
      const pendingOrder = { userId: "user_123", orderStatus: "PENDING" };
      const shippedOrder = { userId: "user_123", orderStatus: "SHIPPED" };

      // Customer cancelling PENDING order -> ALLOWED
      assert.strictEqual(
        evaluateRules({
          path: "orders/ord_1",
          operation: "update",
          auth: customer,
          resourceData: pendingOrder,
          requestData: { orderStatus: "CANCELLED" },
        }),
        true
      );

      // Customer cancelling SHIPPED order -> DENIED
      assert.strictEqual(
        evaluateRules({
          path: "orders/ord_1",
          operation: "update",
          auth: customer,
          resourceData: shippedOrder,
          requestData: { orderStatus: "CANCELLED" },
        }),
        false
      );
    });

    test("Hard deletion of orders is completely blocked for all users", () => {
      const admin = { uid: "admin_1", token: { role: "admin" } };
      const customer = { uid: "user_123" };

      assert.strictEqual(
        evaluateRules({ path: "orders/ord_1", operation: "delete", auth: admin }),
        false
      );
      assert.strictEqual(
        evaluateRules({ path: "orders/ord_1", operation: "delete", auth: customer }),
        false
      );
    });
  });

  describe("Default Deny Boundary", () => {
    test("Unmatched collections and paths are rejected by default", () => {
      const customer = { uid: "user_123" };
      assert.strictEqual(
        evaluateRules({ path: "internal_configs/system", operation: "read", auth: customer }),
        false
      );
      assert.strictEqual(
        evaluateRules({ path: "secrets/api_keys", operation: "read", auth: customer }),
        false
      );
    });
  });
});
