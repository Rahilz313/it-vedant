terraform {
  required_version = ">= 1.10.0"

  backend "s3" {
    key          = "network/terraform.tfstate"
    use_lockfile = true
    encrypt      = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
