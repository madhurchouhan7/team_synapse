// src/routes/index.js
// Central router — mounts all feature route modules under /api/v1

const express = require("express");
const router = express.Router();

const authRoutes = require("./auth.routes");
const userRoutes = require("./user.routes");
const addressRoutes = require("./address.routes");
const applianceRoutes = require("./appliance.routes");
const billRoutes = require("./bill.routes");
const aiRoutes = require("./ai.routes");
const bbpsRoutes = require("./bbps.routes");
const notificationRoutes = require("./notification.routes");
const contentRoutes = require("./content.routes");
const solarRoutes = require("./solar.routes");
const supportRoutes = require("./support.routes");
const smartPlugRoutes = require("./smartPlug.routes");

// Health / Ping Route
router.get("/ping", (req, res) => {
  res.status(200).json({
    success: true,
    message: "Server is up and running",
    timestamp: new Date().toISOString()
  });
});

router.use("/auth", authRoutes);
router.use("/users", userRoutes);
router.use("/addresses", addressRoutes);
router.use("/appliances", applianceRoutes);
router.use("/bills", billRoutes);
router.use("/ai", aiRoutes);
router.use("/bbps", bbpsRoutes);
router.use("/notifications", notificationRoutes);
router.use("/content", contentRoutes);
router.use("/solar", solarRoutes);
router.use("/support", supportRoutes);
router.use("/smart-plugs", smartPlugRoutes);

module.exports = router;
