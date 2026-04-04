// src/middleware/validation.middleware.js
// Centralized input validation middleware using Zod schemas

const { z } = require("zod");
const ApiError = require("../utils/ApiError");

// Common validation schemas
const commonSchemas = {
  objectId: z.string().regex(/^[0-9a-fA-F]{24}$/, "Invalid ObjectId format"),
  email: z.string().email("Invalid email format"),
  password: z.string().min(6, "Password must be at least 6 characters"),
  name: z.string().min(1, "Name is required").max(100, "Name too long"),
  currency: z.enum(["INR", "USD", "EUR", "GBP", "AED"]),
  nonNegativeNumber: z.number().min(0, "Value must be non-negative"),
  positiveNumber: z.number().min(1, "Value must be positive"),
};

const applianceMutableFieldsSchema = {
  applianceId: z.string().trim().min(1, "Appliance ID is required"),
  title: z
    .string()
    .trim()
    .min(1, "Appliance name is required")
    .max(100, "Appliance name too long"),
  category: z
    .enum([
      "cooling",
      "heating",
      "lighting",
      "entertainment",
      "kitchen",
      "laundry",
      "cleaning",
      "computing",
      "charging",
      "other",
    ])
    .or(z.string().trim().min(1, "Category is required")),
  wattage: z
    .number()
    .min(0, "Wattage cannot be negative")
    .max(10000, "Wattage seems too high"),
  starRating: z.string().trim().min(1, "Star rating is required"),
  brand: z
    .string()
    .trim()
    .min(1, "Brand is required")
    .max(50, "Brand name too long"),
  model: z
    .string()
    .trim()
    .min(1, "Model is required")
    .max(50, "Model name too long"),
  usageHoursPerDay: z
    .number()
    .min(0, "Usage hours cannot be negative")
    .max(24, "Usage hours cannot exceed 24"),
  usageLevel: z.enum(["Low", "Medium", "High"]),
  count: z
    .number()
    .int()
    .min(1, "Count must be at least 1")
    .max(100, "Count seems too high"),
  selectedDropdowns: z.record(z.string(), z.string()),
  svgPath: z.string().trim().min(1, "SVG path is required"),
};

