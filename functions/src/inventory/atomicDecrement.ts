import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import {
  InventoryDeductSchema,
  InventoryDeductInput,
  InventoryItemDeductInput,
} from "../types/schemas";

export interface VariantData {
  variantId: string;
  sku?: string;
  label?: string;
  price?: number;
  stock: number;
}

export interface ProductData {
  productId: string;
  name?: string;
  totalStock: number;
  inStock: boolean;
  variants?: VariantData[];
}

export interface AtomicDecrementResult {
  success: boolean;
  orderId?: string;
  deductedItems: InventoryItemDeductInput[];
  timestamp: string;
}

/**
 * Core transactional function to atomically verify and decrement product variant inventory in Firestore.
 * Ensures strict concurrency safety using Firestore transactions.
 */
export async function executeAtomicDecrement(
  db: admin.firestore.Firestore,
  rawInput: unknown
): Promise<AtomicDecrementResult> {
  const parseResult = InventoryDeductSchema.safeParse(rawInput);
  if (!parseResult.success) {
    const errorDetails = parseResult.error.issues
      .map((i) => `${i.path.join(".")}: ${i.message}`)
      .join(", ");
    throw new HttpsError(
      "invalid-argument",
      `Invalid inventory decrement payload: ${errorDetails}`
    );
  }

  const input: InventoryDeductInput = parseResult.data;

  // Group requested product references to prevent duplicate read requests
  const productRefsMap = new Map<string, admin.firestore.DocumentReference>();
  for (const item of input.items) {
    if (!productRefsMap.has(item.productId)) {
      productRefsMap.set(
        item.productId,
        db.collection("products").doc(item.productId)
      );
    }
  }

  return await db.runTransaction(async (transaction) => {
    // 1. Read phase: Fetch all required product documents concurrently
    const productDocsMap = new Map<
      string,
      admin.firestore.DocumentSnapshot<admin.firestore.DocumentData>
    >();

    for (const [productId, ref] of productRefsMap.entries()) {
      const doc = await transaction.get(ref);
      if (!doc.exists) {
        throw new HttpsError(
          "not-found",
          `Product not found with ID: ${productId}`
        );
      }
      productDocsMap.set(productId, doc);
    }

    // 2. Clone and prepare in-memory product data representations
    const productDataMap = new Map<string, ProductData>();
    for (const [productId, doc] of productDocsMap.entries()) {
      const data = doc.data();
      productDataMap.set(productId, {
        productId,
        name: typeof data?.name === "string" ? data.name : productId,
        totalStock:
          typeof data?.totalStock === "number" ? data.totalStock : 0,
        inStock: typeof data?.inStock === "boolean" ? data.inStock : true,
        variants: Array.isArray(data?.variants)
          ? (data.variants as VariantData[]).map((v) => ({ ...v }))
          : undefined,
      });
    }

    // 3. Validation & In-Memory Mutation Phase
    for (const item of input.items) {
      const product = productDataMap.get(item.productId);
      if (!product) {
        throw new HttpsError(
          "not-found",
          `Product not found with ID: ${item.productId}`
        );
      }

      // Check variant stock if variantId is specified
      if (item.variantId) {
        if (!product.variants || product.variants.length === 0) {
          throw new HttpsError(
            "failed-precondition",
            `Product "${product.name}" has no variants configured, but variant "${item.variantId}" was requested.`
          );
        }

        const variantIndex = product.variants.findIndex(
          (v) => v.variantId === item.variantId
        );

        if (variantIndex === -1) {
          throw new HttpsError(
            "not-found",
            `Variant ID "${item.variantId}" not found for product "${product.name}".`
          );
        }

        const variant = product.variants[variantIndex];
        const currentVariantStock = variant.stock ?? 0;

        if (currentVariantStock < item.quantity) {
          throw new HttpsError(
            "resource-exhausted",
            `Insufficient stock for "${product.name}" (${variant.label ?? variant.variantId}). Available: ${currentVariantStock}, Requested: ${item.quantity}.`
          );
        }

        // Decrement variant stock
        variant.stock = currentVariantStock - item.quantity;
      }

      // Check and decrement total product stock
      if (product.totalStock < item.quantity) {
        throw new HttpsError(
          "resource-exhausted",
          `Insufficient total stock for product "${product.name}". Available: ${product.totalStock}, Requested: ${item.quantity}.`
        );
      }

      product.totalStock -= item.quantity;
      product.inStock = product.totalStock > 0;
    }

    // 4. Write Phase: Commit all updated product documents within the transaction
    for (const [productId, product] of productDataMap.entries()) {
      const ref = productRefsMap.get(productId);
      if (ref) {
        const updatePayload: Record<string, unknown> = {
          totalStock: product.totalStock,
          inStock: product.inStock,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };

        if (product.variants !== undefined) {
          updatePayload.variants = product.variants;
        }

        transaction.update(ref, updatePayload);
      }
    }

    return {
      success: true,
      orderId: input.orderId,
      deductedItems: input.items,
      timestamp: new Date().toISOString(),
    };
  });
}

/**
 * 2nd Gen Cloud Function: Atomic Inventory Decrement Callable Handler.
 */
export const atomicDecrement = onCall(async (request) => {
  return await executeAtomicDecrement(admin.firestore(), request.data);
});
