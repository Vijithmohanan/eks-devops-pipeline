variable "aws_region" {
  description = "The AWS region to deploy EKS to."
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "The name for the EKS cluster."
  default     = "devops-beginner-eks"
}
