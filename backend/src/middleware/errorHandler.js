// src/middleware/errorHandler.js
// Enhanced centralized global error handler with comprehensive error handling

const ApiError = require('../utils/ApiError');
const { z } = require('zod');

/**
 * Enhanced error handler with better error categorization and logging
 */
const errorHandler = (err, req, res, _next) => {
  const isProduction = process.env.NODE_ENV === "production";

  // Determine error type and status code
  let statusCode;
  let message;
  let errorCode;
  let details = null;

  // Handle different error types
  if (err instanceof ApiError) {
    statusCode = err.statusCode;
    message = err.message;
    errorCode = "API_ERROR";
  } else if (err instanceof z.ZodError) {
    statusCode = 400;
    message = "Validation failed";
    errorCode = "VALIDATION_ERROR";
    details = err.errors.map(e => ({
      field: e.path.join('.'),
      message: e.message,
      code: e.code,
    }));
  } else if (err.name === 'ValidationError') {
    // Mongoose validation error
    statusCode = 400;
    message = "Data validation failed";
    errorCode = "MONGOOSE_VALIDATION_ERROR";
    details = Object.values(err.errors).map(e => ({
      field: e.path,
      message: e.message,
      value: e.value,
    }));
  } else if (err.name === 'CastError') {
    // Mongoose cast error (invalid ObjectId)
    statusCode = 400;
    message = "Invalid data format";
    errorCode = "CAST_ERROR";
    details = [{
      field: err.path,
      message: `Invalid ${err.path}: ${err.value}`,
      value: err.value,
    }];
  } else if (err.code === 11000) {
    // MongoDB duplicate key error
    statusCode = 409;
    message = "Duplicate entry";
    errorCode = "DUPLICATE_ERROR";
    const field = Object.keys(err.keyPattern)[0];
    details = [{
      field,
      message: `${field} already exists`,
      value: err.keyValue[field],
    }];
  } else if (err.name === 'JsonWebTokenError') {
    statusCode = 401;
    message = "Invalid authentication token";
    errorCode = "INVALID_TOKEN";
  } else if (err.name === 'TokenExpiredError') {
    statusCode = 401;
    message = "Authentication token expired";
    errorCode = "TOKEN_EXPIRED";
  } else if (err.name === 'MulterError') {
    statusCode = 400;
    message = "File upload error";
    errorCode = "UPLOAD_ERROR";
    if (err.code === 'LIMIT_FILE_SIZE') {
      message = "File too large";
    } else if (err.code === 'LIMIT_FILE_COUNT') {
      message = "Too many files";
    } else if (err.code === 'LIMIT_UNEXPECTED_FILE') {
      message = "Unexpected file field";
    }
  } else if (err.statusCode) {
    statusCode = err.statusCode;
    message = err.message;
    errorCode = "HTTP_ERROR";
  } else {
    // Unknown error
    statusCode = 500;
    message = isProduction ? "Internal Server Error" : err.message;
    errorCode = "UNKNOWN_ERROR";
  }

  // Log error with context
  const logData = {
    timestamp: new Date().toISOString(),
    method: req.method,
    url: req.originalUrl,
    ip: req.ip,
    userAgent: req.get('User-Agent'),
    userId: req.user?.id || req.user?._id,
    errorCode,
    message: err.message,
    statusCode,
    ...(isProduction ? {} : { stack: err.stack, details }),
  };

  if (statusCode >= 500) {
    console.error('[SERVER ERROR]', JSON.stringify(logData, null, 2));
  } else {
    console.warn('[CLIENT ERROR]', JSON.stringify(logData, null, 2));
  }

  // Prepare response
  const response = {
    success: false,
    message,
    errorCode,
    timestamp: new Date().toISOString(),
    requestId: req.id || generateRequestId(),
    ...(isProduction || !details ? {} : { details }),
    ...(isProduction ? {} : { stack: err.stack }),
  };

  // Add rate limit headers if available
  if (res.get('X-RateLimit-Limit')) {
    response.rateLimit = {
      limit: res.get('X-RateLimit-Limit'),
      remaining: res.get('X-RateLimit-Remaining'),
      reset: res.get('X-RateLimit-Reset'),
    };
  }

  res.status(statusCode).json(response);
};

/**
 * Generate a unique request ID for tracking
 */
const generateRequestId = () => {
  return Date.now().toString(36) + Math.random().toString(36).substr(2);
};

/**
 * Async error wrapper for route handlers
 * Eliminates need for try-catch blocks in controllers
 */
const asyncHandler = (fn) => {
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
};

/**
 * 404 handler for undefined routes
 */
const notFoundHandler = (req, res, next) => {
  const error = new ApiError(404, `Route ${req.originalUrl} not found`);
  next(error);
};

/**
 * Development error handler for better debugging
 */
const developmentErrorHandler = (err, req, res, _next) => {
  const statusCode = err.statusCode || 500;

  console.error('[DEV ERROR]', {
    message: err.message,
    stack: err.stack,
    body: req.body,
    params: req.params,
    query: req.query,
    user: req.user,
  });

  res.status(statusCode).json({
    success: false,
    message: err.message,
    errorCode: "DEV_ERROR",
    stack: err.stack,
    details: {
      body: req.body,
      params: req.params,
      query: req.query,
      user: req.user?.id || null,
    },
  });
};

module.exports = {
  errorHandler,
  asyncHandler,
  notFoundHandler,
  developmentErrorHandler,
};
