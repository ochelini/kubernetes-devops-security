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

        def commit = sh(script: "git rev-parse HEAD", returnStdout: true).trim()

        sh 'printenv'
        sh "docker build -t ochelini/numericapp:${commit} ."
        sh "docker push ochelini/numericapp:${commit}"
    }
}
