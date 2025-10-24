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
        console.log('🔍 X-Ray SDK loaded in products routes');
    } catch (error) {
        console.log('⚠️ X-Ray not available in products routes:', error.message);
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
            }
        };
    }
    return () => { }; // No-op function
}

// Validation schemas
const productSchema = Joi.object({
    name: Joi.string().min(1).max(100).required(),
    description: Joi.string().min(1).max(500).required(),
    price: Joi.number().positive().precision(2).required(),
    category: Joi.string().min(1).max(50).required(),
    stock: Joi.number().integer().min(0).required(),
    imageUrl: Joi.string().uri().optional()
});

// GET /api/products/categories - Get all categories
router.get('/categories', async (req, res) => {
    const subsegment = createSubsegment('get-categories');

    try {
        const result = await dbConnection.query(`
            SELECT 
                c.id,
                c.name,
                c.description,
                COUNT(p.id) as product_count
            FROM categories c
            LEFT JOIN products p ON c.id = p.category_id AND p.is_active = true
            GROUP BY c.id, c.name, c.description
            ORDER BY c.name
        `);

        const categories = result.rows.map(category => ({
            id: category.id,
            name: category.name,
            description: category.description,
            productCount: parseInt(category.product_count)
        }));

        useSubsegment(subsegment, 'addAnnotation')('categories_count', categories.length);
        useSubsegment(subsegment, 'close')();

        res.json({
            data: categories
        });
    } catch (error) {
        console.error('Categories API error:', error);
        useSubsegment(subsegment, 'addError')(error);
        useSubsegment(subsegment, 'close')();
        res.status(500).json({ error: 'Failed to fetch categories' });
    }
});

// GET /api/products - Get all products
router.get('/', async (req, res) => {
    const subsegment = createSubsegment('get-products');

    try {
        const { category, minPrice, maxPrice, limit = 20, offset = 0 } = req.query;

        // Build the SQL query with filters
        let queryText = `
            SELECT 
                p.id,
                p.name,
                p.description,
                p.price,
                p.stock,
                p.image_url as "imageUrl",
                p.sku,
                p.is_active,
                c.name as category,
                p.created_at as "createdAt",
                p.updated_at as "updatedAt"
            FROM products p
            LEFT JOIN categories c ON p.category_id = c.id
            WHERE p.is_active = true
        `;

        const queryParams = [];
        let paramCount = 1;

        // Filter by category
        if (category) {
            queryText += ` AND LOWER(c.name) = LOWER($${paramCount})`;
            queryParams.push(category);
            paramCount++;
        }

        // Filter by price range
        if (minPrice) {
            queryText += ` AND p.price >= $${paramCount}`;
            queryParams.push(parseFloat(minPrice));
            paramCount++;
        }
        if (maxPrice) {
            queryText += ` AND p.price <= $${paramCount}`;
            queryParams.push(parseFloat(maxPrice));
            paramCount++;
        }

        // Add ordering and pagination
        queryText += ` ORDER BY p.created_at DESC LIMIT $${paramCount} OFFSET $${paramCount + 1}`;
        queryParams.push(parseInt(limit), parseInt(offset));

        // Execute the query
        const result = await dbConnection.query(queryText, queryParams);
        const products = result.rows;

        // Get total count for pagination (without limit/offset)
        let countQuery = `
            SELECT COUNT(*) as total
            FROM products p
            LEFT JOIN categories c ON p.category_id = c.id
            WHERE p.is_active = true
        `;

        const countParams = [];
        let countParamCount = 1;

        if (category) {
            countQuery += ` AND LOWER(c.name) = LOWER($${countParamCount})`;
            countParams.push(category);
            countParamCount++;
        }
        if (minPrice) {
            countQuery += ` AND p.price >= $${countParamCount}`;
            countParams.push(parseFloat(minPrice));
            countParamCount++;
        }
        if (maxPrice) {
            countQuery += ` AND p.price <= $${countParamCount}`;
            countParams.push(parseFloat(maxPrice));
            countParamCount++;
        }

        const countResult = await dbConnection.query(countQuery, countParams);
        const totalCount = parseInt(countResult.rows[0].total);

        useSubsegment(subsegment, 'addAnnotation')('product_count', products.length);
        useSubsegment(subsegment, 'addAnnotation')('total_count', totalCount);
        useSubsegment(subsegment, 'close')();

        res.json({
            data: products,
            pagination: {
                total: totalCount,
                limit: parseInt(limit),
                offset: parseInt(offset),
                hasMore: (parseInt(offset) + parseInt(limit)) < totalCount
            }
        });
    } catch (error) {
        console.error('Products API error:', error);
        useSubsegment(subsegment, 'addError')(error);
        useSubsegment(subsegment, 'close')();
        res.status(500).json({ error: 'Failed to fetch products' });
    }
});

