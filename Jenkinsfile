pipeline {
    agent any

    environment {
        KUBECONFIG = '/home/crazy/kubeconfig' // Set your kubeconfig path
    }

    stages {
        stage('Checkout Code') {
            steps {
                // Checkout your code from Git
                git 'https://github.com/rafeek209/Final_Project.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                // Build your Docker image
                script {
                    sh 'docker build -t rafeek123/final_project:dev .'
                }
            }
        }

        stage('Push Docker Image to DockerHub') {
            steps {
                // Push the Docker image to DockerHub
                script {
                    sh 'docker push rafeek123/final_project:dev'
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    // Deploy the application to Kubernetes
                    sh '''
                        kubectl apply -f k8s_file/deployment-dev.yaml
                        kubectl apply -f k8s_file/service-dev.yaml
                    '''
                }
            }
        }
    }

    post {
        success {
            echo 'Deployment successful!'
        }
        failure {
            echo 'Deployment failed!'
        }
    }
}
