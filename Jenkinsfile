pipeline {
    agent any

    environment {
        IMAGE_NAME = 'project8-cicd-lab'
        IMAGE_TAG = '1.0'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Unit Tests') {
            steps {
                sh 'python3 -W error::ResourceWarning -m unittest discover -s tests -v'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .'
            }
        }

        stage('Verify Docker Image') {
            steps {
                sh 'docker image inspect ${IMAGE_NAME}:${IMAGE_TAG} --format "Image={{.RepoTags}} | Size={{.Size}} bytes"'
            }
        }
    }

    post {
        success {
            echo 'Project 8 CI pipeline completed successfully.'
        }
        failure {
            echo 'Project 8 CI pipeline failed. Review the stage logs.'
        }
    }
}
