pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerpass')
        KUBECONFIG_CREDENTIALS = credentials('kubeconfig')
        DOCKER_IMAGE = 'rafeek123/final_project'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/rafeek209/Final_Project.git'
            }
        }

        stage('Build') {
            steps {
                script {
                    def branch = env.BRANCH_NAME
                    if (branch == 'dev') {
                        sh 'docker build -t $DOCKER_IMAGE:dev .'
                    } else if (branch == 'prod') {
                        sh 'docker build -t $DOCKER_IMAGE:prod .'
                    }
                }
            }
        }

        stage('Push') {
            steps {
                script {
                    docker.withRegistry('', DOCKERHUB_CREDENTIALS) {
                        def branch = env.BRANCH_NAME
                        if (branch == 'dev') {
                            sh 'docker push $DOCKER_IMAGE:dev'
                        } else if (branch == 'prod') {
                            sh 'docker push $DOCKER_IMAGE:prod'
                        }
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    withCredentials([file(credentialsId: 'kubeconfig-credentials', variable: 'KUBECONFIG')]) {
                        def branch = env.BRANCH_NAME
                        if (branch == 'dev') {
                            sh 'kubectl --kubeconfig=$KUBECONFIG apply -f k8s/dev'
                        } else if (branch == 'prod') {
                            sh 'kubectl --kubeconfig=$KUBECONFIG apply -f k8s/prod'
                        }
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
