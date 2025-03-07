pipeline {
    agent any
    
    // Define variables used in the pipeline
    environment {
        APP_NAME = "nextjs-application"
        // Reference credentials stored in Jenkins - DO NOT put actual secrets in the Jenkinsfile
        DATABASE_URL = credentials('DATABASE_URL_CREDENTIAL')
        CLERK_SECRET_KEY = credentials('CLERK_SECRET_KEY_CREDENTIAL')
        NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY = credentials('NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY_CREDENTIAL')
        // Public environment variables can be defined directly
        NEXT_PUBLIC_CLERK_SIGN_IN_URL = "/sign-in"
        NEXT_PUBLIC_CLERK_SIGN_UP_URL = "/sign-up"
        NEXT_PUBLIC_CLERK_AFTER_SIGN_IN_URL = "/onboarding"
        NEXT_PUBLIC_CLERK_AFTER_SIGN_UP_URL = "/onboarding"
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
                // Install Node.js dependencies
                sh 'npm ci'
            }
        }
        
        stage('Lint') {
            steps {
                // Run ESLint
                sh 'npm run lint'
            }
        }
        
        stage('Build') {
            steps {
                // Create .env file with environment variables
                script {
                    // Create a .env file with our environment variables
                    sh '''
                    echo "DATABASE_URL=$DATABASE_URL" > .env
                    echo "CLERK_SECRET_KEY=$CLERK_SECRET_KEY" >> .env
                    echo "NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=$NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY" >> .env
                    echo "NEXT_PUBLIC_CLERK_SIGN_IN_URL=$NEXT_PUBLIC_CLERK_SIGN_IN_URL" >> .env
                    echo "NEXT_PUBLIC_CLERK_SIGN_UP_URL=$NEXT_PUBLIC_CLERK_SIGN_UP_URL" >> .env
                    echo "NEXT_PUBLIC_CLERK_AFTER_SIGN_IN_URL=$NEXT_PUBLIC_CLERK_AFTER_SIGN_IN_URL" >> .env
                    echo "NEXT_PUBLIC_CLERK_AFTER_SIGN_UP_URL=$NEXT_PUBLIC_CLERK_AFTER_SIGN_UP_URL" >> .env
                    '''
                }
                
                // Build the Next.js application
                sh 'npm run build'
            }
        }
        
        stage('Test') {
            when {
                expression { params.RUN_TESTS == true }
            }
            steps {
                // Run Next.js tests
                sh 'npm test'
            }
            post {
                always {
                    // If you're using Jest with junit reporter, you can publish the results
                    junit allowEmptyResults: true, testResults: 'junit-reports/*.xml'
                }
            }
        }
        
        stage('Create Artifact') {
            steps {
                // Archive the .next directory and other necessary files
                sh 'tar -czf nextjs-app.tar.gz .next package.json package-lock.json public .env'
                archiveArtifacts artifacts: 'nextjs-app.tar.gz', fingerprint: true
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
            // Clean workspace but keep the node_modules to speed up future builds
            // If workspace space is an issue, you can use 'cleanWs()' instead
            sh 'rm -rf .next .env'
        }
    }
}
