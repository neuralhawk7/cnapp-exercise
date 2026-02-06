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

variable "eks_cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "express-hello"
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
