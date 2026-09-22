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
var __exportStar = (this && this.__exportStar) || function(m, exports) {
    for (var p in m) if (p !== "default" && !Object.prototype.hasOwnProperty.call(exports, p)) __createBinding(exports, m, p);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.healthCheck = void 0;
const admin = __importStar(require("firebase-admin"));
const v2_1 = require("firebase-functions/v2");
// Initialize Firebase Admin SDK
admin.initializeApp();
// Configure default options for 2nd gen Cloud Functions
(0, v2_1.setGlobalOptions)({
    region: "asia-south1", // Mumbai region for Indian school commerce ecosystem
    maxInstances: 10,
});
const healthCheck = () => {
    return { status: "ok", timestamp: new Date().toISOString() };
};
exports.healthCheck = healthCheck;
// Export schemas and domain types
__exportStar(require("./types/schemas"), exports);
// Export transactional inventory operations
__exportStar(require("./inventory/atomicDecrement"), exports);
// Export payment webhook handlers
__exportStar(require("./payments/webhook"), exports);
// Export order cancellation restock operations
__exportStar(require("./orders/onOrderCancelled"), exports);
// Export order push notification triggers
__exportStar(require("./orders/notifications"), exports);
// Export storage media WebP resizing pipeline
__exportStar(require("./storage/resizeImage"), exports);
//# sourceMappingURL=index.js.map