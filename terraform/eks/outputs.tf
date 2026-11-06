output "aws_account_id" {
  description = "AWS account ID for GitHub repository variables."
  value       = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  description = "AWS region used by this stack."
  value       = var.aws_region
}

output "cluster_name" {
  description = "EKS cluster name."
  value       = aws_eks_cluster.this.name
}

output "ecr_repository" {
  description = "ECR repository name."
  value       = aws_ecr_repository.app.name
}

output "github_deploy_role_arn" {
  description = "IAM role ARN to set as the GitHub AWS_DEPLOY_ROLE_ARN repository variable."
  value       = aws_iam_role.github_deploy.arn
}

output "cluster_endpoint" {
  description = "EKS Kubernetes API endpoint."
  value       = aws_eks_cluster.this.endpoint
}
