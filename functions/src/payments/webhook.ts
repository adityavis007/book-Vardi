import * as admin from "firebase-admin";
import { onRequest } from "firebase-functions/v2/https";
import { createHmac, timingSafeEqual } from "node:crypto";
import {
  PaymentWebhookSchema,
  PaymentWebhookInput,
} from "../types/schemas";

/**
 * Result structure returned from payment webhook processing.
 */
export interface WebhookProcessingResult {
  statusCode: number;
  body: {
    status?: string;
    orderId?: string;
    event?: string;
    message?: string;
    error?: string;
  };
}

/**
 * Verifies the incoming Razorpay webhook signature against the raw payload
 * using HMAC SHA256 and constant-time string comparison.
 *
 * @param rawBody - Raw body buffer or string received in HTTP request.
 * @param signature - Signature provided in 'x-razorpay-signature' header.
 * @param secret - Webhook secret key configured in Razorpay dashboard.
 * @returns boolean indicating whether the signature is authentic.
 */
export function verifyRazorpaySignature(
  rawBody: string | Buffer,
  signature: string,
  secret: string
): boolean {
  if (!signature || !secret) {
    return false;
  }

  try {
    const bodyString =
      typeof rawBody === "string" ? rawBody : rawBody.toString("utf8");

    const expectedSignature = createHmac("sha256", secret)
      .update(bodyString)
      .digest("hex");

    const expectedBuffer = Buffer.from(expectedSignature, "utf8");
    const signatureBuffer = Buffer.from(signature, "utf8");

    if (expectedBuffer.length !== signatureBuffer.length) {
      return false;
    }

    return timingSafeEqual(expectedBuffer, signatureBuffer);
  } catch {
    return false;
  }
}

/**
 * Extracts customer order ID from webhook payload metadata (notes or receipt).
 */
export function extractOrderId(webhookData: PaymentWebhookInput): string | null {
  const orderEntity = webhookData.payload.order?.entity;
  const paymentEntity = webhookData.payload.payment?.entity;

  // 1. Check notes inside Razorpay order entity
  if (orderEntity?.notes) {
    const fromOrderNotes =
      orderEntity.notes.orderId ||
      orderEntity.notes.order_id;
    if (typeof fromOrderNotes === "string" && fromOrderNotes.trim()) {
      return fromOrderNotes.trim();
    }
  }

  // 2. Check notes inside Razorpay payment entity
  if (paymentEntity?.notes) {
    const fromPaymentNotes =
      paymentEntity.notes.orderId ||
      paymentEntity.notes.order_id;
    if (typeof fromPaymentNotes === "string" && fromPaymentNotes.trim()) {
      return fromPaymentNotes.trim();
    }
  }

  // 3. Check receipt identifier inside Razorpay order entity
  if (
    orderEntity?.receipt &&
    typeof orderEntity.receipt === "string" &&
    orderEntity.receipt.trim()
  ) {
    return orderEntity.receipt.trim();
  }

  return null;
}

/**
 * Resolves the Firestore DocumentReference for the target order.
 * First tries direct orderId, then falls back to searching by razorpayOrderId.
 */
export async function findOrderRef(
  db: admin.firestore.Firestore,
  directOrderId: string | null,
  rzpOrderId: string | null | undefined
): Promise<admin.firestore.DocumentReference | null> {
  if (directOrderId) {
    const directRef = db.collection("orders").doc(directOrderId);
    const snap = await directRef.get();
    if (snap.exists) {
      return directRef;
    }
  }

  if (rzpOrderId) {
    const querySnapshot = await db
      .collection("orders")
      .where("razorpayOrderId", "==", rzpOrderId)
      .limit(1)
      .get();

    if (!querySnapshot.empty) {
      return querySnapshot.docs[0].ref;
    }
  }

  // If a direct orderId was provided, return that ref even if not pre-seeded
  if (directOrderId) {
    return db.collection("orders").doc(directOrderId);
  }

  return null;
}

/**
 * Core business handler that authenticates and processes Razorpay webhook payloads.
 * Atomically transitions order status to 'CONFIRMED' and records transaction audit payloads.
 */
