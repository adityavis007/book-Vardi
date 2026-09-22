const { test, describe } = require("node:test");
const assert = require("node:assert");
const crypto = require("node:crypto");
const {
  verifyRazorpaySignature,
  extractOrderId,
  processPaymentWebhook,
} = require("../lib/index.js");

// Mock Firestore implementation for webhook testing
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
      where(field, op, value) {
        return {
          limit(_n) {
            return {
              get: async () => {
                const matches = [];
                for (const [key, docData] of db.storage.entries()) {
                  if (key.startsWith(`${collectionName}/`) && docData[field] === value) {
                    const docId = key.split("/")[1];
                    matches.push({
                      id: docId,
                      ref: db.collection(collectionName).doc(docId),
                      data: () => JSON.parse(JSON.stringify(docData)),
                    });
                  }
                }
                return {
                  empty: matches.length === 0,
                  docs: matches,
                };
              },
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

const TEST_SECRET = "rzp_test_secret_key_12345678";

function generateSignature(payload, secret = TEST_SECRET) {
  const str = typeof payload === "string" ? payload : JSON.stringify(payload);
  return crypto.createHmac("sha256", secret).update(str).digest("hex");
}

describe("TASK-049: Razorpay Webhook & Signature Verification Tests", () => {
  test("Signature Verification: returns true for valid HMAC and false for invalid", () => {
    const rawPayload = JSON.stringify({ event: "order.paid", test: true });
    const validSig = generateSignature(rawPayload, TEST_SECRET);
    const invalidSig = "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef";

    assert.strictEqual(verifyRazorpaySignature(rawPayload, validSig, TEST_SECRET), true);
    assert.strictEqual(verifyRazorpaySignature(rawPayload, invalidSig, TEST_SECRET), false);
    assert.strictEqual(verifyRazorpaySignature(rawPayload, "", TEST_SECRET), false);
    assert.strictEqual(verifyRazorpaySignature(rawPayload, validSig, "wrong_secret"), false);
  });

  test("Missing Signature: returns HTTP 400 error", async () => {
    const mockDb = new MockFirestore();
    const payload = { event: "order.paid" };
    const rawBody = JSON.stringify(payload);

    const result = await processPaymentWebhook(mockDb, rawBody, undefined, TEST_SECRET);
    assert.strictEqual(result.statusCode, 400);
    assert.match(result.body.error, /Missing x-razorpay-signature header/i);
  });

  test("Invalid Signature: returns HTTP 400 error and rejects execution", async () => {
    const mockDb = new MockFirestore();
    const payload = {
      event: "order.paid",
      payload: {
        order: { entity: { id: "order_rzp_999", receipt: "ord_100" } },
        payment: { entity: { id: "pay_999", amount: 120000, status: "captured" } },
      },
    };
    const rawBody = JSON.stringify(payload);
    const fakeSignature = "bad_signature_hex_digest_9999999999999999999999999999999999999999";

    const result = await processPaymentWebhook(mockDb, rawBody, fakeSignature, TEST_SECRET);
    assert.strictEqual(result.statusCode, 400);
    assert.match(result.body.error, /Invalid signature/i);
  });

  test("Valid Signature + order.paid: Atomically confirms order and updates status to PAID", async () => {
    const mockDb = new MockFirestore();
    const orderId = "#BV-2026-8812";

    // Seed existing order in Firestore
    mockDb.setDoc("orders", orderId, {
      orderId,
      userId: "user_aditya_1",
      orderStatus: "PENDING",
      paymentStatus: "PENDING",
      pricing: { grandTotal: 950 },
    });

    const webhookPayload = {
      event: "order.paid",
      payload: {
        order: {
          entity: {
            id: "order_rzp_alpha",
            amount: 95000,
            currency: "INR",
            receipt: orderId,
            notes: { orderId },
          },
        },
        payment: {
          entity: {
            id: "pay_test_xyz123",
            amount: 95000,
            currency: "INR",
            status: "captured",
            order_id: "order_rzp_alpha",
            method: "upi",
            notes: { orderId },
          },
        },
      },
    };

    const rawBody = JSON.stringify(webhookPayload);
    const validSignature = generateSignature(rawBody, TEST_SECRET);

    const result = await processPaymentWebhook(
      mockDb,
      rawBody,
      validSignature,
      TEST_SECRET
    );

    // Verify HTTP 200 response
    assert.strictEqual(result.statusCode, 200);
    assert.strictEqual(result.body.status, "ok");
    assert.strictEqual(result.body.orderId, orderId);

    // Verify Firestore updates
    const updatedOrder = mockDb.getDoc("orders", orderId);
    assert.strictEqual(updatedOrder.orderStatus, "CONFIRMED");
    assert.strictEqual(updatedOrder.paymentStatus, "PAID");
    assert.strictEqual(updatedOrder.paymentId, "pay_test_xyz123");
    assert.strictEqual(updatedOrder.razorpayOrderId, "order_rzp_alpha");
    assert.strictEqual(updatedOrder.signature, validSignature);

    // Verify recorded transaction audit payload
    assert.ok(updatedOrder.transactionPayload);
    assert.strictEqual(updatedOrder.transactionPayload.event, "order.paid");
    assert.strictEqual(updatedOrder.transactionPayload.amount, 95000);
    assert.strictEqual(updatedOrder.transactionPayload.method, "upi");
  });

  test("Valid Signature + payment.captured: Updates order when resolved via razorpayOrderId query", async () => {
    const mockDb = new MockFirestore();
    const orderId = "#BV-2026-5544";
    const rzpOrderId = "order_rzp_beta";

    // Seed existing order in Firestore with razorpayOrderId
    mockDb.setDoc("orders", orderId, {
      orderId,
      userId: "user_school_parent",
      orderStatus: "PENDING",
      paymentStatus: "PENDING",
      razorpayOrderId: rzpOrderId,
    });

    const webhookPayload = {
      event: "payment.captured",
      payload: {
        payment: {
          entity: {
            id: "pay_test_captured456",
            amount: 150000,
            currency: "INR",
            status: "captured",
            order_id: rzpOrderId,
            method: "card",
          },
        },
      },
    };

    const rawBody = JSON.stringify(webhookPayload);
    const validSignature = generateSignature(rawBody, TEST_SECRET);

    const result = await processPaymentWebhook(
      mockDb,
      rawBody,
      validSignature,
      TEST_SECRET
    );

    assert.strictEqual(result.statusCode, 200);
    assert.strictEqual(result.body.status, "ok");
    assert.strictEqual(result.body.orderId, orderId);

    const updatedOrder = mockDb.getDoc("orders", orderId);
    assert.strictEqual(updatedOrder.orderStatus, "CONFIRMED");
    assert.strictEqual(updatedOrder.paymentStatus, "PAID");
    assert.strictEqual(updatedOrder.paymentId, "pay_test_captured456");
  });

  test("Extract Order ID helper: Handles order.entity.notes, payment.entity.notes, and receipt", () => {
    const fromReceipt = {
      event: "order.paid",
      payload: {
        order: { entity: { id: "o1", receipt: "ord_from_receipt" } },
      },
    };
    assert.strictEqual(extractOrderId(fromReceipt), "ord_from_receipt");

    const fromOrderNotes = {
      event: "order.paid",
      payload: {
        order: { entity: { id: "o2", notes: { orderId: "ord_from_order_notes" } } },
      },
    };
    assert.strictEqual(extractOrderId(fromOrderNotes), "ord_from_order_notes");

    const fromPaymentNotes = {
      event: "payment.captured",
      payload: {
        payment: { entity: { id: "p1", amount: 100, status: "captured", notes: { orderId: "ord_from_pay_notes" } } },
      },
    };
    assert.strictEqual(extractOrderId(fromPaymentNotes), "ord_from_pay_notes");
  });

  test("Non-payment webhook event: Acknowledges with HTTP 200 without throwing", async () => {
    const mockDb = new MockFirestore();
    const payload = {
      event: "payment.failed",
      payload: {
        payment: {
          entity: {
            id: "pay_failed_001",
            amount: 50000,
            status: "failed",
            error_code: "BAD_REQUEST_ERROR",
          },
        },
      },
    };

    const rawBody = JSON.stringify(payload);
    const validSignature = generateSignature(rawBody, TEST_SECRET);

    const result = await processPaymentWebhook(mockDb, rawBody, validSignature, TEST_SECRET);
    assert.strictEqual(result.statusCode, 200);
    assert.strictEqual(result.body.status, "ok");
    assert.match(result.body.message, /acknowledged/i);
  });
});
