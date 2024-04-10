#!/bin/bash

# Variables
BUCKET_NAME="the-block-crypto-state-bucket"
TABLE_NAME="the-block-crypto-table"
REGION="eu-north-1"

echo "Starting cleanup for Terraform backend resources..."

# Function to delete all versions of all objects in an S3 bucket
empty_s3_bucket() {
    echo "Removing all versions from $BUCKET_NAME..."

    # List and delete all object versions
    aws s3api list-object-versions --bucket "$BUCKET_NAME" --output text --query 'Versions[*].[Key, VersionId]' 2>&1 | while read -r key versionId; do
        echo "Deleting $key version $versionId"
        aws s3api delete-object --bucket "$BUCKET_NAME" --key "$key" --version-id "$versionId" 2>&1
    done

    # List and delete all delete markers
    aws s3api list-object-versions --bucket "$BUCKET_NAME" --output text --query 'DeleteMarkers[*].[Key, VersionId]' 2>&1 | while read -r key versionId; do
        echo "Deleting marker for $key version $versionId"
        aws s3api delete-object --bucket "$BUCKET_NAME" --key "$key" --version-id "$versionId" 2>&1
    done
}

# Delete all objects including all versions from the S3 bucket
empty_s3_bucket

# Delete the S3 bucket
echo "Deleting the S3 bucket: $BUCKET_NAME..."
if aws s3api delete-bucket --bucket "$BUCKET_NAME" --region "$REGION" 2>&1; then
    echo "S3 bucket deleted successfully."
else
    echo "Failed to delete S3 bucket."
    exit 1
fi

# Delete the DynamoDB table
echo "Deleting the DynamoDB table: $TABLE_NAME..."
if aws dynamodb delete-table --table-name "$TABLE_NAME" 2>&1; then
    echo "DynamoDB table deleted successfully."
else
    echo "Failed to delete DynamoDB table."
    exit 1
fi

echo "Cleanup completed successfully."
