variable "aws_region" {
  description = "AWS region for the shared network."
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Short project name used to name AWS resources."
  type        = string
  default     = "core"
}

variable "cluster_name" {
  description = "EKS cluster name used to tag subnets for Kubernetes load balancers."
  type        = string
  default     = "it-vedant-demo"
}

variable "vpc_cidr" {
  description = "IPv4 address range for the shared VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones and subnet pairs."
  type        = number
  default     = 2
  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "Use between two and three availability zones."
  }
}
