[
    {
        "name": "${container_name}",
        "image": "${image_uri}",
        "cpu": ${cpu},
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
            { "name": "DB_SECRETS_ARN", "value": "${secrets_manager_secret_arn}" }
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
            "command": ["CMD-SHELL", "curl -f http://localhost:${container_port}/health || exit 1"],
            "interval": 30,
            "timeout": 5,
            "retries": 3,
            "startPeriod": 60
        }
    }
]