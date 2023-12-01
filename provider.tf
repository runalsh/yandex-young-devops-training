#==== provider ======================

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.26.0"
    }
  }
}

provider "aws" {
  region = var.region
}

terraform {
  backend "s3" {
    bucket = "statebucket-for-infra"
    key    = "statebucket-for-infra/terraform.tfstate"
    region = "eu-central-1"
  }
}

