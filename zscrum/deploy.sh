#!/bin/bash

# Deployment script for ZScrum Next.js application

# Get the environment from the command line
ENV=$1

if [ -z "$ENV" ]; then
    echo "Error: Environment not specified"
    echo "Usage: ./deploy.sh [dev|staging|production]"
    exit 1
fi

echo "Deploying ZScrum Jira Clone to $ENV environment..."

# Create deployment directory if it doesn't exist
DEPLOY_DIR="deploy_temp"
mkdir -p $DEPLOY_DIR

# Extract the artifact to the deployment directory
tar -xzf nextjs-app.tar.gz -C $DEPLOY_DIR

case $ENV in
    dev)
        # Development server deployment
        echo "Deploying to development server..."
        
        # Example for Docker-based deployment (adjust as needed)
        # cp jira-clone/Dockerfile $DEPLOY_DIR/
        # cd $DEPLOY_DIR
        # docker build -t zscrum:dev .
        # docker stop zscrum-dev || true
        # docker rm zscrum-dev || true
        # docker run -d --name zscrum-dev -p 3000:3000 zscrum:dev
        
        # Alternative: Copy to server using SSH
        # rsync -avz --delete $DEPLOY_DIR/ user@dev-server:/path/to/app/
        # ssh user@dev-server "cd /path/to/app && npm install --production && pm2 restart zscrum-dev"
        
        echo "Development deployment completed"
        ;;
        
    staging)
        # Staging server deployment
        echo "Deploying to staging server..."
        
        # Example for Docker-based deployment
        # cp jira-clone/Dockerfile $DEPLOY_DIR/
        # cd $DEPLOY_DIR
        # docker build -t zscrum:staging .
        # docker stop zscrum-staging || true
        # docker rm zscrum-staging || true
        # docker run -d --name zscrum-staging -p 3001:3000 zscrum:staging
        
        echo "Staging deployment completed"
        ;;
        
    production)
        # Production server deployment
        echo "Deploying to production server..."
        
        # Example for AWS ECS deployment (if using the terraform in your repo)
        # cp jira-clone/Dockerfile $DEPLOY_DIR/
        # cd $DEPLOY_DIR
        # aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin YOUR_AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
        # docker build -t zscrum:latest .
        # docker tag zscrum:latest YOUR_AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/zscrum:latest
        # docker push YOUR_AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/zscrum:latest
        # aws ecs update-service --cluster zscrum-cluster --service zscrum-service --force-new-deployment
        
        echo "Production deployment completed"
        ;;
        
    *)
        echo "Error: Unknown environment '$ENV'"
        exit 1
        ;;
esac

# Clean up deployment directory
rm -rf $DEPLOY_DIR

echo "Deployment to $ENV completed successfully!"
exit 0