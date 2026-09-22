"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.PaymentWebhookSchema = exports.InventoryDeductSchema = exports.InventoryItemDeductSchema = exports.OrderCreateSchema = exports.PriceBreakupSchema = exports.OrderItemSchema = exports.AddressSchema = exports.OrderStatusEnum = exports.PaymentStatusEnum = exports.PaymentMethodEnum = exports.DeliveryModeEnum = void 0;
const zod_1 = require("zod");
/**
 * Valid delivery modes supported by Book Vardi.
 */
exports.DeliveryModeEnum = zod_1.z.enum(["standard", "schoolDelivery", "express"]);
/**
 * Payment methods accepted by Book Vardi checkout.
 */
exports.PaymentMethodEnum = zod_1.z.enum(["COD", "UPI", "CARD", "NET_BANKING", "ONLINE"]);
/**
 * Payment resolution statuses.
 */
exports.PaymentStatusEnum = zod_1.z.enum(["PENDING", "PAID", "FAILED", "CONFIRMED"]);
/**
 * Order fulfillment statuses throughout logistics lifecycle.
 */
exports.OrderStatusEnum = zod_1.z.enum([
    "PENDING",
    "CONFIRMED",
    "PROCESSING",
    "PACKED",
    "SHIPPED",
    "OUT_FOR_DELIVERY",
    "DELIVERED",
    "CANCELLED",
]);
/**
 * Schema for customer shipping addresses.
 */
exports.AddressSchema = zod_1.z.object({
    addressId: zod_1.z.string().optional(),
    fullName: zod_1.z.string().min(2, "Full name must be at least 2 characters"),
    phone: zod_1.z
        .string()
        .min(10, "Phone number must be at least 10 digits")
        .regex(/^[0-9+ -]{10,15}$/, "Invalid Indian mobile number format"),
    addressLine1: zod_1.z.string().min(3, "Address line 1 must be at least 3 characters"),
    addressLine2: zod_1.z.string().nullable().optional(),
    city: zod_1.z.string().min(2, "City must be at least 2 characters"),
    state: zod_1.z.string().min(2, "State must be at least 2 characters"),
    pincode: zod_1.z
        .string()
        .regex(/^[1-9][0-9]{5}$/, "Must be a valid 6-digit Indian postal code"),
    isDefault: zod_1.z.boolean().default(false),
    landmark: zod_1.z.string().nullable().optional(),
    addressType: zod_1.z.enum(["Home", "School", "Work"]).default("Home"),
});
/**
 * Schema for line items inside an order.
 */
exports.OrderItemSchema = zod_1.z.object({
    productId: zod_1.z.string().min(1, "Product ID is required"),
    variantId: zod_1.z.string().nullable().optional(),
    productName: zod_1.z.string().min(1, "Product name is required"),
    schoolName: zod_1.z.string().nullable().optional(),
    variantLabel: zod_1.z.string().nullable().optional(),
    imageUrl: zod_1.z.string().url().nullable().optional().or(zod_1.z.literal("")),
    unitPrice: zod_1.z.number().positive("Unit price must be positive"),
    quantity: zod_1.z.number().int().positive("Quantity must be at least 1"),
    maxStock: zod_1.z.number().int().nonnegative().optional(),
});
/**
 * Schema for price breakdown and financial audits.
 */
exports.PriceBreakupSchema = zod_1.z.object({
    subtotal: zod_1.z.number().nonnegative("Subtotal cannot be negative"),
    schoolBulkDiscount: zod_1.z.number().nonnegative().default(0),
    couponDiscount: zod_1.z.number().nonnegative().default(0),
    deliveryCharge: zod_1.z.number().nonnegative("Delivery charge cannot be negative"),
    grandTotal: zod_1.z.number().nonnegative("Grand total cannot be negative"),
});
/**
 * Schema for creating a new order (used in API / Cloud Function invocation).
 */
