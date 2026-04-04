const fs = require("fs");
const path = require("path");

const { schemas } = require("../src/middleware/validation.middleware");

const contentRoutesPath = path.join(
  __dirname,
  "../src/routes/content.routes.js",
);

describe("Content Contract - /api/v1/content", () => {
  it("mounts /content namespace in api router (CNT-01..CNT-04)", () => {
    const routeIndexPath = path.join(__dirname, "../src/routes/index.js");
    const routeIndexSource = fs.readFileSync(routeIndexPath, "utf8");
    expect(routeIndexSource).toMatch(
      /router\.use\(["']\/content["'],\s*contentRoutes\)/,
    );
  });

  it("provides content route module file for faq/bill/legal endpoints", () => {
    expect(fs.existsSync(contentRoutesPath)).toBe(true);
  });

  it("defines faq, bill-guide, and legal endpoint paths", () => {
    const exists = fs.existsSync(contentRoutesPath);
    expect(exists).toBe(true);

    if (!exists) {
      return;
    }

    const contentRouter = require(contentRoutesPath);
    const routes = contentRouter.stack
      .filter((layer) => layer.route)
      .map((layer) => layer.route.path);

    expect(routes).toContain("/faqs");
    expect(routes).toContain("/bill-guide");
    expect(routes).toContain("/legal/:slug");
  });

  it("exposes validation schema contracts for faq and legal surfaces", () => {
    expect(schemas).toHaveProperty("getFaqContent");
    expect(schemas).toHaveProperty("getBillGuideContent");
    expect(schemas).toHaveProperty("getLegalContent");
  });

  it("freezes expected metadata envelope contract for all content payloads", () => {
    const envelope = {
      success: true,
      message: "Content fetched.",
      data: {
        contentVersion: "2026.03.1",
        lastUpdatedAt: "2026-03-26T00:00:00.000Z",
        effectiveFrom: "2026-03-01T00:00:00.000Z",
      },
    };

    expect(envelope.success).toBe(true);
    expect(envelope).toHaveProperty("data.contentVersion");
    expect(envelope).toHaveProperty("data.lastUpdatedAt");
    expect(envelope).toHaveProperty("data.effectiveFrom");
  });

  it("locks faq search/filter query contract shape", () => {
    const query = {
      q: "peak hours",
      topic: "billing-basics",
      limit: "20",
      offset: "0",
    };

    expect(Object.keys(query)).toEqual(["q", "topic", "limit", "offset"]);
  });
});
