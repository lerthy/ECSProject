const express = require('express');
const router = express.Router();
const dbConnection = require('../database/connection');

// Health check endpoint for ALB
router.get('/', async (req, res) => {
    try {
        // Check database health
        const dbHealth = await dbConnection.healthCheck();

        const healthStatus = {
            status: dbHealth.status === 'healthy' ? 'healthy' : 'degraded',
            timestamp: new Date().toISOString(),
            uptime: process.uptime(),
            memory: process.memoryUsage(),
            service: 'ecommerce-api',
            database: dbHealth
        };

        // If database is unhealthy, mark overall status as degraded
        if (dbHealth.status !== 'healthy') {
            res.status(503);
        } else {
            res.status(200);
        }

        res.json(healthStatus);
    } catch (error) {
        console.error('Health check error:', error);
        res.status(503).json({
            status: 'unhealthy',
            timestamp: new Date().toISOString(),
            error: error.message
        });
    }
});

// Detailed health check
router.get('/detailed', async (req, res) => {
    try {
        const dbHealth = await dbConnection.healthCheck();

        const healthData = {
            status: dbHealth.status === 'healthy' ? 'healthy' : 'degraded',
            timestamp: new Date().toISOString(),
            uptime: process.uptime(),
            memory: process.memoryUsage(),
            service: 'ecommerce-api',
            version: '1.0.0',
            environment: process.env.NODE_ENV || 'development',
            dependencies: {
                database: dbHealth,
                cache: 'not_configured',
                external_apis: 'healthy'
            }
        };

        // Return appropriate status code based on health
        if (dbHealth.status !== 'healthy') {
            res.status(503);
        } else {
            res.status(200);
        }

        res.json(healthData);
    } catch (error) {
        console.error('Detailed health check error:', error);
        res.status(503).json({
            status: 'unhealthy',
            timestamp: new Date().toISOString(),
            error: error.message
        });
    }
});

// Readiness probe for Kubernetes/ECS
router.get('/ready', async (req, res) => {
    try {
        const dbHealth = await dbConnection.healthCheck();

        if (dbHealth.status === 'healthy') {
            res.status(200).json({
                status: 'ready',
                timestamp: new Date().toISOString()
            });
        } else {
            res.status(503).json({
                status: 'not_ready',
                timestamp: new Date().toISOString(),
                reason: 'database_not_available'
            });
        }
    } catch (error) {
        res.status(503).json({
            status: 'not_ready',
            timestamp: new Date().toISOString(),
            error: error.message
        });
    }
});

// Liveness probe for Kubernetes/ECS
router.get('/live', (req, res) => {
    res.status(200).json({
        status: 'alive',
        timestamp: new Date().toISOString(),
        uptime: process.uptime()
    });
});

module.exports = router;