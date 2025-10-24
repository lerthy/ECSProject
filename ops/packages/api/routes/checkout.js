const express = require('express');
const Joi = require('joi');
const { v4: uuidv4 } = require('uuid');
const dbConnection = require('../database/connection');
const router = express.Router();

// AWS X-Ray setup (optional)
let AWSXRay;
if (process.env.DISABLE_XRAY !== 'true') {
    try {
        AWSXRay = require('aws-xray-sdk-core');
        console.log('🔍 X-Ray SDK loaded in checkout routes');
    } catch (error) {
        console.log('⚠️ X-Ray not available in checkout routes:', error.message);
    }
}

// Mock X-Ray for development to prevent errors
if (!AWSXRay || process.env.DISABLE_XRAY === 'true') {
    AWSXRay = {
        getSegment: () => null
    };
}

// Helper function to safely create subsegments
function createSubsegment(name) {
    try {
        const segment = AWSXRay.getSegment();
        if (segment && segment.addNewSubsegment) {
            return segment.addNewSubsegment(name);
        }
    } catch (error) {
        // Ignore X-Ray errors
    }
    return null;
}

// Helper function to safely use subsegment
function useSubsegment(subsegment, action) {
    if (subsegment && typeof subsegment[action] === 'function') {
        return (...args) => {
            try {
                return subsegment[action](...args);
            } catch (error) {
                // Ignore X-Ray errors
                return null;
            }
        };
    }
    return (...args) => null; // No-op function that accepts any arguments
}

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
function processPayment() {
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
    const subsegment = createSubsegment('process-checkout');

    try {
        const { userId } = req.params;
        const { error, value } = checkoutSchema.validate(req.body);

        if (error) {
            useSubsegment(subsegment, 'addAnnotation')('validation_error', true);
            useSubsegment(subsegment, 'close')();
            return res.status(400).json({
                error: 'Validation failed',
                details: error.details.map(d => d.message)
            });
        }

        const { shippingAddress, paymentMethod } = value;

        // Get user's cart from database
        const cartResult = await dbConnection.query(
            'SELECT id FROM carts WHERE user_id = $1',
            [userId]
        );

        if (cartResult.rows.length === 0) {
            useSubsegment(subsegment, 'addAnnotation')('cart_not_found', true);
            useSubsegment(subsegment, 'close')();
            return res.status(400).json({ error: 'Cart not found' });
        }

        const cartId = cartResult.rows[0].id;

        // Get cart items
        const itemsResult = await dbConnection.query(`
            SELECT 
                ci.id,
                ci.product_id,
                ci.quantity,
                ci.price,
                p.name as product_name,
                p.stock
            FROM cart_items ci
            JOIN products p ON ci.product_id = p.id
            WHERE ci.cart_id = $1 AND p.is_active = true
        `, [cartId]);

        const cartItems = itemsResult.rows;

        if (cartItems.length === 0) {
            useSubsegment(subsegment, 'addAnnotation')('cart_empty', true);
            useSubsegment(subsegment, 'close')();
            return res.status(400).json({ error: 'Cart is empty' });
        }

        // Check stock availability for all items
        for (const item of cartItems) {
            if (item.stock < item.quantity) {
                useSubsegment(subsegment, 'addAnnotation')('insufficient_stock', true);
                useSubsegment(subsegment, 'close')();
                return res.status(400).json({
                    error: 'Insufficient stock',
                    product: item.product_name,
                    available: item.stock,
                    requested: item.quantity
                });
            }
        }

        // Calculate order totals
        const totals = calculateOrderTotals(cartItems);

        // Process payment
        useSubsegment(subsegment, 'addAnnotation')('processing_payment', true);
        const paymentResult = await processPayment();

        if (!paymentResult.success) {
            useSubsegment(subsegment, 'addAnnotation')('payment_failed', true);
            useSubsegment(subsegment, 'close')();
            return res.status(400).json({
                error: 'Payment failed',
                message: paymentResult.message
            });
        }

        // Use database transaction to ensure data consistency
        await dbConnection.transaction(async (transaction) => {
            // Create order
            const orderResult = await transaction.query(`
                INSERT INTO orders (user_id, status, subtotal, tax, total, shipping_address, payment_method)
                VALUES ($1, $2, $3, $4, $5, $6, $7)
                RETURNING id, created_at
            `, [
                userId,
                'confirmed',
                totals.subtotal,
                totals.tax,
                totals.total,
                JSON.stringify(shippingAddress),
                JSON.stringify({
                    type: paymentMethod.type,
                    transactionId: paymentResult.transactionId,
                    ...(paymentMethod.type === 'paypal' ? { email: paymentMethod.email } : {})
                })
            ]);

            const order = orderResult.rows[0];

            // Create order items and update product stock
            for (const item of cartItems) {
                // Insert order item
                await transaction.query(`
                    INSERT INTO order_items (order_id, product_id, product_name, quantity, price)
                    VALUES ($1, $2, $3, $4, $5)
                `, [order.id, item.product_id, item.product_name, item.quantity, item.price]);

                // Update product stock
                await transaction.query(`
                    UPDATE products 
                    SET stock = stock - $1, updated_at = CURRENT_TIMESTAMP
                    WHERE id = $2
                `, [item.quantity, item.product_id]);
            }

            // Clear cart items
            await transaction.query(
                'DELETE FROM cart_items WHERE cart_id = $1',
                [cartId]
            );

            return order;
        });

        useSubsegment(subsegment, 'addAnnotation')('order_created', true);
        useSubsegment(subsegment, 'addAnnotation')('order_total', totals.total);
        useSubsegment(subsegment, 'close')();

        res.status(201).json({
            message: 'Order placed successfully',
            data: {
                orderId: 'Will be returned from transaction',
                userId,
                status: 'confirmed',
                totals,
                estimatedDelivery: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
                transactionId: paymentResult.transactionId
            }
        });
    } catch (error) {
        console.error('Checkout API error:', error);
        useSubsegment(subsegment, 'addError')(error);
        useSubsegment(subsegment, 'close')();
        res.status(500).json({ error: 'Failed to process checkout' });
    }
});

