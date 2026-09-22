const { test, describe } = require("node:test");
const assert = require("node:assert");
const {
  formatOrderStatusNotification,
  getCustomerFcmTokens,
  pruneInvalidTokens,
  dispatchOrderStatusNotification,
} = require("../lib/index.js");

// Mock Firestore for notification tests
class MockFirestoreForNotifications {
  constructor() {
    this.storage = new Map();
    this.subcollections = new Map();
  }

  setDoc(path, data) {
    this.storage.set(path, JSON.parse(JSON.stringify(data)));
  }

  setSubDoc(parentPath, subCol, docId, data) {
    const key = `${parentPath}/${subCol}/${docId}`;
    this.subcollections.set(key, JSON.parse(JSON.stringify(data)));
  }

  collection(name) {
    const db = this;
    return {
      doc(docId) {
        const docPath = `${name}/${docId}`;
        return {
          id: docId,
          path: docPath,
          get: async () => {
            const raw = db.storage.get(docPath);
            return {
              exists: !!raw,
              id: docId,
              data: () => (raw ? JSON.parse(JSON.stringify(raw)) : undefined),
            };
          },
          update: async (updates) => {
            const existing = db.storage.get(docPath) || {};
            // Handle arrayRemove simulation
            if (updates.fcmTokens && updates.fcmTokens._elements) {
              const toRemove = new Set(updates.fcmTokens._elements);
              const currentList = Array.isArray(existing.fcmTokens) ? existing.fcmTokens : [];
              existing.fcmTokens = currentList.filter((t) => !toRemove.has(t));
              delete updates.fcmTokens;
            }
            db.storage.set(docPath, { ...existing, ...updates });
          },
          collection(subCol) {
            return {
              get: async () => {
                const prefix = `${docPath}/${subCol}/`;
                const docs = [];
                for (const [k, v] of db.subcollections.entries()) {
                  if (k.startsWith(prefix)) {
                    const id = k.substring(prefix.length);
                    docs.push({
                      id,
                      data: () => JSON.parse(JSON.stringify(v)),
                    });
                  }
                }
                return { docs };
              },
              doc(subDocId) {
                return {
                  id: subDocId,
                  path: `${docPath}/${subCol}/${subDocId}`,
                };
              },
            };
          },
        };
      },
    };
  }

  batch() {
    const db = this;
    const operations = [];
    return {
      delete(docRef) {
        operations.push(() => {
          db.subcollections.delete(docRef.path);
        });
      },
      commit: async () => {
        for (const op of operations) op();
      },
    };
  }
}

// Mock Messaging for FCM tests
class MockMessaging {
  constructor(responseConfig = {}) {
    this.sentMessages = [];
    this.responseConfig = responseConfig;
  }

  async sendEachForMulticast(payload) {
    this.sentMessages.push(payload);
    const responses = (payload.tokens || []).map((token) => {
      if (this.responseConfig.failingTokens && this.responseConfig.failingTokens.includes(token)) {
        return {
          success: false,
          error: { code: "messaging/registration-token-not-registered", message: "Token unregistered" },
        };
      }
      return {
        success: true,
        messageId: `msg_${Math.random().toString(36).substring(7)}`,
      };
    });

    const successCount = responses.filter((r) => r.success).length;
    return {
      successCount,
      failureCount: responses.length - successCount,
      responses,
    };
  }
}

