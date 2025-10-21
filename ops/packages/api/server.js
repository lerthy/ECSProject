const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const morgan = require('morgan');
const path = require('path');

// Import routes
const productRoutes = require('./routes/products');
const cartRoutes = require('./routes/cart');
const checkoutRoutes = require('./routes/checkout');
const healthRoutes = require('./routes/health');

const app = express();
const PORT = process.env.PORT || 3000;

// AWS X-Ray tracing setup (optional for development)
let AWSXRay;
try {
    AWSXRay = require('aws-xray-sdk-express');
    app.use(AWSXRay.express.openSegment('ecommerce-api'));
    console.log('🔍 AWS X-Ray tracing enabled');
} catch (error) {
    console.log('⚠️  AWS X-Ray not available (development mode)');
    // Create mock middleware for development
    app.use((req, res, next) => next());
}

// Middleware
app.use(helmet({
    contentSecurityPolicy: {
        directives: {
            defaultSrc: ["'self'"],
            styleSrc: ["'self'", "'unsafe-inline'", "https://cdnjs.cloudflare.com"],
            scriptSrc: ["'self'"],
            fontSrc: ["'self'", "https://cdnjs.cloudflare.com"],
            imgSrc: ["'self'", "data:", "https:"],
        },
    },
}));
app.use(compression());
app.use(cors());
app.use(morgan('combined'));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Serve static files from the web directory (Vite dev/build output)
app.use(express.static(path.join(__dirname, '../web')));

// Routes
app.use('/health', healthRoutes);
app.use('/api/products', productRoutes);
app.use('/api/cart', cartRoutes);
app.use('/api/checkout', checkoutRoutes);
app.use('/api/orders', checkoutRoutes);

// Frontend route - serve the main HTML file
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, '../web/index.html'));
});

// API info endpoint
app.get('/api', (req, res) => {
    res.json({
        message: 'E-commerce API',
        version: '1.0.0',
        endpoints: {
            products: '/api/products',
            cart: '/api/cart',
            checkout: '/api/checkout',
            orders: '/api/orders',
            health: '/health'
        }
    });
});

// Error handling middleware
// eslint-disable-next-line no-unused-vars
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({
        error: 'Internal Server Error',
        message: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong!'
    });
});

// SPA fallback - serve index.html for non-API routes
app.get('*', (req, res) => {
    // Only serve HTML for non-API routes
    if (!req.path.startsWith('/api/') && !req.path.startsWith('/health')) {
        res.sendFile(path.join(__dirname, '../web/index.html'));
    } else {
        res.status(404).json({
            error: 'Not Found',
            message: 'The requested resource was not found'
        });
    }
});

// Close X-Ray segment (if available)
if (AWSXRay && AWSXRay.express && AWSXRay.express.closeSegment) {
    app.use(AWSXRay.express.closeSegment());
}

// Start server only if not in test environment
let server;
if (process.env.NODE_ENV !== 'test') {
    server = app.listen(PORT, '0.0.0.0', () => {
        console.log(`🚀 E-commerce API server running on port ${PORT}`);
        console.log(`📱 Environment: ${process.env.NODE_ENV || 'development'}`);
        if (AWSXRay && AWSXRay.express) {
            console.log(`🔍 AWS X-Ray tracing enabled`);
        } else {
            console.log(`📊 Running in development mode (X-Ray disabled)`);
        }
    });

    // Graceful shutdown
    process.on('SIGTERM', () => {
        console.log('SIGTERM received, shutting down gracefully');
        server.close(() => {
            console.log('Process terminated');
        });
    });
}

module.exports = app;