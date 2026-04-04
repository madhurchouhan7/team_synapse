// src/controllers/content.controller.js
// Utility content delivery with deterministic filtering and conditional refresh.

const crypto = require("crypto");

const { asyncHandler } = require("../middleware/errorHandler");
const { sendSuccess } = require("../utils/ApiResponse");
const ApiError = require("../utils/ApiError");
const UtilityContent = require("../models/UtilityContent.model");
const cacheService = require("../services/CacheService");

const CONTENT_CACHE_TTL_SECONDS = 300;

const DEFAULT_CONTENT = {
  faq: {
    kind: "faq",
    slug: "default",
    locale: "en-IN",
    contentVersion: "2026.03.1",
    effectiveFrom: new Date("2026-03-01T00:00:00.000Z"),
    lastUpdatedAt: new Date("2026-03-26T00:00:00.000Z"),
    items: [
      {
        id: "faq-billing-basics-01",
        topic: "billing-basics",
        question: "What are peak hours in my electricity bill?",
        answer:
          "Peak hours are the highest demand windows where some tariffs charge more per unit.",
        tags: ["billing", "peak-hours"],
        order: 1,
      },
      {
        id: "faq-reading-bill-01",
        topic: "reading-your-bill",
        question: "How can I identify my monthly units consumed?",
        answer:
          "Check the units consumed row in your bill summary and compare it with the previous cycle.",
        tags: ["units", "bill"],
        order: 2,
      },
      {
        id: "faq-savings-01",
        topic: "savings",
        question: "How quickly can small behavior changes reduce my bill?",
        answer:
          "Consistent appliance scheduling and standby control often show savings in 1-2 bill cycles.",
        tags: ["savings", "behavior"],
        order: 3,
      },
    ],
  },
  bill_guide: {
    kind: "bill_guide",
    slug: "default",
    locale: "en-IN",
    contentVersion: "2026.03.1",
    effectiveFrom: new Date("2026-03-01T00:00:00.000Z"),
    lastUpdatedAt: new Date("2026-03-26T00:00:00.000Z"),
    items: [
      {
        id: "guide-1",
        title: "Consumer Details",
        body: "Verify your consumer number, cycle, and sanctioned load before payment.",
        order: 1,
      },
      {
        id: "guide-2",
        title: "Usage Summary",
        body: "Read units consumed and compare with previous months to spot unusual spikes.",
        order: 2,
      },
      {
        id: "guide-3",
        title: "Charges and Taxes",
        body: "Review energy charge, fixed charge, and government duties for bill accuracy.",
        order: 3,
      },
    ],
  },
  legal: {
    privacy: {
      kind: "legal",
      slug: "privacy",
      locale: "en-IN",
      contentVersion: "2026.03.1",
      effectiveFrom: new Date("2026-03-01T00:00:00.000Z"),
      lastUpdatedAt: new Date("2026-03-26T00:00:00.000Z"),
      items: [
        {
          id: "legal-privacy-1",
          title: "Privacy Policy",
          body: "WattWise uses your profile and utility usage data to personalize energy recommendations.",
          order: 1,
        },
      ],
    },
    terms: {
      kind: "legal",
      slug: "terms",
      locale: "en-IN",
      contentVersion: "2026.03.1",
      effectiveFrom: new Date("2026-03-01T00:00:00.000Z"),
      lastUpdatedAt: new Date("2026-03-26T00:00:00.000Z"),
      items: [
        {
          id: "legal-terms-1",
          title: "Terms of Service",
          body: "By using WattWise you agree to use recommendations as informational guidance.",
          order: 1,
        },
      ],
    },
  },
};

const toIsoOrNull = (value) => (value ? new Date(value).toISOString() : null);

const sortDeterministically = (items) =>
  [...items].sort((a, b) => {
    if ((a.order ?? 0) !== (b.order ?? 0)) {
      return (a.order ?? 0) - (b.order ?? 0);
    }

    return String(a.id || a.question || a.title || "").localeCompare(
      String(b.id || b.question || b.title || ""),
    );
  });

const contentRevisionKey = (content) => {
  const lastUpdated =
    toIsoOrNull(content.lastUpdatedAt || content.updatedAt) || "";
  const version = content.contentVersion || "";
  const hash = content.metadata?.hash || "";
  return `${version}:${lastUpdated}:${hash}`;
};

const buildEtag = (content) => {
  const payload = JSON.stringify({
    kind: content.kind,
    slug: content.slug,
    locale: content.locale,
    revision: contentRevisionKey(content),
  });

  const digest = crypto
    .createHash("sha1")
    .update(payload)
    .digest("hex")
    .slice(0, 16);
  return `"content-v${digest}"`;
};

const setConditionalHeaders = (res, etag) => {
  res.set("ETag", etag);
  res.set("Cache-Control", "no-cache");
  res.set("Vary", "If-None-Match");
};

