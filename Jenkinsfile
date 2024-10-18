pipeline {
    agent any

    environment {
        DOCKER_CREDENTIALS_ID = 'dockerpass' // Update with actual ID
        GITHUB_CREDENTIALS_ID = 'gitpass' // Update with actual ID
        DOCKER_IMAGE = "rafeek123/final_project"
        NAMESPACE = 'dev' // Change to 'prod' for production deployments
    }

    stages {
        stage('Checkout SCM') {
            steps {
                script {
                    checkout([$class: 'GitSCM', branches: [[name: '*/main']], userRemoteConfigs: [[url: 'https://github.com/rafeek209/Final_Project.git', credentialsId: "${GITHUB_CREDENTIALS_ID}"]]])
                }
            }
        }

        stage('DockerHub Login') {
            steps {
                withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDENTIALS_ID}", usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    script {
                        echo "Logging in to DockerHub with user: ${USERNAME}"
                        sh "echo \$PASSWORD | docker login -u \$USERNAME --password-stdin"
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    echo "Building Docker image: ${DOCKER_IMAGE}:dev"
                    sh "docker build -t ${DOCKER_IMAGE}:dev ."
                }
            }
        }

        stage('Push Docker Image to DockerHub') {
            steps {
                script {
                    echo "Pushing Docker image: ${DOCKER_IMAGE}:dev"
                    sh "docker push ${DOCKER_IMAGE}:dev"
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    echo "Deploying to Kubernetes namespace: ${NAMESPACE}"
                    sh "kubectl apply -f k8s_file/deployment-${NAMESPACE}.yaml -n ${NAMESPACE}"
                    sh "kubectl apply -f k8s_file/service-${NAMESPACE}.yaml -n ${NAMESPACE}"
                }
            }
        }
    }

    post {
        always {
            script {
                echo "Cleaning up..."
                sh "docker system prune -f"
            }
        }
        success {
            echo "Build completed successfully!"
        }
        failure {
            echo "Build failed."
        }
    }
}
