# Free Security Settings recommendations for zone 7oas7er.com.
# See docs/architecture.md and the homepage project note
# cloudflare-free-security-features.md for the enable / skip / caution matrix.

# --- Leaked credentials detection (enable) ---------------------------------
# Free: detection is on by default; manage via Terraform so the toggle stays SoT.
# Active mitigation via Free's "leaked password" rate-limit *template* is NOT
# added here: Free allows only one rate-limit rule, already used by /api/scores
# (rate_limit.tf). Detection alone is still useful in Security Analytics.
resource "cloudflare_leaked_credential_check" "zone" {
  zone_id = local.zone_id
  enabled = true
}

# --- Bot Fight Mode (optional / default off) -------------------------------
# Zone-wide challenges; cannot skip via WAF custom rules or Page Rules on Free.
# Conflicts with Grafana synthetics, curl health probes, headless CI, and
# Block Drop /api/scores clients that are not full browsers.
# Flip enable_bot_fight_mode only after verifying those paths still pass.
resource "cloudflare_bot_management" "zone" {
  count = var.enable_bot_fight_mode ? 1 : 0

  zone_id    = local.zone_id
  enable_js  = true # required by Cloudflare when enabling Fight Mode
  fight_mode = true
}

# --- Client-side security / Page Shield (enable; API until provider catches up) ---
# Continuous script monitoring is Free and passive (no request challenges).
# Official cloudflare provider (through 5.28.x) has no zone-level enable resource
# (only cloudflare_page_shield_policy, which needs Client-Side Security Advanced).
# Tracker: https://github.com/cloudflare/terraform-provider-cloudflare/issues/7006
# Apply companion: ../../../../tools/enable-client-side-security
# (or the curl documented in shared-edge/README.md).
