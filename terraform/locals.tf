locals {
  mandatory_tags = {
    app_name            = var.app_name
    environment         = var.environment
    business_unit       = var.business_unit
    cost_center         = var.cost_center
    owner_business      = var.owner_business
    owner_technical     = var.owner_technical
    data_classification = var.data_classification
  }

  recommended_tags = {
    service_tier       = var.service_tier
    compliance_scope   = var.compliance_scope
    lifecycle          = var.lifecycle_stage
    repo               = var.repo
    deployment_method  = var.deployment_method
    support_contact    = var.support_contact
  }

  optional_tags = {
    customer_facing     = var.customer_facing
    rto_hours           = var.rto_hours
    rpo_minutes         = var.rpo_minutes
    backup_enabled      = var.backup_enabled
    monitoring_enabled  = var.monitoring_enabled
  }

  non_empty_tags = merge(
    local.mandatory_tags,
    { for k, v in local.recommended_tags : k => v if v != "" },
    { for k, v in local.optional_tags : k => v if v != "" }
  )
}
