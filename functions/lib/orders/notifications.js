"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.onOrderStatusChanged = void 0;
exports.formatOrderStatusNotification = formatOrderStatusNotification;
exports.getCustomerFcmTokens = getCustomerFcmTokens;
exports.pruneInvalidTokens = pruneInvalidTokens;
exports.dispatchOrderStatusNotification = dispatchOrderStatusNotification;
const admin = __importStar(require("firebase-admin"));
const firestore_1 = require("firebase-functions/v2/firestore");
/**
 * Formats user-friendly push notification copy based on OrderStatus lifecycle progression.
 */
function formatOrderStatusNotification(status, orderId, carrierName, trackingNumber) {
    const cleanStatus = status ? status.trim().toUpperCase() : "";
    switch (cleanStatus) {
        case "CONFIRMED":
            return {
                title: "Order Confirmed! 🎒",
                body: `Your order ${orderId} has been confirmed and routed to our school warehouse.`,
            };
        case "PACKED":
            return {
                title: "Order Packed & Ready 📦",
                body: `Your school kit items for order ${orderId} have passed QC and are packed.`,
            };
        case "SHIPPED": {
            const carrierInfo = carrierName ? ` via ${carrierName}` : "";
            const trackingInfo = trackingNumber ? ` (AWB: ${trackingNumber})` : "";
            return {
                title: "Order Dispatched & In Transit 🚚",
                body: `Order ${orderId} is on its way${carrierInfo}${trackingInfo}!`,
            };
        }
        case "OUT_FOR_DELIVERY":
            return {
                title: "Out for Delivery Today! 🛵",
                body: `Your delivery agent is arriving soon with package ${orderId}.`,
            };
        case "DELIVERED":
            return {
                title: "Order Delivered! 🏫",
                body: `Package ${orderId} was successfully delivered. Have a wonderful school session!`,
            };
        case "CANCELLED":
            return {
                title: "Order Cancelled",
                body: `Order ${orderId} has been cancelled. Any applicable refund has been initiated.`,
            };
        default:
            return null;
    }
}
/**
 * Queries active customer FCM tokens from both user document array and token subcollection.
 */
async function getCustomerFcmTokens(db, userId) {
    const tokenSet = new Set();
    try {
        const userDocRef = db.collection("users").doc(userId);
        const userDoc = await userDocRef.get();
        if (userDoc.exists) {
            const data = userDoc.data();
            if (Array.isArray(data?.fcmTokens)) {
                for (const token of data.fcmTokens) {
                    if (typeof token === "string" && token.trim().length > 0) {
                        tokenSet.add(token.trim());
                    }
                }
            }
        }
        // Also check token subcollection: users/{userId}/fcmTokens
        const subColSnapshot = await userDocRef.collection("fcmTokens").get();
        for (const doc of subColSnapshot.docs) {
            const docData = doc.data();
            const token = docData.token || doc.id;
            if (typeof token === "string" && token.trim().length > 0) {
                tokenSet.add(token.trim());
            }
        }
    }
    catch (error) {
        console.error(`Error retrieving FCM tokens for user ${userId}:`, error);
    }
    return Array.from(tokenSet);
}
/**
 * Prunes expired or unregistered FCM tokens from Firestore user document.
 */
