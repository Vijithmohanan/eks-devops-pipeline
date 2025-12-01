pipeline {
    agent any
    
    // Set environment variables for authentication and configuration
    environment {
        // These IDs must match the IDs you set in the Jenkins Credentials Manager
        PATH = "/opt/homebrew/bin:${env.PATH}"
        AWS_ACCESS_KEY_ID = credentials('devops-project-key')
        AWS_SECRET_ACCESS_KEY = credentials('devops-project-key')
        TERRAFORM_DIR = 'terraform'
        K8S_MANIFESTS = 'ansible/kubernetes'
        CLUSTER_NAME = 'devops-beginner-eks'
        AWS_REGION = 'us-east-1'
    }

    stages {
        stage('Checkout Code') {
            steps {
                // Clones the code using the GitHub credentials
                git branch: 'main', credentialsId: 'jenkins-github-credentials', url: 'https://github.com/Vijithmohanan/eks-devops-pipeline.git'
            }
        }
        
        // 1. Provision Infrastructure
        stage('Terraform Provisioning & Verify') {
            steps {
                dir(env.TERRAFORM_DIR) {
                    sh 'terraform init -upgrade'
                    sh 'terraform apply -auto-approve'
                    sh 'terraform output cluster_name' // Verification 1A
                }
            }
        }
        
        // 2. Configure Local Connection
        stage('Setup Kubeconfig & Verify Nodes') {
            steps {
                script {
                    def clusterName = sh(returnStdout: true, script: "terraform output -raw cluster_name").trim()

                    // Connect Jenkins agent to EKS
                    sh "aws eks update-kubeconfig --name ${clusterName} --region ${env.AWS_REGION}"
                    
                    // Verification 2A: Ensure connection works
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
}
