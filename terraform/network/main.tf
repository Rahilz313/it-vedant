provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "Terraform"
    }
  }
}

module "network" {
  source = "../modules/network"

  name                    = var.project_name
  vpc_cidr                = var.vpc_cidr
  az_count                = var.az_count
  kubernetes_cluster_name = var.cluster_name
  tags = {
    Stack = "network"
  }
}
