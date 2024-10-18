pipeline {
    agent any
    stages {
        stage('DockerHub Login') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerpass', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    script {
                        echo "Logging in to DockerHub with user: ${USERNAME}"
                        sh "echo '${PASSWORD}' | docker login -u '${USERNAME}' --password-stdin"
                    }
                }
            }
        }

        stage('Checkout') {
            steps {
                script {
                    def branchName = env.BRANCH_NAME
                    checkout scm: [
                        $class: 'GitSCM',
                        branches: [[name: "*/${branchName}"]],
                        userRemoteConfigs: [[url: 'https://github.com/yourusername/your-repo.git', credentialsId: 'github-credentials']]
                    ]
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
                    // Define app globally for usage in later stages
                    app = docker.build("rafeek123/final_project:${env.BRANCH_NAME}-${env.BUILD_NUMBER}")
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', 'dockerpass') {
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
