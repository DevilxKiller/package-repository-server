// Jenkinsfile
// Jenkins Pipeline for publishing packages to repository

pipeline {
    agent any

    environment {
        REPO_URL = credentials('package-repo-url')
        API_KEY = credentials('package-repo-api-key')
    }

    parameters {
        choice(
            name: 'PACKAGE_TYPE',
            choices: ['deb', 'rpm', 'arch', 'alpine'],
            description: 'Type of package to build and publish'
        )
        string(
            name: 'VERSION',
            defaultValue: '',
            description: 'Package version (leave empty for git tag)'
        )
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Determine Version') {
            steps {
                script {
                    if (params.VERSION) {
                        env.PKG_VERSION = params.VERSION
                    } else {
                        env.PKG_VERSION = sh(
                            script: 'git describe --tags --always',
                            returnStdout: true
                        ).trim()
                    }
                    echo "Building version: ${env.PKG_VERSION}"
                }
            }
        }

        stage('Build DEB') {
            when {
                expression { params.PACKAGE_TYPE == 'deb' }
            }
            agent {
                docker { image 'debian:bookworm' }
            }
            steps {
                sh '''
                    apt-get update && apt-get install -y dpkg-dev debhelper
                    dpkg-deb --build ./package mypackage_${PKG_VERSION}_amd64.deb
                '''
                stash includes: '*.deb', name: 'deb-package'
            }
        }

        stage('Build RPM') {
            when {
                expression { params.PACKAGE_TYPE == 'rpm' }
            }
            agent {
                docker { image 'fedora:latest' }
            }
            steps {
                sh '''
                    dnf install -y rpm-build rpmdevtools
                    rpmdev-setuptree
                    rpmbuild -ba mypackage.spec
                    cp ~/rpmbuild/RPMS/x86_64/*.rpm .
                '''
                stash includes: '*.rpm', name: 'rpm-package'
            }
        }

        stage('Build Arch') {
            when {
                expression { params.PACKAGE_TYPE == 'arch' }
            }
            agent {
                docker { image 'archlinux:latest' }
            }
            steps {
                sh '''
                    pacman -Sy --noconfirm base-devel
                    useradd -m builder && chown -R builder:builder .
                    su builder -c "makepkg -s --noconfirm"
                '''
                stash includes: '*.pkg.tar.zst', name: 'arch-package'
            }
        }

        stage('Build Alpine') {
            when {
                expression { params.PACKAGE_TYPE == 'alpine' }
            }
            agent {
                docker { image 'alpine:3.19' }
            }
            steps {
                sh '''
                    apk add --no-cache alpine-sdk
                    abuild -r
                '''
                stash includes: '**/*.apk', name: 'alpine-package'
            }
        }

        stage('Publish') {
            steps {
                script {
                    def stashName = "${params.PACKAGE_TYPE}-package"
                    def filePattern = ''

                    switch(params.PACKAGE_TYPE) {
                        case 'deb':
                            filePattern = '*.deb'
                            break
                        case 'rpm':
                            filePattern = '*.rpm'
                            break
                        case 'arch':
                            filePattern = '*.pkg.tar.zst'
                            break
                        case 'alpine':
                            filePattern = '**/*.apk'
                            break
                    }

                    unstash stashName

                    sh """
                        for pkg in ${filePattern}; do
                            echo "Uploading \${pkg}..."
                            curl -X POST \\
                                -H "X-API-Key: ${API_KEY}" \\
                                -F "file=@\${pkg}" \\
                                "${REPO_URL}/api/v1/upload/${params.PACKAGE_TYPE}"
                        done
                    """
                }
            }
        }
    }

    post {
        success {
            echo "Package published successfully to ${REPO_URL}"
        }
        failure {
            echo "Failed to publish package"
        }
    }
}
