terraform {
  required_version = ">= 1.10.0"

  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "~> 4.0"
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

provider "grafana" {
  alias                     = "cloud"
  cloud_access_policy_token = var.cloud_access_policy_token
}

# Stack provider must not depend on the SA token resource (that blocks import / first
# apply). Set stack_service_account_token after creating the platform-terraform SA
# (see docs/MIGRATION.md), or temporarily use any Admin stack SA token.
provider "grafana" {
  alias = "stack"
  url   = data.grafana_cloud_stack.platform.url
  auth  = var.stack_service_account_token
}
