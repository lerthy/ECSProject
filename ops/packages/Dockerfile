FROM node:18-alpine

# Set working directory
WORKDIR /app

# Install app dependencies
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodeuser -u 1001

# Copy app source
COPY src/ ./src/

# Change ownership to nodeuser
RUN chown -R nodeuser:nodejs /app
USER nodeuser

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "const http = require('http'); \
               const req = http.request({hostname: 'localhost', port: 3000, path: '/health', method: 'GET'}, \
               (res) => { process.exit(res.statusCode === 200 ? 0 : 1); }); \
               req.on('error', () => process.exit(1)); \
               req.end();"

# Start application
CMD ["node", "src/server.js"]