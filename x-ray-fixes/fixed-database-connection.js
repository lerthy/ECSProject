const { Pool } = require('pg');
const AWS = require('aws-sdk');

// AWS X-Ray setup (optional)
let AWSXRay;
try {
    AWSXRay = require('aws-xray-sdk-core');
    AWS = AWSXRay.captureAWS(AWS);
    console.log('🔍 X-Ray SDK loaded for database operations');
} catch (error) {
    console.log('⚠️  X-Ray not available for database operations');
}

class DatabaseConnection {
    constructor() {
        this.pool = null;
        this.secretsManager = new AWS.SecretsManager({
            region: process.env.AWS_REGION || 'us-east-1'
        });
    }

    async getDbCredentials() {
        try {
            // For local development with local DB, use environment variables directly
            if (process.env.DISABLE_AWS_SERVICES === 'true') {
                return {
                    username: process.env.DB_USER,
                    password: process.env.DB_PASSWORD
                };
            }

            // Get credentials from AWS Secrets Manager for all AWS environments (dev, staging, prod)
            const secretArn = process.env.DB_SECRETS_ARN;
            if (!secretArn) {
                throw new Error('DB_SECRETS_ARN environment variable not set');
            }

            console.log('🔐 Retrieving database credentials from Secrets Manager...');
            const data = await this.secretsManager.getSecretValue({
                SecretId: secretArn
            }).promise();

            if (!data.SecretString) {
                throw new Error('No SecretString found in Secrets Manager response');
            }

            const credentials = JSON.parse(data.SecretString);
            console.log('✅ Successfully retrieved credentials from Secrets Manager');

            // Validate that we have the required fields
            if (!credentials.username || !credentials.password) {
                throw new Error('Invalid credentials format: missing username or password');
            }

            // Ensure password is a string
            if (typeof credentials.password !== 'string') {
                throw new Error(`Password must be a string, got ${typeof credentials.password}`);
            }

            return {
                username: String(credentials.username),
                password: String(credentials.password)
            };
        } catch (error) {
            console.error('❌ Error retrieving database credentials:', error);
            throw error;
        }
    }

    async initialize() {
        try {
            console.log('🔄 Initializing database connection...');

            // Get database credentials
            const credentials = await this.getDbCredentials();

            console.log('📋 Database connection config:', {
                host: process.env.DB_HOST,
                port: process.env.DB_PORT || 5432,
                database: process.env.DB_NAME || 'ecommerce',
                user: credentials.username,
                passwordProvided: !!credentials.password,
                passwordType: typeof credentials.password
            });

            // Database connection configuration
            const config = {
                host: process.env.DB_HOST,
                port: process.env.DB_PORT || 5432,
                database: process.env.DB_NAME || 'ecommerce',
                user: credentials.username,
                password: credentials.password,

                // Connection pool settings
                max: 20, // Maximum number of connections
                idleTimeoutMillis: 30000, // Close idle connections after 30 seconds
                connectionTimeoutMillis: 10000, // Connection timeout

                // SSL configuration for RDS - Always enabled for AWS RDS
                ssl: {
                    rejectUnauthorized: false // AWS RDS uses self-signed certificates
                },

                // Additional PostgreSQL settings
                statement_timeout: 30000, // 30 second query timeout
                query_timeout: 30000,
                application_name: 'ecommerce-api'
            };

            this.pool = new Pool(config);

            // Test the connection
            const client = await this.pool.connect();
            await client.query('SELECT NOW()');
            client.release();

            console.log('✅ Database connection established successfully');

            // Set up error handling
            this.pool.on('error', (err) => {
                console.error('Unexpected error on idle client', err);
            });

            return this.pool;
        } catch (error) {
            console.error('❌ Failed to initialize database connection:', error);
            throw error;
        }
    }

    async query(text, params) {
        if (!this.pool) {
            throw new Error('Database not initialized. Call initialize() first.');
        }

        // Safely get X-Ray segment without throwing if not available
        let segment = null;
        let subsegment = null;

        try {
            if (AWSXRay && AWSXRay.getSegment) {
                segment = AWSXRay.getSegment();
                if (segment && segment.addNewSubsegment) {
                    subsegment = segment.addNewSubsegment('postgres-query');
                }
            }
        } catch (error) {
            // Silently continue without X-Ray if segment not available
            console.log('🔍 No X-Ray segment available for database query');
        }

        try {
            if (subsegment) {
                subsegment.addAnnotation('query', text.substring(0, 100));
                subsegment.addMetadata('sql', { query: text, params });
            }

            const start = Date.now();
            const result = await this.pool.query(text, params);
            const duration = Date.now() - start;

            if (subsegment) {
                subsegment.addAnnotation('duration_ms', duration);
                subsegment.addAnnotation('rows_affected', result.rowCount);
            }

            console.log(`📊 Query executed in ${duration}ms, ${result.rowCount} rows affected`);
            return result;
        } catch (error) {
            if (subsegment) {
                subsegment.addError(error);
            }
            console.error('Database query error:', error);
            throw error;
        } finally {
            if (subsegment) {
                subsegment.close();
            }
        }
    }

    async transaction(callback) {
        if (!this.pool) {
            throw new Error('Database not initialized. Call initialize() first.');
        }

        const client = await this.pool.connect();

        // Safely get X-Ray segment without throwing if not available
        let segment = null;
        let subsegment = null;

        try {
            if (AWSXRay && AWSXRay.getSegment) {
                segment = AWSXRay.getSegment();
                if (segment && segment.addNewSubsegment) {
                    subsegment = segment.addNewSubsegment('postgres-transaction');
                }
            }
        } catch (error) {
            // Silently continue without X-Ray if segment not available
            console.log('🔍 No X-Ray segment available for database transaction');
        }

        try {
            await client.query('BEGIN');

            const transactionClient = {
                query: (text, params) => client.query(text, params)
            };

            const result = await callback(transactionClient);
            await client.query('COMMIT');

            if (subsegment) {
                subsegment.addAnnotation('transaction_status', 'committed');
            }

            return result;
        } catch (error) {
            await client.query('ROLLBACK');

            if (subsegment) {
                subsegment.addAnnotation('transaction_status', 'rolled_back');
                subsegment.addError(error);
            }

            console.error('Transaction error:', error);
            throw error;
        } finally {
            client.release();
            if (subsegment) {
                subsegment.close();
            }
        }
    }

    async healthCheck() {
        try {
            const result = await this.query('SELECT 1 as health_check, NOW() as current_time');
            return {
                status: 'healthy',
                timestamp: result.rows[0].current_time,
                connection_count: this.pool.totalCount,
                idle_count: this.pool.idleCount,
                waiting_count: this.pool.waitingCount
            };
        } catch (error) {
            return {
                status: 'unhealthy',
                error: error.message,
                timestamp: new Date().toISOString()
            };
        }
    }

    async close() {
        if (this.pool) {
            await this.pool.end();
            console.log('🔌 Database connection closed');
        }
    }
}

// Export singleton instance
const dbConnection = new DatabaseConnection();

module.exports = dbConnection;