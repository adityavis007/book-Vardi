import * as admin from "firebase-admin";
import { setGlobalOptions } from "firebase-functions/v2";

// Initialize Firebase Admin SDK
admin.initializeApp();

// Configure default options for 2nd gen Cloud Functions
setGlobalOptions({
  region: "asia-south1", // Mumbai region for Indian school commerce ecosystem
  maxInstances: 10,
});

export const healthCheck = () => {
  return { status: "ok", timestamp: new Date().toISOString() };
};

// Export schemas and domain types
export * from "./types/schemas";

// Export transactional inventory operations
export * from "./inventory/atomicDecrement";

// Export payment webhook handlers
export * from "./payments/webhook";

// Export order cancellation restock operations
export * from "./orders/onOrderCancelled";

// Export order push notification triggers
export * from "./orders/notifications";

// Export storage media WebP resizing pipeline
export * from "./storage/resizeImage";
