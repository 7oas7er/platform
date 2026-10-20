terraform {
  required_version = ">= 1.10.0"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket       = "shared-7oas7er-platform-terraform-state-bucket"
    key          = "shared-edge/terraform.tfstate"
    region       = "eu-north-1"
    use_lockfile = true
    encrypt      = true
  }
}

provider "cloudflare" {
  # CLOUDFLARE_API_TOKEN from the environment.
}
