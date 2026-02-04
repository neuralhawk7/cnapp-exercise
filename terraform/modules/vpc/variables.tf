variable "name" {
  type        = string
  description = "Name prefix for resources"
}

variable "cidr_block" {
  type        = string
  description = "VPC CIDR block"
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  type        = list(string)
  description = "List of public subnet CIDRs"
  default     = ["10.0.1.0/24"]
}

variable "azs" {
  type        = list(string)
  description = "List of AZs to use"
  default     = []
}
