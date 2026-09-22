const { test, describe } = require("node:test");
const assert = require("node:assert");
const { executeInventoryRestock } = require("../lib/index.js");

// Mock Firestore implementation for restock testing
class MockFirestore {
  constructor() {
    this.storage = new Map();
  }

  setDoc(collection, id, data) {
    this.storage.set(`${collection}/${id}`, JSON.parse(JSON.stringify(data)));
  }

  getDoc(collection, id) {
    return this.storage.get(`${collection}/${id}`);
  }

  collection(collectionName) {
    const db = this;
    return {
      doc(docId) {
        return {
          id: docId,
          path: `${collectionName}/${docId}`,
          get: async () => {
            const raw = db.storage.get(`${collectionName}/${docId}`);
            return {
              exists: !!raw,
              id: docId,
              data: () => (raw ? JSON.parse(JSON.stringify(raw)) : undefined),
            };
          },
        };
      },
    };
  }

  async runTransaction(updateFunction) {
    const stagedUpdates = new Map();

    const transaction = {
      get: async (docRef) => {
        const raw = this.storage.get(docRef.path);
        return {
          exists: !!raw,
          id: docRef.id,
          data: () => (raw ? JSON.parse(JSON.stringify(raw)) : undefined),
        };
      },
      update: (docRef, data) => {
        stagedUpdates.set(docRef.path, data);
      },
    };

    const result = await updateFunction(transaction);

    for (const [path, updates] of stagedUpdates.entries()) {
      const existing = this.storage.get(path) || {};
      this.storage.set(path, { ...existing, ...updates });
    }

    return result;
  }
}

