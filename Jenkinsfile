pipeline {-openjdk-amd64'
        PATH = "${JAVA_HOME}/bin:${env.PATH}"
        IMAGE_NAME = 'ochelini/numericapp'
    }

    stages {

        stage('Verify Java') {
            steps {
                sh '''
                    echo "JAVA_HOME=$JAVA_HOME"
                    java -version
                    javac -version
                '''
            }
        }

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Unit Tests') {
            steps {
                sh 'mvn clean test'
            }
            post {
                always {
                    junit 'target/surefire-reports/*.xml'
                }
            }
        }

        stage('Mutation Tests - PIT') {
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                    sh 'mvn org.pitest:pitest-maven:mutationCoverage'
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'target/pit-reports/**', allowEmptyArchive: true
                }
            }
        }

        stage('SonarQube - SAST') {
            steps {
                withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                    sh '''
                        mvn sonar:sonar \
                          -Dsonar.projectKey=NumericApp \
                          -Dsonar.host.url=http://localhost:9000 \
                          -Dsonar.login=$SONAR_TOKEN
                    '''
                }
            }
        }

        stage('Build JAR') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Docker Build and Push') {
            steps {
                script {
                    def IMAGE_TAG = sh(
                        script: 'git rev-parse --short HEAD',
                        returnStdout: true
                    ).trim()

                    withCredentials([usernamePassword(
                        credentialsId: 'dockerhub',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        sh """
                            echo "\$DOCKER_PASS" | docker login -u "\$DOCKER_USER" --password-stdin
                            docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
                            docker push ${IMAGE_NAME}:${IMAGE_TAG}
                        """
                    }
                }
            }
        }

        stage('Kubernetes Deployment - DEV') {
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                    withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG_FILE')]) {
                        sh '''
                            echo "Configuring kubeconfig"
                            mkdir -p ~/.kube
                            cp "$KUBECONFIG_FILE" ~/.kube/config
                            chmod 600 ~/.kube/config

                            echo "Attempting Kubernetes deployment"
                            kubectl apply --validate=false -f k8s_deployment_service.yaml || true
                        '''
                    }
                }
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline completed successfully'
        }
        unstable {
            echo '⚠️ Pipeline completed with warnings (expected when no Kubernetes cluster is present)'
        }
        failure {
            echo '❌ Pipeline failed'
        }
    }
}
    agent any

    environment {
