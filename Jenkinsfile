stage('Unit Tests') {
    steps {
        sh 'mvn clean test'
        junit 'target/surefire-reports/*.xml'
    }
}

stage('Code Coverage') {
    steps {
        jacoco(
            execPattern: 'target/jacoco.exec',
            classPattern: 'target/classes',
            sourcePattern: 'src/main/java',
            inclusionPattern: '**/*.class',
            exclusionPattern: ''
        )
    }
}
