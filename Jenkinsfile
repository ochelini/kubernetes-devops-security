pipeline {
    agent any

    stages {
        stage('Build Artifact') {
            steps {
                sh 'mvn -B -DskipTests=true clean package'
                archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
                #just to test if automation works
            }
        }
    }
}
