const express = require('express');
const router = express.Router();
const dbConnection = require('../database/connection');

// AWS X-Ray setup
let AWSXRay;
if (process.env.DISABLE_XRAY !== 'true') {
    try {
        AWSXRay = require('aws-xray-sdk-core');
        console.log('🔍 X-Ray SDK loaded in database routes');
    } catch (error) {
        console.log('⚠️ X-Ray not available in database routes:', error.message);
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

// GET /api/database/tables - List all tables in the database
router.get('/tables', async (req, res) => {
    const subsegment = createSubsegment('list-database-tables');

    try {
        const result = await dbConnection.query(`
            SELECT table_name, table_type
            FROM information_schema.tables 
            WHERE table_schema = 'public'
            ORDER BY table_name;
        `);

        useSubsegment(subsegment, 'addAnnotation')('table_count', result.rows.length);
        useSubsegment(subsegment, 'close')();

        res.json({
            message: 'Database tables retrieved successfully',
            data: result.rows,
            count: result.rows.length
        });
    } catch (error) {
        useSubsegment(subsegment, 'addError')(error);
        useSubsegment(subsegment, 'close')();
        console.error('Database tables query error:', error);
        res.status(500).json({
            error: 'Failed to retrieve database tables',
            details: error.message
        });
    }
});

// GET /api/database/products - Get products from database
router.get('/products', async (req, res) => {
    const subsegment = createSubsegment('get-database-products');

    try {
        const result = await dbConnection.query(`
            SELECT 
                p.id,
                p.name,
                p.description,
                p.price,
                p.stock,
                p.image_url,
                p.sku,
                p.is_active,
                c.name as category_name,
                p.created_at,
                p.updated_at
            FROM products p
            LEFT JOIN categories c ON p.category_id = c.id
            WHERE p.is_active = true
            ORDER BY p.created_at DESC
            LIMIT 20;
        `);

        useSubsegment(subsegment, 'addAnnotation')('product_count', result.rows.length);
        useSubsegment(subsegment, 'close')();

        res.json({
            message: 'Database products retrieved successfully',
            data: result.rows,
            count: result.rows.length,
            source: 'database'
        });
    } catch (error) {
        useSubsegment(subsegment, 'addError')(error);
        useSubsegment(subsegment, 'close')();
        console.error('Database products query error:', error);
        res.status(500).json({
            error: 'Failed to retrieve database products',
            details: error.message
        });
    }
});

// GET /api/database/categories - Get categories from database
router.get('/categories', async (req, res) => {
    const subsegment = createSubsegment('get-database-categories');

    try {
        const result = await dbConnection.query(`
            SELECT 
                c.id,
                c.name,
                c.description,
                c.created_at,
                COUNT(p.id) as product_count
            FROM categories c
            LEFT JOIN products p ON c.id = p.category_id AND p.is_active = true
            GROUP BY c.id, c.name, c.description, c.created_at
            ORDER BY c.name;
        `);

        useSubsegment(subsegment, 'addAnnotation')('category_count', result.rows.length);
        useSubsegment(subsegment, 'close')();

        res.json({
            message: 'Database categories retrieved successfully',
            data: result.rows,
            count: result.rows.length,
            source: 'database'
        });
    } catch (error) {
        useSubsegment(subsegment, 'addError')(error);
        useSubsegment(subsegment, 'close')();
        console.error('Database categories query error:', error);
        res.status(500).json({
            error: 'Failed to retrieve database categories',
            details: error.message
        });
    }
});

// POST /api/database/populate - Populate database with initial data
router.post('/populate', async (req, res) => {
    const subsegment = createSubsegment('populate-database');

    try {
        // Check if data already exists
        const existingProducts = await dbConnection.query('SELECT COUNT(*) FROM products WHERE 1=1');
        const productCount = parseInt(existingProducts.rows[0].count);

        if (productCount > 0) {
            useSubsegment(subsegment, 'addAnnotation')('already_populated', true);
            useSubsegment(subsegment, 'close')();
            return res.json({
                message: 'Database already contains data',
                existing_products: productCount,
                action: 'none'
            });
        }

        // Create tables and populate data
        const { populateDatabase } = require('../../scripts/populate-rds');

        // Run population in the background to avoid timeout
        setImmediate(async () => {
            try {
                await populateDatabase();
                console.log('✅ Database population completed in background');
            } catch (error) {
                console.error('❌ Background database population failed:', error);
            }
        });

        useSubsegment(subsegment, 'addAnnotation')('population_started', true);
        useSubsegment(subsegment, 'close')();

        res.json({
            message: 'Database population started',
            status: 'in_progress',
            note: 'Population is running in the background. Check /api/database/products in a few moments.'
        });

    } catch (error) {
        useSubsegment(subsegment, 'addError')(error);
        useSubsegment(subsegment, 'close')();
        console.error('Database population error:', error);
        res.status(500).json({
            error: 'Failed to populate database',
            details: error.message
        });
    }
});

// GET /api/database/status - Get database status and statistics
router.get('/status', async (req, res) => {
    const subsegment = createSubsegment('get-database-status');

    try {
        const healthCheck = await dbConnection.healthCheck();

        // Get table counts
        const tables = ['categories', 'products', 'users', 'orders'];
        const tableCounts = {};

        for (const table of tables) {
            try {
                const result = await dbConnection.query(`SELECT COUNT(*) FROM ${table}`);
                tableCounts[table] = parseInt(result.rows[0].count);
            } catch (error) {
                tableCounts[table] = 'table_not_exists';
            }
        }

        useSubsegment(subsegment, 'addAnnotation')('database_healthy', healthCheck.status === 'healthy');
        useSubsegment(subsegment, 'close')();

        res.json({
            message: 'Database status retrieved successfully',
            health: healthCheck,
            table_counts: tableCounts,
            timestamp: new Date().toISOString()
        });

    } catch (error) {
        useSubsegment(subsegment, 'addError')(error);
        useSubsegment(subsegment, 'close')();
        console.error('Database status error:', error);
        res.status(500).json({
            error: 'Failed to get database status',
            details: error.message
        });
    }
});

module.exports = router;