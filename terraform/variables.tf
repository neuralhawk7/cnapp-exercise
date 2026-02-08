variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-1"
}

variable "name" {
  description = "Name prefix"
  type        = string
  default     = "education"
}

variable "vpc_id" {
  description = "VPC ID to deploy resources in"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the new VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_azs" {
  description = "Availability zones for the new VPC"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_az" {
  description = "Availability zone for public subnet"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for MongoDB"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "EC2 Key Pair name for SSH access"
  type        = string
}

variable "mongo_admin_user" {
  description = "MongoDB admin username"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "mongo_admin_pass" {
  description = "MongoDB admin password"
  type        = string
  sensitive   = true
}

variable "eks_control_plane_azs" {
  description = "Allowed availability zones for the EKS control plane"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d", "us-east-1f"]
}

variable "manage_guardduty" {
  description = "Whether Terraform should create GuardDuty (false if already enabled)"
  type        = bool
  default     = false
}

variable "manage_detective" {
  description = "Whether Terraform should create Detective (false if already enabled)"
  type        = bool
  default     = false
}

variable "manage_securityhub" {
  description = "Whether Terraform should enable Security Hub (false if already enabled)"
  type        = bool
  default     = false
}

variable "manage_securityhub_subscriptions" {
  description = "Whether Terraform should create Security Hub product subscriptions"
  type        = bool
  default     = false
}

variable "manage_config" {
  description = "Whether Terraform should create AWS Config resources (false if already enabled)"
  type        = bool
  default     = false
}

variable "cloudtrail_enable_cloudwatch_logs" {
  description = "Whether CloudTrail should deliver to CloudWatch Logs"
  type        = bool
  default     = true
}

variable "cloudtrail_log_retention_days" {
  description = "CloudTrail CloudWatch Logs retention in days"
  type        = number
  default     = 90
}

variable "cloudtrail_is_organization_trail" {
  description = "Whether CloudTrail should be an organization trail"
  type        = bool
  default     = false
}

variable "cloudtrail_org_id" {
  description = "AWS Organization ID for organization trails (example: o-xxxxxxxxxx)"
  type        = string
  default     = ""

  validation {
    condition     = var.cloudtrail_is_organization_trail ? length(var.cloudtrail_org_id) > 0 : true
    error_message = "cloudtrail_org_id must be set when cloudtrail_is_organization_trail is true."
  }
}

variable "waf_logging_enabled" {
  description = "Whether WAFv2 logging should be enabled"
  type        = bool
  default     = true
}

variable "eks_cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "express-hello-v2"
}

variable "eks_cluster_version" {
  description = "EKS Kubernetes version"
  type        = string
  default     = "1.30"
}

variable "eks_node_instance_type" {
  description = "EKS node instance type"
  type        = string
  default     = "t3.small"
}

variable "eks_node_min_size" {
  description = "EKS node group minimum size"
  type        = number
  default     = 1
}

variable "eks_node_max_size" {
  description = "EKS node group maximum size"
  type        = number
  default     = 3
}

variable "eks_node_desired_size" {
  description = "EKS node group desired size"
  type        = number
  default     = 1
}

variable "eks_admin_role_arns" {
  description = "IAM role ARNs granted cluster-admin access via EKS access entries"
  type        = list(string)
}

variable "app_name" {
  description = "Mandatory tag: application name"
  type        = string
}

variable "environment" {
  description = "Mandatory tag: environment (dev|test|staging|prod|lab)"
  type        = string

  validation {
    condition     = contains(["dev", "test", "staging", "prod", "lab"], var.environment)
    error_message = "environment must be one of: dev, test, staging, prod, lab."
  }
}

variable "business_unit" {
  description = "Mandatory tag: business unit"
  type        = string
}

variable "cost_center" {
  description = "Mandatory tag: cost center"
  type        = string
}

variable "owner_business" {
  description = "Mandatory tag: business owner"
  type        = string
}

variable "owner_technical" {
  description = "Mandatory tag: technical owner"
  type        = string
}

variable "data_classification" {
  description = "Mandatory tag: data classification"
  type        = string
}

variable "service_tier" {
  description = "Recommended tag: service tier"
  type        = string
  default     = ""
}

variable "compliance_scope" {
  description = "Recommended tag: compliance scope"
  type        = string
  default     = ""
}

variable "lifecycle_stage" {
  description = "Recommended tag: lifecycle"
  type        = string
  default     = ""
}

variable "repo" {
  description = "Recommended tag: repository URL or name"
  type        = string
  default     = ""
}

variable "deployment_method" {
  description = "Recommended tag: deployment method"
  type        = string
  default     = ""
}

variable "support_contact" {
  description = "Recommended tag: support contact"
  type        = string
  default     = ""
}

variable "customer_facing" {
  description = "Optional tag: customer facing"
  type        = string
  default     = ""
}

variable "rto_hours" {
  description = "Optional tag: RTO in hours"
  type        = string
  default     = ""
}

variable "rpo_minutes" {
  description = "Optional tag: RPO in minutes"
  type        = string
  default     = ""
}

variable "backup_enabled" {
  description = "Optional tag: backups enabled"
  type        = string
  default     = ""
}

variable "monitoring_enabled" {
  description = "Optional tag: monitoring enabled"
  type        = string
  default     = ""
}
