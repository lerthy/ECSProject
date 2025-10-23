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
    app.use(AWSXRay.express.openSegment('ecommerce-api'));
    console.log('🔍 AWS X-Ray tracing enabled');
} catch (error) {
    console.log('⚠️  AWS X-Ray not available (development mode)');
    // Create mock middleware for development
    app.use((req, res, next) => next());
}

// AWS CloudWatch custom metrics setup
let CloudWatch;
try {
    CloudWatch = require('aws-sdk').CloudWatch;
    const cloudwatch = new CloudWatch({ region: process.env.AWS_REGION || 'us-east-1' });
    console.log('📊 AWS CloudWatch custom metrics enabled');
} catch (error) {
    console.log('⚠️  AWS CloudWatch not available (development mode)');
    CloudWatch = null;
}

// Custom metrics middleware
function sendCustomMetrics(req, res, next) {
    if (!CloudWatch) {
        return next();
    }

    const startTime = Date.now();
    
    res.on('finish', () => {
        const duration = Date.now() - startTime;
        const cloudwatch = new CloudWatch({ region: process.env.AWS_REGION || 'us-east-1' });
        
        const params = {
            Namespace: 'ECommerce/API',
            MetricData: [
                {
                    MetricName: 'RequestCount',
                    Value: 1,
                    Unit: 'Count',
                    Dimensions: [
                        { Name: 'Method', Value: req.method },
                        { Name: 'Route', Value: req.route?.path || req.path },
                        { Name: 'StatusCode', Value: res.statusCode.toString() }
                    ]
                },
                {
                    MetricName: 'ResponseTime',
                    Value: duration,
                    Unit: 'Milliseconds',
                    Dimensions: [
                        { Name: 'Method', Value: req.method },
                        { Name: 'Route', Value: req.route?.path || req.path }
                    ]
                }
            ]
        };
        
        cloudwatch.putMetricData(params, (err) => {
            if (err) {
                console.error('Failed to send custom metrics:', err);
            }
        });
    });
    
    next();
}

// Apply custom metrics middleware
app.use(sendCustomMetrics);

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
                    console.log(`🔍 AWS X-Ray tracing enabled`);
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