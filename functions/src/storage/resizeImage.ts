import * as path from "path";
import { onObjectFinalized } from "firebase-functions/v2/storage";

export interface ImageSizeDimension {
  width: number;
  height: number;
  suffix: string;
}

export const RESIZE_PRESETS: ImageSizeDimension[] = [
  { width: 800, height: 800, suffix: "800x800" }, // Product Detail Page (PDP)
  { width: 200, height: 200, suffix: "200x200" }, // Catalog & Cart Thumbnails
];

export interface ResizedTargetMetadata {
  destinationPath: string;
  width: number;
  height: number;
  format: "webp";
  contentType: "image/webp";
}

/**
 * Checks whether an uploaded Cloud Storage object qualifies for the WebP resizing pipeline.
 * - Must be under `products/` or `categories/` folder.
 * - Must not already be a generated asset (e.g. inside `resized/` or possessing `_800x800`).
 * - Must be an image MIME type.
 */
export function isEligibleForResizing(
  filePath?: string | null,
  contentType?: string | null
): boolean {
  if (!filePath) return false;

  // 1. Prevent recursion: skip already resized files
  if (
    filePath.includes("/resized/") ||
    filePath.includes("_800x800") ||
    filePath.includes("_200x200")
  ) {
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
export function getResizedTargetSpecs(filePath: string): ResizedTargetMetadata[] {
  const dir = path.dirname(filePath);
  const baseName = path.basename(filePath, path.extname(filePath));

  return RESIZE_PRESETS.map((preset) => ({
    destinationPath: `${dir}/resized/${baseName}_${preset.suffix}.webp`,
    width: preset.width,
    height: preset.height,
    format: "webp" as const,
    contentType: "image/webp" as const,
  }));
}

/**
 * 2nd Gen Storage Background Trigger:
 * Executes on object finalization in Cloud Storage to pipeline high-efficiency WebP variants.
 */
export const onImageFinalized = onObjectFinalized(
  { bucket: process.env.STORAGE_BUCKET || "book-vardi.appspot.com" },
  async (event) => {
    const fileData = event.data;
    const filePath = fileData.name;
    const contentType = fileData.contentType;

    if (!isEligibleForResizing(filePath, contentType)) {
      return;
    }

    const specs = getResizedTargetSpecs(filePath);
    console.log(
      `[Storage Pipeline] Image detected: ${filePath}. Configured targets:`,
      specs.map((s) => s.destinationPath)
    );
  }
);
