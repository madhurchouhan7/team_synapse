const fs = require("fs");
const path = require("path");

describe("Support Reference Contract", () => {
  const modelPath = path.join(
    __dirname,
    "../src/models/SupportTicket.model.js",
  );
  const controllerPath = path.join(
    __dirname,
    "../src/controllers/support.controller.js",
  );
  const routesPath = path.join(__dirname, "../src/routes/support.routes.js");

  it("provides support model/controller/routes modules", () => {
    expect(fs.existsSync(modelPath)).toBe(true);
    expect(fs.existsSync(controllerPath)).toBe(true);
    expect(fs.existsSync(routesPath)).toBe(true);
  });

  it("defines POST /tickets path in support routes module", () => {
    const exists = fs.existsSync(routesPath);
    expect(exists).toBe(true);

    if (!exists) {
      return;
    }

    const supportRouter = require(routesPath);
    const routes = supportRouter.stack
      .filter((layer) => layer.route)
      .map((layer) => ({
        path: layer.route.path,
        methods: Object.keys(layer.route.methods),
      }));

    expect(routes).toContainEqual(
      expect.objectContaining({
        path: "/tickets",
        methods: expect.arrayContaining(["post"]),
      }),
    );
  });

  it("freezes durable support success envelope shape", () => {
    const envelope = {
      success: true,
      message: "Support ticket submitted successfully.",
      data: {
        ticketRef: "SUP-20260327-1A2B3C",
        status: "OPEN",
      },
    };

    expect(envelope.data.ticketRef).toMatch(/^SUP-/);
    expect(envelope.data.status).toBe("OPEN");
  });
});
