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
exports.onImageFinalized = exports.RESIZE_PRESETS = void 0;
exports.isEligibleForResizing = isEligibleForResizing;
exports.getResizedTargetSpecs = getResizedTargetSpecs;
const path = __importStar(require("path"));
const storage_1 = require("firebase-functions/v2/storage");
exports.RESIZE_PRESETS = [
    { width: 800, height: 800, suffix: "800x800" }, // Product Detail Page (PDP)
    { width: 200, height: 200, suffix: "200x200" }, // Catalog & Cart Thumbnails
];
/**
 * Checks whether an uploaded Cloud Storage object qualifies for the WebP resizing pipeline.
 * - Must be under `products/` or `categories/` folder.
 * - Must not already be a generated asset (e.g. inside `resized/` or possessing `_800x800`).
 * - Must be an image MIME type.
 */
function isEligibleForResizing(filePath, contentType) {
    if (!filePath)
        return false;
    // 1. Prevent recursion: skip already resized files
    if (filePath.includes("/resized/") ||
        filePath.includes("_800x800") ||
        filePath.includes("_200x200")) {
        return false;
    }
    // 2. Only process product or category assets
    if (!filePath.startsWith("products/") && !filePath.startsWith("categories/")) {
        return false;
    }
    // 3. Validate content type or extension
    const validExtensions = [".jpg", ".jpeg", ".png", ".webp"];
    const ext = path.extname(filePath).toLowerCase();
    if (contentType && !contentType.startsWith("image/")) {
        return false;
    }
    return validExtensions.includes(ext);
}
/**
 * Generates the target destination filepaths and dimensions for WebP transformation.
 */
function getResizedTargetSpecs(filePath) {
    const dir = path.dirname(filePath);
    const baseName = path.basename(filePath, path.extname(filePath));
    return exports.RESIZE_PRESETS.map((preset) => ({
        destinationPath: `${dir}/resized/${baseName}_${preset.suffix}.webp`,
        width: preset.width,
        height: preset.height,
        format: "webp",
        contentType: "image/webp",
    }));
}
/**
 * 2nd Gen Storage Background Trigger:
 * Executes on object finalization in Cloud Storage to pipeline high-efficiency WebP variants.
 */
exports.onImageFinalized = (0, storage_1.onObjectFinalized)({ bucket: process.env.STORAGE_BUCKET || "book-vardi.appspot.com" }, async (event) => {
    const fileData = event.data;
    const filePath = fileData.name;
    const contentType = fileData.contentType;
    if (!isEligibleForResizing(filePath, contentType)) {
        return;
    }
    const specs = getResizedTargetSpecs(filePath);
    console.log(`[Storage Pipeline] Image detected: ${filePath}. Configured targets:`, specs.map((s) => s.destinationPath));
});
//# sourceMappingURL=resizeImage.js.map