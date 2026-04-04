const { z } = require("zod");

const MemoryIdentitySchema = z.object({
  tenantId: z.string().trim().min(1, "tenantId is required"),
  userId: z.string().trim().min(1, "userId is required"),
  threadId: z.string().trim().min(1, "threadId is required"),
});

const EvidenceRefSchema = z.object({
  id: z.string().trim().min(1),
  type: z.string().trim().min(1).optional(),
});

const MemoryEventSchema = z
  .object({
    tenantId: z.string().trim().min(1),
    userId: z.string().trim().min(1),
    threadId: z.string().trim().min(1),
    eventType: z.string().trim().min(1).default("agent_turn"),
    agentId: z.string().trim().min(1, "agentId is required"),
    timestamp: z.string().trim().min(1, "timestamp is required"),
    sourceType: z.string().trim().min(1, "sourceType is required"),
    evidenceRefs: z.array(EvidenceRefSchema).default([]),
    noEvidenceReason: z.string().trim().optional(),
    revisionId: z.string().trim().min(1, "revisionId is required"),
    confidenceScore: z.number().min(0).max(1),
    requestId: z.string().trim().min(1).optional(),
    runId: z.string().trim().min(1).optional(),
    payload: z.any().optional(),
  })
  .superRefine((val, ctx) => {
    const hasEvidence =
      Array.isArray(val.evidenceRefs) && val.evidenceRefs.length > 0;
    if (!hasEvidence && val.confidenceScore > 0.49) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ["evidenceRefs"],
        message: "evidenceRefs required when confidenceScore > 0.49",
      });
    }

    if (!hasEvidence && val.confidenceScore <= 0.49 && !val.noEvidenceReason) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ["noEvidenceReason"],
        message:
          "noEvidenceReason required when evidenceRefs is empty and confidenceScore <= 0.49",
      });
    }
  });

function validateMemoryEvent(input) {
  return MemoryEventSchema.safeParse(input);
}

module.exports = {
  MemoryIdentitySchema,
  MemoryEventSchema,
  validateMemoryEvent,
};
