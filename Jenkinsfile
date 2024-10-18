pipeline {
    agent {
        docker {
            image 'lachlanevenson/k8s-helm:latest'
            args '-u root:root'
        }
    }

    environment {
        DOCKER_HUB_REPO = 'rafeek123/final_project'
        KUBECONFIG_CRED_ID = 'kubeconfig'
        DOCKER_CRED_ID = 'dockerpass'
        KUBE_NAMESPACE_DEV = 'dev'
        KUBE_NAMESPACE_PROD = 'prod'
    }

    stages {
        stage('DockerHub Login') {
            steps {
                withCredentials([usernamePassword(credentialsId: "${DOCKER_CRED_ID}", usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    sh '''
                        echo "Logging in to DockerHub with user: $USERNAME"
                        echo "$PASSWORD" | docker login -u "$USERNAME" --password-stdin
                    '''
                }
            }
        }

        stage('Log Branch Name') {
            steps {
                script {
                    echo "Current GIT_BRANCH: ${env.GIT_BRANCH ?: 'main'}"
                }
            }
        }

        stage('Checkout Code') {
            steps {
                script {
                    echo "Checking out the main branch."
                }
                // Always checks out the main branch
                git branch: 'main', url: 'https://github.com/rafeek209/Final_Project.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    def appName = "${DOCKER_HUB_REPO}:${env.GIT_COMMIT}"
                    docker.build(appName)
                }
            }
        }

        stage('Push Docker Image to DockerHub') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', "${DOCKER_CRED_ID}") {
                        def appImage = docker.image("${DOCKER_HUB_REPO}:${env.GIT_COMMIT}")
                        appImage.push()
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    // Always deploy to the production namespace
                    def namespace = KUBE_NAMESPACE_PROD // Change to PRODUCTION by default
                    withKubeConfig([credentialsId: "${KUBECONFIG_CRED_ID}"]) {
                        sh """
                        kubectl apply -f k8s_file/deployment-prod.yaml -n ${namespace}
                        kubectl apply -f k8s_file/service-prod.yaml -n ${namespace}
                        """
                    }
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}
