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
        console.log('🔍 X-Ray SDK loaded in cart routes');
    } catch (error) {
        console.log('⚠️ X-Ray not available in cart routes:', error.message);
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

// Helper function to get or create cart for session
async function getOrCreateCart(sessionId) {
    // Check if cart exists
    let result = await dbConnection.query(
        'SELECT id FROM carts WHERE user_id = $1',
        [sessionId]
    );

    if (result.rows.length === 0) {
        // Create new cart
        result = await dbConnection.query(
            'INSERT INTO carts (user_id) VALUES ($1) RETURNING id',
            [sessionId]
        );
    }

    return result.rows[0].id;
}

// Helper function to calculate cart totals
async function calculateCartTotals(cartId) {
    const result = await dbConnection.query(`
        SELECT 
            COALESCE(SUM(ci.price * ci.quantity), 0) as subtotal,
            COUNT(ci.id) as item_count
        FROM cart_items ci
        WHERE ci.cart_id = $1
    `, [cartId]);

    const subtotal = parseFloat(result.rows[0].subtotal || 0);
    const tax = subtotal * 0.08; // 8% tax
    const shipping = subtotal > 50 ? 0 : 9.99; // Free shipping over $50
    const total = subtotal + tax + shipping;

    return {
        subtotal: Math.round(subtotal * 100) / 100,
        tax: Math.round(tax * 100) / 100,
        shipping: Math.round(shipping * 100) / 100,
        total: Math.round(total * 100) / 100,
        itemCount: parseInt(result.rows[0].item_count || 0)
    };
}

// Validation schemas
const addItemSchema = Joi.object({
    productId: Joi.string().required(),
    quantity: Joi.number().integer().min(1).required(),
    price: Joi.number().positive().precision(2).required()
});

const updateItemSchema = Joi.object({
    quantity: Joi.number().integer().min(1).required()
});

// GET /api/cart/:sessionId - Get session's cart
router.get('/:sessionId', async (req, res) => {
    const subsegment = createSubsegment('get-cart');

    try {
        const { sessionId } = req.params;

        // Get or create cart
        const cartId = await getOrCreateCart(sessionId);

        // Get cart items with product details
        const itemsResult = await dbConnection.query(`
            SELECT 
                ci.id,
                ci.product_id as "productId",
                ci.quantity,
                ci.price,
                p.name as "productName",
                p.image_url as "imageUrl",
                ci.created_at as "addedAt",
                ci.updated_at as "updatedAt"
            FROM cart_items ci
            LEFT JOIN products p ON ci.product_id = p.id
            WHERE ci.cart_id = $1
            ORDER BY ci.created_at DESC
        `, [cartId]);

        const items = itemsResult.rows;
        const totals = await calculateCartTotals(cartId);

        useSubsegment(subsegment, 'addAnnotation')('session_id', sessionId);
        useSubsegment(subsegment, 'addAnnotation')('cart_items_count', items.length);
        useSubsegment(subsegment, 'close')();

        res.json({
            data: {
                sessionId,
                items,
                ...totals,
                createdAt: new Date().toISOString(),
                updatedAt: new Date().toISOString()
            }
        });
    } catch (error) {
        console.error('Get cart API error:', error);
        useSubsegment(subsegment, 'addError')(error);
        useSubsegment(subsegment, 'close')();
        res.status(500).json({ error: 'Failed to fetch cart' });
    }
});

// POST /api/cart/:sessionId/items - Add item to cart
router.post('/:sessionId/items', async (req, res) => {
    const subsegment = createSubsegment('add-cart-item');

    try {
        const { sessionId } = req.params;
        const { error, value } = addItemSchema.validate(req.body);

        if (error) {
            useSubsegment(subsegment, 'addAnnotation')('validation_error', true);
            useSubsegment(subsegment, 'close')();
            return res.status(400).json({
                error: 'Validation failed',
                details: error.details.map(d => d.message)
            });
        }

        const { productId, quantity, price } = value;

        // Verify product exists and is active
        const productResult = await dbConnection.query(
            'SELECT id, name, stock FROM products WHERE id = $1 AND is_active = true',
            [productId]
        );

        if (productResult.rows.length === 0) {
            useSubsegment(subsegment, 'addAnnotation')('product_found', false);
            useSubsegment(subsegment, 'close')();
            return res.status(404).json({ error: 'Product not found or inactive' });
        }

        const product = productResult.rows[0];

        // Check if enough stock is available
        if (product.stock < quantity) {
            useSubsegment(subsegment, 'addAnnotation')('insufficient_stock', true);
            useSubsegment(subsegment, 'close')();
            return res.status(400).json({
                error: 'Insufficient stock',
                available: product.stock,
                requested: quantity
            });
        }

        // Get or create cart
        const cartId = await getOrCreateCart(sessionId);

        // Check if item already exists in cart
        const existingItemResult = await dbConnection.query(
            'SELECT id, quantity FROM cart_items WHERE cart_id = $1 AND product_id = $2',
            [cartId, productId]
        );

        if (existingItemResult.rows.length > 0) {
            // Update existing item quantity
            const existingItem = existingItemResult.rows[0];
            const newQuantity = existingItem.quantity + quantity;

            await dbConnection.query(
                'UPDATE cart_items SET quantity = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2',
                [newQuantity, existingItem.id]
            );
        } else {
            // Add new item to cart
            await dbConnection.query(
                'INSERT INTO cart_items (cart_id, product_id, quantity, price) VALUES ($1, $2, $3, $4)',
                [cartId, productId, quantity, price]
            );
        }

        // Get updated cart with items
        const itemsResult = await dbConnection.query(`
            SELECT 
                ci.id,
                ci.product_id as "productId",
                ci.quantity,
                ci.price,
                p.name as "productName",
                p.image_url as "imageUrl",
                ci.created_at as "addedAt",
                ci.updated_at as "updatedAt"
            FROM cart_items ci
            LEFT JOIN products p ON ci.product_id = p.id
            WHERE ci.cart_id = $1
            ORDER BY ci.created_at DESC
        `, [cartId]);

        const items = itemsResult.rows;
        const totals = await calculateCartTotals(cartId);

        useSubsegment(subsegment, 'addAnnotation')('session_id', sessionId);
        useSubsegment(subsegment, 'addAnnotation')('product_id', productId);
        useSubsegment(subsegment, 'addAnnotation')('item_added', true);
        useSubsegment(subsegment, 'close')();

        res.status(201).json({
            message: 'Item added to cart successfully',
            data: {
                sessionId,
                items,
                ...totals
            }
        });
    } catch (error) {
        console.error('Add cart item API error:', error);
        useSubsegment(subsegment, 'addError')(error);
        useSubsegment(subsegment, 'close')();
        res.status(500).json({ error: 'Failed to add item to cart' });
    }
});

// PUT /api/cart/:sessionId/items/:itemId - Update cart item quantity
router.put('/:sessionId/items/:itemId', async (req, res) => {
    const subsegment = createSubsegment('update-cart-item');

    try {
        const { sessionId, itemId } = req.params;
        const { error, value } = updateItemSchema.validate(req.body);

        if (error) {
            useSubsegment(subsegment, 'addAnnotation')('validation_error', true);
            useSubsegment(subsegment, 'close')();
            return res.status(400).json({
                error: 'Validation failed',
                details: error.details.map(d => d.message)
            });
        }

        const { quantity } = value;

        // Get cart ID
        const cartResult = await dbConnection.query(
            'SELECT id FROM carts WHERE user_id = $1',
            [sessionId]
        );

        if (cartResult.rows.length === 0) {
            useSubsegment(subsegment, 'addAnnotation')('cart_found', false);
            useSubsegment(subsegment, 'close')();
            return res.status(404).json({ error: 'Cart not found' });
        }

        const cartId = cartResult.rows[0].id;

        // Check if cart item exists
        const itemResult = await dbConnection.query(
            'SELECT id, product_id FROM cart_items WHERE id = $1 AND cart_id = $2',
            [itemId, cartId]
        );

        if (itemResult.rows.length === 0) {
            useSubsegment(subsegment, 'addAnnotation')('item_found', false);
            useSubsegment(subsegment, 'close')();
            return res.status(404).json({ error: 'Item not found in cart' });
        }

        const item = itemResult.rows[0];

        // Verify product has enough stock
        const productResult = await dbConnection.query(
            'SELECT stock FROM products WHERE id = $1 AND is_active = true',
            [item.product_id]
        );

        if (productResult.rows.length === 0) {
            useSubsegment(subsegment, 'addAnnotation')('product_found', false);
            useSubsegment(subsegment, 'close')();
            return res.status(404).json({ error: 'Product not found or inactive' });
        }

        const product = productResult.rows[0];

        if (product.stock < quantity) {
            useSubsegment(subsegment, 'addAnnotation')('insufficient_stock', true);
            useSubsegment(subsegment, 'close')();
            return res.status(400).json({
                error: 'Insufficient stock',
                available: product.stock,
                requested: quantity
            });
        }

        // Update item quantity
        await dbConnection.query(
            'UPDATE cart_items SET quantity = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2',
            [quantity, itemId]
        );

        // Get updated cart with items
        const itemsResult = await dbConnection.query(`
            SELECT 
                ci.id,
                ci.product_id as "productId",
                ci.quantity,
                ci.price,
                p.name as "productName",
                p.image_url as "imageUrl",
                ci.created_at as "addedAt",
                ci.updated_at as "updatedAt"
            FROM cart_items ci
            LEFT JOIN products p ON ci.product_id = p.id
            WHERE ci.cart_id = $1
            ORDER BY ci.created_at DESC
        `, [cartId]);

        const items = itemsResult.rows;
        const totals = await calculateCartTotals(cartId);

        useSubsegment(subsegment, 'addAnnotation')('session_id', sessionId);
        useSubsegment(subsegment, 'addAnnotation')('item_id', itemId);
        useSubsegment(subsegment, 'addAnnotation')('item_updated', true);
        useSubsegment(subsegment, 'close')();

        res.json({
            message: 'Cart item updated successfully',
            data: {
                sessionId,
                items,
                ...totals
            }
        });
    } catch (error) {
        console.error('Update cart item API error:', error);
        useSubsegment(subsegment, 'addError')(error);
        useSubsegment(subsegment, 'close')();
        res.status(500).json({ error: 'Failed to update cart item' });
    }
});

// DELETE /api/cart/:sessionId/items/:itemId - Remove item from cart
router.delete('/:sessionId/items/:itemId', async (req, res) => {
    const subsegment = createSubsegment('remove-cart-item');

    try {
        const { sessionId, itemId } = req.params;

        // Get cart ID
        const cartResult = await dbConnection.query(
            'SELECT id FROM carts WHERE user_id = $1',
            [sessionId]
        );

        if (cartResult.rows.length === 0) {
            useSubsegment(subsegment, 'addAnnotation')('cart_found', false);
            useSubsegment(subsegment, 'close')();
            return res.status(404).json({ error: 'Cart not found' });
        }

        const cartId = cartResult.rows[0].id;

        // Check if cart item exists and delete it
        const deleteResult = await dbConnection.query(
            'DELETE FROM cart_items WHERE id = $1 AND cart_id = $2',
            [itemId, cartId]
        );

        if (deleteResult.rowCount === 0) {
            useSubsegment(subsegment, 'addAnnotation')('item_found', false);
            useSubsegment(subsegment, 'close')();
            return res.status(404).json({ error: 'Item not found in cart' });
        }

        // Get updated cart with items
        const itemsResult = await dbConnection.query(`
            SELECT 
                ci.id,
                ci.product_id as "productId",
                ci.quantity,
                ci.price,
                p.name as "productName",
                p.image_url as "imageUrl",
                ci.created_at as "addedAt",
                ci.updated_at as "updatedAt"
            FROM cart_items ci
            LEFT JOIN products p ON ci.product_id = p.id
            WHERE ci.cart_id = $1
            ORDER BY ci.created_at DESC
        `, [cartId]);

        const items = itemsResult.rows;
        const totals = await calculateCartTotals(cartId);

        useSubsegment(subsegment, 'addAnnotation')('session_id', sessionId);
        useSubsegment(subsegment, 'addAnnotation')('item_id', itemId);
        useSubsegment(subsegment, 'addAnnotation')('item_removed', true);
        useSubsegment(subsegment, 'close')();

        res.json({
            message: 'Item removed from cart successfully',
            data: {
                sessionId,
                items,
                ...totals
            }
        });
    } catch (error) {
        console.error('Remove cart item API error:', error);
        useSubsegment(subsegment, 'addError')(error);
        useSubsegment(subsegment, 'close')();
        res.status(500).json({ error: 'Failed to remove cart item' });
    }
});

// DELETE /api/cart/:sessionId - Clear entire cart
router.delete('/:sessionId', async (req, res) => {
    const subsegment = createSubsegment('clear-cart');

    try {
        const { sessionId } = req.params;

        // Get cart ID
        const cartResult = await dbConnection.query(
            'SELECT id FROM carts WHERE user_id = $1',
            [sessionId]
        );

        if (cartResult.rows.length === 0) {
            useSubsegment(subsegment, 'addAnnotation')('cart_found', false);
            useSubsegment(subsegment, 'close')();
            return res.status(404).json({ error: 'Cart not found' });
        }

        const cartId = cartResult.rows[0].id;

        // Clear all items from cart
        await dbConnection.query(
            'DELETE FROM cart_items WHERE cart_id = $1',
            [cartId]
        );

        // Update cart timestamp
        await dbConnection.query(
            'UPDATE carts SET updated_at = CURRENT_TIMESTAMP WHERE id = $1',
            [cartId]
        );

        const totals = await calculateCartTotals(cartId);

        useSubsegment(subsegment, 'addAnnotation')('session_id', sessionId);
        useSubsegment(subsegment, 'addAnnotation')('cart_cleared', true);
        useSubsegment(subsegment, 'close')();

        res.json({
            message: 'Cart cleared successfully',
            data: {
                sessionId,
                items: [],
                ...totals
            }
        });
    } catch (error) {
        console.error('Clear cart API error:', error);
        useSubsegment(subsegment, 'addError')(error);
        useSubsegment(subsegment, 'close')();
        res.status(500).json({ error: 'Failed to clear cart' });
    }
});

module.exports = router;