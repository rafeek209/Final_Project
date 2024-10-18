pipeline {
    agent any
    environment {
        DOCKER_IMAGE = "rafeek123/final_project:${env.BRANCH_NAME}"
    }
    stages {
        stage('DockerHub Login') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerpass', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    sh '''
                        echo "Logging in to DockerHub with user: $USERNAME"
                        echo "$PASSWORD" | docker login -u "$USERNAME" --password-stdin
                    '''
                }
            }
        }

        stage('Checkout') {
            steps {
                script {
                    if (env.BRANCH_NAME == 'dev') {
                        checkout scm: [
                            $class: 'GitSCM',
                            branches: [[name: '*/dev']],
                            userRemoteConfigs: [[url: 'https://github.com/rafeek209/Final_Project.git', credentialsId: 'github-credentials']]
                        ]
                    } else if (env.BRANCH_NAME == 'prod') {
                        checkout scm: [
                            $class: 'GitSCM',
                            branches: [[name: '*/prod']],
                            userRemoteConfigs: [[url: 'https://github.com/rafeek209/Final_Project.git', credentialsId: 'github-credentials']]
                        ]
                    }
                }
            }
        }

        stage('Build Docker Image') {
            agent {
                docker {
                    image 'docker:latest' // Use Docker as the agent
                    args '-v /var/run/docker.sock:/var/run/docker.sock' // Mount Docker socket
                    reuseNode true
                }
            }
            steps {
                script {
                    // Build the Docker image and assign it to a variable
                    def app = docker.build(DOCKER_IMAGE)
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', 'dockerpass') {
                        // Use the global DOCKER_IMAGE variable here
                        app.push()
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    if (env.BRANCH_NAME == 'dev') {
                        sh "kubectl apply -f k8s_file/deployment-dev.yml"
                        sh "kubectl apply -f k8s_file/service-dev.yml"
                    } else if (env.BRANCH_NAME == 'prod') {
                        sh "kubectl apply -f k8s_file/deployment-prod.yml"
                        sh "kubectl apply -f k8s_file/service-prod.yml"
                    }
                }
            }
        }
    }
    post {
        always {
            echo "Running build: ${env.BUILD_ID}"
        }
    }
}
