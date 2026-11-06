variable "aws_region" {
  description = "AWS region for the EKS stack."
  type        = string
  default     = "ap-south-1"
}

variable "terraform_state_bucket" {
  description = "Existing S3 bucket used for shared Terraform state."
  type        = string
  default     = "devops-user-terraform-state-backend"
}

variable "terraform_state_region" {
  description = "Region containing the Terraform state bucket."
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Short project name used to name AWS resources."
  type        = string
  default     = "it-vedant"
}

variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
  default     = "it-vedant-demo"
}

variable "kubernetes_version" {
  description = "Kubernetes version supported by EKS in the selected region."
  type        = string
  default     = "1.33"
}

variable "github_repository" {
  description = "GitHub repository allowed to deploy, in OWNER/REPOSITORY form."
  type        = string
  default     = "Rahilz313/it-vedant"
}

variable "github_branch" {
  description = "Branch allowed to assume the GitHub Actions deploy role."
  type        = string
  default     = "main"
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "IPv4 CIDRs allowed to reach the EKS public API endpoint. Set to a trusted CIDR when using a fixed runner."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_instance_types" {
  description = "EC2 instance types for EKS managed worker nodes."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "Initial desired number of worker nodes."
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of worker nodes."
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of worker nodes."
  type        = number
  default     = 3
}