describe("TASK-050: Inventory Restock on Order Cancellation Tests", () => {
  test("Updating test order to CANCELLED increments product variant stock back to previous level", async () => {
    const mockDb = new MockFirestore();
    const productId = "prod_uniform_shirt";
    const variantId = "var_size_34";
    const orderId = "#BV-2026-1001";

    // Initial product state after a purchase (stock reduced from 10 to 8)
    mockDb.setDoc("products", productId, {
      name: "School Uniform Shirt",
      totalStock: 8,
      inStock: true,
      variants: [
        { variantId, label: "Size 34", stock: 8, price: 450 },
        { variantId: "var_size_36", label: "Size 36", stock: 15, price: 450 },
      ],
    });

    // Seed the cancelled order document
    const orderData = {
      orderId,
      orderStatus: "CANCELLED",
      items: [
        {
          productId,
          variantId,
          productName: "School Uniform Shirt",
          quantity: 2,
        },
      ],
    };
    mockDb.setDoc("orders", orderId, orderData);

    // Execute restock
    const result = await executeInventoryRestock(mockDb, orderId, orderData);

    assert.strictEqual(result.success, true);
    assert.strictEqual(result.orderId, orderId);
    assert.strictEqual(result.alreadyRestocked, false);
    assert.strictEqual(result.restockedItems.length, 1);
    assert.strictEqual(result.restockedItems[0].restocked, true);

    // Verify product totalStock and variant stock are restored from 8 to 10
    const updatedProduct = mockDb.getDoc("products", productId);
    assert.strictEqual(updatedProduct.totalStock, 10, "Total stock should be restored to 10");
    assert.strictEqual(updatedProduct.variants[0].stock, 10, "Variant stock should be restored to 10");
    // Other variant must remain untouched
    assert.strictEqual(updatedProduct.variants[1].stock, 15, "Other variant stock must not change");

    // Verify order document is marked with isRestocked: true
    const updatedOrder = mockDb.getDoc("orders", orderId);
    assert.strictEqual(updatedOrder.isRestocked, true);
  });

  test("Restocking sets inStock: true when product was completely out of stock (totalStock was 0)", async () => {
    const mockDb = new MockFirestore();
    const productId = "prod_oxford_blazer";
    const variantId = "var_size_40";
    const orderId = "#BV-2026-1002";

    // Product was completely exhausted
    mockDb.setDoc("products", productId, {
      name: "Oxford Blazer",
      totalStock: 0,
      inStock: false,
      variants: [{ variantId, label: "Size 40", stock: 0, price: 1200 }],
    });

    const orderData = {
      orderId,
      orderStatus: "CANCELLED",
      items: [
        {
          productId,
          variantId,
          productName: "Oxford Blazer",
          quantity: 1,
        },
      ],
    };
    mockDb.setDoc("orders", orderId, orderData);

    const result = await executeInventoryRestock(mockDb, orderId, orderData);
    assert.strictEqual(result.success, true);

    const updatedProduct = mockDb.getDoc("products", productId);
    assert.strictEqual(updatedProduct.totalStock, 1);
    assert.strictEqual(updatedProduct.variants[0].stock, 1);
    assert.strictEqual(updatedProduct.inStock, true, "Product must be marked inStock: true");
  });

  test("Idempotency: Subsequent restock attempts on already restocked order do not double-increment stock", async () => {
    const mockDb = new MockFirestore();
    const productId = "prod_math_guide";
    const orderId = "#BV-2026-1003";

    mockDb.setDoc("products", productId, {
      name: "Class 10 Mathematics Guide",
      totalStock: 5,
      inStock: true,
      variants: [],
    });

    const orderData = {
      orderId,
      orderStatus: "CANCELLED",
      items: [
        {
          productId,
          variantId: null,
          productName: "Class 10 Mathematics Guide",
          quantity: 3,
        },
      ],
    };
    mockDb.setDoc("orders", orderId, orderData);

    // First restock call
    const firstResult = await executeInventoryRestock(mockDb, orderId, orderData);
    assert.strictEqual(firstResult.success, true);
    assert.strictEqual(firstResult.alreadyRestocked, false);

    // Product stock increased from 5 to 8
    const productAfterFirst = mockDb.getDoc("products", productId);
    assert.strictEqual(productAfterFirst.totalStock, 8);

    // Second restock call with updated order data (isRestocked: true)
    const updatedOrder = mockDb.getDoc("orders", orderId);
    const secondResult = await executeInventoryRestock(mockDb, orderId, updatedOrder);
    assert.strictEqual(secondResult.success, true);
    assert.strictEqual(secondResult.alreadyRestocked, true);

    // Product stock must still be 8, not 11!
    const productAfterSecond = mockDb.getDoc("products", productId);
    assert.strictEqual(productAfterSecond.totalStock, 8, "Stock must not be double-restocked");
  });

  test("Handles multi-item order with multiple products", async () => {
    const mockDb = new MockFirestore();
    const orderId = "#BV-2026-1004";

    mockDb.setDoc("products", "prod_item_A", {
      name: "Item A",
      totalStock: 3,
      inStock: true,
      variants: [{ variantId: "var_A1", stock: 3 }],
    });

    mockDb.setDoc("products", "prod_item_B", {
      name: "Item B",
      totalStock: 2,
      inStock: true,
      variants: [{ variantId: "var_B1", stock: 2 }],
    });

    const orderData = {
      orderId,
      orderStatus: "CANCELLED",
      items: [
        { productId: "prod_item_A", variantId: "var_A1", quantity: 2 },
        { productId: "prod_item_B", variantId: "var_B1", quantity: 1 },
      ],
    };
    mockDb.setDoc("orders", orderId, orderData);

    const result = await executeInventoryRestock(mockDb, orderId, orderData);
    assert.strictEqual(result.success, true);
    assert.strictEqual(result.restockedItems.length, 2);

    const productA = mockDb.getDoc("products", "prod_item_A");
    assert.strictEqual(productA.totalStock, 5);
    assert.strictEqual(productA.variants[0].stock, 5);

    const productB = mockDb.getDoc("products", "prod_item_B");
    assert.strictEqual(productB.totalStock, 3);
    assert.strictEqual(productB.variants[0].stock, 3);
  });
});
