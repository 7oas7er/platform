# Adaptive Metrics — explicit DROP-only rules (opt-in).
# Auto-apply must stay OFF in the Grafana UI. This root never loads
# grafana-adaptive-metrics_recommendations / ruleset (would replace all rules).
# Evidence: docs in Project store grafana-adaptive-metrics-keep-drop.md;
# UI steps in README.md.

locals {
  adaptive_metrics_enabled = var.enable_adaptive_metrics_drops

  # Exact-name drops only. Never prefix-drop probe_http_ or aws_cloudfront_.
  adaptive_metrics_drop_exact = [
    "probe_all_duration_seconds_bucket",
    "probe_dns_lookup_time_seconds",
    "probe_failed_due_to_regex",
    "probe_http_content_length",
    "probe_http_redirects",
    "probe_http_ssl",
    "probe_http_uncompressed_body_length",
    "probe_http_version",
    "probe_http_last_modified_timestamp_seconds",
    "probe_all_success_count",
    "probe_all_success_sum",
    "aws_cloudfront_bytes_downloaded_sum",
    "aws_cloudfront_total_error_rate_average",
    "aws_cloudfront_info",
  ]

  # Safe prefixes: no KEEP metric shares these prefixes.
  # Do NOT drop aws_lambda_ — DressMe (and other app) env dashboards query
  # Invocations/Errors/Throttles/Duration after the tag_Name selector fix.
  adaptive_metrics_drop_prefix = [
    "probe_ip_",
    "probe_ssl_",
    "probe_tls_",
  ]

  adaptive_metrics_api_key = local.adaptive_metrics_enabled ? format(
    "%s:%s",
    tostring(data.grafana_cloud_stack.platform.prometheus_user_id),
    var.adaptive_metrics_access_token,
  ) : "0:disabled-placeholder"
}

provider "grafana-adaptive-metrics" {
  url     = data.grafana_cloud_stack.platform.prometheus_url
  api_key = local.adaptive_metrics_api_key
}

resource "grafana-adaptive-metrics_rule" "drop_exact" {
  for_each = local.adaptive_metrics_enabled ? toset(local.adaptive_metrics_drop_exact) : toset([])

  metric     = each.value
  match_type = "exact"
  drop       = true
}

resource "grafana-adaptive-metrics_rule" "drop_prefix" {
  for_each = local.adaptive_metrics_enabled ? toset(local.adaptive_metrics_drop_prefix) : toset([])

  metric     = each.value
  match_type = "prefix"
  drop       = true
}
