variable "region" {
  type    = string
  default = "us-west-1"
}

variable "name" {
  type    = string
  default = "education"
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_cidr" {
  type        = string
  description = "New public subnet CIDR inside 10.0.0.0/16, e.g. 10.0.90.0/24"
  default     = "10.0.90.0/24"
}

variable "public_subnet_az" {
  type        = string
  description = "AZ for the public subnet, e.g. us-west-1a or us-west-1c"
  default     = "us-west-1a"
}

variable "key_name" {
  type        = string
  description = "Existing EC2 key pair name"
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "mongo_admin_user" {
  type    = string
  default = "admin"
}

variable "mongo_admin_pass" {
  type      = string
  sensitive = true
}
variable "my_ip_cidr" {
  type        = string
  description = "Your public IP in CIDR notation, e.g. 1.2.3.4/32"
}