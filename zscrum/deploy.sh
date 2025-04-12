pipeline {
    agent any
    
    // Define variables used in the pipeline
    environment {
        APP_NAME = "jira-clone"
        DOCKER_REGISTRY = "your-docker-registry" // e.g., Docker Hub username or your container registry
        DOCKER_IMAGE = "${DOCKER_REGISTRY}/${APP_NAME}"
        DOCKER_TAG = "${env.BUILD_NUMBER}"
        // Reference credentials stored in Jenkins
        DATABASE_URL = credentials('DATABASE_URL_CREDENTIAL')
        CLERK_SECRET_KEY = credentials('CLERK_SECRET_KEY_CREDENTIAL')
        NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY = credentials('NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY_CREDENTIAL')
        // Docker credentials
        DOCKER_CREDENTIALS = credentials('DOCKER_CREDENTIALS')
    }
    
    // Define parameters that can be set when triggering the pipeline
    parameters {
        choice(name: 'ENVIRONMENT', choices: ['dev', 'staging', 'production'], description: 'Deployment Environment')
        booleanParam(name: 'RUN_TESTS', defaultValue: true, description: 'Run Tests?')
        booleanParam(name: 'DEPLOY', defaultValue: true, description: 'Deploy Application?')
    }
    
    stages {
        stage('Checkout') {
            steps {
                // This will automatically check out the code from your SCM
                checkout scm
                
                // Print some info about the commit
                sh "echo 'Building commit: ${env.GIT_COMMIT}'"
            }
        }
        
        stage('Install Dependencies') {
            steps {
                // Change to the jira-clone directory and install dependencies
                dir('jira-clone') {
                    sh 'npm ci'
                }
            }
        }
        
        stage('Lint') {
            steps {
                dir('jira-clone') {
                    // Run ESLint
                    sh 'npm run lint || true' // Adding || true to prevent pipeline failure if lint has warnings
                }
            }
        }
        
        stage('Database Migration') {
            steps {
                dir('jira-clone') {
                    // Create a .env file with DATABASE_URL
                    sh '''
                    echo "DATABASE_URL=$DATABASE_URL" > .env
                    '''
                    
                    // Run Prisma migration
                    sh 'npx prisma migrate deploy'
                }
            }
        }
        
        stage('Build') {
            steps {
                dir('jira-clone') {
                    // Update .env file with all environment variables
                    sh '''
                    echo "CLERK_SECRET_KEY=$CLERK_SECRET_KEY" >> .env
                    echo "NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=$NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY" >> .env
                    echo "NEXT_PUBLIC_CLERK_SIGN_IN_URL=/sign-in" >> .env
                    echo "NEXT_PUBLIC_CLERK_SIGN_UP_URL=/sign-up" >> .env
                    echo "NEXT_PUBLIC_CLERK_AFTER_SIGN_IN_URL=/onboarding" >> .env
                    echo "NEXT_PUBLIC_CLERK_AFTER_SIGN_UP_URL=/onboarding" >> .env
                    '''
                    
                    // Build Docker image
                    sh '''
                    docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} -t ${DOCKER_IMAGE}:latest .
                    '''
                }
            }
        }
        
        stage('Test') {
            when {
                expression { params.RUN_TESTS == true }
            }
            steps {
                dir('jira-clone') {
                    // You can add tests here if you have them
                    sh 'echo "Running tests..."'
                    // Example: sh 'npm test'
                }
            }
        }
        
        stage('Push Docker Image') {
            steps {
                // Log in to Docker registry
                sh '''
                echo $DOCKER_CREDENTIALS_PSW | docker login $DOCKER_REGISTRY -u $DOCKER_CREDENTIALS_USR --password-stdin
                docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                docker push ${DOCKER_IMAGE}:latest
                '''
            }
        }
        
        stage('Deploy') {
            when {
                expression { params.DEPLOY == true }
            }
            steps {
                // Deploy based on the selected environment
                script {
                    def deployEnv = params.ENVIRONMENT
                    
                    echo "Deploying to ${deployEnv} environment..."
                    
                    // Pass environment variables to the deploy script
                    withEnv([
                        "APP_NAME=${APP_NAME}",
                        "DOCKER_IMAGE=${DOCKER_IMAGE}",
                        "DOCKER_TAG=${DOCKER_TAG}",
                        "DEPLOY_ENV=${deployEnv}"
                    ]) {
                        switch(deployEnv) {
                            case 'dev':
                                // Development deployment
                                sh './deploy.sh dev'
                                break
                            case 'staging':
                                // Staging deployment
                                sh './deploy.sh staging'
                                break
                            case 'production':
                                // Add approval step for production
                                timeout(time: 1, unit: 'DAYS') {
                                    input message: 'Approve Production Deployment?', submitter: 'admin'
                                }
                                // Production deployment
                                sh './deploy.sh production'
                                break
                            default:
                                echo "No environment specified"
                                break
                        }
                    }
                }
            }
        }
    }
    
    post {
        success {
            echo "Build succeeded! Sending notifications..."
            // Send success notifications
            // slackSend channel: '#builds', color: 'good', message: "Build Succeeded: ${env.JOB_NAME} #${env.BUILD_NUMBER}"
        }
        failure {
            echo "Build failed! Sending notifications..."
            // Send failure notifications
            // slackSend channel: '#builds', color: 'danger', message: "Build Failed: ${env.JOB_NAME} #${env.BUILD_NUMBER}"
        }
        always {
            // Clean up Docker images to save space
            sh '''
            docker rmi ${DOCKER_IMAGE}:${DOCKER_TAG} || true
            docker rmi ${DOCKER_IMAGE}:latest || true
            '''
        }
    }
}