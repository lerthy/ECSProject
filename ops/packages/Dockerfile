# Multi-stage Dockerfile optimized for ECS/ECR
FROM public.ecr.aws/docker/library/node:18-alpine AS builder

# Set working directory
WORKDIR /app

# Copy package files and install all dependencies (including devDependencies for build)
COPY package*.json ./
RUN npm ci && npm cache clean --force

# Copy frontend source and build
COPY web/ ./web/
COPY vite.config.js ./
# Create a simple build without Vite for CSS
RUN mkdir -p ./web-build && \
    cp ./web/index.html ./web-build/ && \
    cp -r ./web/src ./web-build/

# Production stage
FROM public.ecr.aws/docker/library/node:18-alpine AS production

# Set working directory
WORKDIR /app

# Install production dependencies only
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodeuser -u 1001

# Copy API source code
COPY api/ ./api/

# Copy built frontend from builder stage
COPY --from=builder /app/web-build ./web/

# Change ownership to nodeuser
RUN chown -R nodeuser:nodejs /app
USER nodeuser

# Expose port (ECS will map this to ALB)
EXPOSE 3000

# Add labels for better container management in ECS
LABEL maintainer="ECS Project Team"
LABEL version="1.0.0"
LABEL description="E-commerce API with frontend assets"

# Health check for ECS health monitoring
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD node -e " \
    const http = require('http'); \
    const options = { \
      hostname: 'localhost', \
      port: 3000, \
      path: '/health', \
      method: 'GET', \
      timeout: 5000 \
    }; \
    const req = http.request(options, (res) => { \
      console.log('Health check status:', res.statusCode); \
      process.exit(res.statusCode === 200 ? 0 : 1); \
    }); \
    req.on('error', (err) => { \
      console.error('Health check error:', err.message); \
      process.exit(1); \
    }); \
    req.on('timeout', () => { \
      console.error('Health check timeout'); \
      req.destroy(); \
      process.exit(1); \
    }); \
    req.end();"

# Start application (ECS will manage this process)
CMD ["node", "api/server.js"]