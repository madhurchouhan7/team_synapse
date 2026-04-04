// src/models/UtilityContent.model.js
// Versioned utility content for FAQ, bill guide, and legal pages.

const mongoose = require("mongoose");

const UtilityContentItemSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, trim: true },
    topic: { type: String, trim: true, default: null },
    question: { type: String, trim: true, default: null },
    answer: { type: String, trim: true, default: null },
    title: { type: String, trim: true, default: null },
    body: { type: String, trim: true, default: null },
    tags: { type: [String], default: [] },
    order: { type: Number, default: 0 },
  },
  { _id: false },
);

const UtilityContentSchema = new mongoose.Schema(
  {
    kind: {
      type: String,
      enum: ["faq", "bill_guide", "legal"],
      required: true,
      index: true,
    },
    slug: {
      type: String,
      required: true,
      trim: true,
      default: "default",
    },
    locale: {
      type: String,
      required: true,
      trim: true,
      default: "en-IN",
      index: true,
    },
    status: {
      type: String,
      enum: ["draft", "published", "archived"],
      default: "draft",
      index: true,
    },
    contentVersion: {
      type: String,
      required: true,
      trim: true,
      default: "2026.03.1",
    },
    effectiveFrom: {
      type: Date,
      default: Date.now,
    },
    publishedAt: {
      type: Date,
      default: null,
    },
    lastUpdatedAt: {
      type: Date,
      default: Date.now,
    },
    items: {
      type: [UtilityContentItemSchema],
      default: [],
    },
    metadata: {
      type: mongoose.Schema.Types.Mixed,
      default: {},
    },
  },
  {
    timestamps: true,
    minimize: false,
  },
);

UtilityContentSchema.index(
  { kind: 1, slug: 1, locale: 1, status: 1 },
  { name: "utility_content_lookup_idx" },
);

module.exports = mongoose.model("UtilityContent", UtilityContentSchema);
