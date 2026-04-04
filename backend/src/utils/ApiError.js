// src/utils/ApiError.js
// Custom error class for predictable HTTP errors

class ApiError extends Error {
    /**
     * @param {number} statusCode  - HTTP status code (e.g. 400, 404, 500)
     * @param {string} message     - Human-readable error message
     */
    constructor(statusCode, message) {
        super(message);
        this.statusCode = statusCode;
        this.name = 'ApiError';
        Error.captureStackTrace(this, this.constructor);
    }
}

module.exports = ApiError;
