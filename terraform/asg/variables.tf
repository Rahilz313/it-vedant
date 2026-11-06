variable "aws_region" {
  description = "AWS region for the ASG stack."
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

variable "instance_type" {
  description = "EC2 instance type used by the Auto Scaling group."
  type        = string
  default     = "t3.micro"
}

variable "desired_capacity" {
  description = "Initial desired number of EC2 instances."
  type        = number
  default     = 2
}

variable "min_size" {
  description = "Minimum number of EC2 instances."
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of EC2 instances."
  type        = number
  default     = 4
}
