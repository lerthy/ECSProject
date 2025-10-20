const request = require('supertest');
const app = require('../src/server');

describe('Health Endpoints', () => {
    test('GET /health should return healthy status', async () => {
        const response = await request(app)
            .get('/health')
            .expect(200);

        expect(response.body).toHaveProperty('status', 'healthy');
        expect(response.body).toHaveProperty('timestamp');
        expect(response.body).toHaveProperty('uptime');
    });

    test('GET /health/detailed should return detailed health info', async () => {
        const response = await request(app)
            .get('/health/detailed')
            .expect(200);

        expect(response.body).toHaveProperty('status', 'healthy');
        expect(response.body).toHaveProperty('dependencies');
    });
});

describe('Product Endpoints', () => {
    test('GET /api/products should return products list', async () => {
        const response = await request(app)
            .get('/api/products')
            .expect(200);

        expect(response.body).toHaveProperty('data');
        expect(response.body).toHaveProperty('pagination');
        expect(Array.isArray(response.body.data)).toBe(true);
    });

    test('GET /api/products/:id should return specific product', async () => {
        const response = await request(app)
            .get('/api/products/1')
            .expect(200);

        expect(response.body).toHaveProperty('data');
        expect(response.body.data).toHaveProperty('id', '1');
    });

    test('GET /api/products/:id should return 404 for non-existent product', async () => {
        await request(app)
            .get('/api/products/999')
            .expect(404);
    });

    test('POST /api/products should create new product', async () => {
        const newProduct = {
            name: 'Test Product',
            description: 'Test Description',
            price: 99.99,
            category: 'Test',
            stock: 10
        };

        const response = await request(app)
            .post('/api/products')
            .send(newProduct)
            .expect(201);

        expect(response.body).toHaveProperty('data');
        expect(response.body.data).toHaveProperty('name', 'Test Product');
        expect(response.body.data).toHaveProperty('id');
    });
});

describe('Cart Endpoints', () => {
    test('GET /api/cart/:userId should return empty cart for new user', async () => {
        const response = await request(app)
            .get('/api/cart/testuser')
            .expect(200);

        expect(response.body).toHaveProperty('data');
        expect(response.body.data).toHaveProperty('items');
        expect(response.body.data.items).toHaveLength(0);
    });

    test('POST /api/cart/:userId/items should add item to cart', async () => {
        const cartItem = {
            productId: '1',
            quantity: 2,
            price: 199.99
        };

        const response = await request(app)
            .post('/api/cart/testuser2/items')
            .send(cartItem)
            .expect(201);

        expect(response.body).toHaveProperty('data');
        expect(response.body.data.items).toHaveLength(1);
        expect(response.body.data).toHaveProperty('total');
    });
});

describe('Root Endpoint', () => {
    test('GET / should return API information', async () => {
        const response = await request(app)
            .get('/')
            .expect(200);

        expect(response.body).toHaveProperty('message', 'E-commerce API');
        expect(response.body).toHaveProperty('endpoints');
    });
});

describe('Error Handling', () => {
    test('GET /nonexistent should return 404', async () => {
        const response = await request(app)
            .get('/nonexistent')
            .expect(404);

        expect(response.body).toHaveProperty('error', 'Not Found');
    });
});