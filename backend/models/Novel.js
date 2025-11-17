import mongoose from "mongoose";

const NovelSchema = new mongoose.Schema({
  id: String,
  title: String,
  authors: [String],
  description: String,
  thumbnail: String,
  summary: String,           // AI summary
  recommendations: [String], // AI recommended books
}, { timestamps: true });

export default mongoose.model("Novel", NovelSchema);
