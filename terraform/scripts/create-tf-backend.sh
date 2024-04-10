#!/bin/bash

# Variables
BUCKET_NAME="the-block-crypto-state-bucket"
TABLE_NAME="the-block-crypto-table"
REGION="eu-north-1"

echo "Starting setup for Terraform backend resources..."

# Create S3 bucket
echo "Creating S3 bucket: $BUCKET_NAME..."
if aws s3api create-bucket --bucket $BUCKET_NAME --region $REGION --create-bucket-configuration LocationConstraint=$REGION > /dev/null 2>&1; then
    echo "S3 bucket created successfully."
else
    echo "Failed to create S3 bucket."
    exit 1
fi

# Enable versioning on the S3 bucket
echo "Enabling versioning for the S3 bucket..."
if aws s3api put-bucket-versioning --bucket $BUCKET_NAME --versioning-configuration Status=Enabled > /dev/null 2>&1; then
    echo "Versioning enabled successfully."
else
    echo "Failed to enable versioning."
    exit 1
fi

# Enable server-side encryption on the S3 bucket
echo "Enabling server-side encryption for the S3 bucket..."
if aws s3api put-bucket-encryption --bucket $BUCKET_NAME --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}' > /dev/null 2>&1; then
    echo "Server-side encryption enabled successfully."
else
    echo "Failed to enable server-side encryption."
    exit 1
fi

# Create DynamoDB table for state locking
echo "Creating DynamoDB table: $TABLE_NAME..."
if aws dynamodb create-table \
    --table-name $TABLE_NAME \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 \
    --region $REGION > /dev/null 2>&1; then
    echo "DynamoDB table created successfully."
else
    echo "Failed to create DynamoDB table."
    exit 1
fi

echo "Setup completed successfully. Your Terraform backend resources are ready."