export async function processPaymentWebhook(
  db: admin.firestore.Firestore,
  rawBody: string | Buffer,
  signature: string | undefined,
  secret: string
): Promise<WebhookProcessingResult> {
  // 1. Validate signature header presence
  if (!signature) {
    return {
      statusCode: 400,
      body: { error: "Missing x-razorpay-signature header" },
    };
  }

  // 2. Verify HMAC SHA-256 signature
  const isValidSignature = verifyRazorpaySignature(rawBody, signature, secret);
  if (!isValidSignature) {
    return {
      statusCode: 400,
      body: { error: "Invalid signature" },
    };
  }

  // 3. Parse JSON body
  let parsedJson: unknown;
  try {
    const rawString =
      typeof rawBody === "string" ? rawBody : rawBody.toString("utf8");
    parsedJson = JSON.parse(rawString);
  } catch {
    return {
      statusCode: 400,
      body: { error: "Malformed JSON payload" },
    };
  }

  // 4. Validate schema structure
  const parseResult = PaymentWebhookSchema.safeParse(parsedJson);
  if (!parseResult.success) {
    const issueMessages = parseResult.error.issues
      .map((i) => `${i.path.join(".")}: ${i.message}`)
      .join(", ");
    return {
      statusCode: 400,
      body: { error: `Invalid webhook payload structure: ${issueMessages}` },
    };
  }

  const webhookData: PaymentWebhookInput = parseResult.data;
  const event = webhookData.event;

  // 5. Handle payment confirmation events: order.paid or payment.captured
  if (event === "order.paid" || event === "payment.captured") {
    const orderEntity = webhookData.payload.order?.entity;
    const paymentEntity = webhookData.payload.payment?.entity;
    const directOrderId = extractOrderId(webhookData);
    const rzpOrderId = paymentEntity?.order_id || orderEntity?.id;

    const orderRef = await findOrderRef(db, directOrderId, rzpOrderId);
    if (!orderRef) {
      return {
        statusCode: 404,
        body: { error: "Matching order document could not be found" },
      };
    }

    const resolvedOrderId = orderRef.id;

    await db.runTransaction(async (transaction) => {
      const orderDoc = await transaction.get(orderRef);
      if (!orderDoc.exists) {
        throw new Error(`Order ${resolvedOrderId} does not exist`);
      }

      const existingData = orderDoc.data() || {};
      const paymentId = paymentEntity?.id || (existingData.paymentId as string | undefined) || null;
      const razorpayOrderId = rzpOrderId || (existingData.razorpayOrderId as string | undefined) || null;

      const transactionPayload: Record<string, unknown> = {
        event,
        paymentId,
        razorpayOrderId,
        amount: paymentEntity?.amount ?? orderEntity?.amount ?? 0,
        currency: paymentEntity?.currency ?? orderEntity?.currency ?? "INR",
        method: paymentEntity?.method ?? null,
        captured: paymentEntity?.captured ?? true,
        recordedAt: new Date().toISOString(),
      };

      const updateData: Record<string, unknown> = {
        orderStatus: "CONFIRMED",
        paymentStatus: "PAID",
        paymentId,
        razorpayOrderId,
        signature,
        transactionPayload,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      transaction.update(orderRef, updateData);
    });

    return {
      statusCode: 200,
      body: {
        status: "ok",
        orderId: resolvedOrderId,
        event,
        message: "Order successfully confirmed and payment recorded",
      },
    };
  }

  // 6. Acknowledge other event types (e.g. payment.failed) with HTTP 200
  return {
    statusCode: 200,
    body: {
      status: "ok",
      event,
      message: `Webhook event "${event}" received and acknowledged`,
    },
  };
}

/**
 * 2nd Gen HTTP Cloud Function: Razorpay Webhook Endpoint.
 * Validates 'x-razorpay-signature' header against RAZORPAY_WEBHOOK_SECRET / RAZORPAY_KEY_SECRET
 * and atomically updates order payment and fulfillment status in Firestore.
 */
export const razorpayWebhook = onRequest(
  async (req, res): Promise<void> => {
    if (req.method !== "POST") {
      res.status(405).json({
        error: "Method not allowed. Only POST requests are accepted.",
      });
      return;
    }

    const signature = req.headers["x-razorpay-signature"] as string | undefined;
    const secret =
      process.env.RAZORPAY_WEBHOOK_SECRET ||
      process.env.RAZORPAY_KEY_SECRET ||
      "";

    const rawBody: string | Buffer =
      req.rawBody ||
      (typeof req.body === "string" ? req.body : JSON.stringify(req.body ?? {}));

    const result = await processPaymentWebhook(
      admin.firestore(),
      rawBody,
      signature,
      secret
    );

    res.status(result.statusCode).json(result.body);
  }
);
