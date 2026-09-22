/**
 * Standalone Firestore Data Seeder for Book Vardi
 * Seeds categories, products, and schools matching the website and PRD schema.
 */

const API_KEY = "AIzaSyC_-8ll6ZvHhHvtr8YcKFSJZwp6lKB9Xf0";
const PROJECT_ID = "book-vardi";
const BASE_URL = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

function toFirestoreValue(val) {
  if (val === null || val === undefined) {
    return { nullValue: null };
  }
  if (typeof val === "boolean") {
    return { booleanValue: val };
  }
  if (typeof val === "number") {
    if (Number.isInteger(val)) {
      return { integerValue: val.toString() };
    }
    return { doubleValue: val };
  }
  if (typeof val === "string") {
    return { stringValue: val };
  }
  if (Array.isArray(val)) {
    return { arrayValue: { values: val.map(toFirestoreValue) } };
  }
  if (typeof val === "object") {
    const fields = {};
    for (const [k, v] of Object.entries(val)) {
      if (v !== undefined) {
        fields[k] = toFirestoreValue(v);
      }
    }
    return { mapValue: { fields } };
  }
  return { stringValue: String(val) };
}

function toFirestoreFields(obj) {
  const fields = {};
  for (const [k, v] of Object.entries(obj)) {
    if (v !== undefined) {
      fields[k] = toFirestoreValue(v);
    }
  }
  return fields;
}

async function upsertDocument(collection, docId, data) {
  const url = `${BASE_URL}/${collection}/${docId}?key=${API_KEY}`;
  const payload = {
    fields: toFirestoreFields(data)
  };

  const res = await fetch(url, {
    method: "PATCH",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload)
  });

  if (!res.ok) {
    const errText = await res.text();
    throw new Error(`Failed to write ${collection}/${docId}: ${res.status} ${errText}`);
  }

  return await res.json();
}

// 1. Categories
const categories = [
  {
    categoryId: "books",
    name: "Books",
    iconUrl: "https://images.unsplash.com/photo-1497633762265-9d179a990aa6?w=300&auto=format&fit=crop&q=80",
    displayOrder: 1
  },
  {
    categoryId: "uniforms",
    name: "Uniforms",
    iconUrl: "https://images.unsplash.com/photo-1593032465175-481ac7f401a0?w=300&auto=format&fit=crop&q=80",
    displayOrder: 2
  },
  {
    categoryId: "stationery",
    name: "Stationery",
    iconUrl: "https://images.unsplash.com/photo-1583485088034-697b5bc54ccd?w=300&auto=format&fit=crop&q=80",
    displayOrder: 3
  },
  {
    categoryId: "shoes",
    name: "Shoes",
    iconUrl: "https://images.unsplash.com/photo-1560769629-975ec94e6a86?w=300&auto=format&fit=crop&q=80",
    displayOrder: 4
  },
  {
    categoryId: "bags",
    name: "Bags",
    iconUrl: "https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=300&auto=format&fit=crop&q=80",
    displayOrder: 5
  }
];

// 2. Schools
const schools = [
  {
    schoolId: "SCH-001",
    name: "Delhi Public School",
    city: "New Delhi",
    logoUrl: "https://images.unsplash.com/photo-1580582932707-520aed937b7b?w=200&auto=format&fit=crop&q=80",
    grades: ["Class 1", "Class 2", "Class 3", "Class 4", "Class 5", "Class 6", "Class 7", "Class 8", "Class 9", "Class 10"]
  },
  {
    schoolId: "SCH-002",
    name: "The Mother’s International School",
    city: "New Delhi",
    logoUrl: "https://images.unsplash.com/photo-1546410531-bb4caa6b424d?w=200&auto=format&fit=crop&q=80",
    grades: ["Class 1", "Class 2", "Class 3", "Class 4", "Class 5", "Class 6", "Class 7", "Class 8", "Class 9", "Class 10"]
  },
  {
    schoolId: "SCH-003",
    name: "St. Xavier Senior Secondary School",
    city: "Gurugram",
    logoUrl: "https://images.unsplash.com/photo-1509062522246-3755977927d7?w=200&auto=format&fit=crop&q=80",
    grades: ["Class 1", "Class 2", "Class 3", "Class 4", "Class 5", "Class 6", "Class 7", "Class 8", "Class 9", "Class 10"]
  }
];

