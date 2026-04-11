node {

    stage('Checkout') {
        checkout scm
    }

    stage('Unit Tests') {
        sh 'mvn clean test'
        junit 'target/surefire-reports/*.xml'
    }

    stage('Code Coverage') {
        step([
            $class: 'JacocoPublisher',
            execPattern: 'target/jacoco.exec',
            classPattern: 'target/classes',
            sourcePattern: 'src/main/java'
        ])
    }

    stage('Build JAR') {
        sh 'mvn clean package -DskipTests'
    }

    stage('Docker Build and Push') {
        def commit = sh(script: 'git rev-parse HEAD', returnStdout: true).trim()

        withCredentials([usernamePassword(
            credentialsId: 'dockerhub',
            usernameVariable: 'DOCKER_USER',
            passwordVariable: 'DOCKER_PASS'
        )]) {
            sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
        }

        sh "docker build -t ochelini/numericapp:${commit} ."
        sh "docker push ochelini/numericapp:${commit}"

        // Persist image tag for later stages
        env.IMAGE_TAG = commit
    }

    stage('Kubernetes Deployment - DEV') {
        withCredentials([string(credentialsId: 'kubeconfig-dev', variable: 'KUBECONFIG_CONTENT')]) {
            sh '''
                mkdir -p ~/.kube
                echo "$KUBECONFIG_CONTENT" > ~/.kube/config
                chmod 600 ~/.kube/config

                # Show manifest location (debug-safe)
                ls -l

                # Replace image tag and deploy
                sed -i "s#replace#ochelini/numericapp:${IMAGE_TAG}#g" k8s/K8s_deployment_service.yaml
                kubectl apply -f k8s/K8s_deployment_service.yaml
            '''
        }
    }

}
