import { z } from "zod";

/**
 * Valid delivery modes supported by Book Vardi.
 */
export const DeliveryModeEnum = z.enum(["standard", "schoolDelivery", "express"]);
export type DeliveryMode = z.infer<typeof DeliveryModeEnum>;

/**
 * Payment methods accepted by Book Vardi checkout.
 */
export const PaymentMethodEnum = z.enum(["COD", "UPI", "CARD", "NET_BANKING", "ONLINE"]);
export type PaymentMethod = z.infer<typeof PaymentMethodEnum>;

/**
 * Payment resolution statuses.
 */
export const PaymentStatusEnum = z.enum(["PENDING", "PAID", "FAILED", "CONFIRMED"]);
export type PaymentStatus = z.infer<typeof PaymentStatusEnum>;

/**
 * Order fulfillment statuses throughout logistics lifecycle.
 */
export const OrderStatusEnum = z.enum([
  "PENDING",
  "CONFIRMED",
  "PROCESSING",
  "PACKED",
  "SHIPPED",
  "OUT_FOR_DELIVERY",
  "DELIVERED",
  "CANCELLED",
]);
export type OrderStatus = z.infer<typeof OrderStatusEnum>;

/**
 * Schema for customer shipping addresses.
 */
export const AddressSchema = z.object({
  addressId: z.string().optional(),
  fullName: z.string().min(2, "Full name must be at least 2 characters"),
  phone: z
    .string()
    .min(10, "Phone number must be at least 10 digits")
    .regex(/^[0-9+ -]{10,15}$/, "Invalid Indian mobile number format"),
  addressLine1: z.string().min(3, "Address line 1 must be at least 3 characters"),
  addressLine2: z.string().nullable().optional(),
  city: z.string().min(2, "City must be at least 2 characters"),
  state: z.string().min(2, "State must be at least 2 characters"),
  pincode: z
    .string()
    .regex(/^[1-9][0-9]{5}$/, "Must be a valid 6-digit Indian postal code"),
  isDefault: z.boolean().default(false),
  landmark: z.string().nullable().optional(),
  addressType: z.enum(["Home", "School", "Work"]).default("Home"),
});
export type AddressInput = z.infer<typeof AddressSchema>;

/**
 * Schema for line items inside an order.
 */
export const OrderItemSchema = z.object({
  productId: z.string().min(1, "Product ID is required"),
  variantId: z.string().nullable().optional(),
  productName: z.string().min(1, "Product name is required"),
  schoolName: z.string().nullable().optional(),
  variantLabel: z.string().nullable().optional(),
  imageUrl: z.string().url().nullable().optional().or(z.literal("")),
  unitPrice: z.number().positive("Unit price must be positive"),
  quantity: z.number().int().positive("Quantity must be at least 1"),
  maxStock: z.number().int().nonnegative().optional(),
});
export type OrderItemInput = z.infer<typeof OrderItemSchema>;

/**
 * Schema for price breakdown and financial audits.
 */
export const PriceBreakupSchema = z.object({
  subtotal: z.number().nonnegative("Subtotal cannot be negative"),
  schoolBulkDiscount: z.number().nonnegative().default(0),
  couponDiscount: z.number().nonnegative().default(0),
  deliveryCharge: z.number().nonnegative("Delivery charge cannot be negative"),
  grandTotal: z.number().nonnegative("Grand total cannot be negative"),
});
export type PriceBreakupInput = z.infer<typeof PriceBreakupSchema>;

/**
 * Schema for creating a new order (used in API / Cloud Function invocation).
 */
export const OrderCreateSchema = z.object({
  orderId: z.string().optional(),
  userId: z.string().min(1, "User ID is required"),
  items: z.array(OrderItemSchema).min(1, "Order must contain at least one item"),
  shippingAddress: AddressSchema,
  pricing: PriceBreakupSchema,
  deliveryMode: DeliveryModeEnum.default("standard"),
  paymentMethod: PaymentMethodEnum,
  paymentId: z.string().nullable().optional(),
  razorpayOrderId: z.string().nullable().optional(),
  signature: z.string().nullable().optional(),
  paymentStatus: PaymentStatusEnum.default("PENDING"),
  orderStatus: OrderStatusEnum.default("CONFIRMED"),
  createdAt: z.string().datetime().optional().or(z.date().optional()),
  estimatedDeliveryDate: z.string().datetime().optional().or(z.date().optional()),
});
export type OrderCreateInput = z.infer<typeof OrderCreateSchema>;

/**
 * Schema for individual item inventory deduction.
 */
export const InventoryItemDeductSchema = z.object({
  productId: z.string().min(1, "Product ID is required"),
  variantId: z.string().nullable().optional(),
  quantity: z.number().int().positive("Deduction quantity must be at least 1"),
});
export type InventoryItemDeductInput = z.infer<typeof InventoryItemDeductSchema>;

/**
 * Schema for atomic inventory decrement requests.
 */
export const InventoryDeductSchema = z.object({
  orderId: z.string().optional(),
  items: z
    .array(InventoryItemDeductSchema)
    .min(1, "At least one item required for inventory deduction"),
});
export type InventoryDeductInput = z.infer<typeof InventoryDeductSchema>;

/**
 * Schema for incoming Razorpay webhook payloads.
 */
export const PaymentWebhookSchema = z.object({
  entity: z.string().optional(),
  account_id: z.string().optional(),
  event: z.string().min(1, "Event name is required"),
  contains: z.array(z.string()).optional(),
  payload: z.object({
    payment: z
      .object({
        entity: z.object({
          id: z.string().min(1, "Payment ID is required"),
          entity: z.string().optional(),
          amount: z.number().positive("Amount must be positive"),
          currency: z.string().default("INR"),
          status: z.string(),
          order_id: z.string().nullable().optional(),
          invoice_id: z.string().nullable().optional(),
          international: z.boolean().optional(),
          method: z.string().optional(),
          amount_refunded: z.number().optional(),
          refund_status: z.string().nullable().optional(),
          captured: z.boolean().optional(),
          description: z.string().nullable().optional(),
          email: z.string().nullable().optional(),
          contact: z.string().nullable().optional(),
          notes: z.record(z.string(), z.unknown()).optional(),
          fee: z.number().optional(),
          tax: z.number().optional(),
          error_code: z.string().nullable().optional(),
          error_description: z.string().nullable().optional(),
          created_at: z.number().optional(),
        }),
      })
      .optional(),
    order: z
      .object({
        entity: z.object({
          id: z.string().min(1, "Order ID is required"),
          entity: z.string().optional(),
          amount: z.number().optional(),
          amount_paid: z.number().optional(),
          amount_due: z.number().optional(),
          currency: z.string().optional(),
          receipt: z.string().nullable().optional(),
          offer_id: z.string().nullable().optional(),
          status: z.string().optional(),
          attempts: z.number().optional(),
          notes: z.record(z.string(), z.unknown()).optional(),
          created_at: z.number().optional(),
        }),
      })
      .optional(),
  }),
  created_at: z.number().optional(),
});
export type PaymentWebhookInput = z.infer<typeof PaymentWebhookSchema>;
