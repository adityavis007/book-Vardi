/**
 * Verifies that categories, products, and schools are present and correctly formatted in Firestore.
 */

const API_KEY = "AIzaSyC_-8ll6ZvHhHvtr8YcKFSJZwp6lKB9Xf0";
const PROJECT_ID = "book-vardi";
const BASE_URL = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

async function verify() {
  console.log("🔍 Verifying Firestore collections...");

  // 1. Categories
  const catRes = await fetch(`${BASE_URL}/categories?key=${API_KEY}`);
  const catData = await catRes.json();
  const catDocs = catData.documents || [];
  console.log(`📁 Categories count: ${catDocs.length}`);
  catDocs.forEach(d => {
    const id = d.name.split("/").pop();
    const name = d.fields?.name?.stringValue;
    console.log(`  - [${id}] ${name}`);
  });

  // 2. Schools
  const schRes = await fetch(`${BASE_URL}/schools?key=${API_KEY}`);
  const schData = await schRes.json();
  const schDocs = schData.documents || [];
  console.log(`\n🏫 Schools count: ${schDocs.length}`);
  schDocs.forEach(d => {
    const id = d.name.split("/").pop();
    const name = d.fields?.name?.stringValue;
    console.log(`  - [${id}] ${name}`);
  });

  // 3. Products
  const prodRes = await fetch(`${BASE_URL}/products?key=${API_KEY}`);
  const prodData = await prodRes.json();
  const prodDocs = prodData.documents || [];
  console.log(`\n📦 Products count: ${prodDocs.length}`);
  prodDocs.forEach(d => {
    const id = d.name.split("/").pop();
    const name = d.fields?.name?.stringValue;
    const cat = d.fields?.categoryId?.stringValue;
    const price = d.fields?.discountPrice?.doubleValue || d.fields?.basePrice?.doubleValue;
    const inStock = d.fields?.inStock?.booleanValue;
    const isActive = d.fields?.isActive?.booleanValue;
    console.log(`  - [${id}] ${name} | Category: ${cat} | ₹${price} | inStock: ${inStock} | isActive: ${isActive}`);
  });
}

verify();
