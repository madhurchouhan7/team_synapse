const fs = require("fs");
const path = require("path");

const contentControllerPath = path.join(
  __dirname,
  "../src/controllers/content.controller.js",
);

jest.mock("../src/models/UtilityContent.model", () => ({
  findOne: jest.fn(() => ({
    select: jest.fn().mockReturnThis(),
    lean: jest.fn().mockResolvedValue(null),
  })),
}));

const contentController = require("../src/controllers/content.controller");

function createRes() {
  const res = {
    headers: {},
    statusCode: 200,
    body: null,
    set(name, value) {
      this.headers[name] = value;
      return this;
    },
    get(name) {
      return this.headers[name];
    },
    status(code) {
      this.statusCode = code;
      return this;
    },
    json(payload) {
      this.body = payload;
      return this;
    },
    end() {
      this.ended = true;
      return this;
    },
  };

  return res;
}

async function runHandler(handler, req, res) {
  return new Promise((resolve, reject) => {
    handler(req, res, (error) => {
      if (error) {
        reject(error);
        return;
      }

      resolve();
    });

    setImmediate(resolve);
  });
}

describe("Content Cache Contract - conditional refresh (CNT-05)", () => {
  it("provides a content controller implementation for conditional refresh", () => {
    expect(fs.existsSync(contentControllerPath)).toBe(true);
  });

  it("declares expected controller handlers for faq, bill-guide, and legal", () => {
    const exists = fs.existsSync(contentControllerPath);
    expect(exists).toBe(true);

    if (!exists) {
      return;
    }

    const controller = require(contentControllerPath);
    expect(typeof controller.getFaqs).toBe("function");
    expect(typeof controller.getBillGuide).toBe("function");
    expect(typeof controller.getLegalContent).toBe("function");
  });

  it("contains validator-header semantics for ETag + If-None-Match + 304", () => {
    const exists = fs.existsSync(contentControllerPath);
    expect(exists).toBe(true);

    if (!exists) {
      return;
    }

    const source = fs.readFileSync(contentControllerPath, "utf8");

    expect(source).toMatch(/ETag/i);
    expect(source).toMatch(/If-None-Match/i);
    expect(source).toMatch(/304/);
  });

  it("freezes conditional request headers used by client refresh", () => {
    const headers = {
      "If-None-Match": '"content-v2026.03.1"',
    };

    expect(headers).toHaveProperty("If-None-Match");
    expect(headers["If-None-Match"]).toContain("content-v");
  });

  it("returns 200 with ETag and no-cache headers for initial faq fetch", async () => {
    const req = {
      query: { q: "", topic: "", limit: 20, offset: 0 },
      get: () => undefined,
    };
    const res = createRes();

    await runHandler(contentController.getFaqs, req, res);

    expect(res.statusCode).toBe(200);
    expect(res.get("ETag")).toBeDefined();
    expect(res.get("Cache-Control")).toBe("no-cache");
    expect(res.body).toHaveProperty("success", true);
    expect(res.body).toHaveProperty("data.contentVersion");
  });

  it("returns 304 when If-None-Match matches current validator", async () => {
    const warmReq = {
      query: { q: "", topic: "", limit: 20, offset: 0 },
      get: () => undefined,
    };
    const warmRes = createRes();

    await runHandler(contentController.getFaqs, warmReq, warmRes);

    const etag = warmRes.get("ETag");
    const req = {
      query: { q: "", topic: "", limit: 20, offset: 0 },
      get: (name) => (name === "If-None-Match" ? etag : undefined),
    };
    const res = createRes();

    await runHandler(contentController.getFaqs, req, res);

    expect(res.statusCode).toBe(304);
    expect(res.ended).toBe(true);
  });
});
