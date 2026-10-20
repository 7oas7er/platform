variable "aws_region" {
  description = "Region for the platform Terraform state bucket."
  type        = string
  default     = "eu-north-1"
}

variable "aws_profile" {
  description = "Optional AWS shared-credentials profile for local use. Prefer 7oas7er-terraform when using aws login sessions."
  type        = string
  default     = null
  nullable    = true
}

variable "state_bucket_name" {
  description = "Globally unique S3 bucket for platform Terraform state."
  type        = string
  default     = "shared-7oas7er-platform-terraform-state-bucket"
}
