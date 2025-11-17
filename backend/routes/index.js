import express from "express";
import Novel from "../models/Novel.js";

const router = express.Router();

// POST /api/novels  → Save a new novel
router.post("/novels", async (req, res) => {
  try {
    const novel = await Novel.create(req.body);
    res.status(201).json(novel);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// GET /api/novels → Get all novels
router.get("/novels", async (_, res) => {
  try {
    const novels = await Novel.find({});
    res.json(novels);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/novels/:id → Get one book
router.get("/novels/:id", async (req, res) => {
  try {
    const novel = await Novel.findById(req.params.id);
    if (!novel) return res.status(404).json({ error: "Not found" });
    res.json(novel);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// DELETE /api/novels/:id → Delete
router.delete("/novels/:id", async (req, res) => {
  try {
    await Novel.findByIdAndDelete(req.params.id);
    res.json({ deleted: true });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

export default router;
