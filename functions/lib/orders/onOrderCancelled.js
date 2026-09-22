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
exports.onOrderCancelled = void 0;
exports.executeInventoryRestock = executeInventoryRestock;
const admin = __importStar(require("firebase-admin"));
const firestore_1 = require("firebase-functions/v2/firestore");
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
async function executeInventoryRestock(db, orderId, orderData) {
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
    const productRefsMap = new Map();
    for (const rawItem of rawItems) {
        const item = rawItem;
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
        const productDocsMap = new Map();
        for (const [productId, ref] of productRefsMap.entries()) {
            const doc = await transaction.get(ref);
            if (doc.exists) {
                productDocsMap.set(productId, doc);
            }
        }
        // 4. In-memory mutation phase: Prepare cloned product data
        const productDataMap = new Map();
        for (const [productId, doc] of productDocsMap.entries()) {
            const data = doc.data();
            productDataMap.set(productId, {
                productId,
                name: typeof data?.name === "string" ? data.name : productId,
                totalStock: typeof data?.totalStock === "number" ? data.totalStock : 0,
                inStock: typeof data?.inStock === "boolean" ? data.inStock : false,
                variants: Array.isArray(data?.variants)
                    ? data.variants.map((v) => ({ ...v }))
                    : undefined,
            });
        }
        const restockedItems = [];
        // 5. Restock computation for each line item
        for (const rawItem of rawItems) {
            const item = rawItem;
            const productId = typeof item.productId === "string" ? item.productId : "";
            const variantId = typeof item.variantId === "string" && item.variantId.trim()
                ? item.variantId.trim()
                : null;
            const quantity = typeof item.quantity === "number" && item.quantity > 0
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
                const variantIndex = product.variants.findIndex((v) => v.variantId === variantId);
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
                const updatePayload = {
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
exports.onOrderCancelled = (0, firestore_1.onDocumentUpdated)("orders/{orderId}", async (event) => {
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
    if (beforeData.orderStatus !== "CANCELLED" &&
        afterData.orderStatus === "CANCELLED") {
        const orderId = event.params.orderId;
        await executeInventoryRestock(admin.firestore(), orderId, afterData);
    }
});
//# sourceMappingURL=onOrderCancelled.js.map