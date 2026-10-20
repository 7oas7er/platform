# shared-obs — shared Grafana stack objects

Owns Infinity DS `infinity-cloudflare` and the `grafana-github-datasource` Cloud plugin.

App grafana roots create per-app GitHub data sources (`github-block-drop`, `github-netrunner`) and must **not** install the plugin or recreate Infinity.

```bash
export AWS_PROFILE=7oas7er-terraform
terraform init
terraform apply
```

Copy the Cloudflare analytics probe script usage from Block Drop / Netrunner grafana READMEs; token lives here.
