pipeline {
    agent any

    stages {
        stage('Build Artifact') {
            steps {
                sh 'mvn -B -DskipTests=true clean package'
                archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            }
        } 
       stage('Unit Tests') {
           steps {
               sh 'mvn test'
            }
        post {
          always 
             junit 'target/surefire reports/*.xml
             Jacoco exePattern: 'target/jacoco.exec'
           }
         }
