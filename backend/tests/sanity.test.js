const fs = require("fs");
const path = require("path");

describe("DevOps Backend Sanity Check", () => {
  it("should prove that the testing pipeline works", () => {
    expect(1 + 1).toBe(2);
  });

  it("keeps v2.1 API endpoint groups mounted in the central router", () => {
    const routesPath = path.resolve(__dirname, "../src/routes/index.js");
    const source = fs.readFileSync(routesPath, "utf8");

    const expectedMounts = [
      "/users",
      "/appliances",
      "/content",
      "/support",
      "/solar",
    ];

    expectedMounts.forEach((mountPath) => {
      expect(source).toContain(`router.use("${mountPath}"`);
    });
  });
});
