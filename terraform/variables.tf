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
