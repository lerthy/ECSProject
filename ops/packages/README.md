# E-commerce Web Application

A production-ready Node.js Express API for an e-commerce platform with product catalog, shopping cart, and checkout functionality. Designed to run on AWS ECS Fargate with comprehensive observability and monitoring.

## Features

- **Product Management**: CRUD operations for products with filtering and pagination
- **Shopping Cart**: Add, update, remove items with automatic total calculations
- **Checkout Process**: Secure payment processing with order management
- **Health Monitoring**: Built-in health checks for ALB integration
- **AWS X-Ray Tracing**: Distributed tracing for performance monitoring
- **Production Security**: Helmet, CORS, compression, and input validation

## API Endpoints

### Health
- `GET /health` - Basic health check
- `GET /health/detailed` - Detailed system health information

### Products
- `GET /api/products` - List products (with filtering, pagination)
- `GET /api/products/:id` - Get product details
- `POST /api/products` - Create new product
- `PUT /api/products/:id` - Update product
- `DELETE /api/products/:id` - Delete product

### Cart
- `GET /api/cart/:userId` - Get user's cart
- `POST /api/cart/:userId/items` - Add item to cart
- `PUT /api/cart/:userId/items/:itemId` - Update cart item quantity
- `DELETE /api/cart/:userId/items/:itemId` - Remove item from cart
- `DELETE /api/cart/:userId` - Clear entire cart

### Checkout & Orders
- `POST /api/checkout/:userId` - Process checkout and create order
- `GET /api/orders/:userId` - Get user's order history
- `GET /api/orders/order/:orderId` - Get specific order details
- `PUT /api/orders/order/:orderId/status` - Update order status (admin)
- `GET /api/orders/stats/summary` - Order statistics (admin)

## Quick Start

### Development
```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Run tests
npm test

# Lint code
npm run lint
```

### Production (Docker)
```bash
# Build Docker image
docker build -t ecommerce-api .

# Run container
docker run -p 3000:3000 ecommerce-api
```

### AWS ECS Deployment

This application is designed to run on the existing ECS infrastructure defined in the terraform modules. The container will be deployed to ECS Fargate and load balanced through the ALB.

#### Environment Variables
- `PORT`: Server port (default: 3000)
- `NODE_ENV`: Environment (development/production)
- `AWS_XRAY_TRACING_NAME`: X-Ray service name
- `AWS_REGION`: AWS region for X-Ray

## Architecture Integration

This web application integrates with the existing AWS infrastructure:

- **ECS Fargate**: Runs the containerized API
- **Application Load Balancer**: Routes traffic and performs health checks
- **AWS X-Ray**: Distributed tracing for all API calls
- **CloudWatch**: Logs and metrics collection
- **SNS**: Notifications for alerts and pipeline events

## API Examples

### Get Products
```bash
curl -X GET "http://localhost:3000/api/products?category=Electronics&limit=5"
```

### Add to Cart
```bash
curl -X POST "http://localhost:3000/api/cart/user123/items" \
  -H "Content-Type: application/json" \
  -d '{
    "productId": "1",
    "quantity": 2,
    "price": 199.99
  }'
```

### Checkout
```bash
curl -X POST "http://localhost:3000/api/checkout/user123" \
  -H "Content-Type: application/json" \
  -d '{
    "shippingAddress": {
      "street": "123 Main St",
      "city": "Seattle",
      "state": "WA",
      "zipCode": "98101",
      "country": "USA"
    },
    "paymentMethod": {
      "type": "credit_card",
      "cardNumber": "4111111111111111",
      "expiryMonth": 12,
      "expiryYear": 2025,
      "cvv": "123"
    }
  }'
```

## Data Models

### Product
```json
{
  "id": "string",
  "name": "string",
  "description": "string",
  "price": "number",
  "category": "string",
  "stock": "number",
  "imageUrl": "string",
  "createdAt": "ISO string",
  "updatedAt": "ISO string"
}
```

### Cart Item
```json
{
  "id": "string",
  "productId": "string",
  "quantity": "number",
  "price": "number",
  "addedAt": "ISO string",
  "updatedAt": "ISO string"
}
```

### Order
```json
{
  "id": "string",
  "userId": "string",
  "items": "CartItem[]",
  "totals": {
    "subtotal": "number",
    "tax": "number",
    "shipping": "number",
    "total": "number"
  },
  "shippingAddress": "Address",
  "paymentMethod": "PaymentMethod",
  "status": "string",
  "createdAt": "ISO string"
}
```

## Monitoring & Observability

The application includes comprehensive monitoring:

- **Health Checks**: `/health` endpoint for ALB health checks
- **X-Ray Tracing**: Automatic trace collection for all requests
- **Structured Logging**: JSON formatted logs for CloudWatch
- **Metrics**: Custom metrics for business logic
- **Error Handling**: Centralized error handling with proper HTTP status codes

## Security Features

- **Helmet**: Security headers protection
- **CORS**: Cross-origin resource sharing configuration
- **Input Validation**: Joi schema validation for all inputs
- **Rate Limiting**: Built-in protection against abuse
- **Non-root User**: Docker container runs as non-root user

## Production Considerations

For production deployment:

1. Replace in-memory storage with persistent databases (DynamoDB/RDS)
2. Implement proper authentication and authorization
3. Add rate limiting and API throttling
4. Set up proper secrets management for sensitive data
5. Configure environment-specific settings
6. Implement proper logging and monitoring alerts

## Testing

The application includes:
- Unit tests for business logic
- Integration tests for API endpoints
- Health check validation
- Docker container testing

```bash
npm test
```

## Contributing

1. Follow the existing code style and patterns
2. Add tests for new features
3. Update documentation
4. Ensure all linting passes
5. Test Docker builds
