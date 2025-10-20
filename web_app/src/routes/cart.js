const express = require('express');
const Joi = require('joi');
const { v4: uuidv4 } = require('uuid');
const router = express.Router();

// AWS X-Ray setup (optional)
let AWSXRay;
try {
    AWSXRay = require('aws-xray-sdk-core');
} catch (error) {
    // Mock X-Ray for development
    AWSXRay = {
        getSegment: () => ({
            addNewSubsegment: () => ({
                addAnnotation: () => { },
                addError: () => { },
                close: () => { }
            })
        })
    };
}

// In-memory cart storage (in production, use DynamoDB/Redis)
const carts = {};

// Make carts accessible globally for checkout module
global.carts = carts;

// Validation schemas
const addItemSchema = Joi.object({
    productId: Joi.string().required(),
    quantity: Joi.number().integer().min(1).required(),
    price: Joi.number().positive().precision(2).required()
});

const updateItemSchema = Joi.object({
    quantity: Joi.number().integer().min(1).required()
});

// Helper function to calculate cart totals
function calculateCartTotals(cart) {
    const subtotal = cart.items.reduce((sum, item) => sum + (item.price * item.quantity), 0);
    const tax = subtotal * 0.08; // 8% tax
    const total = subtotal + tax;

    return {
        subtotal: Math.round(subtotal * 100) / 100,
        tax: Math.round(tax * 100) / 100,
        total: Math.round(total * 100) / 100
    };
}

// GET /api/cart/:userId - Get user's cart
router.get('/:userId', (req, res) => {
    const segment = AWSXRay.getSegment();
    const subsegment = segment.addNewSubsegment('get-cart');

    try {
        const { userId } = req.params;

        if (!carts[userId]) {
            carts[userId] = {
                userId,
                items: [],
                createdAt: new Date().toISOString(),
                updatedAt: new Date().toISOString()
            };
        }

        const cart = carts[userId];
        const totals = calculateCartTotals(cart);

        subsegment.addAnnotation('user_id', userId);
        subsegment.addAnnotation('cart_items_count', cart.items.length);
        subsegment.close();

        res.json({
            data: {
                ...cart,
                ...totals
            }
        });
    } catch (error) {
        subsegment.addError(error);
        subsegment.close();
        res.status(500).json({ error: 'Failed to fetch cart' });
    }
});

// POST /api/cart/:userId/items - Add item to cart
router.post('/:userId/items', (req, res) => {
    const segment = AWSXRay.getSegment();
    const subsegment = segment.addNewSubsegment('add-cart-item');

    try {
        const { userId } = req.params;
        const { error, value } = addItemSchema.validate(req.body);

        if (error) {
            subsegment.addAnnotation('validation_error', true);
            subsegment.close();
            return res.status(400).json({
                error: 'Validation failed',
                details: error.details.map(d => d.message)
            });
        }

        const { productId, quantity, price } = value;

        // Initialize cart if doesn't exist
        if (!carts[userId]) {
            carts[userId] = {
                userId,
                items: [],
                createdAt: new Date().toISOString(),
                updatedAt: new Date().toISOString()
            };
        }

        const cart = carts[userId];

        // Check if item already exists in cart
        const existingItemIndex = cart.items.findIndex(item => item.productId === productId);

        if (existingItemIndex !== -1) {
            // Update quantity if item exists
            cart.items[existingItemIndex].quantity += quantity;
            cart.items[existingItemIndex].updatedAt = new Date().toISOString();
        } else {
            // Add new item to cart
            const newItem = {
                id: uuidv4(),
                productId,
                quantity,
                price,
                addedAt: new Date().toISOString(),
                updatedAt: new Date().toISOString()
            };
            cart.items.push(newItem);
        }

        cart.updatedAt = new Date().toISOString();
        const totals = calculateCartTotals(cart);

        subsegment.addAnnotation('user_id', userId);
        subsegment.addAnnotation('product_id', productId);
        subsegment.addAnnotation('item_added', true);
        subsegment.close();

        res.status(201).json({
            message: 'Item added to cart successfully',
            data: {
                ...cart,
                ...totals
            }
        });
    } catch (error) {
        subsegment.addError(error);
        subsegment.close();
        res.status(500).json({ error: 'Failed to add item to cart' });
    }
});

