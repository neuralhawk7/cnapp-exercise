const express = require("express");
const { MongoClient } = require("mongodb");

const app = express();

// Health check must be dependency-free for Kubernetes probes.
app.get("/healthz", (req, res) => {
  res.status(200).send("ok");
});

// AWS Security Agent domain verification
app.get("/.well-known/aws-securityagent-domain-verification.json", (req, res) => {
  res.json({ verificationToken: "ZhKUDSbozI6-DQYgh52V4Q" });
});

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

app.get("/", (req, res) => {
  res.type("text").send("Wiz exercise API running. Use /healthz, GET /items\n");
});

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
