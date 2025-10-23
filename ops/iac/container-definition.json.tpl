[
    {
        "name": "${container_name}",
        "image": "${image_uri}",
        "cpu": 224,
        "memory": ${memory},
        "portMappings": [
            { 
                "containerPort": ${container_port}, 
                "hostPort": ${container_port},
                "protocol": "tcp"
            }
        ],
        "environment": [
            { "name": "ENV", "value": "${environment}" },
            { "name": "NODE_ENV", "value": "${node_env}" },
            { "name": "PORT", "value": "${container_port}" },
            { "name": "DB_HOST", "value": "${db_host}" },
            { "name": "DB_PORT", "value": "${db_port}" },
            { "name": "DB_NAME", "value": "${db_name}" },
            { "name": "DB_USER", "value": "${db_username}" },
            { "name": "AWS_REGION", "value": "${aws_region}" },
            { "name": "DB_SECRETS_ARN", "value": "${secrets_manager_secret_arn}" },
            { "name": "_X_AMZN_TRACE_ID", "value": "" },
            { "name": "AWS_XRAY_TRACING_NAME", "value": "ecommerce-api-dev" },
            { "name": "AWS_XRAY_DAEMON_ADDRESS", "value": "127.0.0.1:2000" }
        ],
        "logConfiguration": {
            "logDriver": "awslogs",
            "options": {
                "awslogs-group": "${log_group}",
                "awslogs-region": "${aws_region}",
                "awslogs-stream-prefix": "ecs"
            }
        },
        "essential": true,
        "healthCheck": {
            "command": ["CMD-SHELL", "node -e \"const http = require('http'); const options = { hostname: 'localhost', port: ${container_port}, path: '/health', timeout: 3000 }; const req = http.request(options, (res) => { process.exit(res.statusCode === 200 ? 0 : 1); }); req.on('error', () => process.exit(1)); req.on('timeout', () => { req.destroy(); process.exit(1); }); req.setTimeout(3000); req.end();\""],
            "interval": 30,
            "timeout": 5,
            "retries": 3,
            "startPeriod": 60
        }
    },
    {
        "name": "xray-daemon",
        "image": "amazon/aws-xray-daemon:latest",
        "cpu": 32,
        "memory": 256,
        "portMappings": [
            {
                "containerPort": 2000,
                "hostPort": 2000,
                "protocol": "udp"
            }
        ],
        "environment": [
            { "name": "AWS_REGION", "value": "${aws_region}" }
        ],
        "logConfiguration": {
            "logDriver": "awslogs",
            "options": {
                "awslogs-group": "${log_group}",
                "awslogs-region": "${aws_region}",
                "awslogs-stream-prefix": "xray"
            }
        },
        "essential": false
    }
]