// 3. Products
const products = [
  {
    productId: "prod_uniform_boys_summer",
    name: "Boys Summer Uniform Set (Navy/White)",
    title: "Boys Summer Uniform Set (Navy/White)",
    description: "Premium breathable cotton blend school uniform set featuring white short-sleeve shirt and navy blue tailored shorts. Tailored for comfort and durability during Indian summer school hours.",
    categoryId: "uniforms",
    schoolId: "ALL_SCHOOLS",
    schoolName: "All Schools",
    targetGrade: "Class 4",
    basePrice: 499.0,
    discountPrice: 399.0,
    images: [
      "https://images.unsplash.com/photo-1593032465175-481ac7f401a0?w=800&auto=format&fit=crop&q=80",
      "https://images.unsplash.com/photo-1603400521630-9f2de124b32b?w=800&auto=format&fit=crop&q=80"
    ],
    hasVariants: true,
    variants: [
      { variantId: "var_u_b_28", sku: "UNIF-B-S28", label: "Size 28", price: 399.0, stock: 25 },
      { variantId: "var_u_b_30", sku: "UNIF-B-S30", label: "Size 30", price: 399.0, stock: 30 },
      { variantId: "var_u_b_32", sku: "UNIF-B-S32", label: "Size 32", price: 419.0, stock: 20 }
    ],
    rating: 4.8,
    reviewCount: 124,
    inStock: true,
    isActive: true,
    isFeatured: true,
    totalStock: 75,
    specifications: {
      "Fabric": "100% Breathable Combed Cotton",
      "Care": "Machine wash warm, tumble dry low",
      "Sleeve": "Short Sleeve"
    }
  },
  {
    productId: "prod_uniform_girls_tunic",
    name: "Girls Tunic Dress (Green Checkered)",
    title: "Girls Tunic Dress (Green Checkered)",
    description: "Durable poly-cotton school tunic with pleated skirt and side button closure. Wrinkle-resistant finish perfect for daily school wear.",
    categoryId: "uniforms",
    schoolId: "ALL_SCHOOLS",
    schoolName: "All Schools",
    targetGrade: "Class 4",
    basePrice: 550.0,
    discountPrice: 450.0,
    images: [
      "https://images.unsplash.com/photo-1593032465175-481ac7f401a0?w=800&auto=format&fit=crop&q=80",
      "https://plus.unsplash.com/premium_photo-1673356302067-aac3b545a362?w=800&auto=format&fit=crop&q=80"
    ],
    hasVariants: true,
    variants: [
      { variantId: "var_u_g_28", sku: "TUNIC-G-S28", label: "Size 28", price: 450.0, stock: 18 },
      { variantId: "var_u_g_30", sku: "TUNIC-G-S30", label: "Size 30", price: 450.0, stock: 22 },
      { variantId: "var_u_g_32", sku: "TUNIC-G-S32", label: "Size 32", price: 475.0, stock: 15 }
    ],
    rating: 4.7,
    reviewCount: 98,
    inStock: true,
    isActive: true,
    isFeatured: true,
    totalStock: 55,
    specifications: {
      "Fabric": "Poly-Cotton Blend",
      "Fit": "Regular School Fit",
      "Closure": "Side Zip & Shoulder Buttons"
    }
  },
  {
    productId: "prod_shoes_leather_black",
    name: "Black Leather School Shoes (Lace-up)",
    title: "Black Leather School Shoes (Lace-up)",
    description: "High-durability genuine action leather formal school shoes with anti-skid TPR soles and cushioned insoles for all-day comfort.",
    categoryId: "shoes",
    schoolId: "ALL_SCHOOLS",
    schoolName: "All Schools",
    targetGrade: "Class 4",
    basePrice: 899.0,
    discountPrice: 750.0,
    images: [
      "https://images.unsplash.com/photo-1560769629-975ec94e6a86?w=800&auto=format&fit=crop&q=80",
      "https://images.unsplash.com/photo-1549298916-b41d501d3772?w=800&auto=format&fit=crop&q=80"
    ],
    hasVariants: true,
    variants: [
      { variantId: "var_s_l_5", sku: "SHOE-BLK-S5", label: "Size 5", price: 750.0, stock: 15 },
      { variantId: "var_s_l_6", sku: "SHOE-BLK-S6", label: "Size 6", price: 750.0, stock: 20 },
      { variantId: "var_s_l_7", sku: "SHOE-BLK-S7", label: "Size 7", price: 750.0, stock: 12 }
    ],
    rating: 4.9,
    reviewCount: 145,
    inStock: true,
    isActive: true,
    isFeatured: true,
    totalStock: 47,
    specifications: {
      "Material": "Action Leather",
      "Sole": "Anti-Skid TPR",
      "Closure": "Lace-Up"
    }
  },
  {
    productId: "prod_shoes_canvas_white",
    name: "White Canvas PT Shoes 244",
    title: "White Canvas PT Shoes 244",
    description: "Classic lightweight white canvas PT and sports shoes with vulcanized rubber sole. Breathable cotton canvas upper easy to clean and wash.",
    categoryId: "shoes",
    schoolId: "ALL_SCHOOLS",
    schoolName: "All Schools",
    targetGrade: "Class 4",
    basePrice: 499.0,
    discountPrice: 399.0,
    images: [
      "https://images.unsplash.com/photo-1525966222134-fcfa99b8ae77?w=800&auto=format&fit=crop&q=80"
    ],
    hasVariants: true,
    variants: [
      { variantId: "var_s_c_5", sku: "PT-WHT-S5", label: "Size 5", price: 399.0, stock: 25 },
      { variantId: "var_s_c_6", sku: "PT-WHT-S6", label: "Size 6", price: 399.0, stock: 30 },
      { variantId: "var_s_c_7", sku: "PT-WHT-S7", label: "Size 7", price: 399.0, stock: 18 }
    ],
    rating: 4.6,
    reviewCount: 89,
    inStock: true,
    isActive: true,
    isFeatured: false,
    totalStock: 73,
    specifications: {
      "Material": "Cotton Canvas",
      "Sole": "Vulcanized Rubber",
      "Closure": "Lace-Up"
    }
  },
  {
    productId: "prod_books_ncert_class4",
    name: "NCERT Complete Class 4 Book Set",
    title: "NCERT Complete Class 4 Book Set",
    description: "Complete official NCERT textbook bundle for Class 4 CBSE curriculum. Includes Marigold (English), Rimjhim (Hindi), Math-Magic (Mathematics), and Looking Around (EVS). Latest 2026 edition.",
    categoryId: "books",
    schoolId: "ALL_SCHOOLS",
    schoolName: "All Schools",
    targetGrade: "Class 4",
    basePrice: 1450.0,
    discountPrice: 1299.0,
    images: [
      "https://images.unsplash.com/photo-1497633762265-9d179a990aa6?w=800&auto=format&fit=crop&q=80",
      "https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=800&auto=format&fit=crop&q=80"
    ],
    hasVariants: false,
    variants: [],
    rating: 4.9,
    reviewCount: 312,
    inStock: true,
    isActive: true,
    isFeatured: true,
    totalStock: 50,
    specifications: {
      "Board": "CBSE",
      "Edition": "Latest 2026 Revised",
      "Books Included": "English, Hindi, Maths, EVS (4 Books)"
    }
  },
  {
    productId: "prod_stationery_starter_kit",
    name: "Standard School Stationery Starter Kit",
    title: "Standard School Stationery Starter Kit",
    description: "Essential academic stationery pack containing 6 four-line notebooks, 2 square math notebooks, pencil box with 10 graphite pencils, non-dust erasers, sharpener, 30cm ruler, and wax crayons set.",
    categoryId: "stationery",
    schoolId: "ALL_SCHOOLS",
    schoolName: "All Schools",
    targetGrade: "Class 4",
    basePrice: 320.0,
    discountPrice: 249.0,
    images: [
      "https://images.unsplash.com/photo-1583485088034-697b5bc54ccd?w=800&auto=format&fit=crop&q=80",
      "https://images.unsplash.com/photo-1513542789411-b6a5d4f31634?w=800&auto=format&fit=crop&q=80"
    ],
    hasVariants: false,
    variants: [],
    rating: 4.8,
    reviewCount: 210,
    inStock: true,
    isActive: true,
    isFeatured: true,
    totalStock: 100,
    specifications: {
      "Items": "8 Notebooks, 10 Pencils, Erasers, Ruler, Crayons",
      "Paper Quality": "70 GSM Bright White Paper"
    }
  },
  {
    productId: "prod_bags_ergonomic_backpack",
    name: "Ergonomic Orthopedic School Backpack (32L)",
    title: "Ergonomic Orthopedic School Backpack (32L)",
    description: "Padded S-curve shoulder straps, multi-compartment book organizer, water-resistant 900D polyester fabric, and reflective night-safety strips.",
    categoryId: "bags",
    schoolId: "ALL_SCHOOLS",
    schoolName: "All Schools",
    targetGrade: "Class 4",
    basePrice: 1199.0,
    discountPrice: 899.0,
    images: [
      "https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=800&auto=format&fit=crop&q=80"
    ],
    hasVariants: false,
    variants: [],
    rating: 4.9,
    reviewCount: 87,
    inStock: true,
    isActive: true,
    isFeatured: true,
    totalStock: 40,
    specifications: {
      "Capacity": "32 Litres",
      "Material": "Water-Resistant 900D Polyester",
      "Warranty": "1 Year Stitching Warranty"
    }
  },
  {
    productId: "prod_uniform_dps_sweater",
    name: "DPS Winter Uniform V-Neck Sweater",
    title: "DPS Winter Uniform V-Neck Sweater",
    description: "Official DPS navy blue knitted winter sweater with golden contrast stripe at neck and cuffs, embroidered school crest monogram.",
    categoryId: "uniforms",
    schoolId: "SCH-001",
    schoolName: "Delhi Public School",
    targetGrade: "Class 4",
    basePrice: 1099.0,
    discountPrice: 899.0,
    images: [
      "https://plus.unsplash.com/premium_photo-1673356302067-aac3b545a362?w=800&auto=format&fit=crop&q=80"
    ],
    hasVariants: true,
    variants: [
      { variantId: "var_sw_30", sku: "DPS-SW-S30", label: "Size 30", price: 899.0, stock: 15 },
      { variantId: "var_sw_32", sku: "DPS-SW-S32", label: "Size 32", price: 899.0, stock: 20 },
      { variantId: "var_sw_34", sku: "DPS-SW-S34", label: "Size 34", price: 949.0, stock: 10 }
    ],
    rating: 4.9,
    reviewCount: 162,
    inStock: true,
    isActive: true,
    isFeatured: false,
    totalStock: 45,
    specifications: {
      "Material": "Cashmilon Wool Blend",
      "Pattern": "Cable Knit V-Neck"
    }
  }
];

