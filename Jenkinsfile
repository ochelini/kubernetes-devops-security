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
}
stage ('Docker Build and Push')  {
    steps {
         sh 'printev'
         sh 'docker build -t ochelini/numericapp:""$GIT_COMMIT"" .'
         sh 'docker push ochelini/numericapp:""$GIT_COMMIT"" .'
               ])
    }
}
