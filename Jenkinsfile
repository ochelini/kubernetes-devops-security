node {

    /*************************
     * Force Java 17 (Snap Jenkins fix)
     *************************/
    env.JAVA_HOME = "/usr/lib/jvm/java-17-openjdk-amd64"
    env.PATH = "${env.JAVA_HOME}/bin:${env.PATH}"

    stage('Verify Java') {
        sh '''
            echo "JAVA_HOME=$JAVA_HOME"
            which java
            java -version
            which javac
            javac -version
        '''
    }

    /*************************
     * Checkout Source
     *************************/
    stage('Checkout') {
        checkout scm
    }

    /*************************
     * Unit Tests
     *************************/
    stage('Unit Tests') {
        sh 'mvn clean test'
        junit 'target/surefire-reports/*.xml'
   
    }

    /*************************
     * Mutation Tests (PIT)
     *************************/
    stage('Mutation Tests - PIT') {
        catchError(buildResult: 'UNSTABLE', stageResult: 'UNSTABLE') {
            sh 'mvn org.pitest:pitest-maven:mutationCoverage'
        }
        archiveArtifacts artifacts: 'target/pit-reports/**', allowEmptyArchive: true
    }

    /*************************
     * SonarQube – SAST
     *************************/
    stage('SonarQube - SAST') {
        sh '''
            mvn sonar:sonar \
              -Dsonar.projectKey=NumericApp \
              -Dsonar.host.url=http://devsecopsdemo.westus2.cloudapp.azure.com:9000 \
              -Dsonar.login=3f73ccd772959bc74307802402300f4cd46f56cc
        '''
    }

    /*************************
     * Build JAR
     *************************/
    stage('Build JAR') {
        sh 'mvn clean package -DskipTests'
    }

    /*************************
     * Docker Build & Push
     *************************/
    stage('Docker Build and Push') {

        def imageTag = sh(
            script: 'git rev-parse --short HEAD',
            returnStdout: true
        ).trim()

        withCredentials([usernamePassword(
            credentialsId: 'dockerhub',
            usernameVariable: 'DOCKER_USER',
            passwordVariable: 'DOCKER_PASS'
        )]) {
            sh 'echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin'
        }

        sh "docker build -t ochelini/numericapp:${imageTag} ."
        sh "docker push ochelini/numericapp:${imageTag}"

        env.IMAGE_TAG = imageTag
    }

    /*************************
     * Kubernetes Deployment (DEV)
     *************************/
    stage('Kubernetes Deployment - DEV') {
        withCredentials([file(
            credentialsId: 'kubeconfig',
            variable: 'KUBECONFIG_FILE'
        )]) {
            sh '''
                set -e

                echo "Setting kubeconfig"
                mkdir -p "$HOME/.kube"
                cp "$KUBECONFIG_FILE" "$HOME/.kube/config"
                chmod 600 "$HOME/.kube/config"

                echo "Cluster endpoint:"
                kubectl config view --minify | grep server

                echo "Updating image tag in manifest"
                sed -i "s#replace#ochelini/numericapp:${IMAGE_TAG}#g" k8s_deployment_service.yaml

                echo "Deploying to Kubernetes"
                kubectl apply -f k8s_deployment_service.yaml --validate=false
            '''
        }
    }

} // ✅ end node