const resolveDefaultContent = ({ kind, slug }) => {
  if (kind === "legal") {
    return DEFAULT_CONTENT.legal[slug] || null;
  }

  return DEFAULT_CONTENT[kind] || null;
};

const normalizeContent = (content) => ({
  kind: content.kind,
  slug: content.slug,
  locale: content.locale,
  contentVersion: content.contentVersion,
  effectiveFrom: toIsoOrNull(content.effectiveFrom),
  lastUpdatedAt: toIsoOrNull(content.lastUpdatedAt || content.updatedAt),
  items: sortDeterministically(
    Array.isArray(content.items) ? content.items : [],
  ),
});

const loadContent = async ({ kind, slug = "default", locale = "en-IN" }) => {
  const cacheKey = cacheService.generateContentKey(kind, slug, locale);
  const cached = await cacheService.get(cacheKey);

  const dbVersionDoc = await UtilityContent.findOne({
    kind,
    slug,
    locale,
    status: "published",
  })
    .select(
      "kind slug locale contentVersion lastUpdatedAt updatedAt metadata.hash",
    )
    .lean();

  const fallback = resolveDefaultContent({ kind, slug });
  const currentVersionSource = dbVersionDoc || fallback;

  if (!currentVersionSource) {
    throw new ApiError(404, "Content not found.");
  }

  const currentRevision = contentRevisionKey(currentVersionSource);

  if (cached && cached.revisionKey === currentRevision) {
    return cached;
  }

  if (cached && cached.revisionKey !== currentRevision) {
    await cacheService.delPattern(`app:content:${kind}:${slug}:${locale}*`);
  }

  const dbContent = dbVersionDoc
    ? await UtilityContent.findOne({
        kind,
        slug,
        locale,
        status: "published",
      }).lean()
    : null;

  const source = dbContent || fallback;
  const normalized = normalizeContent(source);
  const etag = buildEtag(normalized);

  const cacheEntry = {
    ...normalized,
    etag,
    revisionKey: currentRevision,
  };

  await cacheService.set(cacheKey, cacheEntry, CONTENT_CACHE_TTL_SECONDS);

  return cacheEntry;
};

const filterFaqItems = (items, { q, topic, limit, offset }) => {
  let filtered = sortDeterministically(items);

  if (topic) {
    const topicQuery = topic.trim().toLowerCase();
    filtered = filtered.filter(
      (item) =>
        String(item.topic || "")
          .trim()
          .toLowerCase() === topicQuery,
    );
  }

  if (q) {
    const search = q.trim().toLowerCase();
    filtered = filtered.filter((item) => {
      const haystack = [
        item.question,
        item.answer,
        item.topic,
        ...(item.tags || []),
      ]
        .filter(Boolean)
        .join(" ")
        .toLowerCase();
      return haystack.includes(search);
    });
  }

  const paged = filtered.slice(offset, offset + limit);

  return {
    total: filtered.length,
    limit,
    offset,
    items: paged,
  };
};

const maybeNotModified = (req, res, etag) => {
  const ifNoneMatch = req.get("If-None-Match");
  setConditionalHeaders(res, etag);

  if (ifNoneMatch && ifNoneMatch === etag) {
    return res.status(304).end();
  }

  return null;
};

exports.getFaqs = asyncHandler(async (req, res) => {
  const { q, topic, limit = 20, offset = 0, locale = "en-IN" } = req.query;
  const content = await loadContent({ kind: "faq", slug: "default", locale });

  const notModified = maybeNotModified(req, res, content.etag);
  if (notModified) {
    return;
  }

  const filtered = filterFaqItems(content.items, {
    q,
    topic,
    limit: Number(limit),
    offset: Number(offset),
  });

  sendSuccess(res, 200, "Content fetched.", {
    contentVersion: content.contentVersion,
    lastUpdatedAt: content.lastUpdatedAt,
    effectiveFrom: content.effectiveFrom,
    faq: filtered,
  });
});

exports.getBillGuide = asyncHandler(async (req, res) => {
  const { locale = "en-IN" } = req.query;
  const content = await loadContent({
    kind: "bill_guide",
    slug: "default",
    locale,
  });

  const notModified = maybeNotModified(req, res, content.etag);
  if (notModified) {
    return;
  }

  sendSuccess(res, 200, "Content fetched.", {
    contentVersion: content.contentVersion,
    lastUpdatedAt: content.lastUpdatedAt,
    effectiveFrom: content.effectiveFrom,
    sections: content.items,
  });
});

exports.getLegalContent = asyncHandler(async (req, res) => {
  const { slug } = req.params;
  const { locale = "en-IN" } = req.query;

  const content = await loadContent({ kind: "legal", slug, locale });
  const notModified = maybeNotModified(req, res, content.etag);

  if (notModified) {
    return;
  }

  sendSuccess(res, 200, "Content fetched.", {
    contentVersion: content.contentVersion,
    lastUpdatedAt: content.lastUpdatedAt,
    effectiveFrom: content.effectiveFrom,
    slug: content.slug,
    document: content.items[0] || null,
  });
});
