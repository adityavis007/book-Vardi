const { test, describe } = require("node:test");
const assert = require("node:assert");
const {
  isEligibleForResizing,
  getResizedTargetSpecs,
  RESIZE_PRESETS,
} = require("../lib/index.js");

describe("TASK-052: Cloud Storage WebP Image Resizing Pipeline", () => {
  test("Eligibility Validation: accepts valid product and category image uploads", () => {
    assert.strictEqual(
      isEligibleForResizing("products/prod_123/shirt_navy.jpg", "image/jpeg"),
      true
    );
    assert.strictEqual(
      isEligibleForResizing("products/prod_456/skirt.png", "image/png"),
      true
    );
    assert.strictEqual(
      isEligibleForResizing("categories/books/banner.webp", "image/webp"),
      true
    );
  });

  test("Recursion Prevention: rejects already processed resized assets", () => {
    assert.strictEqual(
      isEligibleForResizing("products/prod_123/resized/shirt_800x800.webp", "image/webp"),
      false
    );
    assert.strictEqual(
      isEligibleForResizing("products/prod_123/resized/shirt_200x200.webp", "image/webp"),
      false
    );
    assert.strictEqual(
      isEligibleForResizing("products/prod_123/image_800x800.png", "image/png"),
      false
    );
  });

  test("Filters non-image and non-catalog files", () => {
    // Non-image file
    assert.strictEqual(
      isEligibleForResizing("products/prod_123/specifications.pdf", "application/pdf"),
      false
    );
    // Non-catalog folder (e.g. system logs or receipts)
    assert.strictEqual(
      isEligibleForResizing("invoices/inv_9988.jpg", "image/jpeg"),
      false
    );
    // Null/undefined checks
    assert.strictEqual(isEligibleForResizing(null), false);
    assert.strictEqual(isEligibleForResizing(undefined), false);
  });

  test("Target Specifications: generates 800x800 PDP and 200x200 Thumbnail WebP destinations", () => {
    const specs = getResizedTargetSpecs("products/uniform_shirt/main.jpg");
    assert.strictEqual(specs.length, 2);

    // Preset 1: PDP
    assert.strictEqual(specs[0].width, 800);
    assert.strictEqual(specs[0].height, 800);
    assert.strictEqual(specs[0].format, "webp");
    assert.strictEqual(specs[0].contentType, "image/webp");
    assert.strictEqual(
      specs[0].destinationPath,
      "products/uniform_shirt/resized/main_800x800.webp"
    );

    // Preset 2: Thumbnail
    assert.strictEqual(specs[1].width, 200);
    assert.strictEqual(specs[1].height, 200);
    assert.strictEqual(specs[1].format, "webp");
    assert.strictEqual(specs[1].contentType, "image/webp");
    assert.strictEqual(
      specs[1].destinationPath,
      "products/uniform_shirt/resized/main_200x200.webp"
    );
  });
});
