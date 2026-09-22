import * as admin from "firebase-admin";
import { onDocumentUpdated } from "firebase-functions/v2/firestore";

export interface NotificationMessageContent {
  title: string;
  body: string;
}

export interface NotificationDispatchResult {
  success: boolean;
  orderId: string;
  recipientUserId?: string;
  tokensCount: number;
  successCount: number;
  failureCount: number;
  prunedTokensCount: number;
  reason?: string;
  timestamp: string;
}

/**
 * Formats user-friendly push notification copy based on OrderStatus lifecycle progression.
 */
export function formatOrderStatusNotification(
  status: string,
  orderId: string,
  carrierName?: string | null,
  trackingNumber?: string | null
): NotificationMessageContent | null {
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
export async function getCustomerFcmTokens(
  db: admin.firestore.Firestore,
  userId: string
): Promise<string[]> {
  const tokenSet = new Set<string>();

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
  } catch (error) {
    console.error(`Error retrieving FCM tokens for user ${userId}:`, error);
  }

  return Array.from(tokenSet);
}

/**
 * Prunes expired or unregistered FCM tokens from Firestore user document.
 */
export async function pruneInvalidTokens(
  db: admin.firestore.Firestore,
  userId: string,
  invalidTokens: string[]
): Promise<void> {
  if (!invalidTokens || invalidTokens.length === 0) return;

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
  } catch (err) {
    console.warn(`Failed to prune invalid tokens for user ${userId}:`, err);
  }
}

/**
 * Dispatches high-priority multicast FCM push notifications to customer devices.
 */
export async function dispatchOrderStatusNotification(
  messaging: admin.messaging.Messaging,
  db: admin.firestore.Firestore,
  orderId: string,
  beforeStatus: string,
  afterStatus: string,
  orderData: Record<string, unknown>
): Promise<NotificationDispatchResult> {
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

  const trackingMetadata = (orderData.trackingMetadata as Record<string, unknown>) || {};
  const carrierName = (trackingMetadata.carrierName as string) || null;
  const trackingNumber = (trackingMetadata.trackingNumber as string) || null;

  // 2. Format content
  const content = formatOrderStatusNotification(
    afterStatus,
    orderId,
    carrierName,
    trackingNumber
  );

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
  const userId = (orderData.userId as string) || "";
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
  const multicastPayload: admin.messaging.MulticastMessage = {
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
  const invalidTokens: string[] = [];
  response.responses.forEach((res, index) => {
    if (!res.success && res.error) {
      const code = res.error.code;
      if (
        code === "messaging/registration-token-not-registered" ||
        code === "messaging/invalid-registration-token"
      ) {
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
export const onOrderStatusChanged = onDocumentUpdated(
  "orders/{orderId}",
  async (event) => {
    const change = event.data;
    if (!change) return;

    const beforeData = change.before.data();
    const afterData = change.after.data();

    if (!beforeData || !afterData) return;

    const beforeStatus = String(beforeData.orderStatus || "");
    const afterStatus = String(afterData.orderStatus || "");

    if (beforeStatus !== afterStatus) {
      const orderId = event.params.orderId;
      await dispatchOrderStatusNotification(
        admin.messaging(),
        admin.firestore(),
        orderId,
        beforeStatus,
        afterStatus,
        afterData
      );
    }
  }
);
