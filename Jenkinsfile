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
     * Code Coverage
     *************************/
    stage('Code Coverage') {
        step([
            $class: 'JacocoPublisher',
            execPattern: 'target/jacoco.exec',
            classPattern: 'target/classes',
            sourcePattern: 'src/main/java'
        ])
    }
   /*************************
 * Mutation Tests - PIT
 *************************/
stage('Mutation Tests - PIT') {
    try {
        sh 'mvn org.pitest:pitest-maven:mutationCoverage'
    } finally {
        pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml'
    }
}
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

        // Use git commit hash as image tag
        def imageTag = sh(
            script: 'git rev-parse HEAD',
            returnStdout: true
        ).trim()

        withCredentials([usernamePassword(
            credentialsId: 'dockerhub',
            usernameVariable: 'DOCKER_USER',
            passwordVariable: 'DOCKER_PASS'
        )]) {
            sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
        }

        sh "docker build -t ochelini/numericapp:${imageTag} ."
        sh "docker push ochelini/numericapp:${imageTag}"

        // Persist for next stage
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
                mkdir -p ~/.kube
                cp "$KUBECONFIG_FILE" ~/.kube/config
                chmod 600 ~/.kube/config

                echo "Verifying cluster endpoint"
                kubectl config view --minify | grep server

                echo "Updating image tag in manifest"
                sed -i "s#replace#ochelini/numericapp:${IMAGE_TAG}#g" k8s_deployment_service.yaml

                echo "Applying Kubernetes resources"
                kubectl apply -f k8s_deployment_service.yaml --validate=false
            '''
        }
    

}
