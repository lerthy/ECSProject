const express = require('express');
const Joi = require('joi');
const { v4: uuidv4 } = require('uuid');
const AWSXRay = require('aws-xray-sdk-core');
const router = express.Router();

// In-memory orders storage (in production, use DynamoDB/RDS)
let orders = [];

// Import cart data (in production, this would be from the same database)
// For this demo, we'll import the carts from the cart module
const cartModule = require('./cart');

// Validation schemas
const checkoutSchema = Joi.object({
    shippingAddress: Joi.object({
        street: Joi.string().required(),
        city: Joi.string().required(),
        state: Joi.string().required(),
        zipCode: Joi.string().required(),
        country: Joi.string().required()
    }).required(),
    paymentMethod: Joi.object({
        type: Joi.string().valid('credit_card', 'debit_card', 'paypal').required(),
        cardNumber: Joi.string().when('type', {
            is: Joi.string().valid('credit_card', 'debit_card'),
            then: Joi.required(),
            otherwise: Joi.forbidden()
        }),
        expiryMonth: Joi.number().when('type', {
            is: Joi.string().valid('credit_card', 'debit_card'),
            then: Joi.required(),
            otherwise: Joi.forbidden()
        }),
        expiryYear: Joi.number().when('type', {
            is: Joi.string().valid('credit_card', 'debit_card'),
            then: Joi.required(),
            otherwise: Joi.forbidden()
        }),
        cvv: Joi.string().when('type', {
            is: Joi.string().valid('credit_card', 'debit_card'),
            then: Joi.required(),
            otherwise: Joi.forbidden()
        }),
        email: Joi.string().email().when('type', {
            is: 'paypal',
            then: Joi.required(),
            otherwise: Joi.forbidden()
        })
    }).required()
});

// Helper function to calculate order totals
function calculateOrderTotals(items) {
    const subtotal = items.reduce((sum, item) => sum + (item.price * item.quantity), 0);
    const tax = subtotal * 0.08; // 8% tax
    const shipping = subtotal > 50 ? 0 : 9.99; // Free shipping over $50
    const total = subtotal + tax + shipping;

    return {
        subtotal: Math.round(subtotal * 100) / 100,
        tax: Math.round(tax * 100) / 100,
        shipping: Math.round(shipping * 100) / 100,
        total: Math.round(total * 100) / 100
    };
}

// Helper function to simulate payment processing
function processPayment(paymentMethod, total) {
    // Simulate payment processing delay
    return new Promise((resolve) => {
        setTimeout(() => {
            // Simulate 95% success rate
            const success = Math.random() > 0.05;
            if (success) {
                resolve({
                    success: true,
                    transactionId: uuidv4(),
                    message: 'Payment processed successfully'
                });
            } else {
                resolve({
                    success: false,
                    error: 'Payment failed',
                    message: 'Unable to process payment. Please try again.'
                });
            }
        }, 1000);
    });
}

// POST /api/checkout/:userId - Process checkout
router.post('/:userId', async (req, res) => {
    const segment = AWSXRay.getSegment();
    const subsegment = segment.addNewSubsegment('process-checkout');

    try {
        const { userId } = req.params;
        const { error, value } = checkoutSchema.validate(req.body);

        if (error) {
            subsegment.addAnnotation('validation_error', true);
            subsegment.close();
            return res.status(400).json({
                error: 'Validation failed',
                details: error.details.map(d => d.message)
            });
        }

        const { shippingAddress, paymentMethod } = value;

        // Get user's cart (simulate cart retrieval)
        // In production, this would be retrieved from the same database
        const userCart = global.carts ? global.carts[userId] : null;

        if (!userCart || !userCart.items || userCart.items.length === 0) {
            subsegment.addAnnotation('cart_empty', true);
            subsegment.close();
            return res.status(400).json({ error: 'Cart is empty' });
        }

        // Calculate order totals
        const totals = calculateOrderTotals(userCart.items);

        // Process payment
        subsegment.addAnnotation('processing_payment', true);
        const paymentResult = await processPayment(paymentMethod, totals.total);

        if (!paymentResult.success) {
            subsegment.addAnnotation('payment_failed', true);
            subsegment.close();
            return res.status(400).json({
                error: 'Payment failed',
                message: paymentResult.message
            });
        }

        // Create order
        const order = {
            id: uuidv4(),
            userId,
            items: [...userCart.items],
            totals,
            shippingAddress,
            paymentMethod: {
                type: paymentMethod.type,
                // Don't store sensitive payment info
                ...(paymentMethod.type === 'paypal' ? { email: paymentMethod.email } : {})
            },
            payment: {
                transactionId: paymentResult.transactionId,
                status: 'completed',
                processedAt: new Date().toISOString()
            },
            status: 'confirmed',
            estimatedDelivery: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(), // 7 days
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString()
        };

        orders.push(order);

        // Clear user's cart after successful checkout
        if (global.carts && global.carts[userId]) {
            global.carts[userId].items = [];
            global.carts[userId].updatedAt = new Date().toISOString();
        }

        subsegment.addAnnotation('order_created', true);
        subsegment.addAnnotation('order_id', order.id);
        subsegment.addAnnotation('order_total', totals.total);
        subsegment.close();

        res.status(201).json({
            message: 'Order placed successfully',
            data: order
        });
    } catch (error) {
        subsegment.addError(error);
        subsegment.close();
        res.status(500).json({ error: 'Failed to process checkout' });
    }
});

