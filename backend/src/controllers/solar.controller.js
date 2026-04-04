const { asyncHandler } = require("../middleware/errorHandler");
const { sendSuccess } = require("../utils/ApiResponse");

const TARIFF_BY_STATE = {
  maharashtra: 8.1,
  karnataka: 7.8,
  delhi: 8.5,
  gujarat: 7.2,
  tamilnadu: 7.4,
};

const SHADING_MULTIPLIER = {
  low: 1,
  medium: 0.92,
  high: 0.82,
};

const SOLAR_LIMITATIONS = [
  "Estimate excludes on-site structural and shadow survey.",
  "Estimate is informational and not an installer quotation.",
  "Financing, subsidy approval, and policy updates are not guaranteed.",
];

const DISCLAIMER =
  "This solar output is an informational estimate range and should not be treated as a guaranteed quote.";

const roundTo = (value, places = 2) =>
  Number(Number(value).toFixed(Math.max(0, places)));

const computeEstimate = ({
  monthlyUnits,
  roofArea,
  state,
  discom,
  shadingLevel = "medium",
}) => {
  const normalizedState = String(state).trim().toLowerCase();
  const normalizedShading =
    SHADING_MULTIPLIER[shadingLevel] !== undefined ? shadingLevel : "medium";

  const tariffRateInrPerKwh =
    TARIFF_BY_STATE[normalizedState] !== undefined
      ? TARIFF_BY_STATE[normalizedState]
      : 7.5;

  const roofCapacityKw = roofArea / 100;
  const generationPerKw = 120 * SHADING_MULTIPLIER[normalizedShading];
  const consumptionDrivenKw = monthlyUnits / generationPerKw;

  const recommendedSystemSizeKw = roundTo(
    Math.max(0.5, Math.min(roofCapacityKw, consumptionDrivenKw)),
  );

  const baseGeneration = recommendedSystemSizeKw * generationPerKw;
  const lowGeneration = baseGeneration * 0.88;
  const highGeneration = baseGeneration * 1.12;

  const confidenceLabel =
    normalizedShading === "high" || roofCapacityKw < consumptionDrivenKw
      ? "LOW"
      : "MEDIUM";

  return {
    recommendedSystemSizeKw,
    estimatedMonthlyGenerationKwh: {
      low: roundTo(lowGeneration),
      base: roundTo(baseGeneration),
      high: roundTo(highGeneration),
    },
    estimatedMonthlySavingsInr: {
      low: roundTo(lowGeneration * tariffRateInrPerKwh),
      base: roundTo(baseGeneration * tariffRateInrPerKwh),
      high: roundTo(highGeneration * tariffRateInrPerKwh),
    },
    assumptions: {
      state,
      discom,
      shadingLevel: normalizedShading,
      tariffRateInrPerKwh,
      estimatedGenerationPerKwKwhPerMonth: roundTo(generationPerKw),
      rooftopCapacityKw: roundTo(roofCapacityKw),
      model: "solar-range-v1",
      generatedAt: new Date().toISOString(),
    },
    limitations: SOLAR_LIMITATIONS,
    confidenceLabel,
    disclaimer: DISCLAIMER,
  };
};

const calculateSolarEstimate = asyncHandler(async (req, res) => {
  const payload = computeEstimate(req.body);

  sendSuccess(res, 200, "Solar estimate calculated successfully.", payload);
});

module.exports = {
  calculateSolarEstimate,
  computeEstimate,
};
