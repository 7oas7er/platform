terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.69"
    }
    grafana = {
      source  = "grafana/grafana"
      version = "~> 4.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.13"
    }
  }

  backend "s3" {
    bucket       = "shared-7oas7er-platform-terraform-state-bucket"
    key          = "shared-obs/terraform.tfstate"
    region       = "eu-north-1"
    use_lockfile = true
    encrypt      = true
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = {
      Environment = "shared"
      Project     = "platform"
    }
  }
}

provider "grafana" {
  alias                     = "cloud"
  cloud_access_policy_token = var.cloud_access_policy_token
}

# Cloud Provider Observability API (AWS account + CloudWatch scrape jobs).
# Token may be the same glc_ as cloud_access_policy_token if it includes
# integration-management:read|write; otherwise set cloud_provider_access_token.
provider "grafana" {
  alias                       = "cloud_provider"
  cloud_access_policy_token   = var.cloud_access_policy_token
  cloud_provider_url          = data.grafana_cloud_stack.platform.cloud_provider_url
  cloud_provider_access_token = coalesce(var.cloud_provider_access_token, var.cloud_access_policy_token)
}

# Stack provider must not depend on the SA token resource (that blocks import / first
# apply). Set stack_service_account_token after creating the platform-terraform SA
# (see docs/MIGRATION.md), or temporarily use any Admin stack SA token.
provider "grafana" {
  alias = "stack"
  url   = data.grafana_cloud_stack.platform.url
  auth  = var.stack_service_account_token
}