// GET /api/orders/:userId - Get user's orders
router.get('/:userId', (req, res) => {
    const segment = AWSXRay.getSegment();
    const subsegment = segment.addNewSubsegment('get-user-orders');

    try {
        const { userId } = req.params;
        const { limit = 10, offset = 0, status } = req.query;

        let userOrders = orders.filter(order => order.userId === userId);

        // Filter by status if provided
        if (status) {
            userOrders = userOrders.filter(order => order.status === status);
        }

        // Sort by creation date (newest first)
        userOrders.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

        // Pagination
        const startIndex = parseInt(offset);
        const endIndex = startIndex + parseInt(limit);
        const paginatedOrders = userOrders.slice(startIndex, endIndex);

        subsegment.addAnnotation('user_id', userId);
        subsegment.addAnnotation('orders_count', paginatedOrders.length);
        subsegment.close();

        res.json({
            data: paginatedOrders,
            pagination: {
                total: userOrders.length,
                limit: parseInt(limit),
                offset: parseInt(offset),
                hasMore: endIndex < userOrders.length
            }
        });
    } catch (error) {
        subsegment.addError(error);
        subsegment.close();
        res.status(500).json({ error: 'Failed to fetch orders' });
    }
});

// GET /api/orders/order/:orderId - Get specific order details
router.get('/order/:orderId', (req, res) => {
    const segment = AWSXRay.getSegment();
    const subsegment = segment.addNewSubsegment('get-order-details');

    try {
        const { orderId } = req.params;
        const order = orders.find(o => o.id === orderId);

        if (!order) {
            subsegment.addAnnotation('order_found', false);
            subsegment.close();
            return res.status(404).json({ error: 'Order not found' });
        }

        subsegment.addAnnotation('order_found', true);
        subsegment.addAnnotation('order_id', orderId);
        subsegment.close();

        res.json({ data: order });
    } catch (error) {
        subsegment.addError(error);
        subsegment.close();
        res.status(500).json({ error: 'Failed to fetch order details' });
    }
});

// PUT /api/orders/order/:orderId/status - Update order status (admin endpoint)
router.put('/order/:orderId/status', (req, res) => {
    const segment = AWSXRay.getSegment();
    const subsegment = segment.addNewSubsegment('update-order-status');

    try {
        const { orderId } = req.params;
        const { status } = req.body;

        const validStatuses = ['confirmed', 'processing', 'shipped', 'delivered', 'cancelled'];

        if (!status || !validStatuses.includes(status)) {
            subsegment.addAnnotation('invalid_status', true);
            subsegment.close();
            return res.status(400).json({
                error: 'Invalid status',
                validStatuses
            });
        }

        const orderIndex = orders.findIndex(o => o.id === orderId);

        if (orderIndex === -1) {
            subsegment.addAnnotation('order_found', false);
            subsegment.close();
            return res.status(404).json({ error: 'Order not found' });
        }

        orders[orderIndex].status = status;
        orders[orderIndex].updatedAt = new Date().toISOString();

        // Add delivery date if status is delivered
        if (status === 'delivered') {
            orders[orderIndex].deliveredAt = new Date().toISOString();
        }

        subsegment.addAnnotation('order_status_updated', true);
        subsegment.addAnnotation('order_id', orderId);
        subsegment.addAnnotation('new_status', status);
        subsegment.close();

        res.json({
            message: 'Order status updated successfully',
            data: orders[orderIndex]
        });
    } catch (error) {
        subsegment.addError(error);
        subsegment.close();
        res.status(500).json({ error: 'Failed to update order status' });
    }
});

// GET /api/orders/stats - Get order statistics (admin endpoint)
router.get('/stats/summary', (req, res) => {
    const segment = AWSXRay.getSegment();
    const subsegment = segment.addNewSubsegment('get-order-stats');

    try {
        const totalOrders = orders.length;
        const totalRevenue = orders.reduce((sum, order) => sum + order.totals.total, 0);

        const statusCounts = orders.reduce((counts, order) => {
            counts[order.status] = (counts[order.status] || 0) + 1;
            return counts;
        }, {});

        const averageOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0;

        const stats = {
            totalOrders,
            totalRevenue: Math.round(totalRevenue * 100) / 100,
            averageOrderValue: Math.round(averageOrderValue * 100) / 100,
            statusBreakdown: statusCounts,
            generatedAt: new Date().toISOString()
        };

        subsegment.addAnnotation('stats_generated', true);
        subsegment.close();

        res.json({ data: stats });
    } catch (error) {
        subsegment.addError(error);
        subsegment.close();
        res.status(500).json({ error: 'Failed to generate order statistics' });
    }
});

// Make carts accessible to checkout module
// In production, this would be handled through shared database access
if (typeof global !== 'undefined') {
    global.carts = require('./cart').carts;
}

module.exports = router;