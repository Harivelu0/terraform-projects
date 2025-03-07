#!/bin/bash

# Deployment script for Docker containerized Next.js application
# This script also integrates with Terraform for infrastructure management

# Get the environment from the command line
ENV=$1

if [ -z "$ENV" ]; then
    echo "Error: Environment not specified"
    echo "Usage: ./deploy.sh [dev|staging|production]"
    exit 1
fi

echo "Deploying $APP_NAME to $ENV environment..."

# Make sure required environment variables are set
if [ -z "$DOCKER_IMAGE" ] || [ -z "$DOCKER_TAG" ]; then
    echo "Error: Required environment variables not set"
    echo "Please ensure DOCKER_IMAGE and DOCKER_TAG are defined"
    exit 1
fi

# Function to deploy using Terraform
deploy_with_terraform() {
    local env=$1
    
    echo "Deploying to $env using Terraform..."
    
    # Change to terraform directory
    cd terraform
    
    # Initialize Terraform
    terraform init
    
    # Apply Terraform with variables
    terraform apply \
        -var="environment=$env" \
        -var="docker_image=${DOCKER_IMAGE}:${DOCKER_TAG}" \
        -var="database_url=${DATABASE_URL}" \
        -var="clerk_secret_key=${CLERK_SECRET_KEY}" \
        -var="clerk_publishable_key=${NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY}" \
        -var-file="environments/$env/terraform.tfvars" \
        -auto-approve
    
    # Return to original directory
    cd ..
}

# Function to update ECS service
update_ecs_service() {
    local env=$1
    local cluster="$APP_NAME-$env"
    local service="$APP_NAME-service"
    
    echo "Updating ECS service in $env environment..."
    
    # Force new deployment of the ECS service
    aws ecs update-service \
        --cluster $cluster \
        --service $service \
        --force-new-deployment
}

case $ENV in
    dev)
        # Development environment deployment
        echo "Deploying to development environment..."
        deploy_with_terraform dev
        update_ecs_service dev
        echo "Development deployment completed"
        ;;
        
    staging)
        # Staging environment deployment
        echo "Deploying to staging environment..."
        deploy_with_terraform staging
        update_ecs_service staging
        echo "Staging deployment completed"
        ;;
        
    production)
        # Production environment deployment
        echo "Deploying to production environment..."
        deploy_with_terraform production
        update_ecs_service production
        
        # Tag the release in Git
        git tag -a "release-${DOCKER_TAG}" -m "Production release ${DOCKER_TAG}"
        git push origin "release-${DOCKER_TAG}"
        
        echo "Production deployment completed"
        ;;
        
    *)
        echo "Error: Unknown environment '$ENV'"
        exit 1
        ;;
esac

echo "Deployment to $ENV completed successfully!"
exit 0