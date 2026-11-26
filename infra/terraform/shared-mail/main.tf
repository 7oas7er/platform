# Shared outbound mail identity for @7oas7er.com (Amazon SES, eu-north-1).
# Apps send through it (for example Cognito invites) and consume only the
# identity ARN: app -> platform, never the other way round.
# Inbound (forwarding dressme@ to a real mailbox) is Cloudflare Email Routing in shared-edge.

locals {
  mail_from_domain = "${var.mail_from_subdomain}.${var.zone_name}"
}

resource "aws_sesv2_email_identity" "domain" {
  email_identity = var.zone_name

  dkim_signing_attributes {
    next_signing_key_length = "RSA_2048_BIT"
  }
}

resource "aws_sesv2_email_identity_mail_from_attributes" "domain" {
  email_identity         = aws_sesv2_email_identity.domain.email_identity
  mail_from_domain       = local.mail_from_domain
  behavior_on_mx_failure = "USE_DEFAULT_VALUE"
}

# --- DNS in the Cloudflare zone ------------------------------------------------

# Easy DKIM: three CNAMEs (tokens are known after the identity exists).
resource "cloudflare_dns_record" "dkim" {
  count = 3

  zone_id = var.zone_id
  name    = "${aws_sesv2_email_identity.domain.dkim_signing_attributes[0].tokens[count.index]}._domainkey.${var.zone_name}"
  type    = "CNAME"
  ttl     = 1 # automatic
  content = "${aws_sesv2_email_identity.domain.dkim_signing_attributes[0].tokens[count.index]}.dkim.amazonses.com"
  proxied = false
  comment = "SES Easy DKIM"
}

# Custom MAIL FROM: bounces and complaints come back to SES.
resource "cloudflare_dns_record" "mail_from_mx" {
  zone_id  = var.zone_id
  name     = local.mail_from_domain
  type     = "MX"
  ttl      = 1
  priority = 10
  content  = "feedback-smtp.${var.aws_region}.amazonses.com"
  comment  = "SES custom MAIL FROM"
}

resource "cloudflare_dns_record" "mail_from_spf" {
  zone_id = var.zone_id
  name    = local.mail_from_domain
  type    = "TXT"
  ttl     = 1
  content = "v=spf1 include:amazonses.com ~all"
  comment = "SES custom MAIL FROM SPF"
}

# --- Bounce, complaint and reject handling -------------------------------------
# Account-level suppression (BOUNCE, COMPLAINT) is on by default in SES. On top of
# that: events go to an SNS topic that emails the operator, and CloudWatch alarms
# watch the account reputation rates. Apps pass the configuration set name to SES
# (Cognito: configuration_set).

data "aws_caller_identity" "current" {}

resource "aws_sesv2_configuration_set" "transactional" {
  configuration_set_name = "platform-transactional"

  reputation_options {
    reputation_metrics_enabled = true
  }

  sending_options {
    sending_enabled = true
  }
}

resource "aws_sns_topic" "mail_events" {
  name = "platform-mail-events"
}

data "aws_iam_policy_document" "mail_events" {
  statement {
    sid       = "AllowSesPublishFromThisConfigurationSet"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.mail_events.arn]

    principals {
      type        = "Service"
      identifiers = ["ses.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "AWS:SourceArn"
      values   = [aws_sesv2_configuration_set.transactional.arn]
    }
  }
}

resource "aws_sns_topic_policy" "mail_events" {
  arn    = aws_sns_topic.mail_events.arn
  policy = data.aws_iam_policy_document.mail_events.json
}

resource "aws_sesv2_configuration_set_event_destination" "problems" {
  configuration_set_name = aws_sesv2_configuration_set.transactional.configuration_set_name
  event_destination_name = "bounces-complaints-rejects"

  event_destination {
    enabled              = true
    matching_event_types = ["BOUNCE", "COMPLAINT", "REJECT"]

    sns_destination {
      topic_arn = aws_sns_topic.mail_events.arn
    }
  }

  depends_on = [aws_sns_topic_policy.mail_events]
}

# Email subscription: AWS sends a confirmation mail that must be confirmed once.
resource "aws_sns_topic_subscription" "operator" {
  count = var.alert_email == "" ? 0 : 1

  topic_arn = aws_sns_topic.mail_events.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_cloudwatch_metric_alarm" "bounce_rate" {
  alarm_name          = "platform-ses-bounce-rate"
  alarm_description   = "SES account bounce rate above ${var.bounce_rate_alarm * 100}% (SES reviews at 5%)."
  namespace           = "AWS/SES"
  metric_name         = "Reputation.BounceRate"
  statistic           = "Maximum"
  period              = 3600
  evaluation_periods  = 1
  threshold           = var.bounce_rate_alarm
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.mail_events.arn]
}

resource "aws_cloudwatch_metric_alarm" "complaint_rate" {
  alarm_name          = "platform-ses-complaint-rate"
  alarm_description   = "SES account complaint rate above ${var.complaint_rate_alarm * 100}% (SES reviews at 0.1%)."
  namespace           = "AWS/SES"
  metric_name         = "Reputation.ComplaintRate"
  statistic           = "Maximum"
  period              = 3600
  evaluation_periods  = 1
  threshold           = var.complaint_rate_alarm
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.mail_events.arn]
}