// GET /api/products/:id - Get product by ID
router.get('/:id', async (req, res) => {
    const subsegment = createSubsegment('get-product-by-id');

    try {
        const { id } = req.params;

        const result = await dbConnection.query(`
            SELECT 
                p.id,
                p.name,
                p.description,
                p.price,
                p.stock,
                p.image_url as "imageUrl",
                p.sku,
                p.is_active,
                c.name as category,
                p.created_at as "createdAt",
                p.updated_at as "updatedAt"
            FROM products p
            LEFT JOIN categories c ON p.category_id = c.id
            WHERE p.id = $1 AND p.is_active = true
        `, [id]);

        if (result.rows.length === 0) {
            useSubsegment(subsegment, 'addAnnotation')('product_found', false);
            useSubsegment(subsegment, 'close')();
            return res.status(404).json({ error: 'Product not found' });
        }

        const product = result.rows[0];

        useSubsegment(subsegment, 'addAnnotation')('product_found', true);
        useSubsegment(subsegment, 'addAnnotation')('product_id', id);
        useSubsegment(subsegment, 'close')();

        res.json({ data: product });
    } catch (error) {
        console.error('Product by ID API error:', error);
        useSubsegment(subsegment, 'addError')(error);
        useSubsegment(subsegment, 'close')();
        res.status(500).json({ error: 'Failed to fetch product' });
    }
});

// POST /api/products - Create new product (admin endpoint)
router.post('/', async (req, res) => {
    const subsegment = createSubsegment('create-product');

    try {
        const { error, value } = productSchema.validate(req.body);

        if (error) {
            useSubsegment(subsegment, 'addAnnotation')('validation_error', true);
            useSubsegment(subsegment, 'close')();
            return res.status(400).json({
                error: 'Validation failed',
                details: error.details.map(d => d.message)
            });
        }

        const { name, description, price, category, stock, imageUrl } = value;

        // Find or create category
        let categoryResult = await dbConnection.query(
            'SELECT id FROM categories WHERE LOWER(name) = LOWER($1)',
            [category]
        );

        let categoryId;
        if (categoryResult.rows.length === 0) {
            // Create new category
            const newCategoryResult = await dbConnection.query(
                'INSERT INTO categories (name, description) VALUES ($1, $2) RETURNING id',
                [category, `Category for ${category} products`]
            );
            categoryId = newCategoryResult.rows[0].id;
        } else {
            categoryId = categoryResult.rows[0].id;
        }

        // Generate SKU
        const sku = `${category.substring(0, 2).toUpperCase()}-${Date.now()}`;

        // Insert product
        const result = await dbConnection.query(`
            INSERT INTO products (name, description, price, stock, category_id, image_url, sku, is_active)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
            RETURNING *
        `, [name, description, price, stock, categoryId, imageUrl || null, sku, true]);

        const newProduct = result.rows[0];

        useSubsegment(subsegment, 'addAnnotation')('product_created', true);
        useSubsegment(subsegment, 'addAnnotation')('product_id', newProduct.id);
        useSubsegment(subsegment, 'close')();

        res.status(201).json({
            message: 'Product created successfully',
            data: {
                id: newProduct.id,
                name: newProduct.name,
                description: newProduct.description,
                price: parseFloat(newProduct.price),
                category: category,
                stock: newProduct.stock,
                imageUrl: newProduct.image_url,
                sku: newProduct.sku,
                createdAt: newProduct.created_at
            }
        });
    } catch (error) {
        console.error('Create product API error:', error);
        useSubsegment(subsegment, 'addError')(error);
        useSubsegment(subsegment, 'close')();
        res.status(500).json({ error: 'Failed to create product' });
    }
});

