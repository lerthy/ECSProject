#!/bin/bash
# Request ACM certificate for a domain (DNS validation)
set -e

DOMAIN="$1"
REGION="${2:-us-east-1}"

if [ -z "$DOMAIN" ]; then
  echo "Usage: $0 <domain-name> [region]"
  exit 1
fi

echo "Requesting ACM certificate for $DOMAIN in $REGION..."
CERT_ARN=$(aws acm request-certificate \
  --domain-name "$DOMAIN" \
  --validation-method DNS \
  --region "$REGION" \
  --output text \
  --query CertificateArn)

if [ -z "$CERT_ARN" ]; then
  echo "Failed to request ACM certificate."
  exit 2
fi

echo "Certificate ARN: $CERT_ARN"
echo "Fetching DNS validation options..."
aws acm describe-certificate --certificate-arn "$CERT_ARN" --region "$REGION" --query 'Certificate.DomainValidationOptions' --output table

echo "✅ ACM certificate requested. Add the DNS validation record to your DNS provider (e.g., Route53) to complete validation."
