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

// In-memory product storage (in production, use DynamoDB/RDS)
const products = [
    {
        id: '1',
        name: 'Wireless Headphones',
        description: 'High-quality wireless headphones with noise cancellation',
        price: 199.99,
        category: 'Electronics',
        stock: 50,
        imageUrl: 'https://example.com/headphones.jpg',
        createdAt: new Date().toISOString()
    },
    {
        id: '2',
        name: 'Smartphone',
        description: 'Latest model smartphone with advanced features',
        price: 799.99,
        category: 'Electronics',
        stock: 30,
        imageUrl: 'https://example.com/smartphone.jpg',
        createdAt: new Date().toISOString()
    },
    {
        id: '3',
        name: 'Running Shoes',
        description: 'Comfortable running shoes for all terrains',
        price: 129.99,
        category: 'Sports',
        stock: 100,
        imageUrl: 'https://example.com/shoes.jpg',
        createdAt: new Date().toISOString()
    }
];

// Validation schemas
const productSchema = Joi.object({
    name: Joi.string().min(1).max(100).required(),
    description: Joi.string().min(1).max(500).required(),
    price: Joi.number().positive().precision(2).required(),
    category: Joi.string().min(1).max(50).required(),
    stock: Joi.number().integer().min(0).required(),
    imageUrl: Joi.string().uri().optional()
});

// GET /api/products - Get all products
router.get('/', (req, res) => {
    const segment = AWSXRay.getSegment();
    const subsegment = segment.addNewSubsegment('get-products');

    try {
        const { category, minPrice, maxPrice, limit = 20, offset = 0 } = req.query;

        let filteredProducts = [...products];

        // Filter by category
        if (category) {
            filteredProducts = filteredProducts.filter(p =>
                p.category.toLowerCase() === category.toLowerCase()
            );
        }

        // Filter by price range
        if (minPrice) {
            filteredProducts = filteredProducts.filter(p => p.price >= parseFloat(minPrice));
        }
        if (maxPrice) {
            filteredProducts = filteredProducts.filter(p => p.price <= parseFloat(maxPrice));
        }

        // Pagination
        const startIndex = parseInt(offset);
        const endIndex = startIndex + parseInt(limit);
        const paginatedProducts = filteredProducts.slice(startIndex, endIndex);

        subsegment.addAnnotation('product_count', paginatedProducts.length);
        subsegment.close();

        res.json({
            data: paginatedProducts,
            pagination: {
                total: filteredProducts.length,
                limit: parseInt(limit),
                offset: parseInt(offset),
                hasMore: endIndex < filteredProducts.length
            }
        });
    } catch (error) {
        subsegment.addError(error);
        subsegment.close();
        res.status(500).json({ error: 'Failed to fetch products' });
    }
});

// GET /api/products/:id - Get product by ID
router.get('/:id', (req, res) => {
    const segment = AWSXRay.getSegment();
    const subsegment = segment.addNewSubsegment('get-product-by-id');

    try {
        const { id } = req.params;
        const product = products.find(p => p.id === id);

        if (!product) {
            subsegment.addAnnotation('product_found', false);
            subsegment.close();
            return res.status(404).json({ error: 'Product not found' });
        }

        subsegment.addAnnotation('product_found', true);
        subsegment.addAnnotation('product_id', id);
        subsegment.close();

        res.json({ data: product });
    } catch (error) {
        subsegment.addError(error);
        subsegment.close();
        res.status(500).json({ error: 'Failed to fetch product' });
    }
});

// POST /api/products - Create new product (admin endpoint)
router.post('/', (req, res) => {
    const segment = AWSXRay.getSegment();
    const subsegment = segment.addNewSubsegment('create-product');

    try {
        const { error, value } = productSchema.validate(req.body);

        if (error) {
            subsegment.addAnnotation('validation_error', true);
            subsegment.close();
            return res.status(400).json({
                error: 'Validation failed',
                details: error.details.map(d => d.message)
            });
        }

        const newProduct = {
            id: uuidv4(),
            ...value,
            createdAt: new Date().toISOString()
        };

        products.push(newProduct);

        subsegment.addAnnotation('product_created', true);
        subsegment.addAnnotation('product_id', newProduct.id);
        subsegment.close();

        res.status(201).json({
            message: 'Product created successfully',
            data: newProduct
        });
    } catch (error) {
        subsegment.addError(error);
        subsegment.close();
        res.status(500).json({ error: 'Failed to create product' });
    }
});

// PUT /api/products/:id - Update product
router.put('/:id', (req, res) => {
    const segment = AWSXRay.getSegment();
    const subsegment = segment.addNewSubsegment('update-product');

    try {
        const { id } = req.params;
        const productIndex = products.findIndex(p => p.id === id);

        if (productIndex === -1) {
            subsegment.addAnnotation('product_found', false);
            subsegment.close();
            return res.status(404).json({ error: 'Product not found' });
        }

        const { error, value } = productSchema.validate(req.body);

        if (error) {
            subsegment.addAnnotation('validation_error', true);
            subsegment.close();
            return res.status(400).json({
                error: 'Validation failed',
                details: error.details.map(d => d.message)
            });
        }

        products[productIndex] = {
            ...products[productIndex],
            ...value,
            updatedAt: new Date().toISOString()
        };

        subsegment.addAnnotation('product_updated', true);
        subsegment.addAnnotation('product_id', id);
        subsegment.close();

        res.json({
            message: 'Product updated successfully',
            data: products[productIndex]
        });
    } catch (error) {
        subsegment.addError(error);
        subsegment.close();
        res.status(500).json({ error: 'Failed to update product' });
    }
});

// DELETE /api/products/:id - Delete product
router.delete('/:id', (req, res) => {
    const segment = AWSXRay.getSegment();
    const subsegment = segment.addNewSubsegment('delete-product');

    try {
        const { id } = req.params;
        const productIndex = products.findIndex(p => p.id === id);

        if (productIndex === -1) {
            subsegment.addAnnotation('product_found', false);
            subsegment.close();
            return res.status(404).json({ error: 'Product not found' });
        }

        products.splice(productIndex, 1);

        subsegment.addAnnotation('product_deleted', true);
        subsegment.addAnnotation('product_id', id);
        subsegment.close();

        res.json({ message: 'Product deleted successfully' });
    } catch (error) {
        subsegment.addError(error);
        subsegment.close();
        res.status(500).json({ error: 'Failed to delete product' });
    }
});

module.exports = router;