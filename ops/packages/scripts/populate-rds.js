#!/usr/bin/env node

/**
 * RDS Database Population Script
 * 
 * This script connects to the RDS database and populates it with initial data
 * using the same database connection as the application.
 */

const dbConnection = require('../api/database/connection');

async function populateDatabase() {
    console.log('🚀 Starting RDS database population...');

    try {
        // Initialize database connection
        await dbConnection.initialize();
        console.log('✅ Database connection established');

        // Check if tables exist
        const tablesResult = await dbConnection.query(`
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public'
            ORDER BY table_name;
        `);

        console.log('📋 Existing tables:', tablesResult.rows.map(row => row.table_name));

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

        // Verify data
        const categoriesCount = await dbConnection.query('SELECT COUNT(*) FROM categories');
        const productsCount = await dbConnection.query('SELECT COUNT(*) FROM products');

        console.log(`\n📊 Database Population Summary:`);
        console.log(`   Categories: ${categoriesCount.rows[0].count}`);
        console.log(`   Products: ${productsCount.rows[0].count}`);

        // Show some sample data
        const sampleProducts = await dbConnection.query(`
            SELECT p.name, p.price, c.name as category_name 
            FROM products p 
            LEFT JOIN categories c ON p.category_id = c.id 
            LIMIT 5
        `);

        console.log(`\n📦 Sample Products:`);
        sampleProducts.rows.forEach(product => {
            console.log(`   - ${product.name} (${product.category_name}): $${product.price}`);
        });

        console.log('\n🎉 Database population completed successfully!');

    } catch (error) {
        console.error('❌ Error populating database:', error);
        process.exit(1);
    } finally {
        await dbConnection.close();
        console.log('🔌 Database connection closed');
    }
}

// Run the population script
if (require.main === module) {
    populateDatabase();
}

module.exports = { populateDatabase };