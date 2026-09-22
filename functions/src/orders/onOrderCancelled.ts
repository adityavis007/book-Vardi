import * as admin from "firebase-admin";
import { onDocumentUpdated } from "firebase-functions/v2/firestore";

export interface RestockItemResult {
  productId: string;
  variantId?: string | null;
  quantity: number;
  restocked: boolean;
}

export interface RestockResult {
  success: boolean;
  orderId: string;
  alreadyRestocked?: boolean;
  restockedItems: RestockItemResult[];
  timestamp: string;
}

interface VariantStockData {
  variantId: string;
  sku?: string;
  label?: string;
  price?: number;
  stock: number;
}

interface ProductStockData {
  productId: string;
  name?: string;
  totalStock: number;
  inStock: boolean;
  variants?: VariantStockData[];
}

/**
 * Core transactional business logic to restore product stock and variant stock
 * when a customer order is cancelled.
 *
 * Implements strict idempotency using 'isRestocked' tracking on the order document.
 *
 * @param db - Firestore database instance.
 * @param orderId - Order identifier (e.g. #BV-2026-9812).
 * @param orderData - Order document data containing items list.
 */
export async function executeInventoryRestock(
  db: admin.firestore.Firestore,
  orderId: string,
  orderData: Record<string, unknown>
): Promise<RestockResult> {
  // 1. Check idempotency flag before acquiring transaction
  if (orderData && orderData.isRestocked === true) {
    return {
      success: true,
      orderId,
      alreadyRestocked: true,
      restockedItems: [],
      timestamp: new Date().toISOString(),
    };
  }

  const rawItems = Array.isArray(orderData?.items) ? orderData.items : [];
  if (rawItems.length === 0) {
    return {
      success: true,
      orderId,
      restockedItems: [],
      timestamp: new Date().toISOString(),
    };
  }

  const orderRef = db.collection("orders").doc(orderId);

  // Collect unique product references to fetch in the transaction
  const productRefsMap = new Map<string, admin.firestore.DocumentReference>();
  for (const rawItem of rawItems) {
    const item = rawItem as Record<string, unknown>;
    const productId = typeof item.productId === "string" ? item.productId : "";
    if (productId && !productRefsMap.has(productId)) {
      productRefsMap.set(productId, db.collection("products").doc(productId));
    }
  }

  return await db.runTransaction(async (transaction) => {
    // 2. Read phase: Double-check order idempotency within the transaction
    const orderDoc = await transaction.get(orderRef);
    if (orderDoc.exists && orderDoc.data()?.isRestocked === true) {
      return {
        success: true,
        orderId,
        alreadyRestocked: true,
        restockedItems: [],
        timestamp: new Date().toISOString(),
      };
    }

    // 3. Read phase: Fetch all associated product documents
    const productDocsMap = new Map<
      string,
      admin.firestore.DocumentSnapshot<admin.firestore.DocumentData>
    >();

    for (const [productId, ref] of productRefsMap.entries()) {
      const doc = await transaction.get(ref);
      if (doc.exists) {
        productDocsMap.set(productId, doc);
      }
    }

    // 4. In-memory mutation phase: Prepare cloned product data
    const productDataMap = new Map<string, ProductStockData>();
    for (const [productId, doc] of productDocsMap.entries()) {
      const data = doc.data();
      productDataMap.set(productId, {
        productId,
        name: typeof data?.name === "string" ? data.name : productId,
        totalStock:
          typeof data?.totalStock === "number" ? data.totalStock : 0,
        inStock: typeof data?.inStock === "boolean" ? data.inStock : false,
        variants: Array.isArray(data?.variants)
          ? (data.variants as VariantStockData[]).map((v) => ({ ...v }))
          : undefined,
      });
    }

    const restockedItems: RestockItemResult[] = [];

    // 5. Restock computation for each line item
    for (const rawItem of rawItems) {
      const item = rawItem as Record<string, unknown>;
      const productId = typeof item.productId === "string" ? item.productId : "";
      const variantId =
        typeof item.variantId === "string" && item.variantId.trim()
          ? item.variantId.trim()
          : null;
      const quantity =
        typeof item.quantity === "number" && item.quantity > 0
          ? item.quantity
          : 1;

      const product = productDataMap.get(productId);
      if (!product) {
        // Product no longer exists or invalid ID; record as non-restocked and continue
        restockedItems.push({
          productId,
          variantId,
          quantity,
          restocked: false,
        });
        continue;
      }

      // Restock variant stock if variantId is specified
      if (variantId && product.variants && product.variants.length > 0) {
        const variantIndex = product.variants.findIndex(
          (v) => v.variantId === variantId
        );
        if (variantIndex !== -1) {
          const currentStock = product.variants[variantIndex].stock ?? 0;
          product.variants[variantIndex].stock = currentStock + quantity;
        }
      }

      // Restock product total stock
      product.totalStock += quantity;
      product.inStock = product.totalStock > 0;

      restockedItems.push({
        productId,
        variantId,
        quantity,
        restocked: true,
      });
    }

    // 6. Write phase: Commit all updated product documents
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

    // 7. Write phase: Mark order document as restocked to enforce idempotency
    transaction.update(orderRef, {
      isRestocked: true,
      restockedAt: admin.firestore.FieldValue.serverTimestamp(),
      restockedItemsSummary: restockedItems,
    });

    return {
      success: true,
      orderId,
      alreadyRestocked: false,
      restockedItems,
      timestamp: new Date().toISOString(),
    };
  });
}

/**
 * 2nd Gen Firestore Background Trigger: Restores product inventory when orderStatus becomes CANCELLED.
 */
export const onOrderCancelled = onDocumentUpdated(
  "orders/{orderId}",
  async (event) => {
    const change = event.data;
    if (!change) {
      return;
    }

    const beforeData = change.before.data();
    const afterData = change.after.data();

    if (!beforeData || !afterData) {
      return;
    }

    // Trigger only when order transitions into CANCELLED
    if (
      beforeData.orderStatus !== "CANCELLED" &&
      afterData.orderStatus === "CANCELLED"
    ) {
      const orderId = event.params.orderId;
      await executeInventoryRestock(admin.firestore(), orderId, afterData);
    }
  }
);
