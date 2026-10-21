pipeline {
  agent any

  triggers { githubPush() }

  options {
    timestamps()
    disableConcurrentBuilds()
    buildDiscarder(logRotator(numToKeepStr: '10'))
  }

  environment {
    APP_HOST  = '79.76.22.169'
    APP_USER  = 'opc'
    SITE_ROOT = '/var/www/practice-a'
    SITE_PORT = '8081'
    SSH_OPTS  = '-o StrictHostKeyChecking=accept-new -o BatchMode=yes'
  }

  stages {

    stage('Validate') {
      steps {
        // A red build here means NOTHING was sent to the server.
        sh 'bash scripts/validate.sh public'
      }
    }

    stage('Package') {
      steps {
        sh '''
          set -eu
          echo "build $BUILD_NUMBER commit $GIT_COMMIT" > public/BUILD.txt
          # -C public: archive the CONTENTS of public/, not the folder itself
          tar -czf site.tgz -C public .
          ls -l site.tgz
        '''
      }
    }

    stage('Deploy (push over SSH)') {
      steps {
        sshagent(credentials: ['ssh-oci-vm-key']) {
          sh '''
            set -eu
            REL="$SITE_ROOT/releases/$BUILD_NUMBER"
            TARGET="$APP_USER@$APP_HOST"

            # 1. New, empty folder for this build
            ssh $SSH_OPTS $TARGET "mkdir -p $REL"

            # 2. Stream the archive through SSH and unpack on the far side
            ssh $SSH_OPTS $TARGET "tar -xzf - -C $REL" < site.tgz

            # 3. Give files the SELinux label that /var/www is supposed to have
            ssh $SSH_OPTS $TARGET "sudo restorecon -R $REL"

            # 4. Atomic switch: build the new link beside the old one, then rename over it
            ssh $SSH_OPTS $TARGET "ln -sfn $REL $SITE_ROOT/current.new && mv -Tf $SITE_ROOT/current.new $SITE_ROOT/current"

            # 5. Keep only the 3 newest releases
            ssh $SSH_OPTS $TARGET "cd $SITE_ROOT/releases && ls -1t | tail -n +4 | xargs -r rm -rf"
          '''
        }
      }
    }

    stage('Verify') {
      steps {
        sh '''
          set -eu
          curl -fsS --max-time 15 http://$APP_HOST:$SITE_PORT/ | grep -q 'Team Handbook'
          curl -fsS --max-time 15 http://$APP_HOST:$SITE_PORT/BUILD.txt | grep -q "build $BUILD_NUMBER "
          echo "Live site is build $BUILD_NUMBER"
        '''
      }
    }
  }
}
