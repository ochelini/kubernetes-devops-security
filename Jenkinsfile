node {

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
     * Code Coverage (JaCoCo)
     *************************/
    stage('Code Coverage') {
        jacoco(
            execPattern: 'target/jacoco.exec',
            classPattern: 'target/classes',
            sourcePattern: 'src/main/java'
        )
    }

    /*************************
     * Mutation Tests (PIT)
     * Maven only – no Jenkins plugin
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
            script: 'git rev-parse HEAD',
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

                echo "Verifying cluster endpoint"
                kubectl config view --minify | grep server

                echo "Updating image tag in manifest"
                sed -i "s#replace#ochelini/numericapp:${IMAGE_TAG}#g" k8s_deployment_service.yaml

                echo "Applying Kubernetes resources"
                kubectl apply -f k8s_deployment_service.yaml --validate=false
            '''
        }
    }

} // ✅ end node
