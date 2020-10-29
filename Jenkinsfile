pipeline {
  agent any
  stages {
    stage('run') {
      steps {
        sh 'echo "hello world"'
      }
    }

    stage('ssh-remote') {
      steps {
        sshPublisher(alwaysPublishFromMaster: true, failOnError: true, continueOnError: true)
      }
    }

  }
}