exports.OrderCreateSchema = zod_1.z.object({
    orderId: zod_1.z.string().optional(),
    userId: zod_1.z.string().min(1, "User ID is required"),
    items: zod_1.z.array(exports.OrderItemSchema).min(1, "Order must contain at least one item"),
    shippingAddress: exports.AddressSchema,
    pricing: exports.PriceBreakupSchema,
    deliveryMode: exports.DeliveryModeEnum.default("standard"),
    paymentMethod: exports.PaymentMethodEnum,
    paymentId: zod_1.z.string().nullable().optional(),
    razorpayOrderId: zod_1.z.string().nullable().optional(),
    signature: zod_1.z.string().nullable().optional(),
    paymentStatus: exports.PaymentStatusEnum.default("PENDING"),
    orderStatus: exports.OrderStatusEnum.default("CONFIRMED"),
    createdAt: zod_1.z.string().datetime().optional().or(zod_1.z.date().optional()),
    estimatedDeliveryDate: zod_1.z.string().datetime().optional().or(zod_1.z.date().optional()),
});
/**
 * Schema for individual item inventory deduction.
 */
exports.InventoryItemDeductSchema = zod_1.z.object({
    productId: zod_1.z.string().min(1, "Product ID is required"),
    variantId: zod_1.z.string().nullable().optional(),
    quantity: zod_1.z.number().int().positive("Deduction quantity must be at least 1"),
});
/**
 * Schema for atomic inventory decrement requests.
 */
exports.InventoryDeductSchema = zod_1.z.object({
    orderId: zod_1.z.string().optional(),
    items: zod_1.z
        .array(exports.InventoryItemDeductSchema)
        .min(1, "At least one item required for inventory deduction"),
});
/**
 * Schema for incoming Razorpay webhook payloads.
 */
exports.PaymentWebhookSchema = zod_1.z.object({
    entity: zod_1.z.string().optional(),
    account_id: zod_1.z.string().optional(),
    event: zod_1.z.string().min(1, "Event name is required"),
    contains: zod_1.z.array(zod_1.z.string()).optional(),
    payload: zod_1.z.object({
        payment: zod_1.z
            .object({
            entity: zod_1.z.object({
                id: zod_1.z.string().min(1, "Payment ID is required"),
                entity: zod_1.z.string().optional(),
                amount: zod_1.z.number().positive("Amount must be positive"),
                currency: zod_1.z.string().default("INR"),
                status: zod_1.z.string(),
                order_id: zod_1.z.string().nullable().optional(),
                invoice_id: zod_1.z.string().nullable().optional(),
                international: zod_1.z.boolean().optional(),
                method: zod_1.z.string().optional(),
                amount_refunded: zod_1.z.number().optional(),
                refund_status: zod_1.z.string().nullable().optional(),
                captured: zod_1.z.boolean().optional(),
                description: zod_1.z.string().nullable().optional(),
                email: zod_1.z.string().nullable().optional(),
                contact: zod_1.z.string().nullable().optional(),
                notes: zod_1.z.record(zod_1.z.string(), zod_1.z.unknown()).optional(),
                fee: zod_1.z.number().optional(),
                tax: zod_1.z.number().optional(),
                error_code: zod_1.z.string().nullable().optional(),
                error_description: zod_1.z.string().nullable().optional(),
                created_at: zod_1.z.number().optional(),
            }),
        })
            .optional(),
        order: zod_1.z
            .object({
            entity: zod_1.z.object({
                id: zod_1.z.string().min(1, "Order ID is required"),
                entity: zod_1.z.string().optional(),
                amount: zod_1.z.number().optional(),
                amount_paid: zod_1.z.number().optional(),
                amount_due: zod_1.z.number().optional(),
                currency: zod_1.z.string().optional(),
                receipt: zod_1.z.string().nullable().optional(),
                offer_id: zod_1.z.string().nullable().optional(),
                status: zod_1.z.string().optional(),
                attempts: zod_1.z.number().optional(),
                notes: zod_1.z.record(zod_1.z.string(), zod_1.z.unknown()).optional(),
                created_at: zod_1.z.number().optional(),
            }),
        })
            .optional(),
    }),
    created_at: zod_1.z.number().optional(),
});
//# sourceMappingURL=schemas.js.map