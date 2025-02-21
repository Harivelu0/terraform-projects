#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to log messages
log() {
    echo -e "${GREEN}$(date '+%Y-%m-%d %H:%M:%S') -${NC} $1"
}

# Function to log warnings
warn() {
    echo -e "${YELLOW}$(date '+%Y-%m-%d %H:%M:%S') - WARNING:${NC} $1"
}

# Function to log errors
error() {
    echo -e "${RED}$(date '+%Y-%m-%d %H:%M:%S') - ERROR: $1${NC}"
    exit 1
}

# Function to display usage
usage() {
    echo "Usage: $0 [-a AWS_ACCOUNT] [-r AWS_REGION] [-e ECR_REPOSITORY]"
    echo "  or using environment variables:"
    echo "  AWS_ACCOUNT, AWS_REGION, ECR_REPOSITORY"
    exit 1
}

# Parse command line arguments
while getopts ":a:r:e:" opt; do
    case $opt in
        a) AWS_ACCOUNT="$OPTARG" ;;
        r) AWS_REGION="$OPTARG" ;;
        e) ECR_REPOSITORY="$OPTARG" ;;
        \?) error "Invalid option -$OPTARG" ;;
    esac
done

# Check for environment variables if not provided as arguments
AWS_ACCOUNT=${AWS_ACCOUNT:-${AWS_ACCOUNT_ID}}
AWS_REGION=${AWS_REGION:-${AWS_DEFAULT_REGION:-"us-east-1"}}
ECR_REPOSITORY=${ECR_REPOSITORY:-${ECR_REPO_NAME}}

# Validate required parameters
if [ -z "$AWS_ACCOUNT" ]; then
    error "AWS Account ID is required. Provide it as an argument (-a) or environment variable (AWS_ACCOUNT_ID)"
fi

if [ -z "$ECR_REPOSITORY" ]; then
    error "ECR Repository name is required. Provide it as an argument (-e) or environment variable (ECR_REPO_NAME)"
fi

log "Using AWS Account: $AWS_ACCOUNT"
log "Using AWS Region: $AWS_REGION"
log "Using ECR Repository: $ECR_REPOSITORY"

# Set ECR URL
ECR_URL="${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com"
IMAGE_NAME="${ECR_URL}/${ECR_REPOSITORY}"

# Check if we're in the right directory
if [ ! -f "Dockerfile" ]; then
    if [ -f "jira-clone/Dockerfile" ]; then
        cd jira-clone
        log "Changed directory to jira-clone"
    else
        error "Dockerfile not found in current directory or jira-clone/. Please make sure you're in the correct directory."
    fi
fi

# Check if repository exists (with quiet output)
log "Checking if ECR repository exists..."
if ! aws ecr describe-repositories --repository-names ${ECR_REPOSITORY} --region ${AWS_REGION} --output text &> /dev/null; then
    log "Creating ECR repository..."
    aws ecr create-repository \
        --repository-name ${ECR_REPOSITORY} \
        --region ${AWS_REGION} \
        --image-scanning-configuration scanOnPush=true \
        --output text &> /dev/null
    log "Repository created successfully"
else
    log "Repository already exists"
fi

# Authenticate with ECR
log "Authenticating with ECR..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_URL} &> /dev/null
log "Authentication successful"

# Build Docker image
log "Building Docker image..."
docker build -t ${ECR_REPOSITORY} .

# Tag the image
log "Tagging Docker image..."
docker tag ${ECR_REPOSITORY}:latest ${IMAGE_NAME}:latest

# Push the image
log "Pushing image to ECR..."
docker push ${IMAGE_NAME}:latest

log ":sparkles: Deployment completed successfully! :sparkles:"
log "Your application will be available at your ECS service endpoint."