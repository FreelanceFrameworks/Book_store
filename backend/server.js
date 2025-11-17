// ----------------------------
//  PRODUCTION FLUTTER API
// ----------------------------

import express from "express";
import mongoose from "mongoose";
import cors from "cors";
import compression from "compression";
import dotenv from "dotenv";
import router from "./routes/index.js";   // <-- update path to your Routes

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// ----------------------------
// Middleware
// ----------------------------
app.use(cors());
app.use(express.json({ limit: "10mb" }));
app.use(express.urlencoded({ extended: true }));
app.use(compression());

// ----------------------------
// API routes
// ----------------------------
app.use("/api", router); 
// Example: POST /api/novels

app.get("/", (req, res) => {
  res.send("Novel API running");
});

// ----------------------------
// MongoDB Connection
// ----------------------------
const MONGO_URI =
  process.env.MONGODB_URI || "mongodb://localhost/goobooks";

mongoose
  .connect(MONGO_URI)
  .then(() => console.log("📦 MongoDB connected"))
  .catch((err) => console.error("MongoDB Error:", err));

// ----------------------------
// Start Server
// ----------------------------
app.listen(PORT, () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
});
