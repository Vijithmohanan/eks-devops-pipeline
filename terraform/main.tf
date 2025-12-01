# --- REMOTE STATE CONFIGURATION (MUST BE FIRST BLOCK) ---
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "hollslane-tfstate-2025" 
    key            = "environments/prod/eks-cluster.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock-ddb"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

# 1. VPC and Subnets (Required Network for EKS)
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "${var.cluster_name}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.aws_region}a", "${var.aws_region}b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false
  tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

# 2. EKS Cluster (The Control Plane)
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.16.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.28"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets
  
  # 🚨 ADD THESE LINES TO ENABLE PUBLIC ACCESS 🚨
  cluster_endpoint_private_access = false
  cluster_endpoint_public_access  = true
  # ---------------------------------------------

  # 3. EKS Worker Nodes (EC2 Instances)
  eks_managed_node_groups = {
    # ... (rest of the block) ...
    default = {
      min_size     = 1
      max_size     = 3
      desired_size = 1
      instance_types = ["t3.medium"]
    }
  }
}

# Inside your terraform/ directory configuration
output "cluster_name" {
  description = "The name of the EKS cluster"
  # This assumes your EKS module output is named 'eks_cluster_id' or similar
  value       = module.eks.cluster_id # Adjust 'cluster_id' to your actual output attribute
}

