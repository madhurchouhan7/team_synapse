const express = require("express");

const { validate } = require("../middleware/validation.middleware");
const { calculateSolarEstimate } = require("../controllers/solar.controller");

const router = express.Router();

router.post(
  "/estimate",
  validate("calculateSolarEstimate"),
  calculateSolarEstimate,
);

module.exports = router;
