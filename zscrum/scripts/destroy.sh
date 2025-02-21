#!/bin/bash
set -e

echo "WARNING: This will destroy all resources. Are you sure? (y/N)"
read -r confirmation

if [ "$confirmation" != "y" ]; then
    echo "Aborted"
    exit 1
fi

# Load environment variables
if [ -f .env ]; then
    source .env
else
    echo "Error: .env file not found"
    exit 1
fi

# Empty S3 bucket
echo "Emptying S3 bucket..."
aws s3 rm s3://${WEBSITE_BUCKET_NAME} --recursive

# Delete ECR images
echo "Deleting ECR images..."
aws ecr batch-delete-image \
    --repository-name ${ECR_REPOSITORY_NAME} \
    --image-ids imageTag=latest

# Destroy Terraform resources
echo "Destroying Terraform resources..."
cd ../terraform
terraform destroy -var-file="environments/dev/terraform.tfvars" -auto-approve

echo "Cleanup completed successfully!"