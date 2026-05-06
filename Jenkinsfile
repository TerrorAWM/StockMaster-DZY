pipeline {
    agent any

    environment {
        IMAGE_PREFIX = 'stockmaster'
        IMAGE_TAG = "${BUILD_NUMBER}"
    }

    stages {
        stage('Backend Build') {
            steps {
                dir('backend') {
                    sh 'mvn -DskipTests package'
                }
            }
        }

        stage('Frontend Build') {
            steps {
                dir('frontend') {
                    sh 'npm install'
                    sh 'npm run build'
                }
            }
        }

        stage('Build Images') {
            steps {
                sh '''
                for service in eureka-service config-service gateway-service user-service product-service stock-service order-service; do
                  docker build -t ${IMAGE_PREFIX}/${service}:${IMAGE_TAG} backend/${service}
                done
                docker build -t ${IMAGE_PREFIX}/frontend-nginx:${IMAGE_TAG} frontend
                '''
            }
        }

        stage('Deploy To Kubernetes') {
            steps {
                sh '''
                kubectl apply -f k8s/namespace.yaml
                kubectl apply -f k8s/mysql/mysql.yaml
                kubectl apply -f k8s/services/base-config.yaml
                kubectl apply -f k8s/services/apps.yaml
                '''
            }
        }
    }
}

