const admin = require("firebase-admin");

admin.initializeApp({
  projectId: "book-vardi",
});

const db = admin.firestore();

async function test() {
  try {
    const doc = await db.collection("test_ping").doc("ping").get();
    console.log("SUCCESS! Doc exists:", doc.exists);
  } catch (err) {
    console.error("FAILED to connect:", err.message);
  }
}

test();
