pipeline {
    agent {
        docker {
            image 'your-docker-image:latest'  // Replace with your Docker image
            args '-u root:root'                // Adjust user permissions if necessary
        }
    }
    stages {
        stage('Build') {
            steps {
                echo 'Building...'
                // Add your build commands here, for example:
                sh 'make' // Replace with your build command
            }
        }
        stage('Test') {
            steps {
                echo 'Testing...'
                // Add your test commands here, for example:
                sh 'make test' // Replace with your test command
            }
        }
        stage('Deploy') {
            steps {
                echo 'Deploying...'
                // Add your deployment commands here, for example:
                sh 'make deploy' // Replace with your deployment command
            }
        }
    }
    post {
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed.'
        }
        always {
            echo 'Cleaning up...'
            // Add cleanup commands if necessary
        }
    }
}
