pipeline {
    agent any

    // Set environment variables for authentication and configuration
    environment {
        // --- Configuration Variables ---
        TERRAFORM_DIR = 'terraform'
        K8S_MANIFESTS = 'ansible/kubernetes'
        CLUSTER_NAME  = 'devops-beginner-eks' // Used by the Terraform module/configuration
        AWS_REGION    = 'us-east-1'

        // --- Credentials and PATH (Set globally) ---
        // Sets the PATH to include Homebrew directory, essential for Mac/Linux Jenkins agents
        PATH = "/opt/homebrew/bin:${env.PATH}"
        // Uses Jenkins Credentials Manager IDs
        AWS_ACCESS_KEY_ID = credentials('jenkins-aws-key-id')
        AWS_SECRET_ACCESS_KEY = credentials('jenkins-aws-secret-key')
    }

    stages {
        stage('Checkout Code') {
            steps {
                // Clones the code using the GitHub credentials
                git branch: 'main', credentialsId: 'Jenkinsfile', url: 'https://github.com/Vijithmohanan/eks-devops-pipeline.git'
            }
        }

        // 1. Provision Infrastructure
        stage('Terraform Provisioning & Verify') {
            steps {
                dir(env.TERRAFORM_DIR) {
                    sh 'terraform init -upgrade'
                    sh 'terraform apply -auto-approve'
                }
            }
        }

        // 2. Configure Local Connection
        stage('Setup Kubeconfig & Verify Nodes') {
            steps {
                script {
                    // Navigate to the Terraform directory for safe output retrieval
                    def clusterName = sh(
                        script: "cd ${env.TERRAFORM_DIR} && terraform output -raw cluster_name",
                        returnStdout: true // Capture the output
                    ).trim() // Remove leading/trailing whitespace/newlines

                    // Use the clean cluster name variable in the AWS CLI command
                    sh "aws eks update-kubeconfig --name ${clusterName} --region ${env.AWS_REGION}"

                    // Verification step
                    sh "kubectl get nodes"
                }
            }
        }

        // 3. Deploy Application
        stage('Deploy Application & Verify Rollout') {
            steps {
                // Apply the Kubernetes manifests
                sh "kubectl apply -f ${env.K8S_MANIFESTS}/nginx-deployment.yaml"
                sh "kubectl apply -f ${env.K8S_MANIFESTS}/nginx-service.yaml"

                // Verification 3A: Wait for Nginx Pods to be ready
                sh 'kubectl rollout status deployment/nginx-deployment --timeout=5m'

                // Verification 3B: Wait for the AWS Load Balancer DNS name
                sh 'kubectl wait --for=condition=ready service/nginx-loadbalancer --timeout=5m'
            }
        }

        stage('Final Output') {
            steps {
                // Display the public endpoint
                sh 'echo "Deployment Complete! Public Endpoint:"'
                sh 'kubectl get services nginx-loadbalancer -o=jsonpath="{.status.loadBalancer.ingress[0].hostname}"'
            }
        }
    }

    // --- Post-build Actions ---
    post {
        // Runs regardless of stage success or failure (recommended for cleanup)
        always {
            // Optional: Add logic to skip destroy if not running in a CI/CD environment
            echo 'Starting Terraform Teardown...'
            script {
                dir(env.TERRAFORM_DIR) {
                    // Use a dedicated destroy command
                    sh 'terraform destroy -auto-approve'
                }
            }
            echo 'Teardown Complete.'
        }
    }
}
