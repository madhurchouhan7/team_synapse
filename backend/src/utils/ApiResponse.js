// src/utils/ApiResponse.js
// Standardised response helper for consistent API responses

/**
 * Send a successful JSON response.
 * @param {import('express').Response} res
 * @param {number} statusCode
 * @param {string} message
 * @param {object|array} data
 */
const sendSuccess = (res, statusCode = 200, message = 'Success', data = null) => {
    const payload = { success: true, message };
    if (data !== null) payload.data = data;
    return res.status(statusCode).json(payload);
};

/**
 * Send an error JSON response.
 * @param {import('express').Response} res
 * @param {number} statusCode
 * @param {string} message
 */
const sendError = (res, statusCode = 500, message = 'Internal Server Error') => {
    return res.status(statusCode).json({ success: false, message });
};

module.exports = { sendSuccess, sendError };
