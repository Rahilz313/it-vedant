variable "name" {
  description = "Prefix for network resource names."
  type        = string
}

variable "vpc_cidr" {
  description = "IPv4 CIDR range for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones to use."
  type        = number
  default     = 2
  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "Use between two and three availability zones."
  }
}

variable "kubernetes_cluster_name" {
  description = "Optional EKS cluster name used for subnet discovery tags."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to network resources."
  type        = map(string)
  default     = {}
}
