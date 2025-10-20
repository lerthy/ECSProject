const express = require('express');
const router = express.Router();

// Health check endpoint for ALB
router.get('/', (req, res) => {
    res.status(200).json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        memory: process.memoryUsage(),
        service: 'ecommerce-api'
    });
});

// Detailed health check
router.get('/detailed', (req, res) => {
    const healthData = {
        status: 'healthy',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        memory: process.memoryUsage(),
        service: 'ecommerce-api',
        version: '1.0.0',
        environment: process.env.NODE_ENV || 'development',
        dependencies: {
            database: 'healthy', // In real app, check DB connection
            cache: 'healthy',    // In real app, check Redis/ElastiCache
            external_apis: 'healthy'
        }
    };

    res.status(200).json(healthData);
});

module.exports = router;