async function seedAll() {
  console.log("=========================================");
  console.log("🚀 Starting Book Vardi Firestore Seeder...");
  console.log("=========================================");

  // 1. Seed Categories
  console.log("\n📁 Seeding Categories...");
  for (const cat of categories) {
    try {
      await upsertDocument("categories", cat.categoryId, cat);
      console.log(`  ✅ Category: ${cat.name} (${cat.categoryId})`);
    } catch (err) {
      console.error(`  ❌ Failed: ${cat.name}`, err.message);
    }
  }

  // 2. Seed Schools
  console.log("\n🏫 Seeding Schools...");
  for (const school of schools) {
    try {
      await upsertDocument("schools", school.schoolId, school);
      console.log(`  ✅ School: ${school.name} (${school.schoolId})`);
    } catch (err) {
      console.error(`  ❌ Failed: ${school.name}`, err.message);
    }
  }

  // 3. Seed Products
  console.log("\n📦 Seeding Products...");
  for (const prod of products) {
    try {
      await upsertDocument("products", prod.productId, prod);
      console.log(`  ✅ Product: ${prod.name} (₹${prod.discountPrice || prod.basePrice})`);
    } catch (err) {
      console.error(`  ❌ Failed: ${prod.name}`, err.message);
    }
  }

  console.log("\n=========================================");
  console.log("🎉 Firestore Seeding Finished Successfully!");
  console.log("=========================================");
}

seedAll();
