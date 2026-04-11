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
            sourcePattern: 'src/main/java',
            inclusionPattern: '**/*.class',
            exclusionPattern: ''
        ])
    }

    stage('Build JAR') {
        sh 'mvn clean package -DskipTests'
    }

    stage('Docker Build and Push') {

        // Always works — extract commit hash manually
        def commit = sh(script: "git rev-parse HEAD", returnStdout: true).trim()

        sh 'printenv'

        // Login to Docker Hub using Jenkins credentials
        withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
            sh "echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin"
        }

        // Build and push image
        sh "docker build -t ochelini/numericapp:${commit} ."
        sh "docker push ochelini/numericapp:${commit}"
    }
}
  stage('Kubernetes Deployment - DEV') {
        steps { 
            withKubeConfig(credentialsId: "kubeconfig", url: ""]) {
                sh "sed -i 's#replace#ochelini/numeric-app:${GIT_COMMIT}#g' K8s_deployment_service.yaml
                sh "kubectl apply -f K8s_deployment_service.yaml"
    }

    
    }
}
