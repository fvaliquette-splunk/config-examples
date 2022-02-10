terraform {
  required_providers {
    signalfx = {
      source  = "splunk-terraform/signalfx"
      version = ">= 6.7.6"
    }
  }
  required_version = ">= 0.12.26"
}

# Configure the SignalFx provider
provider "signalfx" {
  #TODO: insert you API token
  auth_token = "..."
  # If your organization uses a different realm
  api_url = "https://api.us1.signalfx.com"
  # If your organization uses a custom URL
  # custom_app_url = "https://myorg.signalfx.com"
}

resource "signalfx_detector" "used_capacity" {
  name = format("%s %s", "DEV", "Azure storage account Used capacity")

  #authorized_writer_teams = var.authorized_writer_teams
  #teams                   = try(coalescelist(var.teams, var.authorized_writer_teams), null)
  #tags                    = compact(concat(local.common_tags, local.tags, var.extra_tags))

  program_text = <<-EOF
    base_filter = filter('resource_type', 'Microsoft.Storage/storageAccounts') and filter('primary_aggregation_type', 'true')
    signal = data('UsedCapacity', filter=base_filter).mean(by=['azure_resource_name', 'azure_resource_group_name', 'azure_region']).max(over='12h').publish('signal')
    signalTB = (signal/1024/1024/1024/1024)
    detect(when(signalTB > 50 )).publish('CRIT')
    detect(when(signalTB > 40) and (not when(signal > 50 ))).publish('MAJOR')
EOF

  rule {
    description           = "is too high > 50 TB"
    severity              = "Critical"
    detect_label          = "CRIT"
    disabled              = false
    #notifications         = coalescelist(lookup(var.used_capacity_notifications, "critical", []), var.notifications.critical)
    #runbook_url           = try(coalesce(var.used_capacity_runbook_url, var.runbook_url), "")
    #tip                   = var.used_capacity_tip
    #parameterized_subject = var.message_subject == "" ? local.rule_subject : var.message_subject
    #parameterized_body    = var.message_body == "" ? local.rule_body : var.message_body
  }

  rule {
    description           = "is too high > 40 TB"
    severity              = "Major"
    detect_label          = "MAJOR"
    disabled              = false
  }
}
