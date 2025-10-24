# Docker Compose Setup for E-commerce Application

This Docker Compose setup provides a complete local development environment for the e-commerce application with PostgreSQL database, Redis cache, and pgAdmin for database management.

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose installed
- Git repository cloned

### 1. Environment Setup
```bash
# Copy environment template
cp .env.example .env

# Edit .env file with your preferred settings (optional)
# The default values work for local development
```

### 2. Start All Services
```bash
# Start all services in detached mode
docker-compose up -d

# Or start with logs visible
docker-compose up

# Start only specific services
docker-compose up -d database app
```

### 3. Access Your Application
- **Application**: http://localhost:3000
- **API Endpoints**: http://localhost:3000/api
- **Health Check**: http://localhost:3000/health
- **pgAdmin** (dev only): http://localhost:8080
  - Email: `admin@ecommerce.local`
  - Password: `admin123`

## 📋 Services Overview

### 🗄️ Database (PostgreSQL 15.7)
- **Port**: 5432
- **Database**: ecommerce
- **User**: ecommerce_user
- **Password**: ecommerce_password
- **Volume**: Persistent data storage
- **Init Scripts**: Automatically creates schema and sample data

### 🎯 Application (Node.js/Express)
- **Port**: 3000
- **Environment**: Development mode
- **Database**: Connected to PostgreSQL
- **Health Checks**: Enabled
- **Live Reload**: Source code mounted for development

### 🔄 Redis (Optional)
- **Port**: 6379
- **Purpose**: Session storage and caching
- **Volume**: Persistent data storage

### 🛠️ pgAdmin (Development Profile)
- **Port**: 8080
- **Purpose**: Database management UI
- **Access**: admin@ecommerce.local / admin123

## 🎛️ Docker Compose Commands

### Basic Operations
```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# Restart services
docker-compose restart

# View logs
docker-compose logs -f

# View logs for specific service
docker-compose logs -f app
```

### Development Commands
```bash
# Start with development profile (includes pgAdmin)
docker-compose --profile development up -d

# Rebuild application after code changes
docker-compose build app
docker-compose up -d app

# Execute commands in running container
docker-compose exec app sh
docker-compose exec database psql -U ecommerce_user -d ecommerce
```

### Database Management
```bash
# Connect to database
docker-compose exec database psql -U ecommerce_user -d ecommerce

# Backup database
docker-compose exec database pg_dump -U ecommerce_user ecommerce > backup.sql

# Restore database
docker-compose exec -T database psql -U ecommerce_user -d ecommerce < backup.sql

# Reset database (remove volumes)
docker-compose down -v
docker-compose up -d
```

## 🔧 Configuration

### Environment Variables
Edit `.env` file to customize:
- Database credentials
- Application ports
- AWS configuration (dummy values for local dev)
- Redis settings
- Session secrets

### Volume Mounts
- **Source Code**: `./api:/app/api` (live reload)
- **Frontend**: `./web:/app/web` (live reload)
- **Database**: `postgres_data` (persistent storage)
- **Redis**: `redis_data` (persistent storage)

### Profiles
- **Default**: app, database, redis
- **Development**: + pgAdmin

## 🧪 Testing

### API Testing
```bash
# Test health endpoint
curl http://localhost:3000/health

# Test API info
curl http://localhost:3000/api

# Test products endpoint
curl http://localhost:3000/api/products

# Test with data
curl -X POST http://localhost:3000/api/cart \
  -H "Content-Type: application/json" \
  -d '{"productId": 1, "quantity": 2}'
```

### Database Testing
```bash
# Connect and run queries
docker-compose exec database psql -U ecommerce_user -d ecommerce

# Sample queries
SELECT * FROM products;
SELECT * FROM customers;
SELECT * FROM orders;
```

## 🐛 Troubleshooting

### Common Issues

#### Service Won't Start
```bash
# Check service status
docker-compose ps

# Check logs
docker-compose logs service_name

# Restart specific service
docker-compose restart service_name
```

#### Database Connection Issues
```bash
# Check database health
docker-compose exec database pg_isready -U ecommerce_user

# Reset database
docker-compose down -v
docker-compose up -d database
```

#### Port Conflicts
```bash
# Check what's using the port
netstat -tulpn | grep :3000

# Change ports in docker-compose.yml if needed
ports:
  - "3001:3000"  # Use different host port
```

### Logs and Debugging
```bash
# Application logs
docker-compose logs -f app

# Database logs
docker-compose logs -f database

# All services logs
docker-compose logs -f

# Execute shell in container
docker-compose exec app sh
```

## 🚀 Production Deployment

This Docker Compose setup is for **development only**. For production:

1. Use the Terraform infrastructure in `ops/iac/`
2. Deploy to AWS ECS using the CI/CD pipeline
3. Use AWS RDS for database
4. Use AWS ElastiCache for Redis
5. Configure proper secrets management

## 📁 File Structure
```
ops/packages/
├── docker-compose.yml          # Main compose file
├── .env.example               # Environment template
├── Dockerfile                 # Application container
├── api/                       # Backend source code
├── web/                       # Frontend source code
└── database/
    └── init/                  # Database initialization scripts
        └── 01-init-schema.sql
```

## 🤝 Contributing

When developing:
1. Make changes to source code in `api/` or `web/`
2. Test with `docker-compose up -d`
3. Run tests with `npm test` inside container
4. Commit changes
5. Deploy via CI/CD pipeline