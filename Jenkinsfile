pipeline {
    agent any

    environment {
        DOCKER_HUB_REPO = 'rafeek123/final_project'
        DOCKER_HUB_CREDENTIALS = 'dockerpass'
        KUBECONFIG = 'kubeconfig'
        KUBE_NAMESPACE = 'dev'
    }

    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/rafeek209/Final_Project.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    def imageTag = "${env.BUILD_NUMBER}"
                    sh "docker build -t ${DOCKER_HUB_REPO}:${imageTag} ."
                }
            }
        }

        stage('Push Docker Image to DockerHub') {
            steps {
                script {
                    def imageTag = "${env.BUILD_NUMBER}"
                    withCredentials([usernamePassword(credentialsId: DOCKER_HUB_CREDENTIALS, usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                        sh 'echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin'
                        sh "docker push ${DOCKER_HUB_REPO}:${imageTag}"
                    }
                }
            }
        }

        stage('Deploy to Kubernetes Dev Namespace') {
            steps {
                script {
                    sh "kubectl apply -f k8s_file/deployment-dev.yaml --namespace=${KUBE_NAMESPACE}"
                    sh "kubectl apply -f k8s_file/service-dev.yaml --namespace=${KUBE_NAMESPACE}"
                }
            }
        }
    }

    post {
        success {
            echo 'Deployment to dev namespace was successful!'
        }
        failure {
            echo 'Deployment failed.'
        }
    }
}
