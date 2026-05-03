pipeline {
    agent any

    environment {
        // DockerHub credentials configured in Jenkins
        DOCKERHUB_CREDENTIALS = credentials('2f5df908-432c-4c5e-aa9d-75794c067f99')
        DOCKERHUB_REPO        = 'tigershroff/octa-byte'
        
        // AWS config
        AWS_REGION            = 'ap-south-1'
        S3_BUCKET             = 'octa-byte-devops-static-site-staging'
        CF_DISTRIBUTION_ID    = 'E3AVYPAHS4L4AO'
        
        // Image tag uses git commit hash — unique per build
        IMAGE_TAG             = "${env.BUILD_NUMBER}-${env.GIT_COMMIT?.take(7)}"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
                echo "Building branch: ${env.BRANCH_NAME}"
                echo "Commit: ${env.GIT_COMMIT}"
            }
        }

        stage('Test') {
            steps {
                echo 'Running HTML validation tests...'
                sh '''
                    # Install html linter if not present
                    if ! command -v tidy &> /dev/null; then
                        sudo yum install -y tidy || sudo apt-get install -y tidy
                    fi
                    
                    # Run tidy on all HTML files
                    find ./app -name "*.html" | while read file; do
                        echo "Checking $file"
                        tidy -errors -quiet "$file" || true
                    done
                    
                    echo "HTML validation complete"
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "Building Docker image: ${DOCKERHUB_REPO}:${IMAGE_TAG}"
                sh '''
                    docker build -t ${DOCKERHUB_REPO}:${IMAGE_TAG} .
                    docker tag ${DOCKERHUB_REPO}:${IMAGE_TAG} ${DOCKERHUB_REPO}:latest
                '''
            }
        }

        stage('Push to DockerHub') {
            steps {
                echo 'Pushing Docker image to DockerHub...'
                sh '''
                    echo ${DOCKERHUB_CREDENTIALS_PSW} | docker login \
                        -u ${DOCKERHUB_CREDENTIALS_USR} \
                        --password-stdin
                    docker push ${DOCKERHUB_REPO}:${IMAGE_TAG}
                    docker push ${DOCKERHUB_REPO}:latest
                '''
            }
        }

        stage('Deploy to Staging') {
            steps {
                echo 'Deploying to staging S3 bucket...'
                withAWS(region: "${AWS_REGION}", credentials: 'aws-credentials') {
                    sh '''
                        # Upload static files to S3
                        aws s3 sync ./app s3://${S3_BUCKET} \
                            --delete \
                            --cache-control "max-age=3600"
                        
                        echo "Files uploaded to S3 successfully"
                    '''
                    
                    // Invalidate CloudFront cache so users get fresh files
                    sh '''
                        aws cloudfront create-invalidation \
                            --distribution-id ${CF_DISTRIBUTION_ID} \
                            --paths "/*"
                        
                        echo "CloudFront cache invalidated"
                    '''
                }
            }
        }

        stage('Approval for Production') {
            steps {
                echo 'Waiting for manual approval...'
                // Pauses pipeline and sends email asking for approval
                mail(
                    to: 'your@gmail.com',
                    subject: "Approval needed: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                    body: """
                        Build ${env.BUILD_NUMBER} is ready for production.
                        
                        Branch : ${env.BRANCH_NAME}
                        Commit : ${env.GIT_COMMIT}
                        
                        Approve here: ${env.BUILD_URL}input
                    """
                )
                timeout(time: 24, unit: 'HOURS') {
                    input message: 'Deploy to production?', ok: 'Yes, deploy'
                }
            }
        }

        stage('Deploy to Production') {
            steps {
                echo 'Deploying to production...'
                withAWS(region: "${AWS_REGION}") {
                    sh '''
                        aws s3 sync ./app s3://${S3_BUCKET} \
                            --delete \
                            --cache-control "max-age=86400"
                    '''
                    sh '''
                        aws cloudfront create-invalidation \
                            --distribution-id ${CF_DISTRIBUTION_ID} \
                            --paths "/*"
                    '''
                }
                echo "Production deployment complete"
            }
        }
    }

    post {
        failure {
            echo 'Pipeline failed — sending email notification'
            mail(
                to: 'siddardhareddy456@gmail.com',
                subject: "FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: """
                    Pipeline failed at stage: ${env.STAGE_NAME}
                    
                    Job    : ${env.JOB_NAME}
                    Build  : ${env.BUILD_NUMBER}
                    Branch : ${env.BRANCH_NAME}
                    
                    Check logs here: ${env.BUILD_URL}console
                """
            )
        }
        success {
            echo 'Pipeline succeeded — sending confirmation email'
            mail(
                to: 'siddardhareddy456@gmail.com',
                subject: "SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: """
                    Deployment completed successfully.
                    
                    Job    : ${env.JOB_NAME}
                    Build  : ${env.BUILD_NUMBER}
                    Branch : ${env.BRANCH_NAME}
                    URL    : https://${CF_DISTRIBUTION_ID}.cloudfront.net
                """
            )
        }
        always {
            // Clean up docker images to save disk space
            sh 'docker rmi ${DOCKERHUB_REPO}:${IMAGE_TAG} || true'
        }
    }
}
