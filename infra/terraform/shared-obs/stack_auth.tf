resource "grafana_cloud_stack_service_account" "terraform" {
  provider = grafana.cloud

  stack_slug  = var.stack_slug
  name        = "platform-terraform"
  role        = "Admin"
  is_disabled = false
}

resource "grafana_cloud_stack_service_account_token" "terraform" {
  provider = grafana.cloud

  stack_slug         = var.stack_slug
  name               = "platform-terraform"
  service_account_id = grafana_cloud_stack_service_account.terraform.id
}
