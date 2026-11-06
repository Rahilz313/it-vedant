output "vpc_id" {
  description = "Shared VPC ID."
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs, intended for the ALB and internet-facing ingress."
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs, intended for EKS worker nodes and the EC2 ASG."
  value       = module.network.private_subnet_ids
}

output "availability_zones" {
  description = "Availability zones used by the shared network."
  value       = module.network.availability_zones
}