// PUT /api/cart/:userId/items/:itemId - Update cart item quantity
router.put('/:userId/items/:itemId', (req, res) => {
    const segment = AWSXRay.getSegment();
    const subsegment = segment.addNewSubsegment('update-cart-item');

    try {
        const { userId, itemId } = req.params;
        const { error, value } = updateItemSchema.validate(req.body);

        if (error) {
            subsegment.addAnnotation('validation_error', true);
            subsegment.close();
            return res.status(400).json({
                error: 'Validation failed',
                details: error.details.map(d => d.message)
            });
        }

        const { quantity } = value;

        if (!carts[userId]) {
            subsegment.addAnnotation('cart_found', false);
            subsegment.close();
            return res.status(404).json({ error: 'Cart not found' });
        }

        const cart = carts[userId];
        const itemIndex = cart.items.findIndex(item => item.id === itemId);

        if (itemIndex === -1) {
            subsegment.addAnnotation('item_found', false);
            subsegment.close();
            return res.status(404).json({ error: 'Item not found in cart' });
        }

        cart.items[itemIndex].quantity = quantity;
        cart.items[itemIndex].updatedAt = new Date().toISOString();
        cart.updatedAt = new Date().toISOString();

        const totals = calculateCartTotals(cart);

        subsegment.addAnnotation('user_id', userId);
        subsegment.addAnnotation('item_id', itemId);
        subsegment.addAnnotation('item_updated', true);
        subsegment.close();

        res.json({
            message: 'Cart item updated successfully',
            data: {
                ...cart,
                ...totals
            }
        });
    } catch (error) {
        subsegment.addError(error);
        subsegment.close();
        res.status(500).json({ error: 'Failed to update cart item' });
    }
});

// DELETE /api/cart/:userId/items/:itemId - Remove item from cart
router.delete('/:userId/items/:itemId', (req, res) => {
    const segment = AWSXRay.getSegment();
    const subsegment = segment.addNewSubsegment('remove-cart-item');

    try {
        const { userId, itemId } = req.params;

        if (!carts[userId]) {
            subsegment.addAnnotation('cart_found', false);
            subsegment.close();
            return res.status(404).json({ error: 'Cart not found' });
        }

        const cart = carts[userId];
        const itemIndex = cart.items.findIndex(item => item.id === itemId);

        if (itemIndex === -1) {
            subsegment.addAnnotation('item_found', false);
            subsegment.close();
            return res.status(404).json({ error: 'Item not found in cart' });
        }

        cart.items.splice(itemIndex, 1);
        cart.updatedAt = new Date().toISOString();

        const totals = calculateCartTotals(cart);

        subsegment.addAnnotation('user_id', userId);
        subsegment.addAnnotation('item_id', itemId);
        subsegment.addAnnotation('item_removed', true);
        subsegment.close();

        res.json({
            message: 'Item removed from cart successfully',
            data: {
                ...cart,
                ...totals
            }
        });
    } catch (error) {
        subsegment.addError(error);
        subsegment.close();
        res.status(500).json({ error: 'Failed to remove cart item' });
    }
});

// DELETE /api/cart/:userId - Clear entire cart
router.delete('/:userId', (req, res) => {
    const segment = AWSXRay.getSegment();
    const subsegment = segment.addNewSubsegment('clear-cart');

    try {
        const { userId } = req.params;

        if (!carts[userId]) {
            subsegment.addAnnotation('cart_found', false);
            subsegment.close();
            return res.status(404).json({ error: 'Cart not found' });
        }

        carts[userId].items = [];
        carts[userId].updatedAt = new Date().toISOString();

        const totals = calculateCartTotals(carts[userId]);

        subsegment.addAnnotation('user_id', userId);
        subsegment.addAnnotation('cart_cleared', true);
        subsegment.close();

        res.json({
            message: 'Cart cleared successfully',
            data: {
                ...carts[userId],
                ...totals
            }
        });
    } catch (error) {
        subsegment.addError(error);
        subsegment.close();
        res.status(500).json({ error: 'Failed to clear cart' });
    }
});

module.exports = router;
module.exports.carts = carts;