# E-commerce Web Application - Frontend & Backend

A complete full-stack e-commerce application with a modern frontend and robust backend API. Built with Node.js, Express, and vanilla JavaScript with a focus on AWS ECS deployment.

## 🚀 Features

### Frontend
- **Modern UI**: Clean, responsive design with CSS Grid and Flexbox
- **Product Catalog**: Browse products with filtering and search
- **Shopping Cart**: Add, update, remove items with real-time totals
- **Checkout Process**: Complete payment flow with form validation
- **Order History**: View past orders and order status
- **Real-time Updates**: Toast notifications and loading states
- **Mobile Responsive**: Works perfectly on all screen sizes

### Backend
- **RESTful API**: Complete CRUD operations for products, cart, and orders
- **AWS Integration**: X-Ray tracing, CloudWatch logging, ECS ready
- **Input Validation**: Joi schema validation for all endpoints
- **Error Handling**: Comprehensive error handling and logging
- **Health Checks**: ALB-compatible health endpoints
- **Security**: Helmet, CORS, compression, and input sanitization

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Backend API   │    │   AWS Services  │
│                 │    │                 │    │                 │
│ • HTML/CSS/JS   │◄──►│ • Express.js    │◄──►│ • ECS Fargate   │
│ • Responsive    │    │ • RESTful API   │    │ • CloudWatch    │
│ • SPA Router    │    │ • X-Ray Tracing │    │ • X-Ray         │
│ • Toast UI      │    │ • Health Checks │    │ • ALB           │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🚦 Quick Start

### Prerequisites
- Node.js 18+
- npm

### Installation
```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Or start production server
npm start
```

The application will be available at `http://localhost:3000`

### Docker Deployment
```bash
# Build Docker image
docker build -t ecommerce-app .

# Run container
docker run -p 3000:3000 ecommerce-app
```

## 📱 Frontend Usage

### Navigation
- **Products**: Browse and filter the product catalog
- **Cart**: Manage items in your shopping cart
- **Orders**: View order history and status

### Key Features
1. **Product Browsing**
   - Filter by category and price range
   - Click products for detailed view
   - Add to cart with one click

2. **Cart Management**
   - Adjust quantities with +/- buttons
   - Remove items individually
   - See real-time total calculations

3. **Checkout Process**
   - Enter shipping address
   - Select payment method (Credit Card, Debit Card, PayPal)
   - Complete secure checkout

4. **Order Tracking**
   - View all past orders
   - Check order status
   - See order details and totals

## 🔌 API Endpoints

### Products
```
GET    /api/products              # List all products
GET    /api/products/:id          # Get product details  
POST   /api/products              # Create new product
PUT    /api/products/:id          # Update product
DELETE /api/products/:id          # Delete product
```

### Cart
```
GET    /api/cart/:userId          # Get user's cart
POST   /api/cart/:userId/items    # Add item to cart
PUT    /api/cart/:userId/items/:itemId  # Update cart item
DELETE /api/cart/:userId/items/:itemId  # Remove cart item
DELETE /api/cart/:userId          # Clear entire cart
```

### Checkout & Orders
```
POST   /api/checkout/:userId      # Process checkout
GET    /api/orders/:userId        # Get user's orders
GET    /api/orders/order/:orderId # Get specific order
PUT    /api/orders/order/:orderId/status  # Update order status
GET    /api/orders/stats/summary  # Order statistics
```

### Health & Info
```
GET    /health                    # Health check for ALB
GET    /health/detailed           # Detailed health info
GET    /api                       # API information
```

## 🎨 Frontend Architecture

### File Structure
```
public/
├── index.html          # Main HTML file
├── css/
│   └── styles.css      # Complete styling
└── js/
    └── app.js          # Frontend application logic
```

### Key Components
- **ECommerceApp Class**: Main application controller
- **Navigation System**: SPA-style page routing
- **API Integration**: RESTful API communication
- **Modal System**: Product details and checkout
- **Toast Notifications**: User feedback system

### State Management
- Products list and filtering
- Shopping cart state
- Order history
- Current user session (simulated)

## 🛡️ Security Features

### Backend Security
- **Helmet**: Security headers protection
- **CORS**: Cross-origin resource sharing
- **Input Validation**: Joi schema validation
- **Error Handling**: Secure error responses

### Frontend Security
- **Content Security Policy**: XSS protection
- **Input Sanitization**: Form validation
- **HTTPS Ready**: Production security headers

## 📊 Monitoring & Observability

### AWS X-Ray Integration
- Automatic tracing for all API calls
- Performance monitoring
- Error tracking
- Custom annotations and metadata

### CloudWatch Integration
- Structured JSON logging
- Custom metrics
- Health check monitoring
- Error alerting

### Health Checks
- Basic health endpoint for ALB
- Detailed system information
- Dependency health status

## 🔧 Configuration

### Environment Variables
```bash
PORT=3000                    # Server port
NODE_ENV=production         # Environment
AWS_XRAY_TRACING_NAME=ecommerce-api  # X-Ray service name
AWS_REGION=us-west-2        # AWS region
```

### Development vs Production
- Development: Detailed error messages, debug logging
- Production: Secure error handling, optimized performance

## 🚢 AWS ECS Deployment

This application is designed for the existing ECS infrastructure:

### Integration Points
- **ECS Task Definition**: Containerized deployment
- **Application Load Balancer**: Traffic distribution and health checks
- **CloudWatch**: Logging and monitoring
- **X-Ray**: Distributed tracing
- **SNS**: Alert notifications

### Health Check Configuration
```yaml
HealthCheck:
  Path: /health
  IntervalSeconds: 30
  TimeoutSeconds: 5
  HealthyThresholdCount: 2
  UnhealthyThresholdCount: 3
```

## 🧪 Testing

### Frontend Testing
- Manual testing of all user flows
- Responsive design testing
- API integration testing

### Backend Testing
```bash
# Run test suite
npm test

# Run linting
npm run lint

# Fix linting issues
npm run lint:fix
```

## 🎯 Production Considerations

### Performance
- Static file serving with compression
- Efficient DOM manipulation
- Lazy loading for large datasets
- Caching strategies

### Scalability
- Stateless design
- Database-ready architecture
- Load balancer compatible
- Container orchestration ready

### Future Enhancements
- Real database integration (DynamoDB/RDS)
- User authentication system
- Real payment gateway integration
- Advanced search and filtering
- Product image management
- Inventory management
- Order fulfillment system

## 📝 License

MIT License - see LICENSE file for details.

---

**Built for AWS ECS with ❤️ by the ECS Project Team**