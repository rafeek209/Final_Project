pipeline {
    agent any
    
    environment {
        DOCKER_CREDENTIALS = credentials('dockerhub-credentials') // Replace with your DockerHub credentials ID
        GIT_URL = 'https://github.com/rafeek209/Final_Project.git'
        IMAGE_NAME = 'rafeek123/final_project' // Change to your desired Docker image name
    }

    stages {
        stage('Checkout SCM') {
            steps {
                echo "Checking out the main branch from Git"
                git branch: 'main', url: GIT_URL
            }
        }

        stage('DockerHub Login') {
            steps {
                script {
                    echo "Logging in to DockerHub with user: ${DOCKER_CREDENTIALS.username}"
                    sh "echo '${DOCKER_CREDENTIALS.password}' | docker login -u '${DOCKER_CREDENTIALS.username}' --password-stdin"
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    echo "Building Docker image: ${IMAGE_NAME}"
                    sh "docker build -t ${IMAGE_NAME}:latest ."
                }
            }
        }

        stage('Push Docker Image to DockerHub') {
            steps {
                script {
                    echo "Pushing Docker image to DockerHub"
                    sh "docker push ${IMAGE_NAME}:latest"
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    echo "Deploying to Kubernetes"
                    // Add your kubectl commands here, e.g., apply a deployment
                    sh "kubectl apply -f k8s/deployment.yaml" // Adjust the path to your deployment YAML file
                }
            }
        }
    }

    post {
        always {
            echo 'Cleaning up the workspace'
            cleanWs()
        }
    }
}