// GET /api/orders/:userId - Get user's orders
router.get('/:userId', async (req, res) => {
    const subsegment = createSubsegment('get-user-orders');

    try {
        const { userId } = req.params;
        const { limit = 10, offset = 0, status } = req.query;

        // Build query
        let queryText = `
            SELECT 
                o.id,
                o.user_id as "userId",
                o.status,
                o.subtotal,
                o.tax,
                o.total,
                o.shipping_address as "shippingAddress",
                o.payment_method as "paymentMethod",
                o.created_at as "createdAt",
                o.updated_at as "updatedAt"
            FROM orders o
            WHERE o.user_id = $1
        `;

        const queryParams = [userId];
        let paramCount = 2;

        if (status) {
            queryText += ` AND o.status = $${paramCount}`;
            queryParams.push(status);
            paramCount++;
        }

        queryText += ` ORDER BY o.created_at DESC LIMIT $${paramCount} OFFSET $${paramCount + 1}`;
        queryParams.push(parseInt(limit), parseInt(offset));

        const ordersResult = await dbConnection.query(queryText, queryParams);

        // Get order items for each order
        const ordersWithItems = await Promise.all(
            ordersResult.rows.map(async (order) => {
                const itemsResult = await dbConnection.query(`
                    SELECT 
                        oi.id,
                        oi.product_id as "productId",
                        oi.product_name as "productName",
                        oi.quantity,
                        oi.price,
                        oi.created_at as "createdAt"
                    FROM order_items oi
                    WHERE oi.order_id = $1
                    ORDER BY oi.created_at
                `, [order.id]);

                return {
                    ...order,
                    items: itemsResult.rows,
                    totals: {
                        subtotal: parseFloat(order.subtotal),
                        tax: parseFloat(order.tax),
                        total: parseFloat(order.total)
                    }
                };
            })
        );

        // Get total count for pagination
        let countQuery = 'SELECT COUNT(*) as total FROM orders WHERE user_id = $1';
        const countParams = [userId];

        if (status) {
            countQuery += ' AND status = $2';
            countParams.push(status);
        }

        const countResult = await dbConnection.query(countQuery, countParams);
        const totalCount = parseInt(countResult.rows[0].total);

        useSubsegment(subsegment, 'addAnnotation')('user_id', userId);
        useSubsegment(subsegment, 'addAnnotation')('orders_count', ordersWithItems.length);
        useSubsegment(subsegment, 'close')();

        res.json({
            data: ordersWithItems,
            pagination: {
                total: totalCount,
                limit: parseInt(limit),
                offset: parseInt(offset),
                hasMore: (parseInt(offset) + parseInt(limit)) < totalCount
            }
        });
    } catch (error) {
        console.error('Get orders API error:', error);
        useSubsegment(subsegment, 'addError')(error);
        useSubsegment(subsegment, 'close')();
        res.status(500).json({ error: 'Failed to fetch orders' });
    }
});

// GET /api/orders/order/:orderId - Get specific order details
router.get('/order/:orderId', (req, res) => {
    const subsegment = createSubsegment('get-order-details');

    try {
        const { orderId } = req.params;
        const order = orders.find(o => o.id === orderId);

        if (!order) {
            useSubsegment(subsegment, 'addAnnotation')('order_found', false);
            useSubsegment(subsegment, 'close')();
            return res.status(404).json({ error: 'Order not found' });
        }

        useSubsegment(subsegment, 'addAnnotation')('order_found', true);
        useSubsegment(subsegment, 'addAnnotation')('order_id', orderId);
        useSubsegment(subsegment, 'close')();

        res.json({ data: order });
    } catch (error) {
        useSubsegment(subsegment, 'addError')(error);
        useSubsegment(subsegment, 'close')();
        res.status(500).json({ error: 'Failed to fetch order details' });
    }
});

// PUT /api/orders/order/:orderId/status - Update order status (admin endpoint)
router.put('/order/:orderId/status', (req, res) => {
    const subsegment = createSubsegment('update-order-status');

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