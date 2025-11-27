output "cluster_name" {
  description = "The name of the EKS cluster."
  value       = module.eks.cluster_id
}

#output "kubeconfig" {
  #description = "The AWS command to update your local kubeconfig file."
  #value       = "aws eks update-kubeconfig --name ${module.eks.cluster_id} --region ${var.aws_region}"
#}
