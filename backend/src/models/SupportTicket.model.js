const mongoose = require("mongoose");

const supportTicketSchema = new mongoose.Schema(
  {
    ticketRef: {
      type: String,
      required: true,
      unique: true,
      immutable: true,
      trim: true,
      index: true,
    },
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: false,
      index: true,
    },
    category: {
      type: String,
      required: [true, "Category is required"],
      trim: true,
      lowercase: true,
    },
    message: {
      type: String,
      required: [true, "Message is required"],
      trim: true,
      maxlength: [5000, "Message too long"],
    },
    preferredContact: {
      name: {
        type: String,
        required: [true, "Contact name is required"],
        trim: true,
      },
      method: {
        type: String,
        enum: ["email", "phone"],
        required: true,
      },
      email: {
        type: String,
        trim: true,
      },
      phone: {
        type: String,
        trim: true,
      },
    },
    status: {
      type: String,
      enum: ["OPEN", "IN_PROGRESS", "RESOLVED", "CLOSED"],
      default: "OPEN",
      index: true,
    },
    consent: {
      policySlug: {
        type: String,
        required: true,
        trim: true,
      },
      consentVersion: {
        type: String,
        required: true,
        trim: true,
      },
      acceptedAt: {
        type: Date,
        required: true,
      },
    },
    trace: {
      requestId: {
        type: String,
        required: true,
        trim: true,
      },
      submittedAt: {
        type: Date,
        required: true,
      },
    },
  },
  {
    timestamps: true,
  },
);

supportTicketSchema.index({ userId: 1, createdAt: -1 });
supportTicketSchema.index({ status: 1, createdAt: -1 });

module.exports = mongoose.model("SupportTicket", supportTicketSchema);
