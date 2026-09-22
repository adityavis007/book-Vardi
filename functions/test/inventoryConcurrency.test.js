const { test, describe } = require("node:test");
const assert = require("node:assert");
const { executeAtomicDecrement } = require("../lib/index.js");

// Mock Firestore implementation with serialized transactional locking
class MockFirestore {
  constructor() {
    this.storage = new Map();
    this.isLocked = false;
    this.lockQueue = [];
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
        };
      },
    };
  }

  async acquireLock() {
    if (!this.isLocked) {
      this.isLocked = true;
      return;
    }
    await new Promise((resolve) => this.lockQueue.push(resolve));
  }

  releaseLock() {
    if (this.lockQueue.length > 0) {
      const next = this.lockQueue.shift();
      next();
    } else {
      this.isLocked = false;
    }
  }

  async runTransaction(updateFunction) {
    await this.acquireLock();
    try {
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

      // Commit staged updates atomically
      for (const [path, updates] of stagedUpdates.entries()) {
        const existing = this.storage.get(path) || {};
        this.storage.set(path, { ...existing, ...updates });
      }

      return result;
    } finally {
      this.releaseLock();
    }
  }
}

describe("TASK-048: Atomic Inventory Decrement Tests", () => {
  test("Successfully decrements stock when sufficient inventory exists", async () => {
    const mockDb = new MockFirestore();
    mockDb.setDoc("products", "prod_1", {
      name: "Delhi Public School Shirt",
      totalStock: 10,
      inStock: true,
      variants: [
        { variantId: "var_size_32", label: "Size 32", stock: 10, price: 450 },
      ],
    });

    const result = await executeAtomicDecrement(mockDb, {
      orderId: "order_single_001",
      items: [{ productId: "prod_1", variantId: "var_size_32", quantity: 2 }],
    });

    assert.strictEqual(result.success, true);
    assert.strictEqual(result.orderId, "order_single_001");

    const updated = mockDb.getDoc("products", "prod_1");
    assert.strictEqual(updated.totalStock, 8);
    assert.strictEqual(updated.variants[0].stock, 8);
    assert.strictEqual(updated.inStock, true);
  });

  test("Rejects transaction when variant stock is 0", async () => {
    const mockDb = new MockFirestore();
    mockDb.setDoc("products", "prod_out_of_stock", {
      name: "Out of stock item",
      totalStock: 0,
      inStock: false,
      variants: [{ variantId: "var_zero", stock: 0, price: 200 }],
    });

    await assert.rejects(
      async () => {
        await executeAtomicDecrement(mockDb, {
          orderId: "order_fail_001",
          items: [{ productId: "prod_out_of_stock", variantId: "var_zero", quantity: 1 }],
        });
      },
      (err) => {
        assert.match(err.message, /Insufficient stock/i);
        return true;
      }
    );
  });

  test("Concurrency Test: Simultaneous orders on 1 stock item allow exactly 1 success and fail the second", async () => {
    const mockDb = new MockFirestore();
    // Only 1 unit in stock
    mockDb.setDoc("products", "prod_hot_item", {
      name: "Last Available Uniform Blazer",
      totalStock: 1,
      inStock: true,
      variants: [
        { variantId: "var_size_36", label: "Size 36", stock: 1, price: 1200 },
      ],
    });

    const order1Promise = executeAtomicDecrement(mockDb, {
      orderId: "order_user_alpha",
      items: [{ productId: "prod_hot_item", variantId: "var_size_36", quantity: 1 }],
    });

    const order2Promise = executeAtomicDecrement(mockDb, {
      orderId: "order_user_beta",
      items: [{ productId: "prod_hot_item", variantId: "var_size_36", quantity: 1 }],
    });

    // Run both orders simultaneously
    const results = await Promise.allSettled([order1Promise, order2Promise]);

    const successes = results.filter((r) => r.status === "fulfilled");
    const failures = results.filter((r) => r.status === "rejected");

    // Exactly one should succeed, exactly one should fail
    assert.strictEqual(successes.length, 1, "Exactly one order must succeed");
    assert.strictEqual(failures.length, 1, "Exactly one order must fail");

    // Verify rejection reason is stock exhaustion
    assert.match(
      failures[0].reason.message,
      /Insufficient stock/i,
      "Failed order must report insufficient stock"
    );

    // Verify database integrity: stock is now exactly 0 and marked out of stock
    const finalProduct = mockDb.getDoc("products", "prod_hot_item");
    assert.strictEqual(finalProduct.totalStock, 0, "Total stock must be 0");
    assert.strictEqual(finalProduct.variants[0].stock, 0, "Variant stock must be 0");
    assert.strictEqual(finalProduct.inStock, false, "Product inStock must be false");
  });
});
