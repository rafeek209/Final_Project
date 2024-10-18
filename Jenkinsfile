pipeline {
    agent any

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

        stage('Build Docker Image') {
            steps {
                script {
                    def branch = env.BRANCH_NAME
                    def imageName = "rafeek123/final_project:${branch == 'main' ? 'prod' : 'dev'}"
                    echo "Building Docker image: $imageName"
                    sh "docker build -t ${imageName} ."
                }
            }
        }

        stage('Push Docker Image to DockerHub') {
            steps {
                script {
                    def branch = env.BRANCH_NAME
                    def imageName = "rafeek123/final_project:${branch == 'main' ? 'prod' : 'dev'}"
                    echo "Pushing Docker image: $imageName"
                    sh "docker push ${imageName}"
                }
            }
        }

        stage('Deploy to Kubernetes') {
            agent {
                docker {
                    image 'bitnami/kubectl:latest'
                    args '-v /var/run/docker.sock:/var/run/docker.sock' // Optional: Mount Docker socket if needed
                }
            }
            steps {
                script {
                    def branch = env.BRANCH_NAME
                    def namespace = branch == 'main' ? 'prod' : 'dev'
                    echo "Deploying to Kubernetes namespace: $namespace"
                    sh '''
                        kubectl apply -f k8s_file/deployment-${namespace}.yaml
                        kubectl apply -f k8s_file/service-${namespace}.yaml
                    '''
                }
            }
        }
    }

    post {
        always {
            echo "Cleaning up..."
            sh '''
                docker system prune -f
            '''
            echo "Build completed: ${env.BUILD_ID}"
        }
    }
}
