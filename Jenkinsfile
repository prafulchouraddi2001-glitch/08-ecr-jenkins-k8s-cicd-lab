
pipeline {
    agent { label 'docker-enabled-agent' }

    environment {
        IMAGE_NAME = 'project8-cicd-lab'
        IMAGE_TAG = '1.0'
        AWS_DEFAULT_REGION = 'ap-south-1'
        ECR_REGISTRY = '258167965211.dkr.ecr.ap-south-1.amazonaws.com'
        ECR_REPOSITORY = 'project8-cicd-lab'
        PYTHONPATH = '/home/jenkins/agent/project8-python-libs'
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

        stage('Export Docker Image') {
            steps {
                sh '''
                    mkdir -p /home/jenkins/agent/project8-handoff
                    docker image save \
                        -o /home/jenkins/agent/project8-handoff/${IMAGE_NAME}-${IMAGE_TAG}.tar \
                        ${IMAGE_NAME}:${IMAGE_TAG}
                    ls -lh /home/jenkins/agent/project8-handoff/${IMAGE_NAME}-${IMAGE_TAG}.tar
                '''
            }
        }

        stage('Push Image to Amazon ECR') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'project8-aws-ecr',
                    usernameVariable: 'AWS_ACCESS_KEY_ID',
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                )]) {
                    sh '''
                        set +x
                        trap 'docker logout "$ECR_REGISTRY" >/dev/null 2>&1 || true' EXIT

                        python3 -c '
import base64
import boto3
import os

client = boto3.client("ecr", region_name=os.environ["AWS_DEFAULT_REGION"])
token = client.get_authorization_token()["authorizationData"][0]["authorizationToken"]
username, password = base64.b64decode(token).decode("utf-8").split(":", 1)
if username != "AWS":
    raise RuntimeError("Unexpected ECR authorization username")
print(password, end="")
' | docker login \
                            --username AWS \
                            --password-stdin "$ECR_REGISTRY"

                        docker tag \
                            "$IMAGE_NAME:$IMAGE_TAG" \
                            "$ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG"

                        docker push \
                            "$ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG"
                    '''
                }
            }
        }
    }

    post {
        success {
            echo 'Project 8 CI pipeline and ECR image push completed successfully.'
        }
        failure {
            echo 'Project 8 CI pipeline failed. Review the stage logs.'
        }
    }
}
