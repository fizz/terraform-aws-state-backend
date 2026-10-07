terraform {
  required_version = ">= 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}

module "state" {
  source = "../.."

  name = "acme-tfstate-${data.aws_caller_identity.current.account_id}"
}

output "backend_config" {
  value = module.state.backend_config
}
