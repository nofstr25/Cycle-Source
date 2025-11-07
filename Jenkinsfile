pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = credentials('DockerHub-Credentials')
        GIT_CREDENTIALS = credentials('GitHub-Pat-Token') // Create this in Jenkins
        IMAGE_NAME = 'nofstr25/cycle'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        SOURCE_REPO = 'https://github.com/nofstr25/Cycle-Source.git'
        OPS_REPO = 'https://github.com/nofstr25/Cycle-Ops.git'
    }

    stages {
        stage('Clone Source Repo') {
            steps {
                git branch: 'main', url: "${SOURCE_REPO}"
            }
        }

        
        stage('Build Docker Image') {
            steps {
                script {
                    sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} -f Dockerfile ."
                }
            }
        }

        stage('Parallel Checks') {
            parallel {
                stage('Linting') {
                    steps {
                        script {
                            // Python linting
                            sh 'pip install flake8 autopep8'
                            sh 'autopep8 --in-place --aggressive --aggressive JenkinsBuildImage/main.py'
                            sh 'flake8 JenkinsBuildImage/main.py'

                            // Shell scripts linting
                            lock(resource: 'apt-lock') {
                                sh '''
                                    apt-get update
                                    apt-get install -y shellcheck
                                '''
                            }
                            sh 'find . -name "*.sh" | xargs shellcheck -e SC2034,SC2223,SC2005,SC2016,SC2124,SC2046,SC2155,SC2166,SC2174,SC2268,SC2006,SC2086'

                            // Dockerfile linting
                            sh '''
                                wget -O /usr/local/bin/hadolint https://github.com/hadolint/hadolint/releases/latest/download/hadolint-Linux-x86_64
                                chmod +x /usr/local/bin/hadolint
                                find . -name "Dockerfile" -print0 | xargs -0 hadolint
                            '''
                        }
                    }
                }

                stage('Security Scanning') {
                    steps {
                        script {
                            sh 'pip install bandit'
                            sh 'bandit -r .'

                            // Docker image security scanning with Trivy
                            lock(resource: 'apt-lock') {
                                sh '''
                                    apt-get update
                                    apt-get install -y wget
                                '''
                            }
                            sh '''
                                wget -qO /tmp/trivy.deb https://github.com/aquasecurity/trivy/releases/download/v0.67.2/trivy_0.67.2_Linux-64bit.deb
                                dpkg -i /tmp/trivy.deb
                                trivy image --exit-code 1 --severity HIGH,CRITICAL ${IMAGE_NAME}:${IMAGE_TAG}
                            '''
                        }
                    }
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                script {
                    sh "echo ${DOCKERHUB_CREDENTIALS_PSW} | docker login -u ${DOCKERHUB_CREDENTIALS_USR} --password-stdin"
                    sh "docker push ${IMAGE_NAME}:${IMAGE_TAG}"
                }
            }
        }
        
        stage('Update GitOps Repo') {
            steps {
                script {
                    // clone Cycle-Ops repo with token
                    sh """
                        rm -rf Cycle-Ops
                        git clone https://${GIT_TOKEN}@github.com/nofstr25/Cycle-Ops.git
                        cd Cycle-Ops

                        sed -i "s|imageTag: .*|imageTag: ${IMAGE_TAG}|" values.yaml

                        git config user.email "jenkins@ci.local"
                        git config user.name "Jenkins CI"

                        git add values.yaml
                        git commit -m "Updated imageTag value to ${IMAGE_TAG}" || echo "No changes to commit"
                        git push https://${GIT_TOKEN}@github.com/nofstr25/Cycle-Ops.git main
                    """
                }
            }
        }
   
    }

    post {
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed! Check logs for details.'
        }
    }
}