// Specific validation schemas
const schemas = {
  // User validation
  updateProfile: z
    .object({
      name: z
        .string()
        .trim()
        .min(2, "Name must be at least 2 characters")
        .max(100, "Name too long")
        .optional(),
      avatarUrl: z
        .string()
        .trim()
        .url("Avatar URL must be a valid HTTP/HTTPS URL")
        .optional(),
      address: z.object({
        state: z.string().optional(),
        city: z.string().optional(),
        discom: z.string().optional(),
        lat: z.number().optional(),
        lng: z.number().optional()
      }).optional(),
      household: z.object({
        peopleCount: commonSchemas.positiveNumber.optional(),
        familyType: z.enum(["Just Me", "Small", "Large", "Joint"]).optional(),
        houseType: z.enum(["Apartment", "Bungalow", "Independent"]).optional(),
      }).optional(),
      planPreferences: z.object({
        mainGoals: z.array(z.string()).optional(),
        focusArea: z.string().optional()
      }).optional(),
      onboardingCompleted: z.boolean().optional(),
      activePlan: z.any().optional(),
      streak: z.number().optional(),
      lastCheckIn: z.string().optional(),
    }),

  updateAddress: z.object({
    state: z.string().min(1, "State is required").optional(),
    city: z.string().min(1, "City is required").optional(),
    discom: z.string().min(1, "DISCOM is required").optional(),
    lat: z.number().min(-90).max(90).optional(),
    lng: z.number().min(-180).max(180).optional(),
  }),

  updateHousehold: z.object({
    peopleCount: commonSchemas.positiveNumber.optional(),
    familyType: z.enum(["Just Me", "Small", "Large", "Joint"]).optional(),
    houseType: z.enum(["Apartment", "Bungalow", "Independent"]).optional(),
  }),

  // Appliance validation
  updateAppliances: z.object({
    appliances: z
      .array(
        z.object({
          applianceId: z.string().min(1, "Appliance ID is required"),
          title: z.string().min(1, "Appliance name is required"),
          category: z.string().min(1, "Category is required"),
          usageHours: z.number().min(0).max(24),
          usageLevel: z.enum(["Low", "Medium", "High"]),
          count: commonSchemas.positiveNumber,
          selectedDropdowns: z.record(z.string(), z.string()),
          svgPath: z.string().optional(),
        }),
      )
      .min(1, "At least one appliance is required"),
  }),

  createAppliance: z
    .object({
      applianceId: applianceMutableFieldsSchema.applianceId,
      title: applianceMutableFieldsSchema.title,
      category: applianceMutableFieldsSchema.category,
      usageLevel: applianceMutableFieldsSchema.usageLevel,
      wattage: applianceMutableFieldsSchema.wattage.optional(),
      starRating: applianceMutableFieldsSchema.starRating.optional(),
      brand: applianceMutableFieldsSchema.brand.optional(),
      model: applianceMutableFieldsSchema.model.optional(),
      usageHoursPerDay:
        applianceMutableFieldsSchema.usageHoursPerDay.optional(),
      count: applianceMutableFieldsSchema.count.optional(),
      selectedDropdowns:
        applianceMutableFieldsSchema.selectedDropdowns.optional(),
      svgPath: applianceMutableFieldsSchema.svgPath.optional(),
    })
    .strict(),

  patchAppliance: z
    .object({
      applianceId: applianceMutableFieldsSchema.applianceId.optional(),
      title: applianceMutableFieldsSchema.title.optional(),
      category: applianceMutableFieldsSchema.category.optional(),
      wattage: applianceMutableFieldsSchema.wattage.optional(),
      starRating: applianceMutableFieldsSchema.starRating.optional(),
      brand: applianceMutableFieldsSchema.brand.optional(),
      model: applianceMutableFieldsSchema.model.optional(),
      usageHoursPerDay:
        applianceMutableFieldsSchema.usageHoursPerDay.optional(),
      usageLevel: applianceMutableFieldsSchema.usageLevel.optional(),
      count: applianceMutableFieldsSchema.count.optional(),
      selectedDropdowns:
        applianceMutableFieldsSchema.selectedDropdowns.optional(),
      svgPath: applianceMutableFieldsSchema.svgPath.optional(),
      _expectedVersion: z
        .number()
        .int()
        .min(0, "Expected version must be zero or greater"),
    })
    .strict(),

  deleteAppliance: z
    .object({
      _expectedVersion: z
        .number()
        .int()
        .min(0, "Expected version must be zero or greater"),
    })
    .strict(),

  // Bill validation
  addBill: z.object({
    source: z.enum(["ocr", "bbps", "manual"]).default("manual"),
    billerId: z.string().trim().min(1).optional(),
    billNumber: z.string().trim().min(1).optional(),
    consumerNumber: z.string().trim().min(1).optional(),
    status: z.string().trim().min(1).optional(),
    amount: commonSchemas.nonNegativeNumber.optional(),
    units: commonSchemas.nonNegativeNumber.optional(),
    subsidy: commonSchemas.nonNegativeNumber.optional(),
    grossAmount: commonSchemas.nonNegativeNumber.optional(),
    amountExact: commonSchemas.nonNegativeNumber.optional(),
    netPayable: commonSchemas.nonNegativeNumber.optional(),
    subsidyAmount: commonSchemas.nonNegativeNumber.optional(),
    dueDate: z.union([z.string().trim(), z.date()]).optional(),
    periodStart: z.union([z.string().trim(), z.date()]).optional(),
    periodEnd: z.union([z.string().trim(), z.date()]).optional(),
    rawText: z.string().optional(),
    imageBase64: z.string().optional(),
  }),

  // AI Plan validation
  generatePlan: z.object({
    user: z
      .object({
        goal: z.string().optional(),
        focusArea: z.string().optional(),
        location: z.string().optional(),
      })
      .optional(),
    appliances: z
      .array(
        z.object({
          name: z.string(),
          wattage: z.number().optional(),
          starRating: z.string().optional(),
          usageHoursPerDay: z.number().optional(),
          usageLevel: z.string().optional(),
          count: z.number().optional(),
        }),
      )
      .optional(),
    bill: z
      .object({
        month: z.string().optional(),
        unitsConsumed: z.number().optional(),
        totalAmount: z.number().optional(),
      })
      .optional(),
  }),

  // BBPS validation
  fetchBill: z.object({
    billerId: z.string().min(1, "Biller ID is required"),
    consumerNumber: z.string().min(1, "Consumer number is required"),
  }),

  getFaqContent: z
    .object({
      q: z.string().trim().min(1).max(120).optional(),
      topic: z.string().trim().min(1).max(80).optional(),
      limit: z.preprocess(
        (value) => (value === undefined ? 20 : Number(value)),
        z.number().int().min(1).max(100),
      ),
      offset: z.preprocess(
        (value) => (value === undefined ? 0 : Number(value)),
        z.number().int().min(0),
      ),
      locale: z.string().trim().min(2).max(20).optional(),
    })
    .strict(),

  getBillGuideContent: z
    .object({
      locale: z.string().trim().min(2).max(20).optional(),
    })
    .strict(),

  getLegalContent: z
    .object({
      slug: z
        .string()
        .trim()
        .regex(/^[a-z0-9-]{2,100}$/, "Invalid legal content slug"),
    })
    .strict(),

  createSupportTicket: z
    .object({
      category: z.string().trim().min(1, "Category is required"),
      message: z
        .string()
        .trim()
        .min(10, "Message must be at least 10 characters")
        .max(5000, "Message too long"),
      preferredContact: z
        .object({
          name: z.string().trim().min(1, "Contact name is required").max(100),
          method: z.enum(["email", "phone"]),
          email: z.string().trim().email("Invalid email format").optional(),
          phone: z
            .string()
            .trim()
            .min(7, "Phone must be at least 7 digits")
            .max(20, "Phone too long")
            .optional(),
        })
        .strict()
        .superRefine((value, ctx) => {
          if (value.method === "email" && !value.email) {
            ctx.addIssue({
              code: z.ZodIssueCode.custom,
              path: ["email"],
              message:
                "Email is required when preferred contact method is email",
            });
          }

          if (value.method === "phone" && !value.phone) {
            ctx.addIssue({
              code: z.ZodIssueCode.custom,
              path: ["phone"],
              message:
                "Phone is required when preferred contact method is phone",
            });
          }
        }),
      consent: z
        .object({
          policySlug: z
            .string()
            .trim()
            .regex(/^[a-z0-9-]{2,100}$/, "Invalid policy slug"),
          consentVersion: z
            .string()
            .trim()
            .min(1, "Consent version is required"),
          acceptedAt: z.string().datetime("acceptedAt must be an ISO datetime"),
        })
        .strict(),
    })
    .strict(),

  calculateSolarEstimate: z
    .object({
      monthlyUnits: z
        .number()
        .min(1, "Monthly units must be at least 1")
        .max(100000, "Monthly units seem too high"),
      roofArea: z
        .number()
        .min(20, "Roof area must be at least 20 sq ft")
        .max(50000, "Roof area seems too high"),
      state: z.string().trim().min(1, "State is required").max(100),
      discom: z.string().trim().min(1, "DISCOM is required").max(120),
      shadingLevel: z.enum(["low", "medium", "high"]).optional(),
      sanctionedLoadKw: z
        .number()
        .min(0.5, "Sanctioned load must be at least 0.5 kW")
        .max(100, "Sanctioned load seems too high")
        .optional(),
    })
    .strict(),

  // ── Smart Plug schemas ────────────────────────────────────────────────────
  registerSmartPlug: z
    .object({
      name: z.string().trim().min(1, "Plug name is required").max(100, "Name too long"),
      applianceId: z.string().regex(/^[0-9a-fA-F]{24}$/, "Invalid appliance ID").optional(),
      vendor: z
        .enum(["tasmota", "shelly", "tplink_kasa", "tuya", "simulator", "webhook", "other"])
        .optional()
        .default("simulator"),
      isSimulated: z.boolean().optional().default(true),
      location: z.string().trim().max(100).optional(),
      baselineWattage: z.number().min(0).max(10000).optional(),
      connectionConfig: z
        .object({
          ipAddress:      z.string().optional(),
          cloudDeviceId:  z.string().optional(),
          webhookSecret:  z.string().optional(),
        })
        .optional(),
    }),

  triggerSmartPlugReading: z
    .object({
      wattageOverride: z.number().min(0).max(15000).optional(),
      forceSpike:      z.boolean().optional(),
    })
    .optional()
    .default({}),
};