describe("TASK-051: FCM Push Notification Triggers & Templates", () => {
  test("Template Formatting: formats distinct copy for all order lifecycle states", () => {
    const orderId = "BV-2026-9812";

    const confirmed = formatOrderStatusNotification("CONFIRMED", orderId);
    assert.match(confirmed.title, /Confirmed/);
    assert.match(confirmed.body, /BV-2026-9812/);

    const packed = formatOrderStatusNotification("PACKED", orderId);
    assert.match(packed.title, /Packed/);

    const shipped = formatOrderStatusNotification("SHIPPED", orderId, "BlueDart", "BD-9912");
    assert.match(shipped.title, /Dispatched/);
    assert.match(shipped.body, /BlueDart/);
    assert.match(shipped.body, /BD-9912/);

    const outForDelivery = formatOrderStatusNotification("OUT_FOR_DELIVERY", orderId);
    assert.match(outForDelivery.title, /Out for Delivery/);

    const delivered = formatOrderStatusNotification("DELIVERED", orderId);
    assert.match(delivered.title, /Delivered/);

    const cancelled = formatOrderStatusNotification("CANCELLED", orderId);
    assert.match(cancelled.title, /Cancelled/);

    const unknown = formatOrderStatusNotification("UNKNOWN_STATE", orderId);
    assert.strictEqual(unknown, null);
  });

  test("Token Resolution: retrieves customer tokens from array and subcollection", async () => {
    const db = new MockFirestoreForNotifications();
    db.setDoc("users/user_abc", {
      fcmTokens: ["token_device_1", "token_device_2"],
    });
    db.setSubDoc("users/user_abc", "fcmTokens", "token_device_3", {
      token: "token_device_3",
      createdAt: new Date().toISOString(),
    });

    const tokens = await getCustomerFcmTokens(db, "user_abc");
    assert.strictEqual(tokens.length, 3);
    assert.ok(tokens.includes("token_device_1"));
    assert.ok(tokens.includes("token_device_2"));
    assert.ok(tokens.includes("token_device_3"));
  });

  test("Dispatch Multicast: builds high-priority payload with Android channel and orderId data", async () => {
    const db = new MockFirestoreForNotifications();
    db.setDoc("users/user_123", {
      fcmTokens: ["token_phone_1"],
    });

    const messaging = new MockMessaging();

    const result = await dispatchOrderStatusNotification(
      messaging,
      db,
      "BV-2026-9812",
      "PACKED",
      "SHIPPED",
      {
        userId: "user_123",
        trackingMetadata: {
          carrierName: "Delhivery",
          trackingNumber: "DLH-5544",
        },
      }
    );

    assert.strictEqual(result.success, true);
    assert.strictEqual(result.tokensCount, 1);
    assert.strictEqual(result.successCount, 1);
    assert.strictEqual(messaging.sentMessages.length, 1);

    const sent = messaging.sentMessages[0];
    assert.deepStrictEqual(sent.tokens, ["token_phone_1"]);
    assert.strictEqual(sent.data.orderId, "BV-2026-9812");
    assert.strictEqual(sent.data.status, "SHIPPED");
    assert.strictEqual(sent.android.priority, "high");
    assert.strictEqual(sent.android.notification.channelId, "order_updates_channel");
  });

  test("Prunes unregistered tokens when FCM returns token-not-registered error", async () => {
    const db = new MockFirestoreForNotifications();
    db.setDoc("users/user_cleanup", {
      fcmTokens: ["active_token", "stale_token"],
    });

    const messaging = new MockMessaging({
      failingTokens: ["stale_token"],
    });

    const result = await dispatchOrderStatusNotification(
      messaging,
      db,
      "BV-2026-9812",
      "CONFIRMED",
      "PACKED",
      {
        userId: "user_cleanup",
      }
    );

    assert.strictEqual(result.success, true);
    assert.strictEqual(result.tokensCount, 2);
    assert.strictEqual(result.successCount, 1);
    assert.strictEqual(result.failureCount, 1);
    assert.strictEqual(result.prunedTokensCount, 1);
  });

  test("No-op when status is unchanged", async () => {
    const messaging = new MockMessaging();
    const db = new MockFirestoreForNotifications();

    const result = await dispatchOrderStatusNotification(
      messaging,
      db,
      "BV-2026-9812",
      "SHIPPED",
      "SHIPPED",
      { userId: "user_123" }
    );

    assert.strictEqual(result.success, true);
    assert.strictEqual(result.tokensCount, 0);
    assert.strictEqual(messaging.sentMessages.length, 0);
  });
});
