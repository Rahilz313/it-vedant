variable "aws_region" {
  description = "AWS region for the S3 bucket."
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Short project name used to name AWS resources."
  type        = string
  default     = "it-vedant"
}
