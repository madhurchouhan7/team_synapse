// src/controllers/bbps.controller.js
const axios = require('axios');
const { z } = require('zod');
const { sendSuccess } = require('../utils/ApiResponse');
const ApiError = require('../utils/ApiError');

/**
 * @desc    Fetch Electricity Bill via Setu
 * @route   POST /api/v1/bbps/fetch-bill
 * @access  Private
 */
exports.fetchBill = async (req, res) => {
    const BodySchema = z.object({
        billerId: z.string().trim().min(1, 'billerId is required'),
        consumerNumber: z.string().trim().min(1, 'consumerNumber is required'),
    });

    const parsed = BodySchema.safeParse(req.body);
    if (!parsed.success) {
        throw new ApiError(400, parsed.error.issues.map((i) => i.message).join(', '));
    }

    const { billerId, consumerNumber } = parsed.data;

    // MOCK RESPONSE FOR TESTING UI (Since sandbox.setu.co is unreachable / offline)
    if (billerId === 'TEST_BILLER_ID') {
        return sendSuccess(res, 200, 'Bill fetched.', {
            source: 'bbps',
            billerId,
            billerName: 'Mock Electricity Board',
            amountExact: 1250.5,
            billNumber: `INV-2026-00${Math.floor(Math.random() * 100)}`,
            dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
                .toISOString()
                .split('T')[0],
            consumerNumber,
            status: 'UNPAID',
        });
    }

    try {
        // 1. Call the Setu Sandbox API
        const setuResponse = await axios.post('https://sandbox.setu.co/api/v1/utilities/bills/fetch', {
            billerId: billerId,
            customerIdentifiers: [
                {
                    // The attribute name depends on the biller, but usually it's "Consumer Number"
                    attributeName: "Consumer Number",
                    attributeValue: consumerNumber
                }
            ]
        }, {
            headers: {
                'X-Client-Id': process.env.SETU_CLIENT_ID,
                'X-Client-Secret': process.env.SETU_CLIENT_SECRET,
                'Content-Type': 'application/json'
            }
        });

        // 2. Send the fetched bill data back securely to the Flutter App
        return sendSuccess(res, 200, 'Bill fetched.', {
            source: 'bbps',
            billerId,
            consumerNumber,
            ...setuResponse.data,
        });

    } catch (error) {
        console.error("Setu API Error:", error.response?.data || error.message);
        throw new ApiError(502, 'Failed to fetch bill from BBPS');
    }
};
