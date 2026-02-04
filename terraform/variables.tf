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

# VPC & EKS variables
variable "vpc_cidr" {
  description = "CIDR for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "List of public subnet CIDRs"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "azs" {
  description = "List of availability zones to use for subnets"
  type        = list(string)
  default     = []
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "cnapp-cluster"
}

variable "instance_type" {
  description = "EC2 instance type for Mongo VM"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "SSH key name for EC2 instances"
  type        = string
  default     = ""
}

variable "mongo_admin_user" {
  description = "Mongo admin user"
  type        = string
  default     = "admin"
}

variable "mongo_admin_pass" {
  description = "Mongo admin password"
  type        = string
  sensitive   = true
  default     = "changeme"
}

variable "ssh_ingress_cidr" {
  description = "CIDR for SSH ingress"
  type        = string
  default     = "0.0.0.0/0"
}