async function pruneInvalidTokens(db, userId, invalidTokens) {
    if (!invalidTokens || invalidTokens.length === 0)
        return;
    try {
        const userDocRef = db.collection("users").doc(userId);
        await userDocRef.update({
            fcmTokens: admin.firestore.FieldValue.arrayRemove(...invalidTokens),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        // Also clean up from subcollection
        const batch = db.batch();
        for (const token of invalidTokens) {
            batch.delete(userDocRef.collection("fcmTokens").doc(token));
        }
        await batch.commit();
    }
    catch (err) {
        console.warn(`Failed to prune invalid tokens for user ${userId}:`, err);
    }
}
/**
 * Dispatches high-priority multicast FCM push notifications to customer devices.
 */
async function dispatchOrderStatusNotification(messaging, db, orderId, beforeStatus, afterStatus, orderData) {
    const timestamp = new Date().toISOString();
    // 1. Status unchanged check
    if (beforeStatus === afterStatus) {
        return {
            success: true,
            orderId,
            tokensCount: 0,
            successCount: 0,
            failureCount: 0,
            prunedTokensCount: 0,
            reason: "Status unchanged",
            timestamp,
        };
    }
    const trackingMetadata = orderData.trackingMetadata || {};
    const carrierName = trackingMetadata.carrierName || null;
    const trackingNumber = trackingMetadata.trackingNumber || null;
    // 2. Format content
    const content = formatOrderStatusNotification(afterStatus, orderId, carrierName, trackingNumber);
    if (!content) {
        return {
            success: true,
            orderId,
            tokensCount: 0,
            successCount: 0,
            failureCount: 0,
            prunedTokensCount: 0,
            reason: `No notification template configured for status: ${afterStatus}`,
            timestamp,
        };
    }
    // 3. Resolve customer userId
    const userId = orderData.userId || "";
    if (!userId) {
        return {
            success: false,
            orderId,
            tokensCount: 0,
            successCount: 0,
            failureCount: 0,
            prunedTokensCount: 0,
            reason: "Missing userId on order document",
            timestamp,
        };
    }
    // 4. Retrieve tokens
    const tokens = await getCustomerFcmTokens(db, userId);
    if (tokens.length === 0) {
        return {
            success: true,
            orderId,
            recipientUserId: userId,
            tokensCount: 0,
            successCount: 0,
            failureCount: 0,
            prunedTokensCount: 0,
            reason: "No registered device tokens found for user",
            timestamp,
        };
    }
    // 5. Construct high-priority payload
    const multicastPayload = {
        tokens,
        notification: {
            title: content.title,
            body: content.body,
        },
        data: {
            orderId,
            type: "order_update",
            status: afterStatus,
            click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
            priority: "high",
            notification: {
                channelId: "order_updates_channel",
                priority: "max",
                defaultSound: true,
                clickAction: "FLUTTER_NOTIFICATION_CLICK",
            },
        },
        apns: {
            headers: {
                "apns-priority": "10",
            },
            payload: {
                aps: {
                    sound: "default",
                    badge: 1,
                },
            },
        },
    };
    // 6. Send multicast
    const response = await messaging.sendEachForMulticast(multicastPayload);
    // 7. Track failed tokens for cleanup
    const invalidTokens = [];
    response.responses.forEach((res, index) => {
        if (!res.success && res.error) {
            const code = res.error.code;
            if (code === "messaging/registration-token-not-registered" ||
                code === "messaging/invalid-registration-token") {
                invalidTokens.push(tokens[index]);
            }
        }
    });
    if (invalidTokens.length > 0) {
        await pruneInvalidTokens(db, userId, invalidTokens);
    }
    return {
        success: true,
        orderId,
        recipientUserId: userId,
        tokensCount: tokens.length,
        successCount: response.successCount,
        failureCount: response.failureCount,
        prunedTokensCount: invalidTokens.length,
        timestamp,
    };
}
/**
 * 2nd Gen Firestore Background Trigger:
 * Fires on any update to `orders/{orderId}`, detecting orderStatus transitions and
 * dispatching high-priority push notifications to the customer's registered devices.
 */
exports.onOrderStatusChanged = (0, firestore_1.onDocumentUpdated)("orders/{orderId}", async (event) => {
    const change = event.data;
    if (!change)
        return;
    const beforeData = change.before.data();
    const afterData = change.after.data();
    if (!beforeData || !afterData)
        return;
    const beforeStatus = String(beforeData.orderStatus || "");
    const afterStatus = String(afterData.orderStatus || "");
    if (beforeStatus !== afterStatus) {
        const orderId = event.params.orderId;
        await dispatchOrderStatusNotification(admin.messaging(), admin.firestore(), orderId, beforeStatus, afterStatus, afterData);
    }
});
//# sourceMappingURL=notifications.js.map