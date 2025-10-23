const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const morgan = require('morgan');
const path = require('path');

// Import database connection
const dbConnection = require('./database/connection');

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

    // Configure X-Ray daemon address for ECS Fargate
    if (process.env.AWS_XRAY_DAEMON_ADDRESS) {
        AWSXRay.setDaemonAddress(process.env.AWS_XRAY_DAEMON_ADDRESS);
        console.log(`🔍 X-Ray daemon address configured: ${process.env.AWS_XRAY_DAEMON_ADDRESS}`);
    }

    // Use the service name from environment variable to match X-Ray configuration
    const serviceName = process.env.AWS_XRAY_TRACING_NAME || 'ecommerce-api-dev';
    app.use(AWSXRay.express.openSegment(serviceName));
    console.log(`🔍 AWS X-Ray tracing enabled with service name: ${serviceName}`);
} catch (error) {
    console.log('⚠️  AWS X-Ray not available (development mode)');
    // Create mock middleware for development
    app.use((req, res, next) => next());
}

// Initialize database connection
async function initializeDatabase() {
    try {
        await dbConnection.initialize();
        console.log('🗄️  Database connection initialized successfully');
    } catch (error) {
        console.error('❌ Failed to initialize database connection:', error);
        // Don't exit immediately in development - allow health checks to report the issue
        if (process.env.NODE_ENV === 'production') {
            process.exit(1);
        }
    }
}

// Middleware
app.use(helmet({
    contentSecurityPolicy: {
        directives: {
            defaultSrc: ["'self'"],
            styleSrc: ["'self'", "'unsafe-inline'", "https://cdnjs.cloudflare.com"],
            scriptSrc: ["'self'", "'unsafe-inline'"],
            scriptSrcAttr: ["'unsafe-inline'"], // Allow inline event handlers
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

// Close X-Ray segment after all routes but before error handling
if (AWSXRay && AWSXRay.express && AWSXRay.express.closeSegment) {
    app.use(AWSXRay.express.closeSegment());
}

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

// Start server only if not in test environment
let server;
if (process.env.NODE_ENV !== 'test') {
    // Initialize database and start server
    async function startServer() {
        try {
            // Initialize database first
            await initializeDatabase();

            server = app.listen(PORT, '0.0.0.0', () => {
                console.log(`🚀 E-commerce API server running on port ${PORT}`);
                console.log(`📱 Environment: ${process.env.NODE_ENV || 'development'}`);
                console.log(`🗄️  Database Host: ${process.env.DB_HOST || 'not configured'}`);
                if (AWSXRay && AWSXRay.express) {
                    console.log(`🔍 AWS X-Ray tracing enabled - Service: ${process.env.AWS_XRAY_TRACING_NAME || 'ecommerce-api-dev'}`);
                    console.log(`🔍 X-Ray daemon address: ${process.env.AWS_XRAY_DAEMON_ADDRESS || '127.0.0.1:2000'}`);
                } else {
                    console.log(`📊 Running in development mode (X-Ray disabled)`);
                }
            });
        } catch (error) {
            console.error('❌ Failed to start server:', error);
            process.exit(1);
        }
    }

    // Start the server
    startServer();

    // Graceful shutdown
    process.on('SIGTERM', async () => {
        console.log('SIGTERM received, shutting down gracefully');

        try {
            await dbConnection.close();
            console.log('🗄️  Database connection closed');
        } catch (error) {
            console.error('❌ Error closing database connection:', error);
        }

        if (server) {
            server.close(() => {
                console.log('🛑 Process terminated');
                process.exit(0);
            });
        } else {
            process.exit(0);
        }
    });

    process.on('SIGINT', async () => {
        console.log('SIGINT received, shutting down gracefully');

        try {
            await dbConnection.close();
            console.log('🗄️  Database connection closed');
        } catch (error) {
            console.error('❌ Error closing database connection:', error);
        }

        if (server) {
            server.close(() => {
                console.log('🛑 Process terminated');
                process.exit(0);
            });
        } else {
            process.exit(0);
        }
    });
}

module.exports = app;