// PUT /api/products/:id - Update product
router.put('/:id', async (req, res) => {
    const subsegment = createSubsegment('update-product');

    try {
        const { id } = req.params;

        // Check if product exists
        const existingProduct = await dbConnection.query(
            'SELECT id FROM products WHERE id = $1 AND is_active = true',
            [id]
        );

        if (existingProduct.rows.length === 0) {
            useSubsegment(subsegment, 'addAnnotation')('product_found', false);
            useSubsegment(subsegment, 'close')();
            return res.status(404).json({ error: 'Product not found' });
        }

        const { error, value } = productSchema.validate(req.body);

        if (error) {
            useSubsegment(subsegment, 'addAnnotation')('validation_error', true);
            useSubsegment(subsegment, 'close')();
            return res.status(400).json({
                error: 'Validation failed',
                details: error.details.map(d => d.message)
            });
        }

        const { name, description, price, category, stock, imageUrl } = value;

        // Find or create category
        let categoryResult = await dbConnection.query(
            'SELECT id FROM categories WHERE LOWER(name) = LOWER($1)',
            [category]
        );

        let categoryId;
        if (categoryResult.rows.length === 0) {
            // Create new category
            const newCategoryResult = await dbConnection.query(
                'INSERT INTO categories (name, description) VALUES ($1, $2) RETURNING id',
                [category, `Category for ${category} products`]
            );
            categoryId = newCategoryResult.rows[0].id;
        } else {
            categoryId = categoryResult.rows[0].id;
        }

        // Update product
        const result = await dbConnection.query(`
            UPDATE products 
            SET name = $1, description = $2, price = $3, stock = $4, 
                category_id = $5, image_url = $6, updated_at = CURRENT_TIMESTAMP
            WHERE id = $7 AND is_active = true
            RETURNING *
        `, [name, description, price, stock, categoryId, imageUrl || null, id]);

        const updatedProduct = result.rows[0];

        useSubsegment(subsegment, 'addAnnotation')('product_updated', true);
        useSubsegment(subsegment, 'addAnnotation')('product_id', id);
        useSubsegment(subsegment, 'close')();

        res.json({
            message: 'Product updated successfully',
            data: {
                id: updatedProduct.id,
                name: updatedProduct.name,
                description: updatedProduct.description,
                price: parseFloat(updatedProduct.price),
                category: category,
                stock: updatedProduct.stock,
                imageUrl: updatedProduct.image_url,
                updatedAt: updatedProduct.updated_at
            }
        });
    } catch (error) {
        console.error('Update product API error:', error);
        useSubsegment(subsegment, 'addError')(error);
        useSubsegment(subsegment, 'close')();
        res.status(500).json({ error: 'Failed to update product' });
    }
});

// DELETE /api/products/:id - Delete product (soft delete)
router.delete('/:id', async (req, res) => {
    const subsegment = createSubsegment('delete-product');

    try {
        const { id } = req.params;

        // Check if product exists
        const existingProduct = await dbConnection.query(
            'SELECT id FROM products WHERE id = $1 AND is_active = true',
            [id]
        );

        if (existingProduct.rows.length === 0) {
            useSubsegment(subsegment, 'addAnnotation')('product_found', false);
            useSubsegment(subsegment, 'close')();
            return res.status(404).json({ error: 'Product not found' });
        }

        // Soft delete - set is_active to false
        await dbConnection.query(
            'UPDATE products SET is_active = false, updated_at = CURRENT_TIMESTAMP WHERE id = $1',
            [id]
        );

        useSubsegment(subsegment, 'addAnnotation')('product_deleted', true);
        useSubsegment(subsegment, 'addAnnotation')('product_id', id);
        useSubsegment(subsegment, 'close')();

        res.json({ message: 'Product deleted successfully' });
    } catch (error) {
        console.error('Delete product API error:', error);
        useSubsegment(subsegment, 'addError')(error);
        useSubsegment(subsegment, 'close')();
        res.status(500).json({ error: 'Failed to delete product' });
    }
});

module.exports = router;