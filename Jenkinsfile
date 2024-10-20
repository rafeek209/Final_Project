pipeline {
    agent {
        docker {
            image 'docker:latest'
            args '--privileged'
        }
    }

    environment {
        DOCKER_CREDENTIALS_ID = 'dockerpass'
        KUBECONFIG_PATH = 'kubeconfig'
    }

    stages {
        stage('Clone Repository') {
            steps {
                git branch: 'main', url: 'https://github.com/rafeek209/Final_Project.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    // Check if Docker is available before proceeding
                    sh 'docker --version'
                    dockerImage = docker.build("rafeek123/final_project:${env.BUILD_NUMBER}")
                }
            }
        }

        stage('Push Docker Image to Docker Hub') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', "${DOCKER_CREDENTIALS_ID}") {
                        dockerImage.push('latest')
                        dockerImage.push("${env.BUILD_NUMBER}")
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    sh 'mkdir -p ~/.kube'
                    sh "cp ${KUBECONFIG_PATH} ~/.kube/config"

                    sh 'export KUBECONFIG=~/.kube/config'

                    sh 'kubectl apply -f k8s_file/deployment-dev.yaml --namespace=dev'
                    sh 'kubectl apply -f k8s_file/service-dev.yaml --namespace=dev'
                }
            }
        }
    }
}
