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
        // Check if products table exists and has data
        let productCount = 0;
        try {
            const existingProducts = await dbConnection.query('SELECT COUNT(*) FROM products WHERE 1=1');
            productCount = parseInt(existingProducts.rows[0].count);
        } catch (error) {
            // Table doesn't exist yet, which is fine
            console.log('Products table does not exist yet, proceeding with population');
        }

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
        const { populateDatabase } = require('../scripts/populate-rds');

        // Run population synchronously to ensure completion
        await populateDatabase();
        console.log('✅ Database population completed successfully');

        useSubsegment(subsegment, 'addAnnotation')('population_completed', true);
        useSubsegment(subsegment, 'close')();

        // Get final counts
        const categoriesResult = await dbConnection.query('SELECT COUNT(*) FROM categories');
        const productsResult = await dbConnection.query('SELECT COUNT(*) FROM products');

        res.json({
            message: 'Database population completed successfully',
            status: 'completed',
            results: {
                categories_created: parseInt(categoriesResult.rows[0].count),
                products_created: parseInt(productsResult.rows[0].count)
            }
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

// POST /api/database/create-tables - Create tables and populate with sample data (inline)
router.post('/create-tables', async (req, res) => {
    const subsegment = createSubsegment('create-database-tables');

    try {
        console.log('🚀 Starting inline database table creation...');

        // Create UUID extension if not exists
        await dbConnection.query('CREATE EXTENSION IF NOT EXISTS "uuid-ossp"');
        console.log('✅ UUID extension created');

        // Create categories table
        await dbConnection.query(`
            CREATE TABLE IF NOT EXISTS categories (
                id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                name VARCHAR(100) UNIQUE NOT NULL,
                description TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        `);
        console.log('✅ Categories table created');

        // Create products table
        await dbConnection.query(`
            CREATE TABLE IF NOT EXISTS products (
                id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                name VARCHAR(255) NOT NULL,
                description TEXT,
                price DECIMAL(10,2) NOT NULL CHECK (price >= 0),
                stock INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0),
                category_id UUID REFERENCES categories(id),
                image_url VARCHAR(500),
                sku VARCHAR(100) UNIQUE,
                is_active BOOLEAN DEFAULT true,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        `);
        console.log('✅ Products table created');

        // Insert categories
        const categoriesData = [
            ['Electronics', 'Electronic devices and gadgets'],
            ['Sports', 'Sports equipment and apparel'],
            ['Books', 'Books and educational materials'],
            ['Home & Garden', 'Home improvement and garden supplies'],
            ['Clothing', 'Fashion and apparel']
        ];

        for (const [name, description] of categoriesData) {
            try {
                await dbConnection.query(
                    'INSERT INTO categories (name, description) VALUES ($1, $2) ON CONFLICT (name) DO NOTHING',
                    [name, description]
                );
                console.log(`✅ Category inserted: ${name}`);
            } catch (error) {
                console.log(`⚠️  Category ${name} already exists or error:`, error.message);
            }
        }

        // Get category IDs
        const electronicsResult = await dbConnection.query(
            'SELECT id FROM categories WHERE name = $1', ['Electronics']
        );
        const sportsResult = await dbConnection.query(
            'SELECT id FROM categories WHERE name = $1', ['Sports']
        );

        if (electronicsResult.rows.length === 0 || sportsResult.rows.length === 0) {
            throw new Error('Categories not found after insertion');
        }

        const electronicsId = electronicsResult.rows[0].id;
        const sportsId = sportsResult.rows[0].id;

        // Insert products
        const productsData = [
            ['Wireless Headphones', 'High-quality wireless headphones with noise cancellation', 199.99, 50, electronicsId, 'WH-001'],
            ['Smartphone', 'Latest model smartphone with advanced features', 799.99, 30, electronicsId, 'SP-002'],
            ['Running Shoes', 'Comfortable running shoes for all terrains', 129.99, 100, sportsId, 'RS-003'],
            ['Gaming Laptop', 'High-performance gaming laptop with RTX graphics', 1499.99, 15, electronicsId, 'GL-004'],
            ['Fitness Tracker', 'Advanced fitness tracker with heart rate monitoring', 249.99, 80, sportsId, 'FT-005']
        ];

        for (const [name, description, price, stock, categoryId, sku] of productsData) {
            try {
                await dbConnection.query(
                    'INSERT INTO products (name, description, price, stock, category_id, sku) VALUES ($1, $2, $3, $4, $5, $6) ON CONFLICT (sku) DO NOTHING',
                    [name, description, price, stock, categoryId, sku]
                );
                console.log(`✅ Product inserted: ${name}`);
            } catch (error) {
                console.log(`⚠️  Product ${name} already exists or error:`, error.message);
            }
        }

        // Get final counts
        const categoriesCount = await dbConnection.query('SELECT COUNT(*) FROM categories');
        const productsCount = await dbConnection.query('SELECT COUNT(*) FROM products');

        useSubsegment(subsegment, 'addAnnotation')('tables_created', true);
        useSubsegment(subsegment, 'close')();

        res.json({
            message: 'Database tables created and populated successfully',
            status: 'completed',
            results: {
                categories_created: parseInt(categoriesCount.rows[0].count),
                products_created: parseInt(productsCount.rows[0].count)
            }
        });

    } catch (error) {
        useSubsegment(subsegment, 'addError')(error);
        useSubsegment(subsegment, 'close')();
        console.error('Database table creation error:', error);
        res.status(500).json({
            error: 'Failed to create database tables',
            details: error.message
        });
    }
});

module.exports = router;