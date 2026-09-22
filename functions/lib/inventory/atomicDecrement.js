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
exports.atomicDecrement = void 0;
exports.executeAtomicDecrement = executeAtomicDecrement;
const admin = __importStar(require("firebase-admin"));
const https_1 = require("firebase-functions/v2/https");
const schemas_1 = require("../types/schemas");
/**
 * Core transactional function to atomically verify and decrement product variant inventory in Firestore.
 * Ensures strict concurrency safety using Firestore transactions.
 */
async function executeAtomicDecrement(db, rawInput) {
    const parseResult = schemas_1.InventoryDeductSchema.safeParse(rawInput);
    if (!parseResult.success) {
        const errorDetails = parseResult.error.issues
            .map((i) => `${i.path.join(".")}: ${i.message}`)
            .join(", ");
        throw new https_1.HttpsError("invalid-argument", `Invalid inventory decrement payload: ${errorDetails}`);
    }
    const input = parseResult.data;
    // Group requested product references to prevent duplicate read requests
    const productRefsMap = new Map();
    for (const item of input.items) {
        if (!productRefsMap.has(item.productId)) {
            productRefsMap.set(item.productId, db.collection("products").doc(item.productId));
        }
    }
    return await db.runTransaction(async (transaction) => {
        // 1. Read phase: Fetch all required product documents concurrently
        const productDocsMap = new Map();
        for (const [productId, ref] of productRefsMap.entries()) {
            const doc = await transaction.get(ref);
            if (!doc.exists) {
                throw new https_1.HttpsError("not-found", `Product not found with ID: ${productId}`);
            }
            productDocsMap.set(productId, doc);
        }
        // 2. Clone and prepare in-memory product data representations
        const productDataMap = new Map();
        for (const [productId, doc] of productDocsMap.entries()) {
            const data = doc.data();
            productDataMap.set(productId, {
                productId,
                name: typeof data?.name === "string" ? data.name : productId,
                totalStock: typeof data?.totalStock === "number" ? data.totalStock : 0,
                inStock: typeof data?.inStock === "boolean" ? data.inStock : true,
                variants: Array.isArray(data?.variants)
                    ? data.variants.map((v) => ({ ...v }))
                    : undefined,
            });
        }
        // 3. Validation & In-Memory Mutation Phase
        for (const item of input.items) {
            const product = productDataMap.get(item.productId);
            if (!product) {
                throw new https_1.HttpsError("not-found", `Product not found with ID: ${item.productId}`);
            }
            // Check variant stock if variantId is specified
            if (item.variantId) {
                if (!product.variants || product.variants.length === 0) {
                    throw new https_1.HttpsError("failed-precondition", `Product "${product.name}" has no variants configured, but variant "${item.variantId}" was requested.`);
                }
                const variantIndex = product.variants.findIndex((v) => v.variantId === item.variantId);
                if (variantIndex === -1) {
                    throw new https_1.HttpsError("not-found", `Variant ID "${item.variantId}" not found for product "${product.name}".`);
                }
                const variant = product.variants[variantIndex];
                const currentVariantStock = variant.stock ?? 0;
                if (currentVariantStock < item.quantity) {
                    throw new https_1.HttpsError("resource-exhausted", `Insufficient stock for "${product.name}" (${variant.label ?? variant.variantId}). Available: ${currentVariantStock}, Requested: ${item.quantity}.`);
                }
                // Decrement variant stock
                variant.stock = currentVariantStock - item.quantity;
            }
            // Check and decrement total product stock
            if (product.totalStock < item.quantity) {
                throw new https_1.HttpsError("resource-exhausted", `Insufficient total stock for product "${product.name}". Available: ${product.totalStock}, Requested: ${item.quantity}.`);
            }
            product.totalStock -= item.quantity;
            product.inStock = product.totalStock > 0;
        }
        // 4. Write Phase: Commit all updated product documents within the transaction
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
exports.atomicDecrement = (0, https_1.onCall)(async (request) => {
    return await executeAtomicDecrement(admin.firestore(), request.data);
});
//# sourceMappingURL=atomicDecrement.js.map