const express = require('express');
const app = express();

// Health check should be dependency‑free
app.get('/healthz', (req, res) => {
  res.status(200).send('ok');cat 
});

// … your existing middleware and routes …

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server listening on port ${PORT}`);
});


// or: const express = require("express");



/**
 * Kubernetes readiness / liveness
 * Must be fast and dependency-free
 */



const { MongoClient } = require("mongodb");


app.use(express.json());

const mongoUri = process.env.MONGO_URI;
const mongoDbName = process.env.MONGO_DB || "wizdb";

let client;
let db;

async function connectMongo() {
  if (!mongoUri) throw new Error("MONGO_URI is not set");
  client = new MongoClient(mongoUri, { serverSelectionTimeoutMS: 5000 });
  await client.connect();
  db = client.db(mongoDbName);
}

/*app.get("/healthz", async (req, res) => {
  try {
    if (!db) await connectMongo();
    await db.command({ ping: 1 });
    res.status(200).json({ ok: true });
  } catch (e) {
    res.status(500).json({ ok: false, error: e.message });
  }
});
*/
app.get("/", (req, res) => {
  res.type("text").send("Wiz exercise API running. Use /healthz, POST /item, GET /items\n");
});

/*app.post("/item", async (req, res) => {
  try {
    if (!db) await connectMongo();
    const doc = { ...req.body, createdAt: new Date() };
    const r = await db.collection("items").insertOne(doc);
    res.status(201).json({ insertedId: r.insertedId });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});
*/
app.get("/items", async (req, res) => {
  try {
    if (!db) await connectMongo();
    const items = await db.collection("items").find({}).sort({ createdAt: -1 }).limit(50).toArray();
    res.json(items);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

const port = process.env.PORT || 3000;
app.listen(port, () => console.log(`Listening on ${port}`));