/**
 * Validation middleware factory
 * @param {string} schemaName - Name of the schema to use
 * @param {string} source - Source of data ('body', 'query', 'params')
 * @returns {Function} Express middleware function
 */
const validate = (schemaName, source = "body") => {
  const schema = schemas[schemaName];

  if (!schema) {
    throw new Error(`Validation schema '${schemaName}' not found`);
  }

  return (req, res, next) => {
    try {
      const data = req[source];
      const result = schema.safeParse(data);

      if (!result.success) {
        const details = result.error.issues.flatMap((issue) => {
          if (issue.code === "unrecognized_keys" && Array.isArray(issue.keys)) {
            return issue.keys.map((key) => ({
              path: key,
              message: "Unsupported field",
            }));
          }

          return [
            {
              path: issue.path.join("."),
              message: issue.message,
            },
          ];
        });

        return res.status(400).json({
          success: false,
          message: "Validation failed",
          errorCode: "VALIDATION_ERROR",
          timestamp: new Date().toISOString(),
          requestId: req.id,
          details,
        });
      }

      // Attach validated data back to request
      req[source] = result.data;
      next();
    } catch (error) {
      next(error);
    }
  };
};

/**
 * Custom validation middleware for complex scenarios
 */
const customValidations = {
  // Validate file uploads
  validateFileUpload: (req, res, next) => {
    if (!req.file && !req.body.imageBase64) {
      return next(new ApiError(400, "No file or image data provided"));
    }

    if (req.file) {
      const allowedTypes = ["image/jpeg", "image/png", "image/webp"];
      if (!allowedTypes.includes(req.file.mimetype)) {
        return next(
          new ApiError(
            400,
            "Invalid file type. Only JPEG, PNG, and WebP are allowed",
          ),
        );
      }

      const maxSize = 5 * 1024 * 1024; // 5MB
      if (req.file.size > maxSize) {
        return next(new ApiError(400, "File too large. Maximum size is 5MB"));
      }
    }

    next();
  },

  // Validate pagination parameters
  validatePagination: (req, res, next) => {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;

    if (page < 1) {
      return next(new ApiError(400, "Page must be greater than 0"));
    }

    if (limit < 1 || limit > 100) {
      return next(new ApiError(400, "Limit must be between 1 and 100"));
    }

    req.pagination = {
      page,
      limit,
      skip: (page - 1) * limit,
    };

    next();
  },
};

module.exports = {
  validate,
  schemas,
  commonSchemas,
  customValidations,
};
