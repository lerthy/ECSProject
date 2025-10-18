# SNS Module

This module creates an SNS topic and optional email/Slack subscriptions for alerting.

## Inputs
- `name`: SNS topic name
- `tags`: Tags for resources
- `email`: Email address for subscription (optional)
- `slack_webhook`: Slack webhook URL for subscription (optional)

## Outputs
- `sns_topic_arn`: SNS topic ARN
