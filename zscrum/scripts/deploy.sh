#!/bin/bash
set -e

# Function to log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Function to handle errors
handle_error() {
    log "Error occurred on line $1"
    exit 1
}

trap 'handle_error $LINENO' ERR

# Get the absolute path of the project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$PROJECT_ROOT/app"

# Load environment variables
log "Loading environment variables..."
if [ -f "$PROJECT_ROOT/.env" ]; then
    source "$PROJECT_ROOT/.env"
else
    log "Error: .env file not found"
    exit 1
fi

# Check AWS CLI is installed
if ! command -v aws &> /dev/null; then
    log "Error: AWS CLI is not installed"
    exit 1
fi

# Check AWS credentials
log "Checking AWS credentials..."
if ! aws sts get-caller-identity &> /dev/null; then
    log "Error: AWS credentials not configured. Please run 'aws configure'"
    exit 1
fi

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
log "AWS Account ID: ${AWS_ACCOUNT_ID}"

# Construct ECR repository URL
ECR_REPOSITORY_URL="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${APP_NAME}-${ENVIRONMENT}"
log "ECR Repository URL: ${ECR_REPOSITORY_URL}"

# Create ECR repository if it doesn't exist
if ! aws ecr describe-repositories --repository-names "${APP_NAME}-${ENVIRONMENT}" &> /dev/null; then
    log "Creating ECR repository..."
    aws ecr create-repository --repository-name "${APP_NAME}-${ENVIRONMENT}" \
        --image-scanning-configuration scanOnPush=true
fi

# Login to ECR
log "Logging into ECR..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPOSITORY_URL}

if [ $? -ne 0 ]; then
    log "Error: Failed to login to ECR. Retrying..."
    # Try to authenticate again
    aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPOSITORY_URL}
    
    if [ $? -ne 0 ]; then
        log "Error: Failed to login to ECR after retry"
        exit 1
    fi
fi

# Build Docker image
log "Building Docker image..."
cd "$APP_DIR"
docker build --no-cache -t ${APP_NAME}-${ENVIRONMENT} .

# Tag Docker image
log "Tagging Docker image..."
docker tag ${APP_NAME}-${ENVIRONMENT}:latest ${ECR_REPOSITORY_URL}:latest

# Push to ECR with retry logic
max_attempts=3
attempt=1

while [ $attempt -le $max_attempts ]; do
    log "Pushing to ECR (Attempt $attempt of $max_attempts)..."
    if docker push ${ECR_REPOSITORY_URL}:latest; then
        log "Successfully pushed image to ECR"
        break
    else
        if [ $attempt -eq $max_attempts ]; then
            log "Error: Failed to push to ECR after $max_attempts attempts"
            exit 1
        fi
        log "Push failed. Retrying..."
        # Re-authenticate before retry
        aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPOSITORY_URL}
        attempt=$((attempt + 1))
    fi
done

# Deploy static assets to S3
log "Deploying static assets to S3..."
aws s3 sync out/ s3://${WEBSITE_BUCKET_NAME} --delete

# Update ECS service
log "Updating ECS service..."
aws ecs update-service \
    --cluster ${ECS_CLUSTER_NAME} \
    --service ${ECS_SERVICE_NAME} \
    --force-new-deployment

log "Deployment completed successfully!"